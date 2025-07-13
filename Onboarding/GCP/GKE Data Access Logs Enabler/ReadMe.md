# Enable GKE Data Access Logs Script

This Python script automates the process of **enabling Data Access audit logs for GKE (Google Kubernetes Engine)** clusters. It modifies an IAM policy file to ensure that logging is properly configured to capture both administrative and data-level access within GKE.

This script is used as part of the **GCP Connector Creation** when onboarding a GCP Project or Organization to **Microsoft Defender for Cloud**, specifically needed for **Agentless threat protection in the Containers Plan**.

The script **updates a local IAM policy file (`currentPolicy.json` — representing the current policy of the Project/Organization)**, adding the necessary audit logging configurations for the GKE API (`container.googleapis.com`). This updated file is then used by the onboarding script to apply changes to the customer's environment.

> ⚠️ **Important**: This script does not interact with GCP directly. It modifies a JSON file that must be applied using the `gcloud` CLI or another appropriate method.

---

## ✅ What It Does

- Reads a local IAM policy from `currentPolicy.json`
- Ensures `auditConfigs` for `container.googleapis.com` exist
- Adds required audit log types:
  - `ADMIN_READ`
  - `DATA_READ`
  - `DATA_WRITE`
- Writes the updated policy back to the file

---

## 📋 Prerequisites

Before you run this script, make sure you have:

- **Python 3.6 or higher**
- A valid IAM policy file saved as `currentPolicy.json` in the script directory

