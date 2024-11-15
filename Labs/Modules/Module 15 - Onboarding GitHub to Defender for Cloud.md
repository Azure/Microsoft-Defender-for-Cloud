# Module 15 – Onboarding GitHub to Defender for Cloud

<p align="left"><img src="../Images/asc-labs-intermediate.gif?raw=true"></p>

#### 🎓 Level: 200 (Intermediate)
#### ⌛ Estimated time to complete this lab: 30 minutes

## Objectives
In this exercise, you will learn how to create a GitHub Connector in Defender for Cloud.

### Exercise 1: Preparing the Environment

If you alredy finished [Module 1](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module-1-Preparing-the-Environment.md) of this lab, you can skip this exercise, otherwise plesae finish at least Exercise 1, 2 and 3 from Module 1.

### Exercise 2: Creating an GitHub Trial account

1.	Open an In-Private session in your web browser and navigate to [https://github.com/join](https://github.com/join)
2.	If this is the first time you're creating GitHub account, enter the UserName, Password and email address and follow the screen to create a new account 
3.	Type your Account email address and Password and login to your GitHub environment.

### Exercise 3: Obtain trial of GitHub Enterprise Cloud account
#### NOTE: GitHub Advanced Security is available for Enterprise accounts on GitHub Enterprise Cloud and GitHub Enterprise Server. Some features of GitHub Advanced Security are also available for public repositories on GitHub.com. For more information, see GitHub’s products.

To setup trial of GitHub Enterprise Cloud, try the steps from this article. In order to setup GitHub Enterprise Server trial account, try the steps from this article.
For the purpose of this lab, we’re setting up a trial to evaluate GitHub Enterprise Cloud. To get a Trial version of GitHub Enterprise Cloud, click [here](https://docs.github.com/en/enterprise-cloud@latest/admin/overview/setting-up-a-trial-of-github-enterprise-cloud). This will be a 30-day trial and you don’t need to provide a payment method during the trial unless you add GitHub marketplace apps to your organization that require a payment method. 

Go ahead and create a new repository for the purpose of this lab, make the repository as ‘Public’ for testing purposes in order to benefit from the GHAS features.

### Exercise 4: Connecting your GitHub organization

1.	Login to your Azure Portal and navigate to Defender for Cloud dashboard
2.	In the left navigation pane, click **Environment settings** option
3.	Click the **Add environment** button and click **GitHub** option. The **Create GitHub connection** page appears as shown the sample below.
   <img width="399" alt="image" src="https://github.com/user-attachments/assets/3bba3c1c-6616-4487-8a9b-888011d62963">

4.	Type the name for the connector, select the subscription, select the Resource Group, which can be the same you used in this lab and the region. 
5. In the next page, click **Authorize** button. Now Click **Install** button under Install Defender for Cloud app. If this is the first time you’re authorizing your DevOps connection, you’ll receive a pop-up screen, that will ask you confirmation of which repository you'd like to install the app. 
6. Click on **Review and generate** button to continue.  
7. Navigating to the **Environment Settings** under **Microsoft Defender for Cloud**, you’ll notice the GitHub Connection was successfully created. 

![GitHub Connector - Confirming the connector](../Images/Pic6.png?raw=true)

### Exercise 5: Configure the Microsoft Security DevOps GitHub action:

To setup GitHub action:
1.	Login to the GitHub repo that you created in Exercise 4.
2.	Select a repository on which you want to configure the GitHub action.
3.	Select **Actions** as shown in the image below 

![Azure GitHub - Actions](../Images/Pic7.png?raw=true)

4.	Select **New Workflow**

![GitHub - New workflow](../Images/Pic8.png?raw=true)

5.	In the text box, enter a name for your workflow file. For example **msdevopssec.yml**

![GitHub - New workflow](../Images/Pic9.png?raw=true)

6.	Copy and paste the following sample action workflow into the **Edit new file** tab. 

~~~~~~
name: MSDO Scan

on:
  # Triggers the workflow on push or pull request events but only for the main branch
  push:
    branches: [ main ]
    
  pull_request:
    branches: [ main ]

  workflow_dispatch:

jobs:
  security:
    runs-on: windows-latest
    continue-on-error: false
    strategy:
      fail-fast: true
      
    steps:
    - uses: actions/checkout@v3
          
    - name: Run Microsoft Security DevOps
      uses: microsoft/security-devops-action@preview
      continue-on-error: false
      id: msdo

    - name: Upload alerts to Security tab
      uses: github/codeql-action/upload-sarif@v2
      with:
        sarif_file: ${{ steps.msdo.outputs.sarifFile }}
~~~~~~~

7.	Click on **Start Commit** **Commit new file**

![Azure GitHub - Commit](../Images/Pic10.png?raw=true)

![Azure GitHub - Commit](../Images/Pic11.png?raw=true)

The process can take up to one minute to complete. 
A workflow gets created in your repositories github folder with the above copied yml file 

![Azure GitHub - Workflow example](../Images/Picture11.png?raw=true)

8.	Select **Actions** and verify the new action is running/completed running. 

![Azure GitHub - New Action](../Images/Picture12.png?raw=true)

9.	Once this job completes running, navigate to the Security tab > Click on Code scanning 

NOTE: if you don’t see anything is because your code scanning feature is disabled in GitHub. Refer to the prerequisites section of this lab to review the instructions to enable. 

10.	If you see No code scanning alerts here, In the filter of Code scanning tab, choose is:open tool: Notice the available tools Defender for Cloud uses.

![Azure GitHub - Code Scanning](../Images/Picture13.png?raw=true)

11.	Code scanning findings will be filtered by specific MSDO tools in GitHub. These code scanning results are also pulled into Defender for Cloud recommendations.

![Azure GitHub - Code Scanning Findins](../Images/Picture14.png?raw=true)

