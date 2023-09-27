import re
import os
import subprocess
import argparse
import boto3
import botocore
from tqdm import tqdm
from Utils import *
from typing import Set

ROLE_ARN_TO_MAP = "arn:aws:iam::916244236412:role/EksMasterSefiRole"


def validate_roles(session, roles: List[str]):
    for role_arn in roles:
        iam_client = session.client("iam")
        if not re.match(IAM_ROLE_ARN_PATTERN, role_arn):
            print(f"Invalid IAM role ARN format: {role_arn}", file=sys.stderr)
            return False

        try:
            iam_client.get_role(RoleName=role_arn.split('/')[-1])
        except iam_client.exceptions.NoSuchEntityException:
            print(f"IAM role not found: {role_arn}", file=sys.stderr)
            return False
        except botocore.exceptions.UnauthorizedSSOTokenError as ex:
            print(ex.msg, file=sys.stderr)
            return False
        except:
            print("An unhandled exception occurred getting iam role", file=sys.stderr)
        return True


def remove_duplicate_regions(regions: List[str]) -> Set[str]:
    no_dup_regions = set(regions)
    if len(no_dup_regions) != len(regions):
        print_warning("You entered duplicate regions, ignoring duplications...")
    return no_dup_regions


def remove_unavailable_regions(all_available_regions: Set[str], regions_input: Set[str]):
    available_regions = regions_input.intersection(all_available_regions)

    if not available_regions:
        print(f"All of the provided regions are unavailable to you", file=sys.stderr)
    elif len(available_regions) != len(regions_input):
        print_warning(f"Some of the provided regions are unavailable, proceeding only with the available regions {available_regions}")

    return available_regions


def filter_regions(all_available_regions: List[str], regions: List[str]) -> Set[str]:
    all_available_regions = set(all_available_regions)
    if regions == ["*"]:
        return all_available_regions
    filtered_regions = remove_duplicate_regions(regions)
    filtered_regions = remove_unavailable_regions(all_available_regions, filtered_regions)
    return filtered_regions


def parse_arguments():
    parser = argparse.ArgumentParser(description="Update AWS auth for EKS clusters in specified regions")
    parser.add_argument("--regions", nargs='+', help="List of AWS regions or '*' to run for all regions", type=str, required=True)
    parser.add_argument("--roles", nargs='+', help="List of IAM role ARNs", type=str, required=True)
    parser.add_argument("--profile", help="AWS profile name (default: default)", type=str, default="default", required=False)
    args = parser.parse_args()
    return args


def get_all_available_regions(session):
    ec2_client = session.client('ec2')
    return [region['RegionName'] for region in ec2_client.describe_regions()['Regions']]


def get_role_credentials(sts_client, role_to_assume_arn: str):
    session_name = "updateAwsAuthSession"
    try:
        return sts_client.assume_role(RoleArn=role_to_assume_arn, RoleSessionName=session_name)["Credentials"]
    except botocore.exceptions.ClientError as ex:
        if ex.response["Error"]["Code"] == "AccessDenied":
            print(ex.msg)
            exit(1)
    except:
        print(UNHANDLED_EXCEPTION_MESSAGE.format(f"Assuming role {role_to_assume_arn}"), file=sys.stderr)
        exit(1)


def create_iamidentitymapping(cluster_name: str, region: str):
    command = [
        'eksctl',
        'create',
        'iamidentitymapping',
        '--cluster', cluster_name,
        '--region', region,
        '--arn', ROLE_ARN_TO_MAP,
        '--group', 'system:masters',
        '--no-duplicate-arns'
    ]
    try:
        result = subprocess.run(command, capture_output=True, text=True)
    except:
        print("Could not create iamidentity mapping. Make sure you have eksctl installed", file=sys.stderr)
        exit(1)
    return result


def set_credentials(credentials: Dict[str, str]):
    os.environ["AWS_ACCESS_KEY_ID"] = credentials['AccessKeyId']
    os.environ["AWS_SECRET_ACCESS_KEY"] = credentials['SecretAccessKey']
    os.environ["AWS_SESSION_TOKEN"] = credentials['SessionToken']


def get_iamidentitymapping(cluster_name: str, region: str):
    command = [
        'eksctl',
        'get',
        'iamidentitymapping',
        '--region', region,
        '--cluster', cluster_name
    ]
    result = subprocess.run(command, capture_output=True, text=True)
    return result


def get_clusters(eks_client):
    response = eks_client.list_clusters()
    return response.get('clusters', [])


def get_original_credentials():
    return {"AccessKeyId": os.environ.get("AWS_ACCESS_KEY_ID", ""),
            "SecretAccessKey": os.environ.get('AWS_SECRET_ACCESS_KEY', ""),
            "SessionToken": os.environ.get('AWS_SESSION_TOKEN', "")}


def update_clusters(clusters: List[str], region, pbar):
    clusters_to_retry = []
    for cluster in clusters:
        res = create_iamidentitymapping(cluster, region)
        if res.returncode != 0:
            clusters_to_retry.append(cluster)
        else:
            # res = get_iamidentitymapping(cluster, region)
            # print(res.stdout)
            pbar.update(1)
    return clusters_to_retry


def update_aws_auth_for_region(sts_client, clusters, region: str, roles: List[str]):
    print(f"Attempting to create iamidentitymapping for {len(clusters)} EKS clusters in {region} region")
    with tqdm(clusters, total=len(clusters), bar_format=CUSTOM_BAR_FORMAT, desc=f"Progress in {region}", unit=" cluster", ncols=100, file=sys.stdout, colour="GREEN") as pbar:
        for role in roles:
            tqdm.write(f"Assuming role {role}")
            role_credentials = get_role_credentials(sts_client, role)
            set_credentials(role_credentials)

            clusters = update_clusters(clusters, region, pbar)
    return clusters


def update_aws_auth_for_all_regions(session, sts_client, all_regions: Set[str], roles: List[str]):
    print(f"Attempting to grant MDC access to {' '.join(all_regions)} regions")
    count_clusters_in_all_regions = 0
    count_failed_clusters_in_all_regions = 0
    failed_to_updated_clusters = dict()

    for region in all_regions:
        eks_client = session.client("eks", region_name=region)
        clusters_to_update = get_clusters(eks_client)
        if not clusters_to_update:
            print_warning(f"You don't have any EKS clusters in {region} region. Skipping...")
            continue

        left_clusters = update_aws_auth_for_region(sts_client, clusters_to_update, region, roles)
        if left_clusters:
            count_failed_clusters_in_all_regions += len(left_clusters)
            failed_to_updated_clusters[region] = left_clusters
        count_clusters_in_all_regions += len(clusters_to_update)

        print_region_summary_message(region, clusters_to_update, left_clusters)
    return count_clusters_in_all_regions, count_failed_clusters_in_all_regions, failed_to_updated_clusters


def get_session(profile: str):
    try:
        return boto3.Session(profile_name=profile)
    except botocore.exceptions.ProfileNotFound:
        print("The provided profile could not be found", file=sys.stderr)
    except:
        print(UNHANDLED_EXCEPTION_MESSAGE.format(f"getting session for profile {profile}"), file=sys.stderr)


def init():
    args = parse_arguments()
    regions, roles, profile = args.regions, args.roles, args.profile

    session = get_session(profile)
    if not session:
        exit(1)

    if not validate_roles(session, roles):
        exit(1)

    all_available_regions = get_all_available_regions(session)
    all_regions = filter_regions(all_available_regions, regions)
    if not all_regions:
        exit(1)

    return all_regions, roles, session


def run():
    # Save original Env variables to revert to.
    original_credentials = get_original_credentials()

    regions, roles, session = init()

    sts_client = session.client("sts")
    sum_clusters_in_all_regions, count_failed_clusters_in_all_regions, failed_to_updated_clusters = update_aws_auth_for_all_regions(session, sts_client, regions, roles)

    print_summary_message(sum_clusters_in_all_regions, count_failed_clusters_in_all_regions, failed_to_updated_clusters, regions)

    # Reverting to original Env variables.
    set_credentials(original_credentials)


if __name__ == '__main__':
    print_title()
    run()
