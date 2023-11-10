import pyfiglet
import re
from typing import List, Dict, Set
from shutil import which

GREEN = '\033[92m'
ORANGE = '\033[38;5;208m'
RED = "\033[91m"
RESET = '\033[0m'  # Reset color to default
IAM_ROLE_ARN_PATTERN = r'^arn:aws:iam::\d{12}:role/[a-zA-Z_0-9+=,.@-]+$'
CUSTOM_BAR_FORMAT = "{desc} {percentage:3.0f}%|{bar}| {n_fmt}/{total_fmt}"
DEFAULT_ROLE_ARN_TO_MAP = "arn:aws:iam::{}:role/MDCContainersAgentlessDiscoveryK8sRole"
DEFAULT_REGION = "us-west-1"
DEFAULT_PROFILE_NAME = "default"


def print_colored_message(message: str, color: str) -> None:
    print(color + message + RESET)


def print_warning(message: str) -> None:
    print_colored_message(message, ORANGE)


def add_color(message: str, color: str, with_color: bool) -> str:
    return color + message + RESET if with_color else message


def format_region_cluster_map(region_cluster_map: Dict[str, List[str]], color, with_color) -> List[str]:
    messages = []
    for region, clusters in region_cluster_map.items():
        messages.append(add_color(f"{region}: {' '.join(clusters)}", color, with_color))
    return messages


def format_successful_clusters(failed_clusters_map: Dict[str, List[str]], with_color: bool) -> List[str]:
    success_message = add_color("Successfully granted MDC permission to the following clusters:", GREEN, with_color)
    return [success_message] + format_region_cluster_map(failed_clusters_map, GREEN, with_color)


def format_failed_clusters(failed_clusters_map: Dict[str, List[str]], with_color: bool) -> List[str]:
    failure_message = add_color("Failed to grant MDC permissions to the following clusters:", RED, with_color)
    return [failure_message] + format_region_cluster_map(failed_clusters_map, RED, with_color)


def print_region_summary_message(region: str, clusters_to_update: Set[str], left_clusters: List[str]):
    num_of_successfully_updated_clusters = len(clusters_to_update) - len(left_clusters)

    if num_of_successfully_updated_clusters > 0:
        print_colored_message(f"Successfully updated {num_of_successfully_updated_clusters} EKS clusters in {region} region", GREEN)

    if len(left_clusters):
        print_colored_message(f"Failed on {len(left_clusters)} Eks clusters, due to insufficient permissions.", RED)


def format_summary_messages(failed_clusters_map: Dict[str, List[str]], successful_clusters_map: Dict[str, List[str]], is_all_clusters: bool, with_color: bool) -> str:
    if not failed_clusters_map and not successful_clusters_map:
        message = "You didn't have any EKS clusters in all regions, exiting..." if is_all_clusters else \
            "The EKS clusters you requested to onboard doesn't exist in all requested regions. Make sure you don't have spelling mistakes"
        return add_color(message, RED, with_color)

    if successful_clusters_map and not failed_clusters_map:
        return add_color("Successfully granted MDC permission to all requested EKS clusters", GREEN, with_color)

    summary_messages = []
    if successful_clusters_map:
        summary_messages += format_successful_clusters(successful_clusters_map, with_color)
    else:
        summary_messages.append(add_color("Failed to grant MDC permissions to all EKS clusters", RED, with_color))

    if failed_clusters_map:
        summary_messages += format_failed_clusters(failed_clusters_map, with_color)

    return "\n".join(summary_messages)


def show_summary(failed_clusters_map: Dict[str, List[str]], successful_clusters_map: Dict[str, List[str]], is_all_clusters: bool, output_file: str) -> None:
    print_summary(failed_clusters_map, successful_clusters_map, is_all_clusters)
    write_summary_to_file(failed_clusters_map, successful_clusters_map, is_all_clusters, output_file)


def print_summary(failed_clusters_map: Dict[str, List[str]], successful_clusters_map: Dict[str, List[str]], is_all_clusters: bool) -> None:
    summary = format_summary_messages(failed_clusters_map, successful_clusters_map, is_all_clusters, with_color=True)
    print('\n' + pyfiglet.figlet_format("Summary", font="slant") + '\n')
    print(summary)


def write_summary_to_file(failed_clusters_map: Dict[str, List[str]], successful_clusters_map: Dict[str, List[str]], is_all_clusters: bool, output_file: str) -> None:
    if output_file == "":
        return

    summary = format_summary_messages(failed_clusters_map, successful_clusters_map, is_all_clusters, with_color=False)
    with open(output_file, "w") as file:
        file.write(summary)


def is_role_arn(role_arn: str) -> bool:
    return bool(re.match(r"^arn:aws:[^:]*:[^:]*:[0-9]{12}:role/.*", role_arn))


def print_title() -> None:
    print(pyfiglet.figlet_format("Powered By Microsoft"))


def check_assume_role_permitted(trust_policy_document: Dict[str, Dict]) -> bool:
    for statement in trust_policy_document.get('Statement', []):
        effect = statement.get('Effect', '')
        if effect != 'Allow':
            continue

        actions = statement.get('Action', {})
        if not isinstance(actions, list):
            actions = [actions]

        if "sts:AssumeRole" not in actions:
            return False
    return True


def check_condition(trust_policy_document: Dict[str, Dict], predicate) -> bool:
    for statement in trust_policy_document.get('Statement', []):
        effect = statement.get('Effect', '')
        if effect != 'Allow':
            continue

        conditions = statement.get('Condition', {})
        if predicate(conditions):
            return True
    return False


def is_mfa_required(conditions: Dict[str, Dict[str, str]]) -> bool:
    condition_type, condition_key = 'Bool', 'aws:MultiFactorAuthPresent'
    return conditions.get(condition_type, {}).get(condition_key, "") == "true"


def is_external_id_required(conditions: Dict[str, Dict[str, str]]) -> bool:
    condition_type, value = 'StringEquals', 'sts:ExternalId'
    return conditions.get(condition_type, {}).get(value, "")


def is_source_identity_required(conditions: Dict[str, Dict[str, str]]) -> bool:
    condition_type, value = 'StringEquals', 'sts:SourceIdentity'
    return conditions.get(condition_type, {}).get(value, "")


def check_required_conditions(trust_policy_document: Dict[str, Dict]):
    conditions = {
        "sts:AssumeRole": not check_assume_role_permitted(trust_policy_document),
        "MFA": check_condition(trust_policy_document, is_mfa_required),
        "ExternalId": check_condition(trust_policy_document, is_external_id_required),
        "SourceIdentity": check_condition(trust_policy_document, is_source_identity_required)
    }
    return conditions


def convert_to_role_arns(roles_details: List[Dict[str, Dict]]) -> List[str]:
    return [role_details["Role"]["Arn"] for role_details in roles_details]


def remove_duplicates(lst: List[str], msg: str) -> Set[str]:
    no_dup = set(lst)
    if len(no_dup) != len(lst):
        print_warning(f"You entered duplicate {msg}, ignoring...")
    return no_dup


def check_eksctl() -> bool:
    return which("eksctl") is not None


def env_credentials_is_empty(credentials: Dict[str, str]):
    return credentials["AccessKeyId"] == "" or credentials["SecretAccessKey"] == ""
