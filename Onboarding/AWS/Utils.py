import sys
from typing import List, Dict, Set
import pyfiglet

GREEN = '\033[92m'
ORANGE = '\033[38;5;208m'
RED = "\033[91m"
RESET = '\033[0m'  # Reset color to default

IAM_ROLE_ARN_PATTERN = r'^arn:aws:iam::\d{12}:role/[a-zA-Z_0-9+=,.@-]+$'
UNHANDLED_EXCEPTION_MESSAGE = "An unhandled exception occurred while {}"
CUSTOM_BAR_FORMAT = "{desc} {percentage:3.0f}%|{bar}| {n_fmt}/{total_fmt}"


def print_colored_message(message, color):
    print(color + message + RESET)


def print_success(message):
    print_colored_message(message, GREEN)


def print_failure(message):
    print_colored_message(message, RED)


def print_warning(message):
    print_colored_message(message, ORANGE)


def print_region_summary_message(region: str, clusters_to_update: List[str], left_clusters: List[str]):
    num_of_successfully_updated_clusters = len(clusters_to_update) - len(left_clusters)

    if num_of_successfully_updated_clusters > 0:
        print_success(f"Successfully updated {num_of_successfully_updated_clusters} EKS clusters in {region} region")

    if len(left_clusters):
        print_failure(f"Failed on {len(left_clusters)} Eks clusters, due to insufficient permissions.")


def print_summary_message(count_clusters: int, count_failed_clusters_in_all_regions, failed_to_updated_clusters: Dict[str, List[str]], all_regions: Set[str]):
    if count_clusters == 0:
        print("You didn't have any EKS clusters in all regions, exiting...", sys.stderr)
        return

    print(pyfiglet.figlet_format("Summary", font="slant"))
    if count_failed_clusters_in_all_regions == 0:
        print_success(f"Updated successfully all EKS clusters ({count_clusters}) in regions {' '.join(all_regions)}")
        return

    if count_failed_clusters_in_all_regions == count_clusters:
        print("Failed to update all clusters in al regions", file=sys.stderr)
        return

    num_of_successfully_updated_clusters = count_clusters - count_failed_clusters_in_all_regions
    print(f"Out of {count_clusters} EKS clusters, successfully grant permission to {num_of_successfully_updated_clusters} EKS clusters.")
    print_failure("Failed to grant access to the following EKS clusters:")
    for region, clusters in failed_to_updated_clusters.items():
        print_failure(f"{region}: {' '.join(clusters)}")


def print_title():
    print(pyfiglet.figlet_format("Powered By Microsoft"))
