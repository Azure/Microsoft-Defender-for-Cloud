# Deployment Guide
## For the successful deployment of the dashboard, azure defender should be enabled for the subscription and targeted workspace. Continuous export should be enabled too. Below is the process explained stepwise along with snapshots.
### 1.	Configure subscription settings:
        1.	Head to Management -> Pricing & Settings in the left panel. Select required targeted workspace
        
        2.	Select required subscription
        3.	Enable azure defender and save
        4.  Select “Auto provisioning”
        5.	Click “Edit configuration” in “Log Analytics agent Azure VMs
        6.  Select the required target workspace -> Apply -> Save
        7.	Select “Continuous Export” and head to “Log Analytics workspace” tab
        8.	Enable “Export enabled”. Check all the boxes under this tab. Also select the required targeted resource group, workspace and subscription. Click Save
        The pricing and settings tab should look like this now:
### 2.	Configure targeted workspace settings:
        1.  Head to Management -> Pricing & Settings in the left panel. Select required targeted workspace
        2.	Enable azure defender and save
        3.	Select “data collection” from the left panel. Select “All events” and Save
        The pricing and settings tab should look like this now:
        
## The environment is finally set for the deployment of the dashboard.

## Snapshots of Dashboard
