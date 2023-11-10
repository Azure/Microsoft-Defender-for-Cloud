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

provider "google" {
  project = var.project_id
}

provider "google-beta" {
  project = var.project_id
}

data "google_project" "project" {}

locals {
  DefenderForCspmOfferingName       = "DefenderCspm"
  DefenderForServersOfferingName    = "DefenderForServers"
  DefenderForDatabasesOfferingName  = "DefenderForDatabases"
  DefenderForContainersOfferingName = "DefenderForContainers"
}

// Enable the requested APIs.
resource "google_project_service" "gcp_apis" {
  count   = length(var.enable_apis)
  project = data.google_project.project.project_id
  service = element(var.enable_apis, count.index)
}

//Allow logging to send logs to pub sub 
resource "google_project_iam_binding" "cloud_logs_account_project_role_binding" {
  role    = "roles/pubsub.publisher"
  project = data.google_project.project.project_id
  members = ["serviceAccount:cloud-logs@system.gserviceaccount.com"]
}

// Create workload identity pool
resource "google_iam_workload_identity_pool" "mdc_workload_identity_pool" {
  workload_identity_pool_id = var.workload_pool_id
  display_name              = "Microsoft Defender for Cloud"
  description               = "Microsoft defender for cloud provisioner workload identity pool"
  project                   = data.google_project.project.project_id
}

// Create CSPM service account
resource "google_service_account" "cspm_service_account" {
  account_id   = "microsoft-defender-cspm"
  display_name = "Microsoft Defender CSPM"
  project      = data.google_project.project.project_id
  count        = contains(var.offerings, local.DefenderForCspmOfferingName) ? 1 : 0
}

//Assign role to CSPM service account
resource "google_project_iam_binding" "cspm_project_role_binding" {
  project = data.google_project.project.project_id
  role    = "roles/viewer"
  members = ["serviceAccount:${google_service_account.cspm_service_account[0].email}"]
  count   = contains(var.offerings, local.DefenderForCspmOfferingName) ? 1 : 0
}

// Bind CSPM service account to workload identity pool
resource "google_service_account_iam_binding" "cspm_workload_assignment" {
  service_account_id = google_service_account.cspm_service_account[0].name
  role               = "roles/iam.workloadIdentityUser"
  members            = ["principalSet://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.mdc_workload_identity_pool.workload_identity_pool_id}/*"]
  count              = contains(var.offerings, local.DefenderForCspmOfferingName) ? 1 : 0
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
  count = contains(var.offerings, local.DefenderForCspmOfferingName) ? 1 : 0
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Create Containers service account
resource "google_service_account" "containers_service_account" {
  account_id   = "microsoft-defender-containers"
  display_name = "Microsoft Defender Containers"
  project      = data.google_project.project.project_id
  count        = contains(var.offerings, local.DefenderForContainersOfferingName) ? 1 : 0
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
    "iam.serviceAccounts.get",
  "iam.workloadIdentityPoolProviders.get"]
  stage = "ALPHA"
  count = contains(var.offerings, local.DefenderForContainersOfferingName) ? 1 : 0
}

//Assign the custom role to the service account
resource "google_project_iam_binding" "containers_service_account_custom_role_binding" {
  project = data.google_project.project.project_id
  role    = google_project_iam_custom_role.containers_iam_role[0].id
  members = ["serviceAccount:${google_service_account.containers_service_account[0].email}"]
  count   = contains(var.offerings, local.DefenderForContainersOfferingName) ? 1 : 0
}

//Assign role to Containers service account
resource "google_project_iam_binding" "containers_project_role_binding" {
  role    = "roles/container.admin"
  project = data.google_project.project.project_id
  members = ["serviceAccount:${google_service_account.containers_service_account[0].email}"]
  count   = contains(var.offerings, local.DefenderForContainersOfferingName) ? 1 : 0
}

resource "google_project_iam_binding" "containers_project_role_binding2" {
  role    = "roles/pubsub.admin"
  project = data.google_project.project.project_id
  members = ["serviceAccount:${google_service_account.containers_service_account[0].email}"]
  count   = contains(var.offerings, local.DefenderForContainersOfferingName) ? 1 : 0
}

// Bind Containers service account to workload identity pool
resource "google_service_account_iam_binding" "containers_workload_assignment" {
  service_account_id = google_service_account.containers_service_account[0].name
  role               = "roles/iam.workloadIdentityUser"
  members            = ["principalSet://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.mdc_workload_identity_pool.workload_identity_pool_id}/*"]
  count              = contains(var.offerings, local.DefenderForContainersOfferingName) ? 1 : 0
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
  count = contains(var.offerings, local.DefenderForContainersOfferingName) ? 1 : 0
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Create Containers Data Collection service account
resource "google_service_account" "containers_data_collection_service_account" {
  account_id   = "ms-defender-containers-stream"
  display_name = "Microsoft Defender Data Collector"
  project      = data.google_project.project.project_id
  count        = contains(var.offerings, local.DefenderForContainersOfferingName) ? 1 : 0
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
  count = contains(var.offerings, local.DefenderForContainersOfferingName) ? 1 : 0
}

//Assign role to Containers Data Collection service account
resource "google_project_iam_binding" "containers_data_collection_project_role_binding" {
  role    = google_project_iam_custom_role.containers_data_collection_iam_role[0].id
  project = data.google_project.project.project_id
  members = ["serviceAccount:${google_service_account.containers_data_collection_service_account[0].email}"]
  count   = contains(var.offerings, local.DefenderForContainersOfferingName) ? 1 : 0
}

// Bind Containers Data Collection service account to workload identity pool
resource "google_service_account_iam_binding" "containers_data_collection_workload_assignment" {
  service_account_id = google_service_account.containers_data_collection_service_account[0].name
  role               = "roles/iam.workloadIdentityUser"
  members            = ["principalSet://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.mdc_workload_identity_pool.workload_identity_pool_id}/*"]
  count              = contains(var.offerings, local.DefenderForContainersOfferingName) ? 1 : 0
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
  count = contains(var.offerings, local.DefenderForContainersOfferingName) ? 1 : 0
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Create service account for ARC onboarding
resource "google_service_account" "arc_service_account" {
  account_id   = "azure-arc-for-servers-onboard"
  display_name = "Azure-Arc for servers onboarding"
  project      = data.google_project.project.project_id
  count        = contains(var.offerings, local.DefenderForServersOfferingName) || contains(var.offerings, local.DefenderForDatabasesOfferingName) ? 1 : 0
}

// Gives ARC auto provisioning permissions to service account
resource "google_service_account_iam_binding" "arc_auto_provisioning_mdfs_service_account_permission_assignment" {
  service_account_id = google_service_account.arc_service_account[0].name
  role               = "roles/iam.serviceAccountTokenCreator"
  members            = ["serviceAccount:${google_service_account.mdfs_service_account[0].email}"]
  count              = contains(var.offerings, local.DefenderForServersOfferingName) ? 1 : 0
}

resource "google_service_account_iam_binding" "arc_auto_provisioning_ap_service_account_permission_assignment" {
  service_account_id = google_service_account.arc_service_account[0].name
  role               = "roles/iam.serviceAccountTokenCreator"
  members            = ["serviceAccount:${google_service_account.arc_ap_service_account[0].email}"]
  count              = contains(var.offerings, local.DefenderForDatabasesOfferingName) ? 1 : 0
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Create service account for Defender for Servers
resource "google_service_account" "mdfs_service_account" {
  account_id   = "microsoft-defender-for-servers"
  display_name = "Microsoft Defender for Servers"
  project      = data.google_project.project.project_id
  count        = contains(var.offerings, local.DefenderForServersOfferingName) ? 1 : 0
}

//Assign role to Defender for Servers service account
resource "google_project_iam_binding" "mdfs_project_role_binding" {
  role    = "roles/compute.viewer"
  project = data.google_project.project.project_id
  members = ["serviceAccount:${google_service_account.mdfs_service_account[0].email}"]
  count   = contains(var.offerings, local.DefenderForServersOfferingName) ? 1 : 0
}
resource "google_project_iam_binding" "mdfs_project_role_binding2" {
  role    = "roles/osconfig.osPolicyAssignmentAdmin"
  project = data.google_project.project.project_id
  members = ["serviceAccount:${google_service_account.mdfs_service_account[0].email}"]
  count   = contains(var.offerings, local.DefenderForServersOfferingName) ? 1 : 0
}
resource "google_project_iam_binding" "mdfs_project_role_binding3" {
  role    = "roles/osconfig.osPolicyAssignmentReportViewer"
  project = data.google_project.project.project_id
  members = ["serviceAccount:${google_service_account.mdfs_service_account[0].email}"]
  count   = contains(var.offerings, local.DefenderForServersOfferingName) ? 1 : 0
}

// Bind Defender for Servers service account to workload identity pool
resource "google_service_account_iam_binding" "mdfs_workload_assignment" {
  service_account_id = google_service_account.arc_service_account[0].name
  role               = "roles/iam.workloadIdentityUser"
  members            = ["principalSet://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.mdc_workload_identity_pool.workload_identity_pool_id}/*"]
  count              = contains(var.offerings, local.DefenderForServersOfferingName) ? 1 : 0
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
  count = contains(var.offerings, local.DefenderForServersOfferingName) ? 1 : 0
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Create service account for Defender for Databases ARC auto provisioning.
resource "google_service_account" "arc_ap_service_account" {
  account_id   = "microsoft-databases-arc-ap"
  display_name = "Microsoft Defender for Databases ARC auto provisioning"
  project      = data.google_project.project.project_id
  count        = contains(var.offerings, local.DefenderForDatabasesOfferingName) ? 1 : 0
}

// Bind Defender for Defender for Databases ARC auto provisioning to workload identity pool
resource "google_service_account_iam_binding" "arc_ap_workload_assignment" {
  service_account_id = google_service_account.arc_ap_service_account[0].name
  role               = "roles/iam.workloadIdentityUser"
  members            = ["principalSet://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.mdc_workload_identity_pool.workload_identity_pool_id}/*"]
  count              = contains(var.offerings, local.DefenderForDatabasesOfferingName) ? 1 : 0
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
  count = contains(var.offerings, local.DefenderForDatabasesOfferingName) ? 1 : 0
}

//Assign role to Defender for Databases ARC auto provisioning service account
resource "google_project_iam_binding" "arc_ap_project_role_binding" {
  role    = "roles/compute.viewer"
  project = data.google_project.project.project_id
  members = ["serviceAccount:${google_service_account.arc_ap_service_account[0].email}"]
  count   = contains(var.offerings, local.DefenderForDatabasesOfferingName) ? 1 : 0
}
resource "google_project_iam_binding" "arc_ap_project_role_binding_2" {
  role    = "roles/osconfig.osPolicyAssignmentAdmin"
  project = data.google_project.project.project_id
  members = ["serviceAccount:${google_service_account.arc_ap_service_account[0].email}"]
  count   = contains(var.offerings, local.DefenderForDatabasesOfferingName) ? 1 : 0
}
resource "google_project_iam_binding" "arc_ap_project_role_binding_3" {
  role    = "roles/osconfig.osPolicyAssignmentReportViewer"
  project = data.google_project.project.project_id
  members = ["serviceAccount:${google_service_account.arc_ap_service_account[0].email}"]
  count = contains(var.offerings, local.DefenderForDatabasesOfferingName) ? 1 : 0
}
