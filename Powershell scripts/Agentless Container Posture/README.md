## Microsoft Defender for CSPM – Agentless Container Posture 

> ## Important note
>  A new agentless container offer is now available as part of Defender CSPM.

> This feature provides customers with enhanced posture capabilities and an intelligent cloud security graph to help identify, prioritize, and reduce risk across cloud resources,  including Kubernetes clusters and container vulnerability assessment. 

> Up until today, the addition of containers and Kubernetes to the cloud security graph requires an agent-based solution through Defender for Containers offering. 
> In this private preview, Defender CSPM will introduce a new agentless discovery and visibility capability for Kubernetes and containers registries across SDLC and runtime, including container vulnerability assessment insights as part of the cloud security explorer and Kubernetes attack path analysis.

## Onboarding Via PowerShell Script: 
For at-scale onboarding, it is possible to use the PowerShell script. 
Note: only subscriptions from the same tenant could be enabled at one time.The script expects a path to a text file containing a list of subscription IDs to be enabled:
Script usage is as follows: 

onboarding.ps1 subscriptions.txt 

Where subscriptions.txt is a path to a file with the following (example) content: 

12345678-9123-4567-8901-234567890123 

12345678-9123-4567-8901-456789012345 



> **Credits:** [Future Kortor](https://github.com/future-at-work), [Shay Amar](https://www.linkedin.com/in/shay-amar/)
