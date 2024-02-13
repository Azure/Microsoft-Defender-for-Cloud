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

data "aws_caller_identity" "current" {

}

data "aws_partition" "current" {

}

resource "aws_iam_openid_connect_provider" "ASCDefendersOIDCIdentityProvider" {
  url             = "https://sts.windows.net/${var.aad_tenant_id}/"
  client_id_list  = var.oidc_client_id_list
  thumbprint_list = var.oidc_thumbprint_list
}

resource "aws_iam_policy" "CspmMonitorAwsPolicy" {
  name        = "CspmMonitorAwsPolicy"
  description = "Policy for CSPM Permissions"
  count       = var.least_privilege_permissions == true ? 1 : 0
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "acm:DescribeCertificate",
          "acm:ListCertificates",
          "acm:ListTagsForCertificate",
          "apigateway:GET",
          "application-autoscaling:DescribeScalableTargets",
          "autoscaling:DescribeAutoScalingGroups",
          "cloudformation:ListStacks",
          "cloudformation:DescribeStackSet",
          "cloudformation:ListStackSets",
          "cloudformation:DescribeStackInstance",
          "cloudformation:GetTemplate",
          "cloudformation:ListStackInstances",
          "cloudformation:ListStackResources",
          "cloudfront:DescribeFunction",
          "cloudfront:GetDistribution",
          "cloudfront:GetDistributionConfig",
          "cloudfront:ListTagsForResource",
          "cloudfront:ListDistributions",
          "cloudtrail:DescribeTrails",
          "cloudtrail:GetEventSelectors",
          "cloudtrail:ListTags",
          "cloudtrail:LookupEvents",
          "cloudtrail:GetTrailStatus",
          "cloudwatch:ListTagsForResource",
          "cloudwatch:DescribeAlarms",
          "codebuild:BatchGetProjects",
          "codebuild:ListSourceCredentials",
          "codebuild:ListProjects",
          "config:DescribeConfigurationRecorders",
          "config:DescribeDeliveryChannels",
          "config:DescribeConfigurationRecorderStatus",
          "dax:DescribeClusters",
          "dax:ListTags",
          "dms:DescribeReplicationInstances",
          "dynamodb:DescribeTable",
          "dynamodb:ListTables",
          "dynamodb:DescribeContinuousBackups",
          "dynamodb:ListTagsOfResource",
          "ec2:DescribeAddresses",
          "ec2:DescribeInstances",
          "ec2:DescribeSnapshotAttribute",
          "ec2:DescribeVpcPeeringConnections",
          "ec2:GetEbsEncryptionByDefault",
          "ec2:DescribeFlowLogs",
          "ec2:DescribeRegions",
          "ec2:DescribeSnapshots",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeImages",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeVpcs",
          "ec2:DescribeVolumes",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeVpcEndpoints",
          "ec2:DescribeSubnets",
          "ec2:DescribeNetworkAcls",
          "ec2:DescribeRouteTables",
          "ec2:DescribeInstanceStatus",
          "ecr:GetRegistryPolicy",
          "ecr:DescribeImages",
          "ecr:DescribeRepositories",
          "ecr:GetRepositoryPolicy",
          "ecs:ListServices",
          "ecs:ListTagsForResource",
          "ecs:DescribeServices",
          "ecs:ListTaskDefinitions",
          "ecs:DescribeTaskDefinition",
          "ecs:ListClusters",
          "eks:DescribeNodegroup",
          "eks:ListNodegroups",
          "eks:DescribeCluster",
          "eks:ListClusters",
          "elasticbeanstalk:DescribeEnvironments",
          "elasticbeanstalk:DescribeConfigurationSettings",
          "elasticfilesystem:DescribeMountTargets",
          "elasticfilesystem:DescribeFileSystems",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeTags",
          "elasticloadbalancing:DescribeLoadBalancerPolicies",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeRules",
          "elasticmapreduce:ListClusters",
          "elasticmapreduce:DescribeCluster",
          "es:ListDomainNames",
          "es:DescribeElasticsearchDomain",
          "es:ListTags",
          "es:DescribeElasticsearchDomains",
          "guardduty:ListDetectors",
          "iam:ListPolicies",
          "iam:GenerateCredentialReport",
          "iam:GetRole",
          "iam:GetPolicyVersion",
          "iam:GetAccountPasswordPolicy",
          "iam:ListServerCertificates",
          "iam:GetAccessKeyLastUsed",
          "iam:ListEntitiesForPolicy",
          "iam:ListUserPolicies",
          "iam:ListMFADevices",
          "iam:ListInstanceProfiles",
          "iam:ListVirtualMFADevices",
          "iam:ListGroupsForUser",
          "iam:ListAttachedUserPolicies",
          "iam:ListAccountAliases",
          "iam:ListUsers",
          "iam:GetAccountSummary",
          "iam:ListAccessKeys",
          "kms:ListKeys",
          "kms:ListKeyPolicies",
          "kms:GetKeyRotationStatus",
          "kms:ListAliases",
          "kms:GetKeyPolicy",
          "kms:DescribeKey",
          "lambda:ListFunctions",
          "lambda:ListTags",
          "lambda:GetFunction",
          "lambda:GetPolicy",
          "logs:DescribeLogGroups",
          "logs:DescribeMetricFilters",
          "network-firewall:DescribeLoggingConfiguration",
          "network-firewall:DescribeResourcePolicy",
          "network-firewall:DescribeRuleGroupMetadata",
          "network-firewall:ListTagsForResource",
          "network-firewall:DescribeRuleGroup",
          "network-firewall:DescribeFirewallPolicy",
          "network-firewall:ListFirewalls",
          "network-firewall:DescribeFirewall",
          "network-firewall:ListFirewallPolicies",
          "network-firewall:ListRuleGroups",
          "rds:DescribeDBClusterSnapshotAttributes",
          "rds:DescribeEventSubscriptions",
          "rds:DescribeDBSnapshots",
          "rds:DescribeExportTasks",
          "rds:DescribeDBClusterSnapshots",
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters",
          "rds:DescribeDBSnapshotAttributes",
          "redshift:DescribeClusters",
          "redshift:DescribeLoggingStatus",
          "redshift:DescribeClusterParameterGroups",
          "redshift:DescribeClusterParameters",
          "s3:GetEncryptionConfiguration",
          "s3:GetBucketPublicAccessBlock",
          "s3:GetBucketTagging",
          "s3:GetBucketLogging",
          "s3:GetBucketAcl",
          "s3:GetBucketLocation",
          "s3:GetBucketPolicy",
          "s3:GetReplicationConfiguration",
          "s3:GetAccountPublicAccessBlock",
          "s3:GetObjectAcl",
          "s3:GetObjectTagging",
          "s3:ListBucket",
          "s3:ListAllMyBuckets",
          "s3:GetBucketPolicyStatus",
          "s3:GetBucketVersioning",
          "s3:GetAccountPublicAccessBlock",
          "sagemaker:DescribeNotebookInstance",
          "sagemaker:ListNotebookInstances",
          "sagemaker:GetSearchSuggestions",
          "sagemaker:Search",
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecrets",
          "sns:ListTagsForResource",
          "sns:GetTopicAttributes",
          "sns:ListTopics",
          "sns:ListSubscriptions",
          "sqs:ListQueues",
          "sqs:GetQueueAttributes",
          "sqs:ListQueueTags",
          "ssm:DescribeInstanceInformation",
          "ssm:DescribeParameters",
          "ssm:ListTagsForResource",
          "ssm:ListResourceComplianceSummaries",
          "sts:GetCallerIdentity",
          "waf-regional:GetWebACLForResource",
          "waf-regional:GetRuleGroup",
          "waf-regional:GetPermissionPolicy",
          "waf-regional:GetWebACL",
          "waf-regional:GetSampledRequests",
          "waf-regional:GetLoggingConfiguration",
          "waf-regional:GetRule",
          "wafv2:ListResourcesForWebACL",
          "wafv2:ListWebACLs",
          "waf:ListWebACLs",
          "waf:GetLoggingConfiguration",
          "waf:GetWebACL",
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets",
          "appsync:ListGraphqlApis",
          "access-analyzer:ListAnalyzers",
          "secretsmanager:GetResourcePolicy",
          "route53domains:ListDomains",
          "macie2:GetMacieSession",
          "macie2:ListClassificationJobs",
          "resource-explorer-2:ListTagsForResource"
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_policy" "CspmMonitorAwsDenyPolicy" {
  name        = "CspmMonitorAwsDenyPolicy"
  description = "Deny policy to limit CSPM Permissions"
  count       = var.least_privilege_permissions == false ? 1 : 0
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Deny",
        "Action" : [
          "consolidatedbilling:*",
          "freetier:*",
          "invoicing:*",
          "payments:*",
          "billing:*",
          "tax:*",
          "cur:*"
        ],
        "Resource" : "*"
      }
    ]
  })
}

data "aws_iam_policy_document" "cspm_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = ["arn:${local.partition}:iam::${local.account_id}:oidc-provider/sts.windows.net/${var.aad_tenant_id}/"]
    }

    dynamic "condition" {
      for_each = [
        {
          test     = "StringLike"
          variable = "sts.windows.net/${var.aad_tenant_id}/:aud"
          values   = ["api://4d8bed1f-eee7-4d8e-b0dc-8462049a4479"]
        },
        {
          test     = "StringLike"
          variable = "sts:RoleSessionName"
          values   = ["MicrosoftDefenderForClouds_${var.client_tenant}"]
        }
      ]
      content {
        test     = condition.value.test
        variable = condition.value.variable
        values   = condition.value.values
      }
    }
  }
}

resource "aws_iam_role" "CspmMonitorAwsIamRole" {
  name               = var.CspmMonitorAwsIamRoleName
  description        = "Microsoft Defender for Cloud - CSPM ready only role"
  assume_role_policy = data.aws_iam_policy_document.cspm_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "cspm_policy_attachment1" {
  role       = aws_iam_role.CspmMonitorAwsIamRole.name
  policy_arn = var.least_privilege_permissions == true ? aws_iam_policy.CspmMonitorAwsPolicy[0].arn : "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "cspm_policy_attachment2" {
  count      = var.least_privilege_permissions == true ? 1 : 0
  role       = aws_iam_role.CspmMonitorAwsIamRole.name
  policy_arn = aws_iam_policy.CspmMonitorAwsDenyPolicy[0].arn
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

resource "aws_iam_policy" "DefenderForServers_VmScanner" {
  name        = "AzureSecurityCenter_DefenderForServers_VmScanner"
  description = "Microsoft Defender for Servers VM Scanner access policy"
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
          "ec2:CopySnapshot",
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
      },
      {
        "Sid" : "VmScannerEncryptionKeyCreation",
        "Effect" : "Allow",
        "Action" : [
          "kms:CreateKey",
          "kms:ListKeys"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "VmScannerEncryptionKeyManagement",
        "Effect" : "Allow",
        "Action" : [
          "kms:TagResource",
          "kms:GetKeyRotationStatus",
          "kms:PutKeyPolicy",
          "kms:GetKeyPolicy",
          "kms:CreateAlias",
          "kms:TagResource",
          "kms:ListResourceTags"
        ],
        "Resource" : [
          "arn:aws:kms:*:${local.account_id}:key/*",
          "arn:aws:kms:*:${local.account_id}:alias/DefenderForCloudKey"
        ]
      },
      {
        "Sid" : "VmScannerEncryptionKeyUsage",
        "Effect" : "Allow",
        "Action" : [
          "kms:GenerateDataKeyWithoutPlaintext",
          "kms:DescribeKey",
          "kms:RetireGrant",
          "kms:CreateGrant",
          "kms:ReEncryptFrom"
        ],
        "Resource" : [
          "arn:aws:kms:*:${local.account_id}:key/*"
        ]
      }
    ]
  })
}

data "aws_iam_policy_document" "vm_scanner_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = ["arn:${local.partition}:iam::${local.account_id}:oidc-provider/sts.windows.net/${var.aad_tenant_id}/"]
    }

    dynamic "condition" {
      for_each = [
        {
          test     = "StringLike"
          variable = "sts.windows.net/${var.aad_tenant_id}/:aud"
          values   = ["api://AzureSecurityCenter.MultiCloud.DefenderForServers.VmScanner"]
        },
        {
          test     = "StringLike"
          variable = "sts:RoleSessionName"
          values   = ["MicrosoftDefenderForClouds_${var.client_tenant}"]
        }
      ]
      content {
        test     = condition.value.test
        variable = condition.value.variable
        values   = condition.value.values
      }
    }
  }
}

resource "aws_iam_role" "VmScannerIamRole" {
  name               = var.DefenderForServersVmScannerRoleName
  description        = "Microsoft Defender for Cloud - Defender For Servers VmScanner role"
  assume_role_policy = data.aws_iam_policy_document.vm_scanner_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "vm_scanner_policy_attachment" {
  role       = aws_iam_role.VmScannerIamRole.name
  policy_arn = aws_iam_policy.DefenderForServers_VmScanner.arn
}

resource "aws_iam_policy" "MicrosoftDefenderForCloud_DefenderForServers" {
  name        = "MicrosoftDefenderForCloud_DefenderForServers"
  description = "Microsoft Defender for Servers policy"
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

data "aws_iam_policy_document" "servers_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = ["arn:${local.partition}:iam::${local.account_id}:oidc-provider/sts.windows.net/${var.aad_tenant_id}/"]
    }

    dynamic "condition" {
      for_each = [
        {
          test     = "StringLike"
          variable = "sts.windows.net/${var.aad_tenant_id}/:aud"
          values   = ["api://AzureSecurityCenter.MultiCloud.DefenderForServers"]
        },
        {
          test     = "StringLike"
          variable = "sts:RoleSessionName"
          values   = ["MicrosoftDefenderForClouds_${var.client_tenant}"]
        }
      ]
      content {
        test     = condition.value.test
        variable = condition.value.variable
        values   = condition.value.values
      }
    }
  }
}


resource "aws_iam_role" "ServersIamRole" {
  name               = var.DefenderForServersRoleName
  description        = "Microsoft Defender for Cloud - Defender For Servers role"
  assume_role_policy = data.aws_iam_policy_document.servers_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "servers_policy_attachment" {
  role       = aws_iam_role.ServersIamRole.name
  policy_arn = aws_iam_policy.MicrosoftDefenderForCloud_DefenderForServers.arn
}

resource "aws_iam_policy" "DefenderForCloud_ArcAutoProvisioning" {
  name        = "DefenderForCloud_ArcAutoProvisioning"
  description = "Microsoft Defender for Cloud Arc Auto Provisioning policy"
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


data "aws_iam_policy_document" "arc_ap_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = ["arn:${local.partition}:iam::${local.account_id}:oidc-provider/sts.windows.net/${var.aad_tenant_id}/"]
    }

    dynamic "condition" {
      for_each = [
        {
          test     = "StringLike"
          variable = "sts.windows.net/${var.aad_tenant_id}/:aud"
          values   = ["api://AzureSecurityCenter.MultiCloud.DefenderForServers"]
        },
        {
          test     = "StringLike"
          variable = "sts:RoleSessionName"
          values   = ["MicrosoftDefenderForClouds_${var.client_tenant}"]
        }
      ]
      content {
        test     = condition.value.test
        variable = condition.value.variable
        values   = condition.value.values
      }
    }
  }
}

resource "aws_iam_role" "AzureArcAutoProvisioningIamRole" {
  name               = var.ArcAutoProvisioningRoleName
  description        = "Microsoft Defender for Cloud - ARC Auto provisioning role"
  assume_role_policy = data.aws_iam_policy_document.servers_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "arc_ap_policy_attachment" {
  role       = aws_iam_role.AzureArcAutoProvisioningIamRole.name
  policy_arn = aws_iam_policy.DefenderForCloud_ArcAutoProvisioning.arn
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

resource "aws_ssm_association" "SystemAssociationForManagingInstances" {
  count            = (var.SetupType == "Organizational" || var.ProvidedInstanceProfileName == "") ? 1 : 0
  name             = aws_ssm_document.CreateAndAttachIAMToInstance.name
  association_name = "AWS-MDCSetup-SSMHostMgmt-AttachIAMToInstance-${var.ConfigurationID}"
  parameters = {
    AutomationAssumeRole  = var.SetupType == "Organizational" || var.ProvidedAssumeRoleArn == "*" ? aws_iam_role.RoleForAutomation.arn : var.ProvidedAssumeRoleArn
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
  count            = (var.SetupType == "Organizational" || var.ProvidedInstanceProfileName == "") ? 1 : 0
  name             = aws_ssm_document.UpdateExistingInstanceProfile.name
  association_name = "AWS-MDCSetup-SSMHostMgmt-UpdateIAMForInstanceMgmt-${var.ConfigurationID}"
  parameters = {
    AutomationAssumeRole = var.SetupType == "Organizational" || var.ProvidedAssumeRoleArn == "*" ? aws_iam_role.RoleForAutomation.arn : var.ProvidedAssumeRoleArn
    InstanceProfile      = var.ProvidedInstanceProfileName
  }
  automation_target_parameter_name = "InstanceId"
  targets {
    key    = local.SystemAssociationForInstances_targets.key
    values = local.SystemAssociationForInstances_targets.values
  }
  schedule_expression = "rate(30 days)"
}

data "aws_iam_policy_document" "SecurityCenterKubernetesPolicyDocument" {
  statement {
    actions   = ["logs:PutSubscriptionFilter", "logs:DescribeSubscriptionFilters", "logs:DescribeLogGroups", "logs:PutRetentionPolicy"]
    resources = ["arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:*:*"]
    effect    = "Allow"
  }
  statement {
    actions   = ["firehose:*"]
    resources = ["arn:aws:firehose:*:${data.aws_caller_identity.current.account_id}:deliverystream/azuredefender-*", "arn:aws:firehose:*:${data.aws_caller_identity.current.account_id}:deliverystream/ms-defender-*"]
    effect    = "Allow"
  }
  statement {
    actions   = ["iam:PassRole"]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/azuredefender-*", "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/msdefender-*", "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/DefenderForCloud-*"]
    effect    = "Allow"
  }
  statement {
    actions   = ["eks:UpdateClusterConfig", "eks:DescribeCluster"]
    resources = ["arn:aws:eks:*:${data.aws_caller_identity.current.account_id}:*"]
    effect    = "Allow"
  }
  statement {
    actions   = ["sqs:*"]
    resources = ["arn:aws:sqs:*:${data.aws_caller_identity.current.account_id}:azuredefender-*", "arn:aws:sqs:*:${data.aws_caller_identity.current.account_id}:ms-defender-*"]
    effect    = "Allow"
  }
  statement {
    actions   = ["s3:*"]
    resources = ["arn:aws:s3:::azuredefender-*", "arn:aws:s3:::ms-defender-*"]
    effect    = "Allow"
  }
}

resource "aws_iam_policy" "SecurityCenterKubernetesPolicy" {
  name        = "SecurityCenterKubernetesPolicy"
  description = "Security Center Kubernetes Policy"
  policy      = data.aws_iam_policy_document.SecurityCenterKubernetesPolicyDocument.json
}

data "aws_iam_policy_document" "kubernetes_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = ["arn:${local.partition}:iam::${local.account_id}:oidc-provider/sts.windows.net/${var.aad_tenant_id}/"]
    }

    dynamic "condition" {
      for_each = [
        {
          test     = "StringLike"
          variable = "sts.windows.net/${var.aad_tenant_id}/:aud"
          values   = ["api://6610e979-c931-41ec-adc7-b9920c9d52f1"]
        },
        {
          test     = "StringLike"
          variable = "sts:RoleSessionName"
          values   = ["MicrosoftDefenderForClouds_${var.client_tenant}"]
        }
      ]
      content {
        test     = condition.value.test
        variable = condition.value.variable
        values   = condition.value.values
      }
    }
  }
}

resource "aws_iam_role" "MicrosoftDefenderKubernetesIamRole" {
  name               = var.SecurityCenterKubernetesRoleName
  description        = "Microsoft Defender for Cloud - Defender For Kubernetes role"
  assume_role_policy = data.aws_iam_policy_document.kubernetes_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "kubernetes_role_policy_attachment" {
  role       = aws_iam_role.MicrosoftDefenderKubernetesIamRole.name
  policy_arn = aws_iam_policy.SecurityCenterKubernetesPolicy.arn
}

data "aws_iam_policy_document" "AzureDefenderKubernetesScubaReaderPolicyDocument" {
  statement {
    actions   = ["sqs:ReceiveMessage", "sqs:DeleteMessage"]
    resources = ["arn:aws:sqs:*:${data.aws_caller_identity.current.account_id}:azuredefender-*", "arn:aws:sqs:*:${data.aws_caller_identity.current.account_id}:ms-defender-*"]
    effect    = "Allow"
  }
  statement {
    actions   = ["s3:GetObject", "s3:GetBucketLocation"]
    resources = ["arn:aws:s3:::azuredefender-*", "arn:aws:s3:::ms-defender-*"]
    effect    = "Allow"
  }
}

resource "aws_iam_policy" "AzureDefenderKubernetesScubaReaderPolicy" {
  name        = "AzureDefenderKubernetesScubaReader"
  description = ""
  policy      = data.aws_iam_policy_document.AzureDefenderKubernetesScubaReaderPolicyDocument.json
}

data "aws_iam_policy_document" "scuba_reader_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::197857026523:user/azuredefender-eks"]
    }

    dynamic "condition" {
      for_each = [1]
      content {
        test     = "StringEquals"
        variable = "sts:ExternalId"
        values   = [var.AzureDefenderKubernetesScubaReaderRoleStsExternalId]
      }
    }
  }

  dynamic "statement" {
    for_each = [1]
    content {
      effect  = "Allow"
      actions = ["sts:AssumeRoleWithWebIdentity"]

      principals {
        type = "Federated"

        identifiers = ["arn:${local.partition}:iam::${local.account_id}:oidc-provider/sts.windows.net/${var.aad_tenant_id}/"]
      }

      dynamic "condition" {
        for_each = [
          {
            test     = "StringLike"
            variable = "sts.windows.net/${var.aad_tenant_id}/:aud"
            values   = ["api://1462b192-27f7-4cb9-8523-0f4ecb54b47e"]
          },
          {
            test     = "StringLike"
            variable = "sts:RoleSessionName"
            values   = ["MicrosoftDefenderForClouds_${var.client_tenant}"]
          }
        ]
        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }
}

resource "aws_iam_role" "AzureDefenderKubernetesScubaReaderRole" {
  name               = var.AzureDefenderKubernetesScubaReaderRoleName
  description        = ""
  assume_role_policy = data.aws_iam_policy_document.scuba_reader_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "custom" {
  role       = var.AzureDefenderKubernetesScubaReaderRoleName
  policy_arn = aws_iam_policy.AzureDefenderKubernetesScubaReaderPolicy.arn
}

data "aws_iam_policy_document" "SecurityCenterCloudWatchToKinesisPolicyDocument" {
  statement {
    actions   = ["firehose:*"]
    resources = ["arn:aws:firehose:*:${data.aws_caller_identity.current.account_id}:deliverystream/azuredefender-*", "arn:aws:firehose:*:${data.aws_caller_identity.current.account_id}:deliverystream/ms-defender-*"]
    effect    = "Allow"
  }
}

resource "aws_iam_policy" "SecurityCenterCloudWatchToKinesisPolicy" {
  name        = "SecurityCenterCloudWatchToKinesis"
  description = ""
  policy      = data.aws_iam_policy_document.SecurityCenterCloudWatchToKinesisPolicyDocument.json
}

module "AzureDefenderCloudWatchToKinesisRole" {
  source                            = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  trusted_role_services             = ["logs.amazonaws.com"]
  trusted_role_actions              = ["sts:AssumeRole"]
  create_role                       = true
  role_name                         = var.AzureDefenderCloudWatchToKinesisRoleName
  role_requires_mfa                 = false
  custom_role_policy_arns           = [aws_iam_policy.SecurityCenterCloudWatchToKinesisPolicy.arn]
  number_of_custom_role_policy_arns = 1
}

resource "aws_iam_policy" "SecurityCenterKinesisToS3Policy" {
  name        = "SecurityCenterKinesisToS3Policy"
  description = ""
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
          "arn:aws:s3:::azuredefender-*",
          "arn:aws:s3:::ms-defender-*"
        ]
      }
    ]
  })
}

module "AzureDefenderKinesisToS3Role" {
  source                            = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  trusted_role_services             = ["firehose.amazonaws.com"]
  trusted_role_actions              = ["sts:AssumeRole"]
  create_role                       = true
  role_name                         = var.DefenderForCloudContainersK8sKinesisToS3RoleName
  role_requires_mfa                 = false
  role_sts_externalid               = [data.aws_caller_identity.current.account_id]
  custom_role_policy_arns           = [aws_iam_policy.SecurityCenterKinesisToS3Policy.arn]
  number_of_custom_role_policy_arns = 1
}

data "aws_iam_policy_document" "MDCContainersAgentlessDiscoveryK8sPolicyDocument" {
  statement {
    actions   = ["eks:UpdateClusterConfig", "eks:DescribeCluster"]
    resources = ["arn:aws:eks:*:${data.aws_caller_identity.current.account_id}:*"]
    effect    = "Allow"
  }
}

resource "aws_iam_policy" "MDCContainersAgentlessDiscoveryK8sPolicy" {
  name        = "MDCContainersAgentlessDiscoveryK8sPolicy"
  description = "Microsoft Defender For Cloud - Containers Discovery For Kubernetes Policy."
  policy      = data.aws_iam_policy_document.MDCContainersAgentlessDiscoveryK8sPolicyDocument.json
}


data "aws_iam_policy_document" "agentless_discovery_kubernetes_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = ["arn:${local.partition}:iam::${local.account_id}:oidc-provider/sts.windows.net/${var.aad_tenant_id}/"]
    }

    dynamic "condition" {
      for_each = [
        {
          test     = "StringLike"
          variable = "sts.windows.net/${var.aad_tenant_id}/:aud"
          values   = ["api://6610e979-c931-41ec-adc7-b9920c9d52f1"]
        },
        {
          test     = "StringLike"
          variable = "sts:RoleSessionName"
          values   = ["MicrosoftDefenderForClouds_${var.client_tenant}"]
        }
      ]
      content {
        test     = condition.value.test
        variable = condition.value.variable
        values   = condition.value.values
      }
    }
  }
}

resource "aws_iam_role" "MDCContainersAgentlessDiscoveryK8sRole" {
  name               = var.MDCContainersAgentlessDiscoveryK8sRoleName
  description        = "Microsoft Defender for Cloud - Containers Agentless Discovery For Kubernetes Role"
  assume_role_policy = data.aws_iam_policy_document.agentless_discovery_kubernetes_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "agentless_discovery_kubernetes_role_policy_attachment" {
  role       = aws_iam_role.MDCContainersAgentlessDiscoveryK8sRole.name
  policy_arn = aws_iam_policy.MDCContainersAgentlessDiscoveryK8sPolicy.arn
}


data "aws_iam_policy_document" "containers_image_assessment_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = ["arn:${local.partition}:iam::${local.account_id}:oidc-provider/sts.windows.net/${var.aad_tenant_id}/"]
    }

    dynamic "condition" {
      for_each = [
        {
          test     = "StringLike"
          variable = "sts.windows.net/${var.aad_tenant_id}/:aud"
          values   = ["api://6610e979-c931-41ec-adc7-b9920c9d52f1"]
        },
        {
          test     = "StringLike"
          variable = "sts:RoleSessionName"
          values   = ["MicrosoftDefenderForClouds_${var.client_tenant}"]
        }
      ]
      content {
        test     = condition.value.test
        variable = condition.value.variable
        values   = condition.value.values
      }
    }
  }
}

resource "aws_iam_role" "MDCContainersImageAssessmentRole" {
  name               = var.MDCContainersImageAssessmentRoleName
  description        = "Microsoft Defender for Cloud - Containers Discovery For Kubernetes Role."
  assume_role_policy = data.aws_iam_policy_document.containers_image_assessment_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "containers_image_assessment_policy_attachment1" {
  role       = aws_iam_role.MDCContainersImageAssessmentRole.name
  policy_arn = var.least_privilege_permissions == true ? "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly" : "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_role_policy_attachment" "containers_image_assessment_policy_attachment2" {
  role       = aws_iam_role.MDCContainersImageAssessmentRole.name
  policy_arn = var.least_privilege_permissions == true ? "arn:aws:iam::aws:policy/AmazonElasticContainerRegistryPublicReadOnly" : "arn:aws:iam::aws:policy/AmazonElasticContainerRegistryPublicPowerUser"
}

resource "aws_iam_policy" "SensitiveDataDiscoveryPolicy" {
  name        = "AzureSecurityCenter_SensitiveDataDiscovery"
  description = "Microsoft Defender for Servers policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "kms:Decrypt",
        "Resource" : "*"
      }
    ]
  })
}

data "aws_iam_policy_document" "sensitive_data_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = ["arn:${local.partition}:iam::${local.account_id}:oidc-provider/sts.windows.net/${var.aad_tenant_id}/"]
    }

    dynamic "condition" {
      for_each = [
        {
          test     = "StringLike"
          variable = "sts.windows.net/${var.aad_tenant_id}/:aud"
          values   = ["api://b2f86835-c959-461c-b08c-2cd5ca382af5"]
        },
        {
          test     = "StringLike"
          variable = "sts:RoleSessionName"
          values   = ["MicrosoftDefenderForClouds_${var.client_tenant}"]
        }
      ]
      content {
        test     = condition.value.test
        variable = condition.value.variable
        values   = condition.value.values
      }
    }
  }
}

resource "aws_iam_role" "SensitiveDataDiscoveryIamRole" {
  name               = var.SensitiveDataDiscoveryRoleName
  description        = "Microsoft Defender for Cloud - Sensitive Data Discovery Role"
  assume_role_policy = data.aws_iam_policy_document.sensitive_data_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "sensitive_data_role_policy_attachment1" {
  role       = aws_iam_role.SensitiveDataDiscoveryIamRole.name
  policy_arn = aws_iam_policy.SensitiveDataDiscoveryPolicy.arn
}

resource "aws_iam_role_policy_attachment" "sensitive_data_role_policy_attachment2" {
  role       = aws_iam_role.SensitiveDataDiscoveryIamRole.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_policy" "DatabasesDspmPolicy" {
  name        = "AzureSecurityCenter_DatabasesDspm"
  description = "Microsoft Defender for databases policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters",
          "rds:DescribeDBClusterSnapshots",
          "rds:DescribeDBSnapshots",
          "rds:CopyDBSnapshot",
          "rds:CopyDBClusterSnapshot"
        ],
        "Resource" : [
          "arn:aws:rds:*:${local.account_id}:cluster:*",
          "arn:aws:rds:*:${local.account_id}:db:*",
          "arn:aws:rds:*:${local.account_id}:snapshot:*",
          "arn:aws:rds:*:${local.account_id}:cluster-snapshot:*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "rds:DescribeDBClusterParameters",
          "rds:DescribeDBParameters",
          "rds:DescribeOptionGroups",
        ],
        "Resource" : [
          "arn:aws:rds:*:${local.account_id}:pg:*",
          "arn:aws:rds:*:${local.account_id}:og:*",
          "arn:aws:rds:*:${local.account_id}:cluster-pg:*",
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "rds:DeleteDBSnapshot",
          "rds:DeleteDBClusterSnapshot",
          "rds:ModifyDBSnapshotAttribute",
          "rds:ModifyDBClusterSnapshotAttribute"
        ],
        "Resource" : [
          "arn:aws:rds:*:${local.account_id}:snapshot:defenderfordatabases*",
          "arn:aws:rds:*:${local.account_id}:cluster-snapshot:defenderfordatabases*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "kms:ListAliases"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : "kms:CreateGrant",
        "Resource" : "*",
        "Condition" : {
          "StringLike" : {
            "kms:ViaService" : [
              "rds.*.amazonaws.com"
            ]
          },
          "StringEquals" : {
            "kms:CallerAccount" : "${local.account_id}"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "kms:CreateKey",
          "kms:TagResource",
          "kms:ListGrants",
          "kms:DescribeKey",
          "kms:PutKeyPolicy",
          "kms:Encrypt",
          "kms:CreateGrant",
          "kms:EnableKey",
          "kms:CancelKeyDeletion",
          "kms:DisableKey",
          "kms:ScheduleKeyDeletion",
          "kms:UpdateAlias",
          "kms:UpdateKeyDescription"
        ],
        "Resource" : "*",
        "Condition" : {
          "ForAnyValue:StringLike" : {
            "aws:TagKeys" : "DefenderForDatabases*"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "kms:CreateAlias"
        ],
        "Resource" : [
          "arn:aws:kms:*:${local.account_id}:alias/DefenderForDatabases*",
          "arn:aws:kms:*:${local.account_id}:key/*"
        ]
      }
    ]
  })
}


data "aws_iam_policy_document" "dspm_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = ["arn:${local.partition}:iam::${local.account_id}:oidc-provider/sts.windows.net/${var.aad_tenant_id}/"]
    }

    dynamic "condition" {
      for_each = [
        {
          test     = "StringLike"
          variable = "sts.windows.net/${var.aad_tenant_id}/:aud"
          values   = ["api://AzureSecurityCenter.MultiCloud.DefenderForDatabases"]
        },
        {
          test     = "StringLike"
          variable = "sts:RoleSessionName"
          values   = ["MicrosoftDefenderForClouds_${var.client_tenant}"]
        }
      ]
      content {
        test     = condition.value.test
        variable = condition.value.variable
        values   = condition.value.values
      }
    }
  }
}

resource "aws_iam_role" "DspmIamRole" {
  name               = var.DataSecurityPostureDbRoleName
  description        = "Microsoft Defender for Cloud - Databases DSPM role"
  assume_role_policy = data.aws_iam_policy_document.dspm_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "dspm_role_policy_attachment" {
  role       = aws_iam_role.DspmIamRole.name
  policy_arn = aws_iam_policy.DatabasesDspmPolicy.arn
}

resource "aws_iam_openid_connect_provider" "MDCCiemOIDCIdentityProvider" {
  url             = "https://sts.windows.net/${var.client_tenant}/"
  client_id_list  = ["api://mciem-aws-oidc-app"]
  thumbprint_list = ["626d44e704d1ceabe3bf0d53397464ac8080142c"]
}

resource "aws_iam_policy" "CiemCloudTrailAccessPolicy" {
  name        = "mdc-ciem-cloudtrail-${var.client_tenant}"
  description = "Microsoft Defender for Ciem - Cloud trail access policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:ListBucket"
        ],
        "Resource" : [
          "arn:aws:s3:::${var.CiemCloudTrailBucketName}",
          "arn:aws:s3:::${var.CiemCloudTrailBucketName}/*"
        ]
      }
  ] })
}


data "aws_iam_policy_document" "ciem_account_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:${local.partition}:iam::${local.account_id}:role/${var.CiemOidcRoleName}"]
    }
  }
}

resource "aws_iam_role" "CiemAccountRole" {
  name               = var.CiemAccountRoleName
  description        = "Microsoft Defender for Cloud - Ciem Account role"
  assume_role_policy = data.aws_iam_policy_document.ciem_account_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "ciem_role_policy_attachment1" {
  role       = aws_iam_role.CiemAccountRole.name
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}

resource "aws_iam_role_policy_attachment" "ciem_role_policy_attachment2" {
  role       = aws_iam_role.CiemAccountRole.name
  policy_arn = aws_iam_policy.CiemCloudTrailAccessPolicy.arn
}

resource "aws_iam_policy" "CiemOidcRolePolicy" {
  name        = "mdc-mciem-oidc-${var.client_tenant}-assume"
  description = "Policy for CIEM "
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "sts:AssumeRole",
          "sts:GetAccessKeyInfo",
          "sts:GetCallerIdentity",
          "sts:GetFederationToken",
          "sts:GetServiceBearerToken",
          "sts:GetSessionToken",
          "sts:TagSession"
        ],
        "Resource" : "arn:aws:iam::*:role/${var.CiemAccountRoleName}}",
        "Effect" : "Allow"
      }
    ]
  })
}


data "aws_iam_policy_document" "ciem_oidc_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = ["arn:${local.partition}:iam::${local.account_id}:oidc-provider/sts.windows.net/${var.client_tenant}/"]
    }

    dynamic "condition" {
      for_each = [
        {
          test     = "StringEquals"
          variable = "sts.windows.net/${var.client_tenant}/:aud"
          values   = ["api://mciem-aws-oidc-app"]
        },
        {
          test     = "StringEquals"
          variable = "sts.windows.net/${var.client_tenant}/:sub"
          values   = ["${var.AzureSPClientId}"]
        }
      ]
      content {
        test     = condition.value.test
        variable = condition.value.variable
        values   = condition.value.values
      }
    }
  }
}

resource "aws_iam_role" "CiemOidcRole" {
  name               = var.CiemOidcRoleName
  description        = "Microsoft Defender for Cloud - Ciem Oidc role"
  assume_role_policy = data.aws_iam_policy_document.ciem_oidc_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "ciem_oidc_role_policy_attachment" {
  role       = aws_iam_role.CiemOidcRole.name
  policy_arn = aws_iam_policy.CiemOidcRolePolicy.arn
}
