# Defender for AI Services Threat Protection and AI Red Team Workshop
This guide provides instructions to first run the AIRT-Eval.ipynb notebook to execute AI red team evaluations, if you want to only evaluate Defender for AI Services threat protection alerts from the DfAI-Eval.ipynb, skip to the [Examine AI evaluations and Defender alerts](#examine-ai-evaluations-and-defender-alerts) section.

# Prerequisites to meet

 - [ ] Azure subscription is ideally in a Sandbox Management Group, with
       less restrictive policies
       
 - [ ] Azure Subscription has [Defender for AI Services turned
       on](https://learn.microsoft.com/en-us/azure/defender-for-cloud/ai-onboarding#enable-threat-protection-for-ai-services-1)
       
 - [ ] Attendee has access to their own Azure Subscription and can
       deploy resources to it
       
 - [ ] Azure Subscription has capacity to deploy Azure AI Foundry in
       East US 2
       
 - [ ] Azure Subscription has Provider Types registered [register_providers.sh](https://raw.githubusercontent.com/swiftsolves-msft/AI-Red-Teaming-Workshop/refs/heads/main/register_providers.sh)  can help here, by running in Azure Cloud Shell session

# PreDeploy Steps

1. Be sure to create new Resource Group as part of the deployment
2. Obtain your current user's Microsoft Entra ID (AAD) Object ID using Cloud Shell (Bash). You will use this in the deployment parameter **User Object Id**. ```az ad signed-in-user show --query id -o tsv```
3. Ensure you deploy to East US 2 region, only a select few regions are supported

![Deploy](../images/deploytemplatedirections.png)

# Participant ML Notebook Setup Instructions

**Avg setup time: ~10 min**

These instructions configure the ML notebook environment needed to execute AI red team evaluations from AIRT-Eval.ipynb.
Execution environment note: 

This workshop is intentionally designed to run the notebooks on the Azure Machine Learning compute instance that is deployed (remote Jupyter kernel), not your local laptop Python environment. Running on the managed compute ensures:

 - Consistent, pre-provisioned VM size & dependencies across
   participants
- Managed identity & RBAC access to storage and project resources
   without exposing keys locally
 - Isolation from local machine package/version conflicts
- Easier cleanup (stop / delete compute when finished) If you still
   choose to run locally: (1) create a virtual env with Python >=3.10,
   (2) install dependencies matching the first install cell, (3)
   replicate the .env variables, and (4) ensure your identity or
   key-based auth has the same roles. Local runs may diverge from
   screenshots and are not the validated workshop path.

## Launch VS Code Web

1.	Open URL to:  https://ml.azure.com/workspaces and navigate to the Machine Learning workspace Azure resource by clicking the Name.
 
![Launch](../images/launchmlworkspace.png)

2. In Machine Learning Studio, Goto Compute , ensure the VM is running and launch VS Code Web

![Launch](../images/launchvscodeweb.png)

3. Allow Extension to use Remote and Authenticate

![Launch](../images/allowext.png)

4. Trust the Authors dialog box

![Launch](../images/trust.png)

5. Be sure to download the workshop files from GitHub and unzip and enter the Shared root folder into the workshop and drag *files* folder into the VS Code

![Launch](../images/downloadzip.png)

![Launch](../images/copyover.png)

![Launch](../images/copied.png)

6. Right Click on *files* folder in Left Navigation pane, and click Open in Integrated terminal

![Launch](../images/openterminal.png)

7.	click on generate-env.sh

## (Script) Create .env and populate information

1. execute ```./generate-env.sh```

![Launch](../images/runsh.png)

2. Authenticate using the URL link and Device code in the terminal
3.	Afterwards you should have a .env file created and populated 

![Launch](../images/runsh.png)

## Execute installs, imports, and credential login

1. Open the AIRT-Eval.ipynb file.

![Launch](../images/airtnotebook.png)

2. Run the first install cell. A pop‑up prompts you to select the Python kernel (choose your compute instance).

![Launch](../images/newkernel.png)

3. You should now see the ML compute selected and the first run succeeded (green check mark). The top-right 'Select Kernel' indicator updates.

![Launch](../images/cellrun.png)

4. Continue executing the remaining setup cells. You may receive an error that can safely be ignored.

![Launch](../images/error.png)

![Launch](../images/import.png)

5.	During the login step, you should see "Managed Identity OK".

![Launch](../images/msi.png)

6.	Running the next step ensures the .env file is found and loaded properly. If needed, adjust the pathing when variables do not load.

![Launch](../images/loadenv.png)

# Run AI red team evaluations agent

**Avg execution time (section): ~25 min**

These instructions cover running the remaining AIRT.ipynb cells where the AI Red Teaming Agent conducts basic, intermediate, advanced, and custom prompt attacks against the target model in your Azure AI project.

## Prerequisites

1.	Azure AI project deployed (hub + project) with system‑assigned managed identity.
2.	Default blob storage connection (workspaceblobstore) set to Microsoft Entra ID-based (see Module 1 if you need to toggle it). No SAS or account keys required.
3.	OpenAI deployment (e.g., gpt-4o-mini) accessible with your identity (Cognitive Services OpenAI User role).
4.	Python environment with azure-ai-evaluation[redteam] installed (done in earlier notebook cells).
5.	Region supported for AI Red Teaming Agent (preview) – confirm your project region is in the current preview list.

## Key Microsoft Documentation

- AI Red Teaming Agent overview (preview): https://learn.microsoft.com/azure/ai-foundry/concepts/ai-red-teaming-agent
- Run scans with the AI Red Teaming Agent: https://learn.microsoft.com/azure/ai-foundry/how-to/develop/run-scans-ai-red-teaming-agent
- View AI Red Teaming results: https://learn.microsoft.com/azure/ai-foundry/how-to/view-ai-red-teaming-results
- Observability & evaluation stages: https://learn.microsoft.com/azure/ai-foundry/concepts/observability#the-three-stages-of-genaiops-evaluation
- Risk & safety evaluators: https://learn.microsoft.com/azure/ai-foundry/concepts/evaluation-evaluators/risk-safety-evaluators

## Workflow summary

1.	Generate / specify attack objectives (risk categories, counts).
2.	Launch AI Red Teaming Agent scan (PyRIT-powered) from the notebook.
3.	Monitor scan progress (optional logging output).
4.	Retrieve evaluation metrics (attack success rate, per-category breakdown).
5.	Inspect conversation-level artifacts for successful vs. failed attacks.
6.	Iterate with additional categories / custom prompts.

# Warning
The content from the prompts and outputs in scan results contain descriptions that might be disturbing to some users.

### Basic attack

The Basic attack focuses on default risk categories (violence, sexual, hate & unfairness, self-harm) with a low prompt count to validate the pipeline end-to-end.

Results from the execution of the cell should indicate Completed Tasks and Evaluation Results being saved and uploaded.

![Launch](../images/basicattack.png)

Be sure to review the risk_categories available in the array. While Basic focuses on Violence and Hateful/Unfair Content, there are others [documented here](https://learn.microsoft.com/en-us/azure/ai-foundry/concepts/evaluation-evaluators/risk-safety-evaluators).

If you want to add to the risk_categories array, you can add elements by typing RiskCategory. and choosing other categories from the IntelliSense suggestions list.

![Launch](../images/riskcategory.png)

### Intermediate attack

The Intermediate attack increases the objectives count and optionally introduces additional attack strategies (e.g., obfuscation, role-play) to probe guardrails more thoroughly.

Be sure to review the attack_strategies available in the array. While Basic only used the Flip strategy, Intermediate employs many other techniques to manipulate and trick the model behavior into the categories being used.

![Launch](../images/intattack.png)

Just like the risk_categories array in the Basic attack, if you want to add additional attack strategies to the Intermediate attack, you can add elements to the attack_strategies array by typing AttackStrategy. and choosing other strategy types from the IntelliSense suggestions list.

![Launch](../images/attackstrat.png)

One of the more fascinating strategies is the use of early 19th century technology like Morse Code being employed in an attack against an AI model. Almost all human knowledge can be used to interpret and translate prompts as a potential attack vector!

### Advanced and custom attack

The Advanced attack delivers bespoke high-risk or application-specific prompt objectives and enables more complex PyRIT transformation strategies. Here, we can correlate successful attacks with mitigations (system messages, content filters) before progressing to production.

Be sure to review the prompts.json file in the data directory. This file includes easily extensible custom prompting that would apply to your application or model. 

![Launch](../images/advattack.png)

As an example, let's ask a Generative AI to help produce some red teaming prompts specific to isolation and self-harm for a health assistance application.

![Launch](../images/promptresponse.png)

### Review AI red team results

# Warning
The content from the prompts and outputs in scan results contain descriptions that might be disturbing to some users.

1.	Go to the Azure AI Foundry project resource and launch Azure AI Studio.

![Launch](../images/aiproj.png)

2.	In the left navigation, go to the Evaluation and the AI red teaming tab.

![Launch](../images/resultsoverview.png)

3.	Let's examine the Advanced Scan where we see some percentages above 0% indicating some successful attacks. Click the Advanced-Scan- name.

4.	Within the report we have high level attack success in some risk categories. Be sure to note these in production. Operationally, these risk categories and attack strategies can then be used to benchmark and track progress to the application to determine how content filters and data sources are further securing the models.

![Launch](../images/asr.png)

5.	Going to the Data tab shows all the conversation history and provides more information on each prompt including the Risk category and attack technique used and the complexity.
6.	Scroll to the bottom, switch view to 100 results per page, and scroll back up to see some Attack successful results. Choose one and click on "view more". In this case, we'll examine a successful Violence attack.

![Launch](../images/results.png)

7.	You will now see the prompt that was crafted using the Red Team Eval library and Pyrit using attack techniques to successfully bypass content filtering on this model.

![Launch](../images/jsonpreview.png)

## Examine AI evaluations and Defender alerts

**Avg review time: ~15 min**

This guide provides instructions for examining the AI red teaming agent results across areas relevant to different personas protecting the GenAI application. One of the byproducts of running the AI red team agent is that it can produce security alerts due to it's attack strategy techniques employed on risk category content. Defender for AI Services will generate security alerts that can be found where the persona is.

### Azure AI Foundry project red team evaluations

Security alerting from Defender for AI Services can be found in the Azure AI Foundry Left navigation's blade, here the data analyst or application owner can find if an alert was recently issued and some basic information on the alert and affected resource, including some remediation steps. The user is invited to review the alert in more detail and evidence in Defender for Cloud.

![Launch](../images/aialert.png)

![Launch](../images/aialertdetails.png)

### Defender for Cloud

The security alert is also in Defender for Cloud and in the left navigation Security Alerts. The alert itself contains some mor security context including aspects of the suspicious prompt that triggered the alert.

![Launch](../images/mdcalert.png)

![Launch](../images/mdcalertdetails.png)

Some of those aspects include:
-	Mitre Tactics
-	IP address
-	Geo information
-	model involved in attack.

![Launch](../images/mdcalertdetailsaspect.png)

The Supporting Evidence and show events in the bottom right provider even more rich data can be found like:
-	Suspicious prompt segment
-	User agent involved with browser or application.
-	Confidence score

![Launch](../images/mdcevidence.png)

### Defender XDR alerting

Finally the Defender for AI Services alerting is available in the Defender XDR portal, and can also be correlated with other suspicious or malicious activity around similar patterns. The following below shows a Jailbreak attempt as part of a correlated larger attack story. The same evidence and information is available in different tiles as well including the same information in the Defender for Cloud alert like Prompt Suspicious Segment.

![Launch](../images/xdralert.png)

### AI-SPM within Azure AI Foundry and Defender for Cloud

Security Recommendations are also generated to reduce attack surfaces and harden Azure Services including Azure AI Foundry, these results can be found across areas relevant to different personas protecting the GenAI application. Again this will include Azure AI Foundry Project -> Guardrails + controls -> Security Recommendations. By clicking on a recommendation you can get some additional details and a button to send you to more information found in Defender for Cloud.

![Launch](../images/aispm.png)

and Defender for Cloud -> Recommendations

![Launch](../images/mdcrec.png)

Defender for Cloud will have additional context involving the MITRE Tactics involved with the attack surface. Any additional risk factors, and a top suggested active user for assignment for remediation.

# Examine and configure filters rerun tests

**Avg deployment time: 10 min**

The following instructions are for deploying our first model to test in Azure AI Foundry and also configuring Content Filters and Prompt Shields.

While deploying models in Azure AI Foundry from the model catalog will deploy a default filter that will protect against some harms, we recommend creating custom filters and tailoring for your risk tolerance and needs. The following will walk through these steps and also we encourage after applying to the model re running the AI Red Team to see the differences.

![Launch](../images/nodefaults.png)

### Azure AI Foundry Project

1.	In the Azure portal, locate the deployed Azure AI Foundry project resource in the resource group. Open it and click Launch AI Studio.

![Launch](../images/aiprojfind.png)

![Launch](../images/launch.png)

2.	In the left-hand navigation, select Model catalog

![Launch](../images/modelcatalog.png)

Within the model catalog you can examine various attributes of models. Click "Browse the leaderboards" and scroll to review leaderboards by scenario. Review Standard harmful behavior and other scenarios to understand relative safety posture (higher score = higher measured risk). Learn more: [Model leaderboards in Azure AI Foundry](https://ai.azure.com/doc/azure/ai-foundry/concepts/model-benchmarks?tid=b8f7636c-2e7b-476f-858c-93b63e87d81b)

![Launch](/images/modeldash1.png)

![Launch](/images/modeldash2.png)

3.	In the upper left navigation trail, click on the project and switch to the foundry view:

![Launch](/images/navigate.png)

4.	In the left-hand navigation, select Model + Endpoint, you should see a gpt-4o-mini deployed with the lab

![Launch](/images/gpt4omini.png)

5.	In the left-hand navigation, select Guardrails + controls, then choose the Content filters tab.

![Launch](/images/contentfiltertab.png)

6.	Click Create a content filter.

![Launch](/images/createcontentfilter.png)

7.	Name the content filter LowSafetyAITest, choose the connection created from the model deployment, then click Next.

![Launch](/images/namefilter.png)

8.	Adjust the input filters as shown. Set them to the lowest blocking level and turn OFF Prompt Shields, then click Next.

![Launch](/images/adjustfilter1.png)

You can learn more from the following Learn document: [Content filtering overview](https://learn.microsoft.com/en-us/azure/ai-foundry/openai/concepts/content-filter?tabs=warning%2Cuser-prompt%2Cpython-new#risk-categories)

9.	Adjust the output filters likewise. Set them to the lowest blocking level and turn OFF Prompt Shields, then click Next.

![Launch](/images/adjustfilter2.png)

10.	On the connection screen, check the gpt-4o-mini model name and click Next, then choose Replace.

![Launch](/images/replace.png)

11.	Scroll down and create the filter.

![Launch](/images/createfilter.png)

You will later create another content filter HighSafetyAITest by moving thresholds to the highest settings, turning ON Prompt Shields (block), and enabling the block list in output filters.

With the content filter at the lowest settings and Prompt Shields OFF, you demonstrate more permissive model behavior and how deployments without additional guardrails can increase exposure across categories (e.g., hate, sexual, self-harm). This is for controlled educational red teaming only. Do not deploy production systems with these relaxed settings.

Safety disclaimer: Use the relaxed filter configuration solely within this isolated workshop environment. Always restore stricter filters (HighSafetyAITest) or defaults before exposing endpoints beyond this exercise.

# Conclusion

We have now been through the stand up and usage of the AI Red teaming agent through a Jupyter Python Notebook targeting and evaluating certain risks categories with differing attack strategies. We explored the results of these attacks in AI Red team evaluations in Azure AI Foundry, the attack success rates, and details of unique and novel prompt attacks. Finally we explored the alerting and further security elements within Azure AI Foundry and Defender for Cloud and Defender XDR portals.

Going forward review material in workshop and

- Form a AI red team

- Develop testing criteria using the risk categories, attack strategies, and custom prompts

 - Execute AI red teaming in the lifecycle process, 
	- choosing a model, 
    - piloting a generative AI application, 
    - and in production or when new data sources or models change and come on board

[Continue learning AI Red teaming](https://github.com/swiftsolves-msft/AI-Red-Teaming-Workshop/blob/main/workshop/Module%20Appendix%20-%20Learning%20further.md)

Special Thanks to:

Thor Draper, Nathan Swift, Stephen Revel, Daniel Bates, Matt Hanson
