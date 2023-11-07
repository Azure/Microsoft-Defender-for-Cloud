# Grant Access to EKS Clusters Script

The Python script automates the process of granting MDC (Microsoft Defender for Cloud) permissions to query your EKS (Amazon Elastic Kubernetes Service) clusters. It is designed to be run within the context of an AWS account, which means **you should execute the script from a CLI (Command Line Interface) that is properly configured to access your AWS account**. Please refer to the details below for more information on AWS account configuration.

The script grants access by adding to the `aws-auth ConfigMap` an IAM identity mapping between MDC role (`arn:aws:iam::<account id>:role/MDCContainersAgentlessDiscoveryK8sRole` by default) to the `system:masters` group.
Therefore, the script requires a list of roles among other parameters, which should have permissions to update the `aws-auth` configuration of the EKS clusters you intend to onboard. For instance, the roles used to create the EKS clusters typically possess these required permissions.
**If you don't know/have the roles that created the EKS clusters, unfortunately you can't use this script**.

In addition, the script acquires temporary credentials by assuming the provided roles. Therefore, the principal who runs the script must have the necessary permissions to assume these roles. In other words, **the principal should be explicitly trusted according to the role's Trust Policy**.

## Prerequisites

Before you can run the script, make sure you have the following prerequisites (or higher) installed on your system:

- **Python 3.4**
- **Windows: pip 23.0 | Linux: pip 21.3 (optional)**
- **eksctl 0.155**
- Packages listed in `requirements.txt`

**Note**: The recommended way is to *first create a venv* (virtual environment) and *then* install the packages using:
- Windows
```cmd:
pip install -r requirements.txt
```
- Bash
```Bash:
pip3 install -r requirements.txt
```
If you want to install those packages using another package manager, then you don't need pip.

## Installation

**Download or Clone the Repository**

   You can use the following command to clone the repository:

   ```cmd
   git clone https://github.com/Azure/Microsoft-Defender-for-Cloud.git
   ```

# AWS Account Configuration

Before running the script, you will need to have AWS API credentials configured. What works for AWS CLI should be sufficient.
This guide does not explain how to configure AWS credentials. Here, we'll list two ways the script supports:

1. **AWS Credentials**
   Configure your AWS credentials by creating a profile in the [.aws/credentials file](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html).

2. **Environment Variables**
   Alternatively, you can set [environment variables](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html) to store your AWS access and secret keys.

**Please Note**: If you set environment variables, and also have a default profile, the credentials that would be used is the ones defined via environment variables.

**Permissions Required**: The principal who runs the script should have (at least) the following AWS IAM permissions:

- `ec2:DescribeRegions`: This permission is required to list AWS regions.
- `sts:AssumeRole`: This permission is necessary to assume the roles specified in the script (in addition to the role to trust the principal who runs the script).
- `sts:GetCallerIdentity`: This is used to obtain the caller's account id.
- `eks:ListClusters`: Required to list EKS clusters in the specified regions.
- `iam:GetRole`: This permission is needed to fetch details about the IAM roles specified in the script.

# Steps to Run the Script

Now that you have your AWS account properly configured and the prerequisites installed, follow these steps to run the Python script:

Open your preferred command-line interface (CLI), navigate to the script's directory, and run the script with the desired parameters.
### Regions:

You can specify the regions of the EKS clusters you wish to onboard using **one** of the following options:
- `--regions`: List of AWS regions, separated by space.
- `--all-regions`: Run for all available AWS regions (if there is a region with no EKS clusters, the script would skip it).
- `--regions-file`: A path to a txt file containing a list of regions separated by new lines.

### EKS Clusters Names:
You can specify the EKS clusters names you wish to onboard using **one** of the following options:

- `--clusters`: List of EKS clusters names, separated by space.
- `--all-clusters`: Run for all EKS clusters in the specified regions.
- `--clusters-file`: A path to a txt file contains a list of EKS clusters name separated by new lines.

### IAM Roles:
You can specify the roles names (or ARNs) that *has permission to grant access to the EKS clusters you wish to onboard*, using **one** of the following options:
- `--roles`: List of IAM roles names (or ARNs), separated by space.
- `--roles-file`: A path to a txt file contains a list of IAM roles names (or ARNs) separated by new lines. <br>

**Note**: The script supports roles with Trust Policies that trust the principal executing the script. However, the role's Trust Policy should not include any additional conditions that restrict who can run the script. For instance, if role 'A' trusts the principal running the script but requires MFA (Multi-Factor Authentication), the script will not succeed.

### Profile (optional):
You can specify the AWS profile name that has permissions to assume the provided roles. If you don't specify any profile, the script will use the default profile. If a default profile is not configured, the script will fail.
- `--profile`: The AWS profile name that has permissions to assume to provided roles (default: default).

### Output file (optional):
You can specify a path to an output file to which a summary would be written (in addition to writing it to the console).
- `----output-file`: A path to a txt file which will contain the script summary (In addition to showing the summary in the console). **Please note**: if the file does not exist, the script would create it in the specified location.

### Role to Map (optional):
You can specify the role arn to map to system:masters group in aws-auth ConfigMap. If you don't specify any role, the script will map arn:aws:iam::<account id>:role/MDCContainersAgentlessDiscoveryK8sRole role.<br>
**Note**: The role arn should match exactly the role created by the cloudFormation script you ran during the creation of the Connector. The default role arn here, is the same as the cloudFormation script default.
- `--role-arn`: The role arn to map to system:masters group in aws-auth ConfigMap (default: arn:aws:iam::<account>:role/MDCContainersAgentlessDiscoveryK8sRole).


# Examples (Windows):
Note: the commands assume you navigated to the script directory.

Getting the script help menu:
```
python GrantAccessToEksClusters.py -h
```

Running the script with input from files:
```
python GrantAccessToEksClusters.py --regions-file regions.txt --clusters-file clusters.txt --roles-file roles.txt
```

Running the script with inline input:
```
python GrantAccessToEksClusters.py --regions us-east-1 us-east-2 ap-south-1 --clusters cluster1 clustet2 cluster3 --roles arn:aws:iam::123456789123:role/role1 role2
```

Running the script to onboard all EKS clusters in the account:
```
python GrantAccessToEksClusters.py --all-regions --all-clusters --roles arn:aws:iam::123456789123:role/role1 arn:aws:iam::123456789123:role/role2
```

You can also use different kinds of parameters:
```
python GrantAccessToEksClusters.py --all-regions --clusters cluster1 cluster2 cluster3 --roles-file roles.txt
```

# Examples (MacOs/Linux):
Note: the commands assume you navigated to the script directory.

Getting the script help menu:
```
python3 GrantAccessToEksClusters.py -h
```

Running the script with input from files:
```
python3 GrantAccessToEksClusters.py --regions-file regions.txt --clusters-file clusters.txt --roles-file roles.txt
```

Running the script with inline input:
```
python3 GrantAccessToEksClusters.py --regions us-east-1 us-east-2 ap-south-1 --clusters cluster1 clustet2 cluster3 --roles arn:aws:iam::123456789123:role/role1 role2
```

Running the script to onboard all EKS clusters in the account:
```
python3 GrantAccessToEksClusters.py --all-regions --all-clusters --roles arn:aws:iam::123456789123:role/role1 arn:aws:iam::123456789123:role/role2
```

You can also use different kinds of parameters:
```
python3 GrantAccessToEksClusters.py --all-regions --clusters cluster1 cluster2 cluster3 --roles-file roles.txt
```

# Notes: 
1. The script iterates over all provided roles and clusters, and for each role-cluster pair, it attempts to grant access. If the role already has access to the cluster, the script would skip it and continue to the next role-cluster pair.
2. The more you'd be specific with the script parameters (i.e. specific clusters names, specific regions) the faster it would run.
3. The script does not support IAM roles that impose any limitations on who can assume them, including but not limited to: MFA (Multi-Factor Authentication), ExternalId, or SourceIdentity.