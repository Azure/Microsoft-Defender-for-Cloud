terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Required for "iam-assumable-role-with-oidc" submodule
module "iam" {
  source  = "terraform-aws-modules/iam/aws"
  version = "~> 5.0.0"
}

# Holds the affective account id
data "aws_caller_identity" "current" {}

# holds the aws url
data "aws_partition" "current" {}

resource "aws_iam_openid_connect_provider" "ASCDefendersOIDCIdentityProvider" {
  url             = "https://sts.windows.net/${var.aad_tenant_id}/"
  client_id_list  = var.oidc_client_id_list
  thumbprint_list = var.oidc_thumbprint_list
}

######################################## CSPM #########################################

resource "aws_iam_policy" "CspmMonitorAwsDenyPolicy" {
  name        = "CspmMonitorAwsDenyPolicy"
  description = "Deny policy to limit CSPM Permissions"
  count       = contains(var.offerings, local.DefenderForCspmOfferingName) ? 1 : 0
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Deny",
        "Action" : [
          "aws-portal:*",
          "cur:*"
        ],
        "Resource" : "*"
      }
    ]
  })
}

module "CspmIamRole" {
  source      = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version     = "~> 5.0.0"
  count       = contains(var.offerings, local.DefenderForCspmOfferingName) ? 1 : 0
  create_role = true
  # Default name - if changed, please update Azure security connector file
  role_name        = "CspmMonitorAws"
  role_description = ""
  provider_url     = "sts.windows.net/${var.aad_tenant_id}/"

  role_policy_arns = [
    "arn:aws:iam::aws:policy/ReadOnlyAccess",
    aws_iam_policy.CspmMonitorAwsDenyPolicy[0].arn
  ]

  oidc_fully_qualified_audiences = [
    "api://4d8bed1f-eee7-4d8e-b0dc-8462049a4479"
  ]

  number_of_role_policy_arns = 2
}

resource "aws_iam_policy" "DefenderForServers_VmScanner" {
  name        = "AzureSecurityCenter_DefenderForServers_VmScanner"
  description = "Microsoft Defender for Servers VM Scanner access policy"
  count       = contains(var.offerings, local.DefenderForCspmOfferingName) ? 1 : 0

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "VmScannerDeleteSnapshotAccess",
        "Effect" : "Allow",
        "Action" : "ec2:DeleteSnapshot",
        "Resource" : "arn:aws:ec2:*::snapshot/*",
        "Condition" : {
          "StringEquals" : {
            "ec2:ResourceTag/CreatedBy" : "Microsoft Defender for Cloud"
          }
        }
      },
      {
        "Sid" : "VmScannerAccess",
        "Effect" : "Allow",
        "Action" : [
          "ec2:ModifySnapshotAttribute",
          "ec2:DeleteTags",
          "ec2:CreateTags",
          "ec2:CreateSnapshots",
          "ec2:CreateSnapshot"
        ],
        "Resource" : [
          "arn:aws:ec2:*:*:instance/*",
          "arn:aws:ec2:*::snapshot/*",
          "arn:aws:ec2:*:*:volume/*"
        ]
      },
      {
        "Sid" : "VmScannerVerificationAccess",
        "Effect" : "Allow",
        "Action" : [
          "ec2:DescribeSnapshots",
          "ec2:DescribeInstanceStatus"
        ],
        "Resource" : "*"
      }
    ]
  })
}

module "DefenderForServersVmScannerRole" {
  source      = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version     = "~> 5.0.0"
  count       = contains(var.offerings, local.DefenderForCspmOfferingName) ? 1 : 0
  create_role = true
  # Default name - if changed, please update Azure security connector file
  role_name        = var.DefenderForServersVmScannerRoleName
  role_description = "Microsoft Defender for Servers VM Scanner role"
  provider_url     = "sts.windows.net/${var.aad_tenant_id}/"

  oidc_fully_qualified_audiences = [
    "api://AzureSecurityCenter.MultiCloud.DefenderForServers.VmScanner"
  ]

  role_policy_arns = [
    aws_iam_policy.DefenderForServers_VmScanner[0].arn
  ]
  number_of_role_policy_arns = 1
}

######################################## Defender for servers + Defender for Data #########################################

resource "aws_iam_policy" "AzureSecurityCenter_DefenderForServers" {
  name        = "AzureSecurityCenter_DefenderForServers"
  description = "Microsoft Defender for Servers policy"
  count       = contains(var.offerings, local.DefenderForServersOfferingName) ? 1 : 0
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "JitNetworkAccess",
        "Effect" : "Allow",
        "Action" : [
          "ec2:RevokeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:DescribeInstances",
          "ec2:DescribeSecurityGroupRules",
          "ec2:DescribeVpcs",
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:ModifyNetworkInterfaceAttribute",
          "ec2:ModifySecurityGroupRules",
          "ec2:ModifyInstanceAttribute",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups"
        ],
        "Resource" : "*"
      }
    ]
  })
}

module "DefenderForServersRole" {
  source      = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version     = "~> 5.0.0"
  count       = contains(var.offerings, local.DefenderForServersOfferingName) ? 1 : 0
  create_role = true
  # Default name - if changed, please update Azure security connector file
  role_name        = var.DefenderForServersRoleName
  role_description = "Azure Security Center - Defender For Servers VmScanner role"
  provider_url     = "sts.windows.net/${var.aad_tenant_id}/"

  role_policy_arns = [
    aws_iam_policy.AzureSecurityCenter_DefenderForServers[0].arn
  ]

  oidc_fully_qualified_audiences = [
    "api://AzureSecurityCenter.MultiCloud.DefenderForServers"
  ]

  number_of_role_policy_arns = 1
}

resource "aws_iam_policy" "DefenderForCloud_ArcAutoProvisioning" {
  name        = "DefenderForCloud_ArcAutoProvisioning"
  description = "Microsoft Defender for Cloud Arc Auto Provisioning policy"
  count       = contains(var.offerings, local.DefenderForServersOfferingName) || contains(var.offerings, local.DefenderForDatabasesOfferingName) ? 1 : 0

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "RunInstallationCommands",
        "Effect" : "Allow",
        "Action" : "ssm:SendCommand",
        "Resource" : [
          "arn:aws:ssm:*::document/AWS-RunPowerShellScript",
          "arn:aws:ssm:*::document/AWS-RunShellScript",
          "arn:aws:ec2:*:${local.account_id}:instance/*"
        ]
      },
      {
        "Sid" : "CheckInstallationCommandStatus",
        "Effect" : "Allow",
        "Action" : [
          "ssm:CancelCommand",
          "ssm:DescribeInstanceInformation",
          "ssm:GetCommandInvocation"
        ],
        "Resource" : "*"
      }
    ]
  })
}

module "DefenderForCloudArcAutoProvisioningRole" {
  source      = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version     = "~> 5.0.0"
  count       = contains(var.offerings, local.DefenderForServersOfferingName) || contains(var.offerings, local.DefenderForDatabasesOfferingName) ? 1 : 0
  create_role = true
  # Default name - if changed, please update Azure security connector file
  role_name        = var.ArcAutoProvisioningRoleName
  role_description = "Microsoft Defender for Cloud Arc Auto Provisioning role"
  provider_url     = "sts.windows.net/${var.aad_tenant_id}/"

  oidc_fully_qualified_audiences = [
    "api://AzureSecurityCenter.MultiCloud.DefenderForServers"
  ]

  role_policy_arns = [
    aws_iam_policy.DefenderForCloud_ArcAutoProvisioning[0].arn
  ]
  number_of_role_policy_arns = 1
}

data "aws_iam_policy_document" "sts_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ssm.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "SSMMDCSetupEnableExplorerInlinePolicy" {
  statement {
    effect = "Allow"
    actions = [
      "iam:ListRoles",
      "config:DescribeConfigurationRecorders",
      "compute-optimizer:GetEnrollmentStatus",
      "support:DescribeTrustedAdvisorChecks"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "ssm:UpdateServiceSetting",
      "ssm:GetServiceSetting"
    ]
    resources = [
      "arn:${local.partition}:ssm:*:*:servicesetting/ssm/opsitem/ssm-patchmanager",
      "arn:${local.partition}:ssm:*:*:servicesetting/ssm/opsitem/EC2",
      "arn:${local.partition}:ssm:*:*:servicesetting/ssm/opsdata/ExplorerOnboarded",
      "arn:${local.partition}:ssm:*:*:servicesetting/ssm/opsdata/Association",
      "arn:${local.partition}:ssm:*:*:servicesetting/ssm/opsdata/ComputeOptimizer",
      "arn:${local.partition}:ssm:*:*:servicesetting/ssm/opsdata/ConfigCompliance",
      "arn:${local.partition}:ssm:*:*:servicesetting/ssm/opsdata/OpsData-TrustedAdvisor",
      "arn:${local.partition}:ssm:*:*:servicesetting/ssm/opsdata/SupportCenterCase"
    ]
  }
  statement {
    effect  = "Allow"
    actions = ["iam:CreateServiceLinkedRole"]
    resources = [
      "arn:${local.partition}:iam::*:role/aws-service-role/ssm.${local.aws_dns_suffix}/AWSServiceRoleForAmazonSSM"
    ]
    condition {
      test     = "StringLike"
      variable = "iam:AWSServiceName"
      values = [
        "ssm.${local.aws_dns_suffix}"
      ]
    }
  }
}

data "aws_iam_policy_document" "AWS-MDCSetup-SSMHostMgmt-CreateAndAttachRoleInlinePolicy" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetAutomationExecution",
      "ec2:DescribeIamInstanceProfileAssociations",
      "ec2:DisassociateIamInstanceProfile",
      "ec2:DescribeInstances",
      "ssm:StartAutomationExecution",
      "iam:GetInstanceProfile",
      "iam:ListInstanceProfilesForRole"
    ]
    resources = ["*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["iam:AttacheRolePolicy"]
    resources = var.IsPolicyAttachAllowed == true ? ["*"] : ["arn:${local.partition}:iam::${local.account_id}:role/AmazonSSMRoleForInstancesMDCSetup"]
    condition {
      test     = "ArnEquals"
      variable = "iam:PolicyARN"
      values = [
        "arn:${local.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore",
        "arn:${local.partition}:iam::aws:policy/AmazonSSMPatchAssociation"
      ]
    }
  }

  statement {
    effect  = "Allow"
    actions = ["iam:AddRoleToInstanceProfile"]
    resources = [
      "arn:${local.partition}:iam::${local.account_id}:instance-profile/AmazonSSMRoleForInstancesMDCSetup"
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["ec2:AssociateIamInstanceProfile"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "ec2:NewInstanceProfile"
      values = [
        "arn:${local.partition}:iam::${local.account_id}:instance-profile/AmazonSSMRoleForInstancesMDCSetup"
      ]
    }
  }

  statement {
    effect  = "Allow"
    actions = ["iam:CreateInstanceProfile"]
    resources = [
      "arn:${local.partition}:iam::${local.account_id}:instance-profile/AmazonSSMRoleForInstancesMDCSetup"
    ]
  }

  statement {
    effect  = "Allow"
    actions = ["iam:GetRole"]
    resources = [
      "arn:${local.partition}:iam::${local.account_id}:role/AmazonSSMRoleForInstancesMDCSetup",
      "arn:${local.partition}:iam::${local.account_id}:role/AWS-MDCSetup-HostMgmtRole-${var.aws_region}-${var.ConfigurationID}"

    ]
  }

  statement {
    effect  = "Allow"
    actions = ["iam:PassRole"]
    resources = [
      "arn:${local.partition}:iam::${local.account_id}:role/AmazonSSMRoleForInstancesMDCSetup"
    ]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values = [
        "ec2.${local.aws_dns_suffix}"
      ]
    }
  }

  statement {
    effect  = "Allow"
    actions = ["iam:PassRole"]
    resources = [
      "arn:${local.partition}:iam::${local.account_id}:role/AWS-MDCSetup-HostMgmtRole-${var.aws_region}-${var.ConfigurationID}"
    ]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values = [
        "ssm.${local.aws_dns_suffix}"
      ]
    }
  }

  statement {
    effect  = "Allow"
    actions = ["iam:CreateRole"]
    resources = [
      "arn:${local.partition}:iam::${local.account_id}:role/AmazonSSMRoleForInstancesMDCSetup"
    ]
  }

}

resource "aws_iam_role" "RoleForAutomation" {
  name               = "AWS-MDCSetup-HostMgmtRole-${var.aws_region}-${var.ConfigurationID}"
  count              = contains(var.offerings, local.DefenderForServersOfferingName) || contains(var.offerings, local.DefenderForDatabasesOfferingName) ? 1 : 0
  assume_role_policy = data.aws_iam_policy_document.sts_assume_role.json

  inline_policy {
    name   = "SSMHostMgmt-CreateAndAttachRoleInlinePolicy"
    policy = data.aws_iam_policy_document.SSMMDCSetupEnableExplorerInlinePolicy.json
  }

  inline_policy {
    name   = "AWS-MDCSetup-SSMHostMgmt-CreateAndAttachRoleInlinePolicy-${var.aws_region}-${var.ConfigurationID}"
    policy = data.aws_iam_policy_document.AWS-MDCSetup-SSMHostMgmt-CreateAndAttachRoleInlinePolicy.json
  }
}

resource "aws_ssm_document" "CreateAndAttachIAMToInstance" {
  name          = "AWSMDCSetup-CreateAndAttachIAMToInstance-${var.ConfigurationID}"
  count         = contains(var.offerings, local.DefenderForServersOfferingName) || contains(var.offerings, local.DefenderForDatabasesOfferingName) ? 1 : 0
  document_type = "Automation"
  target_type   = "/AWS::EC2::Instance"
  content       = <<DOC
  {
    "description": "Composite document for MDC Setup Managing Instances association. This document ensures IAM role for instance profile is created in account with all required policies",
    "schemaVersion": "0.3",
    "assumeRole": "{{ AutomationAssumeRole }}",
    "parameters": {
      "AutomationAssumeRole": {
        "type": "String"
      },
      "InstanceId": {
        "type": "String"
      },
      "IsPolicyAttachAllowed": {
        "type": "String"
      }
    },
    "mainSteps": [
      {
        "name": "getExistingRoleName",
        "action": "aws:executeScript",
        "inputs": {
          "Runtime": "python3.6",
          "Handler": "getInstanceProfileName",
          "InputPayload": {
            "InstanceId": "{{InstanceId}}"
          },
          "Script": "import boto3\n\ndef getInstanceProfileName(events, context):\n    ec2_client = boto3.client(\"ec2\")\n    response = ec2_client.describe_instances(InstanceIds=[events[\"InstanceId\"]])\n    if 'IamInstanceProfile' in response['Reservations'][0]['Instances'][0]:\n        return {'RoleName': response['Reservations'][0]['Instances'][0]['IamInstanceProfile']['Arn'].split('instance-profile/')[1]}\n    return {'RoleName': 'NoRoleFound'}"
        },
        "outputs": [
          {
            "Name": "existingInstanceProfileRoleName",
            "Selector": "$.Payload.RoleName",
            "Type": "String"
          }
        ],
        "nextStep": "branchIfProfileExists"
      },
      {
        "name": "branchIfProfileExists",
        "action": "aws:branch",
        "inputs": {
          "Choices": [
            {
              "NextStep": "createRoleIfNotExists",
              "Variable": "{{getExistingRoleName.existingInstanceProfileRoleName}}",
              "StringEquals": "NoRoleFound"
            }
          ],
          "Default": "checkIfPolicyAttachAllowed"
        }
      },
      {
        "name": "checkIfPolicyAttachAllowed",
        "action": "aws:branch",
        "inputs": {
          "Choices": [
            {
              "NextStep": "getRoleFromInstanceProfile",
              "Variable": "{{IsPolicyAttachAllowed}}",
              "StringEquals": "true"
            }
          ],
          "Default": "createRoleIfNotExists"
        }
      },
      {
        "name": "getRoleFromInstanceProfile",
        "action": "aws:executeAwsApi",
        "inputs": {
          "Service": "iam",
          "Api": "GetInstanceProfile",
          "InstanceProfileName": "{{getExistingRoleName.existingInstanceProfileRoleName}}"
        },
        "outputs": [
          {
            "Name": "existingRoleName",
            "Selector": "$.InstanceProfile.Roles[0].RoleName",
            "Type": "String"
          }
        ],
        "nextStep": "attachAmazonSSMManagedInstanceCoreToExistingRole"
      },
      {
        "name": "attachAmazonSSMManagedInstanceCoreToExistingRole",
        "action": "aws:executeAwsApi",
        "inputs": {
          "Service": "iam",
          "Api": "AttachRolePolicy",
          "RoleName": "{{getRoleFromInstanceProfile.existingRoleName}}",
          "PolicyArn": "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
        },
        "nextStep": "attachAmazonSSMPatchAssociationToExistingRole"
      },
      {
        "name": "attachAmazonSSMPatchAssociationToExistingRole",
        "action": "aws:executeAwsApi",
        "inputs": {
          "Service": "iam",
          "Api": "AttachRolePolicy",
          "RoleName": "{{getRoleFromInstanceProfile.existingRoleName}}",
          "PolicyArn": "arn:aws:iam::aws:policy/AmazonSSMPatchAssociation"
        },
        "isEnd": true
      },
      {
        "name": "createRoleIfNotExists",
        "action": "aws:executeAwsApi",
        "inputs": {
          "Service": "iam",
          "Api": "CreateRole",
          "Path": "/",
          "RoleName": "AmazonSSMRoleForInstancesMDCSetup",
          "AssumeRolePolicyDocument": "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"ec2.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}",
          "Description": "EC2 role for SSM for MDC Setup"
        },
        "description": "Create AmazonSSMRoleForInstancesMDCSetup Role For SSM MDC Setup",
        "onFailure": "Continue",
        "nextStep": "assertRoleForInstanceProfileExists"
      },
      {
        "name": "assertRoleForInstanceProfileExists",
        "action": "aws:assertAwsResourceProperty",
        "inputs": {
          "Service": "iam",
          "Api": "GetRole",
          "PropertySelector": "$.Role.RoleName",
          "DesiredValues": [
            "AmazonSSMRoleForInstancesMDCSetup"
          ],
          "RoleName": "AmazonSSMRoleForInstancesMDCSetup"
        },
        "nextStep": "attachAmazonSSMManagedInstanceCoreToRole"
      },
      {
        "name": "attachAmazonSSMManagedInstanceCoreToRole",
        "action": "aws:executeAwsApi",
        "inputs": {
          "Service": "iam",
          "Api": "AttachRolePolicy",
          "RoleName": "AmazonSSMRoleForInstancesMDCSetup",
          "PolicyArn": "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
        },
        "nextStep": "attachAmazonSSMPatchAssociationToRole"
      },
      {
        "name": "attachAmazonSSMPatchAssociationToRole",
        "action": "aws:executeAwsApi",
        "inputs": {
          "Service": "iam",
          "Api": "AttachRolePolicy",
          "RoleName": "AmazonSSMRoleForInstancesMDCSetup",
          "PolicyArn": "arn:aws:iam::aws:policy/AmazonSSMPatchAssociation"
        },
        "nextStep": "createInstanceProfileIfNotExists"
      },
      {
        "name": "createInstanceProfileIfNotExists",
        "action": "aws:executeAwsApi",
        "inputs": {
          "InstanceProfileName": "AmazonSSMRoleForInstancesMDCSetup",
          "Service": "iam",
          "Api": "CreateInstanceProfile"
        },
        "onFailure": "Continue",
        "nextStep": "addRoleToInstanceProfile"
      },
      {
        "name": "addRoleToInstanceProfile",
        "action": "aws:executeAwsApi",
        "inputs": {
          "InstanceProfileName": "AmazonSSMRoleForInstancesMDCSetup",
          "RoleName": "AmazonSSMRoleForInstancesMDCSetup",
          "Service": "iam",
          "Api": "AddRoleToInstanceProfile"
        },
        "onFailure": "Continue",
        "nextStep": "executeAttachIAMToInstance"
      },
      {
        "name": "executeAttachIAMToInstance",
        "action": "aws:executeAutomation",
        "maxAttempts": 10,
        "timeoutSeconds": 60,
        "inputs": {
          "DocumentName": "AWS-AttachIAMToInstance",
          "RuntimeParameters": {
            "RoleName": "AmazonSSMRoleForInstancesMDCSetup",
            "ForceReplace": false,
            "AutomationAssumeRole": "{{ AutomationAssumeRole }}",
            "InstanceId": "{{ InstanceId }}"
          }
        },
        "isEnd": true
      }
    ]
  }
DOC
}

resource "aws_ssm_document" "UpdateExistingInstanceProfile" {
  name          = "AWSMDCSetup-UpdateExistingInstanceProfile-${var.ConfigurationID}"
  count         = contains(var.offerings, local.DefenderForServersOfferingName) || contains(var.offerings, local.DefenderForDatabasesOfferingName) ? 1 : 0
  document_type = "Automation"
  target_type   = "/AWS::EC2::Instance"
  content       = <<DOC
  {
    "description": "Composite document for MDC Setup Managing Instances association. This document updates the user provided instance profile with roles and policies",
    "schemaVersion": "0.3",
    "assumeRole": "{{AutomationAssumeRole}}",
    "parameters": {
      "AutomationAssumeRole": {
        "type": "String"
      },
      "InstanceId": {
        "type": "String"
      },
      "InstanceProfile": {
        "type": "String"
      }
    },
    "mainSteps": [
      {
        "name": "getRoleFromInstanceProfile",
        "action": "aws:executeAwsApi",
        "inputs": {
          "Service": "iam",
          "Api": "GetInstanceProfile",
          "InstanceProfileName": "{{InstanceProfile}}"
        },
        "outputs": [
          {
            "Name": "existingRoleName",
            "Selector": "$.InstanceProfile.Roles[0].RoleName",
            "Type": "String"
          }
        ],
        "nextStep": "attachAmazonSSMManagedInstanceCoreToExistingRole"
      },
      {
        "name": "attachAmazonSSMManagedInstanceCoreToExistingRole",
        "action": "aws:executeAwsApi",
        "inputs": {
          "Service": "iam",
          "Api": "AttachRolePolicy",
          "RoleName": "{{getRoleFromInstanceProfile.existingRoleName}}",
          "PolicyArn": "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
        },
        "nextStep": "attachAmazonSSMPatchAssociationToExistingRole"
      },
      {
        "name": "attachAmazonSSMPatchAssociationToExistingRole",
        "action": "aws:executeAwsApi",
        "inputs": {
          "Service": "iam",
          "Api": "AttachRolePolicy",
          "RoleName": "{{getRoleFromInstanceProfile.existingRoleName}}",
          "PolicyArn": "arn:aws:iam::aws:policy/AmazonSSMPatchAssociation"
        },
        "isEnd": true
      }
    ]
  }
DOC
}

locals {
  account_id                        = data.aws_caller_identity.current.account_id
  partition                         = data.aws_partition.current.partition
  aws_dns_suffix                    = data.aws_partition.current.dns_suffix
  DefenderForCspmOfferingName       = "DefenderCspm"
  DefenderForServersOfferingName    = "DefenderForServers"
  DefenderForDatabasesOfferingName  = "DefenderForDatabases"
  DefenderForContainersOfferingName = "DefenderForContainers"
  SystemAssociationForInstances_targets = (var.SetupType == "Organizational" ? { key = "InstanceIds", values = ["*"] }
    : (var.TargetType == "Tags" && var.TargetTagValue != "" ? { key = "tag:${var.TargetTagKey}", values = [var.TargetTagValue] }
      : (var.TargetType == "Tags" && var.TargetTagValue == "" ? { key = "tag-key", values = [var.TargetTagKey] }
        : (var.TargetType == "ResourceGroups" ? { key = "ResourceGroup", values = [var.ResourceGroupName] }
          : (var.TargetInstances == "*" ? { key = "InstanceIds", values = ["*"] }
  : { key = "ParameterValues", values = [var.TargetInstances] })))))
}

resource "aws_ssm_association" "SystemAssociationForManagingInstances" {
  count            = (var.SetupType == "Organizational" || var.ProvidedInstanceProfileName == "") && (contains(var.offerings, local.DefenderForServersOfferingName) || contains(var.offerings, local.DefenderForDatabasesOfferingName)) ? 1 : 0
  name             = aws_ssm_document.CreateAndAttachIAMToInstance[0].name
  association_name = "AWS-MDCSetup-SSMHostMgmt-AttachIAMToInstance-${var.ConfigurationID}"
  parameters = {
    AutomationAssumeRole  = var.SetupType == "Organizational" || var.ProvidedAssumeRoleArn == "*" ? aws_iam_role.RoleForAutomation[0].arn : var.ProvidedAssumeRoleArn
    IsPolicyAttachAllowed = tostring(var.IsPolicyAttachAllowed)
  }
  automation_target_parameter_name = "InstanceId"
  targets {
    key    = local.SystemAssociationForInstances_targets.key
    values = local.SystemAssociationForInstances_targets.values
  }

  schedule_expression = "rate(30 days)"
}

resource "aws_ssm_association" "SystemAssociationForUpdateManagingInstances" {
  count            = (var.SetupType == "Organizational" || var.ProvidedInstanceProfileName == "") && (contains(var.offerings, local.DefenderForServersOfferingName) || contains(var.offerings, local.DefenderForDatabasesOfferingName)) ? 1 : 0
  name             = aws_ssm_document.UpdateExistingInstanceProfile[0].name
  association_name = "AWS-MDCSetup-SSMHostMgmt-UpdateIAMForInstanceMgmt-${var.ConfigurationID}"
  parameters = {
    AutomationAssumeRole = var.SetupType == "Organizational" || var.ProvidedAssumeRoleArn == "*" ? aws_iam_role.RoleForAutomation[0].arn : var.ProvidedAssumeRoleArn
    InstanceProfile      = var.ProvidedInstanceProfileName
  }
  automation_target_parameter_name = "InstanceId"
  targets {
    key    = local.SystemAssociationForInstances_targets.key
    values = local.SystemAssociationForInstances_targets.values
  }
  schedule_expression = "rate(30 days)"
}

######################################### Defender for Containers ########################################

data "aws_iam_policy_document" "SecurityCenterKubernetesPolicyDocument" {
  statement {
    actions   = ["logs:PutSubscriptionFilter", "logs:DescribeSubscriptionFilters", "logs:DescribeLogGroups", "logs:PutRetentionPolicy"]
    resources = ["arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:*:*"]
    effect    = "Allow"
  }
  statement {
    actions   = ["firehose:*"]
    resources = ["arn:aws:firehose:*:${data.aws_caller_identity.current.account_id}:deliverystream/azuredefender-*"]
    effect    = "Allow"
  }
  statement {
    actions   = ["iam:PassRole"]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/azuredefender-*"]
    effect    = "Allow"
  }
  statement {
    actions   = ["eks:UpdateClusterConfig", "eks:DescribeCluster"]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/azuredefender-*"]
    effect    = "Allow"
  }
  statement {
    actions   = ["sqs:*"]
    resources = ["arn:aws:sqs:*:${data.aws_caller_identity.current.account_id}:azuredefender-*"]
    effect    = "Allow"
  }
  statement {
    actions   = ["s3:*"]
    resources = ["arn:aws:s3:::azuredefender-*"]
    effect    = "Allow"
  }
}

resource "aws_iam_policy" "SecurityCenterKubernetesPolicy" {
  name        = "SecurityCenterKubernetesPolicy"
  description = ""
  count       = contains(var.offerings, local.DefenderForContainersOfferingName) ? 1 : 0
  policy      = data.aws_iam_policy_document.SecurityCenterKubernetesPolicyDocument.json
}

module "AzureDefenderKubernetesRole" {
  source      = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version     = "~> 5.0.0"
  count       = contains(var.offerings, local.DefenderForContainersOfferingName) ? 1 : 0
  create_role = true
  # Default name - if changed, please update Azure security connector file
  role_name        = "azuredefender-kubernetes"
  role_description = ""
  provider_url     = "sts.windows.net/${var.aad_tenant_id}/"

  oidc_fully_qualified_audiences = [
    "api://6610e979-c931-41ec-adc7-b9920c9d52f1"
  ]

  role_policy_arns = [
    aws_iam_policy.SecurityCenterKubernetesPolicy[0].arn
  ]
  number_of_role_policy_arns = 1
}

data "aws_iam_policy_document" "AzureDefenderKubernetesScubaReaderPolicyDocument" {
  statement {
    actions   = ["sqs:ReceiveMessage", "sqs:DeleteMessage"]
    resources = ["arn:aws:sqs:*:${data.aws_caller_identity.current.account_id}:azuredefender-*"]
    effect    = "Allow"
  }
  statement {
    actions   = ["s3:GetObject", "s3:GetBucketLocation"]
    resources = ["arn:aws:s3:::azuredefender-*"]
    effect    = "Allow"
  }
}

resource "aws_iam_policy" "AzureDefenderKubernetesScubaReaderPolicy" {
  name        = "AzureDefenderKubernetesScubaReader"
  description = ""
  count       = contains(var.offerings, local.DefenderForContainersOfferingName) ? 1 : 0
  policy      = data.aws_iam_policy_document.AzureDefenderKubernetesScubaReaderPolicyDocument.json
}

module "AzureDefenderKubernetesScubaReaderRole" {
  source = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  count  = contains(var.offerings, local.DefenderForContainersOfferingName) ? 1 : 0
  trusted_role_arns = [
    "arn:aws:iam::197857026523:user/azuredefender-eks"
  ]

  create_role = true

  role_name           = "azuredefender-kubernetes-scuba-reader"
  role_requires_mfa   = false
  role_sts_externalid = ["00d04923-b008-48fd-bc0e-faa7dfd0549e"]

  custom_role_policy_arns = [
    aws_iam_policy.AzureDefenderKubernetesScubaReaderPolicy[0].arn
  ]
  number_of_custom_role_policy_arns = 1
}

data "aws_iam_policy_document" "SecurityCenterCloudWatchToKinesisPolicyDocument" {
  statement {
    actions   = ["firehose:*"]
    resources = ["arn:aws:firehose:*:${data.aws_caller_identity.current.account_id}:deliverystream/azuredefender-*"]
    effect    = "Allow"
  }
}

resource "aws_iam_policy" "SecurityCenterCloudWatchToKinesisPolicy" {
  name        = "SecurityCenterCloudWatchToKinesis"
  description = ""
  count       = contains(var.offerings, local.DefenderForContainersOfferingName) ? 1 : 0
  policy      = data.aws_iam_policy_document.SecurityCenterCloudWatchToKinesisPolicyDocument.json
}

module "AzureDefenderCloudWatchToKinesisRole" {
  source                = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  count                 = contains(var.offerings, local.DefenderForContainersOfferingName) ? 1 : 0
  trusted_role_services = ["logs.amazonaws.com"]
  trusted_role_actions  = ["sts:AssumeRole"]
  create_role           = true

  role_name         = "azuredefender-kubernetes-cloudwatch-to-kinesis"
  role_requires_mfa = false

  custom_role_policy_arns = [
    aws_iam_policy.AzureDefenderKubernetesScubaReaderPolicy[0].arn
  ]
  number_of_custom_role_policy_arns = 1
}

resource "aws_iam_policy" "SecurityCenterKinesisToS3Policy" {
  name        = "SecurityCenterKinesisToS3Policy"
  description = ""
  count       = contains(var.offerings, local.DefenderForContainersOfferingName) ? 1 : 0
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject"
        ],
        "Resource" : [
          "arn:aws:s3:::azuredefender-*"
        ]
      }
    ]
  })
}

module "AzureDefenderKinesisToS3Role" {
  source                = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  count                 = contains(var.offerings, local.DefenderForContainersOfferingName) ? 1 : 0
  trusted_role_services = ["firehose.amazonaws.com"]
  trusted_role_actions  = ["sts:AssumeRole"]
  create_role           = true

  role_name           = "azuredefender-kubernetes-kinesis-to-s3"
  role_requires_mfa   = false
  role_sts_externalid = [data.aws_caller_identity.current.account_id]

  custom_role_policy_arns = [
    aws_iam_policy.AzureDefenderKubernetesScubaReaderPolicy[0].arn
  ]
  number_of_custom_role_policy_arns = 1
}

resource "aws_iam_policy" "MicrosoftDefenderForCloud_Containers_Vulnerability_Assessment" {
  name        = "MicrosoftDefenderForCloud_Containers_Vulnerability_Assessment"
  description = ""
  count       = contains(var.offerings, local.DefenderForContainersOfferingName) ? 1 : 0
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:*"
        ],
        "Resource" : [
          "arn:aws:s3:::defender-for-containers*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "application-autoscaling:DeleteScalingPolicy",
          "application-autoscaling:DeregisterScalableTarget",
          "application-autoscaling:DescribeScalableTargets",
          "application-autoscaling:DescribeScalingActivities",
          "application-autoscaling:DescribeScalingPolicies",
          "application-autoscaling:PutScalingPolicy",
          "application-autoscaling:RegisterScalableTarget",
          "appmesh:DescribeVirtualGateway",
          "appmesh:DescribeVirtualNode",
          "appmesh:ListMeshes",
          "appmesh:ListVirtualGateways",
          "appmesh:ListVirtualNodes",
          "autoscaling:CreateAutoScalingGroup",
          "autoscaling:CreateLaunchConfiguration",
          "autoscaling:DeleteAutoScalingGroup",
          "autoscaling:DeleteLaunchConfiguration",
          "autoscaling:Describe*",
          "autoscaling:UpdateAutoScalingGroup",
          "cloudformation:CreateStack",
          "cloudformation:DeleteStack",
          "cloudformation:DescribeStack*",
          "cloudformation:UpdateStack",
          "cloudwatch:DeleteAlarms",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:PutMetricAlarm",
          "codedeploy:BatchGetApplicationRevisions",
          "codedeploy:BatchGetApplications",
          "codedeploy:BatchGetDeploymentGroups",
          "codedeploy:BatchGetDeployments",
          "codedeploy:ContinueDeployment",
          "codedeploy:CreateApplication",
          "codedeploy:CreateDeployment",
          "codedeploy:CreateDeploymentGroup",
          "codedeploy:GetApplication",
          "codedeploy:GetApplicationRevision",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:GetDeploymentGroup",
          "codedeploy:GetDeploymentTarget",
          "codedeploy:ListApplicationRevisions",
          "codedeploy:ListApplications",
          "codedeploy:ListDeploymentConfigs",
          "codedeploy:ListDeploymentGroups",
          "codedeploy:ListDeployments",
          "codedeploy:ListDeploymentTargets",
          "codedeploy:RegisterApplicationRevision",
          "codedeploy:StopDeployment",
          "ec2:AssociateRouteTable",
          "ec2:AttachInternetGateway",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:CancelSpotFleetRequests",
          "ec2:CreateInternetGateway",
          "ec2:CreateLaunchTemplate",
          "ec2:CreateRoute",
          "ec2:CreateRouteTable",
          "ec2:CreateSecurityGroup",
          "ec2:CreateSubnet",
          "ec2:CreateVpc",
          "ec2:CreateTags",
          "ec2:AttachVpnGateway",
          "ec2:DeleteLaunchTemplate",
          "ec2:DeleteSubnet",
          "ec2:DeleteVpc",
          "ec2:Describe*",
          "ec2:DetachInternetGateway",
          "ec2:DisassociateRouteTable",
          "ec2:ModifySubnetAttribute",
          "ec2:ModifyVpcAttribute",
          "ec2:RequestSpotFleet",
          "ec2:RunInstances",
          "ecs:*",
          "elasticfilesystem:DescribeAccessPoints",
          "elasticfilesystem:DescribeFileSystems",
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:CreateRule",
          "elasticloadbalancing:CreateTargetGroup",
          "elasticloadbalancing:DeleteListener",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:DeleteRule",
          "elasticloadbalancing:DeleteTargetGroup",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeRules",
          "elasticloadbalancing:DescribeTargetGroups",
          "events:DeleteRule",
          "events:DescribeRule",
          "events:ListRuleNamesByTarget",
          "events:ListTargetsByRule",
          "events:PutRule",
          "events:PutTargets",
          "events:RemoveTargets",
          "fsx:DescribeFileSystems",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfiles",
          "iam:ListRoles",
          "lambda:ListFunctions",
          "logs:CreateLogGroup",
          "logs:DescribeLogGroups",
          "logs:FilterLogEvents",
          "route53:CreateHostedZone",
          "route53:DeleteHostedZone",
          "route53:GetHealthCheck",
          "route53:GetHostedZone",
          "route53:ListHostedZonesByName",
          "servicediscovery:CreatePrivateDnsNamespace",
          "servicediscovery:CreateService",
          "servicediscovery:DeleteService",
          "servicediscovery:GetNamespace",
          "servicediscovery:GetOperation",
          "servicediscovery:GetService",
          "servicediscovery:ListNamespaces",
          "servicediscovery:ListServices",
          "servicediscovery:UpdateService",
          "sns:ListTopics"
        ],
        "Resource" : [
          "*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ],
        "Resource" : "arn:aws:ssm:*:*:parameter/aws/service/ecs*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:DeleteInternetGateway",
          "ec2:DeleteRoute",
          "ec2:DeleteRouteTable",
          "ec2:DeleteSecurityGroup"
        ],
        "Resource" : [
          "*"
        ],
        "Condition" : {
          "StringLike" : {
            "ec2:ResourceTag/aws:cloudformation:stack-name" : "EC2ContainerService-*"
          }
        }
      },
      {
        "Action" : "iam:PassRole",
        "Effect" : "Allow",
        "Resource" : [
          "*"
        ],
        "Condition" : {
          "StringLike" : {
            "iam:PassedToService" : "ecs-tasks.amazonaws.com"
          }
        }
      },
      {
        "Action" : "iam:PassRole",
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:iam::*:role/ecsInstanceRole*"
        ],
        "Condition" : {
          "StringLike" : {
            "iam:PassedToService" : [
              "ec2.amazonaws.com",
              "ec2.amazonaws.com.cn"
            ]
          }
        }
      },
      {
        "Action" : "iam:PassRole",
        "Effect" : "Allow",
        "Resource" : [
          "arn:aws:iam::*:role/ecsAutoscaleRole*"
        ],
        "Condition" : {
          "StringLike" : {
            "iam:PassedToService" : [
              "application-autoscaling.amazonaws.com",
              "application-autoscaling.amazonaws.com.cn"
            ]
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : "iam:CreateServiceLinkedRole",
        "Resource" : "*",
        "Condition" : {
          "StringLike" : {
            "iam:AWSServiceName" : [
              "autoscaling.amazonaws.com",
              "ecs.amazonaws.com",
              "ecs.application-autoscaling.amazonaws.com",
              "spot.amazonaws.com",
              "spotfleet.amazonaws.com"
            ]
          }
        }
      }
    ]
  })
}

module "DefenderForContainersVaRole" {
  source      = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version     = "~> 5.0.0"
  count       = contains(var.offerings, local.DefenderForContainersOfferingName) ? 1 : 0
  create_role = true
  # Default name - if changed, please update Azure security connector file
  role_name        = "azuredefender-containers-va"
  role_description = ""
  provider_url     = "sts.windows.net/${var.aad_tenant_id}/"

  role_policy_arns = [
    aws_iam_policy.MicrosoftDefenderForCloud_Containers_Vulnerability_Assessment[0].arn
  ]

  oidc_fully_qualified_audiences = [
    "api://6610e979-c931-41ec-adc7-b9920c9d52f1"
  ]

  number_of_role_policy_arns = 1
}

resource "aws_iam_policy" "MicrosoftDefenderForCloud_Containers_Vulnerability_Assessment_TaskPolicy" {
  name        = "MicrosoftDefenderForCloud_Containers_Vulnerability_Assessment_Task"
  description = ""
  count       = contains(var.offerings, local.DefenderForContainersOfferingName) ? 1 : 0
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:*"
        ],
        "Resource" : [
          "arn:aws:s3:::defender-for-containers*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ecr:GetLifecyclePolicyPreview",
          "ecr:GetDownloadUrlForLayer",
          "ecr:DescribeImageReplicationStatus",
          "ecr:ListTagsForResource",
          "ecr:BatchGetRepositoryScanningConfiguration",
          "ecr:ListImages",
          "ecr:UntagResource",
          "ecr:BatchGetImage",
          "ecr:DescribeImages",
          "ecr:TagResource",
          "ecr:DescribeRepositories",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetLifecyclePolicy",
          "ecr:GetRepositoryPolicy"
        ],
        "Resource" : [
          "arn:aws:ecr:*:${data.aws_caller_identity.current.account_id}:repository/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "ecr:GetAuthorizationToken"
        ],
        "Resource" : "*"
      }
    ]
  })
}
module "DefenderForContainersVaTaskRole" {
  source                = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  count                 = contains(var.offerings, local.DefenderForContainersOfferingName) ? 1 : 0
  trusted_role_services = ["ecs-tasks.amazonaws.com"]
  trusted_role_actions  = ["sts:AssumeRole"]
  create_role           = true

  role_name         = "azuredefender-containers-va-task"
  role_requires_mfa = false

  custom_role_policy_arns = [
    aws_iam_policy.MicrosoftDefenderForCloud_Containers_Vulnerability_Assessment_TaskPolicy[0].arn
  ]
  number_of_custom_role_policy_arns = 1
}
