terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 4.0"
    }
  }
}

locals {
  mgmt_project_id = "${var.project_id_prefix}${var.organization_id}"
}

provider "google" {
  project = local.mgmt_project_id
}

provider "google-beta" {
  project = local.mgmt_project_id
}

resource "google_project" "project" {
  name            = var.project_name
  project_id      = local.mgmt_project_id
  org_id          = var.organization_id
  billing_account = var.billing_account
}

// Enable the requested APIs.
resource "google_project_service" "gcp_apis" {
  count   = length(var.enable_apis)
  project = google_project.project.project_id
  service = element(var.enable_apis, count.index)
}

// Create a Custom Organization Role
resource "google_organization_iam_custom_role" "ms_custom_role" {
  role_id     = "MDCCustomRole"
  org_id      = google_project.project.org_id
  title       = "MDCCustomRole"
  description = "Microsoft organization custom role for onboarding"
  permissions = [
    "resourcemanager.folders.get",
    "resourcemanager.folders.list",
    "resourcemanager.projects.get",
    "resourcemanager.projects.list",
    "serviceusage.services.enable",
    "iam.roles.create",
    "iam.roles.list",
    "iam.serviceAccounts.actAs",
    "compute.projects.get",
    "compute.projects.setCommonInstanceMetadata",
    "logging.googleapis.com"
  ]
}

//Allow logging to send logs to pub sub 
resource "google_organization_iam_binding" "cloud_logs_account_organization_role_binding" {
  role    = "roles/pubsub.publisher"
  org_id  = google_project.project.org_id
  members = ["serviceAccount:cloud-logs@system.gserviceaccount.com"]
}

// Create workload identity pool 
resource "google_iam_workload_identity_pool" "mdc_workload_identity_pool" {
  workload_identity_pool_id = var.workload_pool_id
  display_name              = "Microsoft Defender for Cloud"
  description               = "Microsoft defender for cloud provisioner workload identity pool"
  project                   = google_project.project.project_id
}

// Create AutoProvisioner service account
resource "google_service_account" "onb_service_account" {
  account_id   = "mdc-onboarding-sa"
  display_name = "Microsoft Onboarding management service account"
  project      = google_project.project.project_id
}

//Assign role to AutoProvisioner service account
resource "google_organization_iam_binding" "onb_organization_role_binding" {
  role    = "organizations/${google_project.project.org_id}/roles/${google_organization_iam_custom_role.ms_custom_role.role_id}"
  org_id  = google_project.project.org_id
  members = ["serviceAccount:${google_service_account.onb_service_account.email}"]
}

// Bind AutoProvisioner service account to workload identity pool
resource "google_service_account_iam_binding" "onb_workload_assignment" {
  service_account_id = google_service_account.onb_service_account.email
  role               = "roles/iam.workloadIdentityUser"
  members            = ["principalSet://iam.googleapis.com/projects/${google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.mdc_workload_identity_pool.workload_identity_pool_id}/*"]
}

// Create OIDC provider for AutoProvisioner
resource "google_iam_workload_identity_pool_provider" "onb_workload_identity_pool_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.mdc_workload_identity_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "auto-provisioner"
  description                        = "OIDC identity pool provider for autoprovisioner"
  attribute_mapping = {
    "google.subject" = "assertion.sub"
  }
  oidc {
    allowed_audiences = ["api://d17a7d74-7e73-4e7d-bd41-8d9525e86cab"]
    issuer_uri        = "https://sts.windows.net/${var.mdc_tenant_id}/"
  }
}

// Create CSPM service account
resource "google_service_account" "cspm_service_account" {
  account_id   = "microsoft-defender-cspm"
  display_name = "Microsoft Defender CSPM"
  project      = google_project.project.project_id
}

//Assign role to CSPM service account
resource "google_organization_iam_binding" "cspm_organization_role_binding" {
  role    = "roles/viewer"
  org_id  = google_project.project.org_id
  members = ["serviceAccount:${google_service_account.cspm_service_account.email}"]
}

// Bind CSPM service account to workload identity pool
resource "google_service_account_iam_binding" "cspm_workload_assignment" {
  service_account_id = google_service_account.cspm_service_account.email
  role               = "roles/iam.workloadIdentityUser"
  members            = ["principalSet://iam.googleapis.com/projects/${google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.mdc_workload_identity_pool.workload_identity_pool_id}/*"]
}

// Create OIDC provider for CSPM
resource "google_iam_workload_identity_pool_provider" "cspm_workload_identity_pool_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.mdc_workload_identity_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "cspm"
  description                        = "OIDC identity pool provider for CSPM"
  attribute_mapping = {
    "google.subject" = "assertion.sub"
  }
  oidc {
    allowed_audiences = ["api://6e81e733-9e7f-474a-85f0-385c097f7f52"]
    issuer_uri        = "https://sts.windows.net/${var.mdc_tenant_id}/"
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Create Containers service account
resource "google_service_account" "containers_service_account" {
  account_id   = "microsoft-defender-containers"
  display_name = "Microsoft Defender Containers"
  project      = google_project.project.project_id
}

// Create Containers Role
resource "google_project_iam_custom_role" "containers_iam_role" {
  role_id     = "MicrosoftDefenderContainersRole"
  title       = "Microsoft Defender Containers Custom Role"
  description = "Microsoft Defender Containers Custom Role."
  permissions = [
    "logging.sinks.list",
    "logging.sinks.get",
    "logging.sinks.create",
    "logging.sinks.update",
    "logging.sinks.delete",
    "resourcemanager.projects.getIamPolicy",
    "resourcemanager.organizations.getIamPolicy",
    "iam.serviceAccounts.get",
  "iam.workloadIdentityPoolProviders.get"]
  stage = "ALPHA"
}

//Assign the custom role to the service account
resource "google_organization_iam_binding" "containers_service_account_custom_role_binding" {
  role    = google_project_iam_custom_role.containers_iam_role.id
  org_id  = google_project.project.org_id
  members = ["serviceAccount:${google_service_account.containers_service_account.email}"]
}

//Assign role to Containers service account
resource "google_organization_iam_binding" "containers_organization_role_binding" {
  role    = "roles/container.admin"
  org_id  = google_project.project.org_id
  members = ["serviceAccount:${google_service_account.containers_service_account.email}"]
}

resource "google_organization_iam_binding" "containers_organization_role_binding2" {
  role    = "roles/pubsub.admin"
  org_id  = google_project.project.org_id
  members = ["serviceAccount:${google_service_account.containers_service_account.email}"]
}

// Bind Containers service account to workload identity pool
resource "google_service_account_iam_binding" "containers_workload_assignment" {
  service_account_id = google_service_account.containers_service_account.email
  role               = "roles/iam.workloadIdentityUser"
  members            = ["principalSet://iam.googleapis.com/projects/${google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.mdc_workload_identity_pool.workload_identity_pool_id}/*"]
}

// Create OIDC provider for Containers
resource "google_iam_workload_identity_pool_provider" "containers_workload_identity_pool_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.mdc_workload_identity_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "containers"
  description                        = "OIDC identity pool provider for Containers."
  attribute_mapping = {
    "google.subject" = "assertion.sub"
  }
  oidc {
    allowed_audiences = ["api://6610e979-c931-41ec-adc7-b9920c9d52f1"]
    issuer_uri        = "https://sts.windows.net/${var.mdc_tenant_id}/"
  }
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Create Containers Data Collection service account
resource "google_service_account" "containers_data_collection_service_account" {
  account_id   = "ms-defender-containers-stream"
  display_name = "Microsoft Defender Data Collector"
  project      = google_project.project.project_id
}

// Create Containers Data Collection Role
resource "google_project_iam_custom_role" "containers_data_collection_iam_role" {
  role_id     = "MicrosoftDefenderContainersDataCollectionRole"
  title       = "Microsoft Defender Containers Data Collection Custom Role"
  description = "Microsoft Defender Containers Data Collection Custom Role."
  permissions = [
    "pubsub.subscriptions.consume",
    "pubsub.subscriptions.get"
  ]
  stage = "ALPHA"
}

//Assign role to Containers Data Collection service account
resource "google_organization_iam_binding" "containers_data_collection_organization_role_binding" {
  role    = google_project_iam_custom_role.containers_data_collection_iam_role.id
  org_id  = google_project.project.org_id
  members = ["serviceAccount:${google_service_account.containers_data_collection_service_account.email}"]
}

// Bind Containers Data Collection service account to workload identity pool
resource "google_service_account_iam_binding" "containers_data_collection_workload_assignment" {
  service_account_id = google_service_account.containers_data_collection_service_account.email
  role               = "roles/iam.workloadIdentityUser"
  members            = ["principalSet://iam.googleapis.com/projects/${google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.mdc_workload_identity_pool.workload_identity_pool_id}/*"]
}

// Create OIDC provider for Containers Data Collection
resource "google_iam_workload_identity_pool_provider" "containers_data_collection_workload_identity_pool_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.mdc_workload_identity_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "containers-streams"
  description                        = "OIDC identity pool provider for Containers Data Collection."
  attribute_mapping = {
    "google.subject" = "assertion.sub"
  }
  oidc {
    allowed_audiences = ["api://2041288c-b303-4ca0-9076-9612db3beeb2"]
    issuer_uri        = "https://sts.windows.net/${var.mdc_tenant_id}/"
  }
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Create service account for ARC onboarding
resource "google_service_account" "arc_service_account" {
  account_id   = "azure-arc-for-servers-onboard"
  display_name = "Azure-Arc for servers onboarding"
  project      = google_project.project.project_id
}

// Gives ARC auto provisioning permissions to service account
resource "google_service_account_iam_binding" "arc_auto_provisioning_permission_assignment" {
  service_account_id = google_service_account.arc_service_account.email
  role               = "roles/iam.serviceAccountTokenCreator"
  members            = ["serviceAccount:${google_service_account.mdfs_service_account.email}", "serviceAccount:${google_service_account.arc_ap_service_account.email}"]
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Create service account for Defender for Servers
resource "google_service_account" "mdfs_service_account" {
  account_id   = "microsoft-defender-for-servers"
  display_name = "Microsoft Defender for Servers"
  project      = google_project.project.project_id
}

//Assign role to Defender for Servers service account
resource "google_organization_iam_binding" "mdfs_organization_role_binding" {
  role    = "roles/compute.viewer"
  org_id  = google_project.project.org_id
  members = ["serviceAccount:${google_service_account.mdfs_service_account.email}"]
}
resource "google_organization_iam_binding" "mdfs_organization_role_binding2" {
  role    = "roles/osconfig.osPolicyAssignmentAdmin"
  org_id  = google_project.project.org_id
  members = ["serviceAccount:${google_service_account.mdfs_service_account.email}"]
}
resource "google_organization_iam_binding" "mdfs_organization_role_binding3" {
  role    = "roles/osconfig.osPolicyAssignmentReportViewer"
  org_id  = google_project.project.org_id
  members = ["serviceAccount:${google_service_account.mdfs_service_account.email}"]
}

// Bind Defender for Servers service account to workload identity pool
resource "google_service_account_iam_binding" "mdfs_workload_assignment" {
  service_account_id = google_service_account.arc_service_account.email
  role               = "roles/iam.workloadIdentityUser"
  members            = ["principalSet://iam.googleapis.com/projects/${google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.mdc_workload_identity_pool.workload_identity_pool_id}/*"]
}

// Create OIDC provider for Defender for Servers
resource "google_iam_workload_identity_pool_provider" "defender_for_servers_workload_identity_pool_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.mdc_workload_identity_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "defender-for-servers"
  description                        = "OIDC identity pool provider for Defender for Servers."
  attribute_mapping = {
    "google.subject" = "assertion.sub"
  }
  oidc {
    allowed_audiences = ["api://AzureSecurityCenter.MultiCloud.DefenderForServers"]
    issuer_uri        = "https://sts.windows.net/${var.mdc_tenant_id}/"
  }
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Create service account for Defender for Databases ARC auto provisioning.
resource "google_service_account" "arc_ap_service_account" {
  account_id   = "microsoft-databases-arc-ap"
  display_name = "Microsoft Defender for Databases ARC auto provisioning"
  project      = google_project.project.project_id
}

// Bind Defender for Defender for Databases ARC auto provisioning to workload identity pool
resource "google_service_account_iam_binding" "arc_ap_workload_assignment" {
  service_account_id = google_service_account.arc_ap_service_account.name
  role               = "roles/iam.workloadIdentityUser"
  members            = ["principalSet://iam.googleapis.com/projects/${google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.mdc_workload_identity_pool.workload_identity_pool_id}/*"]
}

// Create OIDC provider for Defender for Databases ARC auto provisioning
resource "google_iam_workload_identity_pool_provider" "arc_ap_workload_identity_pool_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.mdc_workload_identity_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "microsoft-databases-arc-ap"
  description                        = "OIDC identity pool provider for Defender for Servers."
  attribute_mapping = {
    "google.subject" = "assertion.sub"
  }
  oidc {
    allowed_audiences = ["api://AzureSecurityCenter.MultiCloud.DefenderForServers"]
    issuer_uri        = "https://sts.windows.net/${var.mdc_tenant_id}/"
  }
}

//Assign role to Defender for Databases ARC auto provisioning service account
resource "google_organization_iam_binding" "arc_ap_organization_role_binding" {
  role    = "roles/compute.viewer"
  org_id  = google_project.project.org_id
  members = ["serviceAccount:${google_service_account.arc_ap_service_account.email}"]
}
resource "google_organization_iam_binding" "arc_ap_organization_role_binding_2" {
  role    = "roles/osconfig.osPolicyAssignmentAdmin"
  org_id  = google_project.project.org_id
  members = ["serviceAccount:${google_service_account.arc_ap_service_account.email}"]
}
resource "google_organization_iam_binding" "arc_ap_organization_role_binding_3" {
  role    = "roles/osconfig.osPolicyAssignmentReportViewer"
  org_id  = google_project.project.org_id
  members = ["serviceAccount:${google_service_account.arc_ap_service_account.email}"]
}