# Export affected components - Microsoft Defender for Containers

**Author: Shay Amar**

## Overview

This script will allow you to export all the affected components from the Defenender for Containers, based on a specific recommendation by setting the policy definition ID. 

## Description

You can query the affected components and export the list from the Azure portal. 

![CSV example](./affectedcomponents.png)

You can learn more about some of the recommendations about Microsoft Defender for Containers in [our documentation](https://learn.microsoft.com/en-us/azure/defender-for-cloud/kubernetes-workload-protections#view-and-configure-the-bundle-of-recommendations).

### Prerequisites

- You need to run the script with a user account that has reader access rights on the speicifc subscription you want to query the specfic recommenation.
- Make sure to use the latest version of the [Az.Security PowerShell module](https://docs.microsoft.com/powershell/module/az.security).
- In order to allow the output from the recommenations blade, you need to enable [Microsoft Defender for Containers plans](https://learn.microsoft.com/en-us/azure/defender-for-cloud/kubernetes-workload-protections) on your subscriptions.

> **Credits:** [Future Kortor](https://github.com/future-at-work), [Lior Kesten](https://github.com/Liorkesten)
