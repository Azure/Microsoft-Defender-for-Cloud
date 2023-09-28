# Grant Access to EKS Clusters Script
This Python script is used to automates the process of granting MDC access to query your EKS clusters in account.

## Prerequisites:
Python 3.4
pip 23.0
eksctl 0.155
Packages in requirements.txt

# Steps to run the script
1. Download the AWS directory.
2. Sign in to your AWS account from your favorite CLI tool (CMD/PowerShell/Bash).
3. Run the Python script from the singed in CLI with the following parameters:
--regions: List of AWS regions or '*' to run for all regions (Required).
--roles: List of IAM role ARNs (Required).
--profile: AWS profile name (Optional, default: default).

Important Note: if you don't specify profile, the script would try to run with your default profile.
If you didn't configure default profile the script would fail with the following message:
The provided profile (default) could not be found.
