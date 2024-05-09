import os
import subprocess
import argparse
import boto3
import botocore
import sys
from tqdm import tqdm
from Utils import *
from time import time
from typing import Tuple


def get_roles_details(session: boto3.Session, roles: List[str]) -> List[Dict[str, Dict]]:
    iam_client = session.client("iam")
    roles_details = list()
    skipped_roles = list()
    for role in roles:
        role_name = role.split("/")[-1] if is_role_arn(role) else role
        try:
            details = iam_client.get_role(RoleName=role_name)
            roles_details.append(details)
        except iam_client.exceptions.NoSuchEntityException:
            skipped_roles.append(role_name)
        except Exception as ex:
            sys.exit(str(ex))

    if not roles_details:
        sys.exit("You didn't provide any valid roles to onboard. Please make sure you provide valid roles names or ARNs")

    for role in skipped_roles:
        print_warning(f"Role {role} doesn't exist, skipping...")

    return roles_details


def fileter_unsupported_roles(roles_details: List[Dict[str, Dict]]) -> List[Dict[str, Dict]]:
    supported_roles = []
    unsupported_roles = []

    for role in roles_details:
        trust_policy_document = role["Role"]["AssumeRolePolicyDocument"]
        conditions = check_required_conditions(trust_policy_document)
        if any(conditions.values()):
            unsupported_roles.append((role, conditions))
        else:
            supported_roles.append(role)

    if not supported_roles:
        sys.exit("All of the provided roles are not supported. Please make sure the roles you provided doesn't require MFA, ExternalId, or SourceIdentity")

    for role, conditions in unsupported_roles:
        role_arn = role['Role']['Arn']
        warnings = [f"Role {role_arn} doesn't allow sts:AssumeRole action. Skipping..."
                    if condition == "sts:AssumeRole" else f"Role {role_arn} requires {condition}, which is currently not supported. Skipping..."
                    for condition, required in conditions.items() if required]
        print_warning("\n".join(warnings))

    return supported_roles


def remove_unavailable_regions(session: boto3.Session, regions_input: Set[str]) -> Set[str]:
    all_available_regions = set(get_all_available_regions(session))
    available_regions = regions_input.intersection(all_available_regions)

    if not available_regions:
        sys.exit(f"All of the provided regions are unavailable to you")

    elif len(available_regions) != len(regions_input):
        print_warning(f"Some of the provided regions are unavailable: {regions_input - available_regions}. Skipping...")

    return available_regions


def parse_file_parameter(file_name: str) -> List[str]:
    if not os.path.exists(file_name):
        sys.exit(f"File '{file_name}' does not exist")

    if not os.access(file_name, os.R_OK):
        sys.exit(f"The file {file_name} has no read permissions")

    with open(file_name, 'r') as file:
        values = [line.strip() for line in file.readlines()]
        if not values:
            sys.exit(f"The file {file_name} is empty")
        return values


def set_credentials(credentials: Dict[str, str]) -> None:
    os.environ["AWS_ACCESS_KEY_ID"] = credentials['AccessKeyId']
    os.environ["AWS_SECRET_ACCESS_KEY"] = credentials['SecretAccessKey']
    os.environ["AWS_SESSION_TOKEN"] = credentials['SessionToken']


def get_original_credentials() -> Dict[str, str]:
    return {"AccessKeyId": os.environ.get("AWS_ACCESS_KEY_ID", ""),
            "SecretAccessKey": os.environ.get('AWS_SECRET_ACCESS_KEY', ""),
            "SessionToken": os.environ.get('AWS_SESSION_TOKEN', ""),
            "DefaultRegion": os.environ.get('AWS_DEFAULT_REGION', "")}


def validate_output_file(output_file: str) -> bool:
    return output_file == "" or not os.path.exists(output_file) or os.access(output_file, os.W_OK)


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=f"Granting access to MDC to query EKS clusters."
                                                 f"\nThe script adds MDC role {DEFAULT_ROLE_ARN_TO_MAP.format('<account id>')} to the aws-auth of specified EKS clusters.")
    regions_group = parser.add_mutually_exclusive_group(required=True)
    regions_group.add_argument("--regions", nargs='+', help="List of AWS regions, separated by space", type=str)
    regions_group.add_argument("--all-regions", help="Run for all available AWS regions (if there is a region with no EKS clusters, the script would skip it)", action="store_true")
    regions_group.add_argument("--regions-file", help="A path to a txt file contains a list of regions separated by new lines", type=str)

    roles_group = parser.add_mutually_exclusive_group(required=True)
    roles_group.add_argument("--roles", nargs='+', help="List of IAM roles names (or ARNs), separated by space", type=str)
    roles_group.add_argument("--roles-file", help="A path to a txt file contains a list of IAM roles names (or ARNs) separated by new lines", type=str)

    clusters_group = parser.add_mutually_exclusive_group(required=True)
    clusters_group.add_argument("--clusters", nargs='+', help="List of EKS clusters name (that deployed in the provided regions), separated by space", type=str)
    clusters_group.add_argument("--all-clusters", help="Run for all EKS clusters in the provided regions", action="store_true")
    clusters_group.add_argument("--clusters-file", help="A path to a txt file contains a list of EKS clusters name separated by new lines", type=str)

    parser.add_argument("--profile", help=f"AWS profile name (default: {DEFAULT_PROFILE_NAME})", type=str, default=DEFAULT_PROFILE_NAME, required=False)
    parser.add_argument("--output-file", help=f"A path to a txt file which will contain the script summary (In addition to showing the summary in the console)\n"
                                              f"Please note: if the file does not exist, hte script would create it in the specified location", default="", type=str, required=False)

    parser.add_argument("--role-arn", help=f"The role arn to map to system:masters group in aws-auth ConfigMap (default: {DEFAULT_ROLE_ARN_TO_MAP.format('account')})", type=str,
                        default=DEFAULT_ROLE_ARN_TO_MAP, required=False)
    args = parser.parse_args()
    return args


def get_all_available_regions(session: boto3.Session) -> List[str]:
    try:
        ec2_client = session.client('ec2')
        return [region['RegionName'] for region in ec2_client.describe_regions()['Regions']]
    except Exception as ex:
        sys.exit(str(ex))


def get_role_credentials(session: boto3.Session, role_to_assume: str) -> Dict[str, str]:
    session_name = f"GrantAccessToEksClusters-{int(time())}"
    try:
        sts_client = session.client("sts")
        tqdm.write(f"Assuming role {role_to_assume}")
        return sts_client.assume_role(RoleArn=role_to_assume, RoleSessionName=session_name)["Credentials"]
    except Exception as ex:
        sys.exit(str(ex))


def create_iamidentitymapping(cluster_name: str, region: str, role_to_map: str) -> int:
    command = [
        'eksctl',
        'create',
        'iamidentitymapping',
        '--cluster', cluster_name,
        '--region', region,
        '--arn', role_to_map,
        '--group', 'system:masters',
        '--no-duplicate-arns'
    ]
    try:
        result = subprocess.run(command, capture_output=True, text=True)
        return result.returncode
    except subprocess.CalledProcessError as ex:
        sys.exit(f"Could not create IAM identity mapping.\n{ex.stderr}")


def get_all_eks_clusters(eks_client) -> List[str]:
    try:
        response = eks_client.list_clusters()
        return response.get('clusters', [])
    except Exception as ex:
        sys.exit(str(ex))


def update_clusters(clusters: List[str], region: str, pbar: tqdm, role_to_map: str) -> List[str]:
    clusters_to_retry = []
    for cluster in clusters:
        return_code = create_iamidentitymapping(cluster, region, role_to_map)
        if return_code != 0:
            clusters_to_retry.append(cluster)
        else:
            pbar.update(1)
    return clusters_to_retry


def get_clusters_to_onboard(session: boto3.Session, region: str, requested_clusters: Set[str], is_all_clusters: bool) -> Set[str]:
    eks_client = session.client("eks", region_name=region)
    clusters_in_region = get_all_eks_clusters(eks_client)

    if not clusters_in_region:
        print_warning(f"You don't have any EKS clusters deployed in {region} region. Skipping...")
        return set()

    if is_all_clusters:
        return set(clusters_in_region)

    clusters_to_onboard = set(clusters_in_region).intersection(requested_clusters)
    if not clusters_to_onboard:
        print(f"The requested EKS clusters are not deployed in {region} region. Skipping...")
    return clusters_to_onboard


def get_account_id(session: boto3.Session) -> str:
    sts_client = session.client("sts")
    try:
        return sts_client.get_caller_identity().get("Account")
    except Exception as ex:
        sys.exit(str(ex))


def update_aws_auth_for_region(session: boto3.Session, clusters: Set[str], region: str, roles: List[str], role_to_map: str) -> List[str]:
    print(f"Attempting to create iamidentitymapping for {len(clusters)} EKS clusters in {region} region")
    with tqdm(clusters, total=len(clusters), bar_format=CUSTOM_BAR_FORMAT, desc=f"Progress in {region}", unit=" cluster", ncols=100, file=sys.stdout, colour="GREEN") as pbar:
        for role in roles:
            role_credentials = get_role_credentials(session, role)
            set_credentials(role_credentials)

            clusters = update_clusters(clusters, region, pbar, role_to_map)
            if not clusters:
                break
    return clusters


def update_aws_auth_for_all_regions(session: boto3.Session, args: argparse.Namespace) -> Tuple[Dict[str, List[str]], Dict[str, List[str]]]:
    print(f"Attempting to grant MDC access to {' '.join(args.regions)} regions")
    successful_clusters_map = dict()
    failed_clusters_map = dict()

    for region in args.regions:
        clusters_to_onboard = get_clusters_to_onboard(session, region, args.clusters, args.all_clusters)
        if not clusters_to_onboard:
            continue

        left_clusters = update_aws_auth_for_region(session, clusters_to_onboard, region, args.roles, args.role_arn)

        successful_clusters = list(set(clusters_to_onboard) - set(left_clusters))
        if successful_clusters:
            successful_clusters_map[region] = successful_clusters
        if left_clusters:
            failed_clusters_map[region] = left_clusters

        print_region_summary_message(region, clusters_to_onboard, left_clusters)
    return failed_clusters_map, successful_clusters_map


def get_session(profile: str, credentials: Dict[str, str]) -> boto3.Session:
    if profile == DEFAULT_PROFILE_NAME and not env_credentials_is_empty(credentials):
        default_region = credentials["DefaultRegion"] if credentials["DefaultRegion"] != "" else DEFAULT_REGION
        print("Starting session...")
        try:
            return boto3.Session(aws_access_key_id=credentials["AccessKeyId"], aws_secret_access_key=credentials["SecretAccessKey"], region_name=default_region)
        except Exception as ex:
            sys.exit(str(ex))

    try:
        print(f"Starting session for profile {profile}...")
        return boto3.Session(profile_name=profile, region_name=DEFAULT_REGION)
    except botocore.exceptions.ProfileNotFound:
        if profile == DEFAULT_PROFILE_NAME:
            sys.exit(f"You didn't configure a {DEFAULT_PROFILE_NAME} profile\n"
                     f"Either configure a default profile (see ReadMe) or set environment variables with the account credentials you wish to onboard.")
        sys.exit(f"The provided profile ({profile}) could not be found")
    except Exception as ex:
        print(DEFAULT_REGION)


def init_roles(session: boto3.Session, args: argparse.Namespace) -> List[str]:
    roles = args.roles
    if args.roles_file:
        roles = parse_file_parameter(args.roles_file)

    roles_details = get_roles_details(session, roles)
    roles_details = fileter_unsupported_roles(roles_details)
    return convert_to_role_arns(roles_details)


def init_clusters(args: argparse.Namespace) -> List[str]:
    if args.all_clusters:
        return []

    clusters = args.clusters
    if args.clusters_file:
        clusters = parse_file_parameter(args.clusters_file)

    return list(remove_duplicates(clusters, "clusters names"))


def init_regions(session: boto3.Session, args: argparse.Namespace) -> List[str]:
    if args.all_regions:
        return get_all_available_regions(session)

    regions = args.regions
    if args.regions_file:
        regions = parse_file_parameter(args.regions_file)

    regions = remove_duplicates(regions, "regions")
    return list(remove_unavailable_regions(session, regions))


def init_output_file(args: argparse.Namespace) -> str:
    if not validate_output_file(args.output_file):
        print_warning(f"The file {args.output_file} has no write permissions. The summary would not be written to the file")
        return ""
    return args.output_file


def init_role_arn(session: boto3.Session, args: argparse.Namespace) -> str:
    role_to_map = args.role_arn.format(get_account_id(session))
    print(f"The script will create iamidentitymapping between {role_to_map} to system:masters group")
    return role_to_map


def init(original_credentials: Dict[str, str]) -> Tuple[boto3.Session, argparse.Namespace]:
    args = parse_arguments()
    print_title()
    session = get_session(args.profile, original_credentials)

    # Those function exit when error occurs:
    args.clusters = init_clusters(args)
    args.roles = init_roles(session, args)
    args.regions = init_regions(session, args)
    args.role_arn = init_role_arn(session, args)

    # Those function doesn't exist when error occurs:
    args.output_file = init_output_file(args)

    if not args.all_clusters and len(args.regions) > len(args.clusters):
        print_warning("You entered more regions than EKS clusters names. Will skip regions without the specified clusters.")
    return session, args


def run():
    if not check_eksctl():
        sys.exit("Please make sure you have eksctl installed and added to the PATH")

    # Save original Env variables to revert to.
    original_credentials = get_original_credentials()

    session, args = init(original_credentials)

    failed_clusters_map, successful_clusters_map = update_aws_auth_for_all_regions(session, args)

    show_summary(failed_clusters_map, successful_clusters_map, args.all_clusters, args.output_file)

    # Reverting to original Env variables.
    set_credentials(original_credentials)


if __name__ == '__main__':
    run()
