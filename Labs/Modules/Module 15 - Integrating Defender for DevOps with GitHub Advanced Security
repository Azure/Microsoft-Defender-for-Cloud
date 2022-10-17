# Module 14 – Configuring Azure ADO Connector in Defender for DevOps

<p align="left"><img src="../Images/asc-labs-intermediate.gif?raw=true"></p>

#### 🎓 Level: 200 (Intermediate)
#### ⌛ Estimated time to complete this lab: 30 minutes

## Objectives
In this exercise, you will learn how to configure GitHub Connector in Defender for DevOps.

### Exercise 1: Preparing the Environment

If you alredy finished [Module 1](https://github.com/Azure/Microsoft-Defender-for-Cloud/blob/main/Labs/Modules/Module-1-Preparing-the-Environment.md) of this lab, you can skip this exercise, otherwise plesae finish at least Exercise 1, 2 and 3 from Module 1.

### Exercise 2: Creating an GitHub Trial account

1.	Open an In-Private session in your web browser and navigate to [https://github.com/join](https://github.com/join)
2.	If this is the first time you're creating GitHub account, enter the UserName, Password and email address and follow the screen to create a new account 
3.	Type your Account email address and Password and login to your GitHub environment.

### Exercise 3: Obtain trial of GitHub Enterprise Cloud account
#### NOTE: GitHub Advanced Security is available for Enterprise accounts on GitHub Enterprise Cloud and GitHub Enterprise Server. Some features of GitHub Advanced Security are also available for public repositories on GitHub.com. For more information, see GitHub’s products.

To setup trial of GitHub Enterprise Cloud, try the steps from this article. In order to setup GitHub Enterprise Server trial account, try the steps from this article.
For the purpose of this lab, we’re setting up a trial to evaluate GitHub Enterprise Cloud. To get a Trial version of GitHub Enterprise Cloud, click here. This will be a 30-day trial and you don’t need to provide a payment method during the trial unless you add GitHub marketplace apps to your organization that require a payment method. 

Go ahead and create a new repository for the purpose of this lab, make the repository as ‘Public’ for testing purposes in order to benefit from the GHAS features.

### Exercise 4: Connecting your GitHub organization

1.	Login to your Azure Portal and navigate to Defender for Cloud dashboard
2.	In the left navigation pane, click **Environment settings** option
3.	Click the **Add environment** button and click **GitHub (preview)** option. The **Create GitHub connection** page appears as shown the sample below.

![Azure ADO Connector](../Images/M14_Fig1.PNG?raw=true)

4.	Type the name for the connector, select the subscription, select the Resource Group, which can be the same you used in this lab and the region. 
11.	Click **Next:select plans >** button to continue.
12.	In the next page leave the default selection with **DevOps** selected and click **Next: Authorize connection >** button to continue. The following page appears:

![Azure ADO Connector - Authorize](../Images/M14_Fig2.PNG?raw=true)


13.	Click **Authorize** button. Now Click **Install** button under Install Defender for DevOps app. If this is the first time you’re authorizing your DevOps connection, you’ll receive a pop-up screen, that will ask you confirmation of which repository you'd like to install the app. 

![Azure ADO Connector - Accept](../Images/M14_Fig3.PNG?raw=true)

14. Choose **All repositories** or **only select repositories** as per your choice and click on **Install**
15. Once you click on install, you'll recieve another pop-up window requesting to enter the password inorder to confirm access. 
15. Back to the Azure portal, you'll notice that the extension status is changed to **Installed** 

16.	Click **Review and create** button to continue.

### Exercise 5: Configure the Microsoft Security DevOps GitHub action:

To setup GitHub action:
1.	Login to the GitHub repo that you created in Exercise 4.
2.	Select a repository on which you want to configure the GitHub action.
3.	Select **Actions** as shown in the image below 

![Azure GitHub - Actions](../Images/M14_Fig3.PNG?raw=true)

4.	Select **New Workflow**

![Azure GitHub - New workflow](../Images/M14_Fig3.PNG?raw=true)

5.	In the text box, enter a name for your workflow file. For example **msdevopssec.yml**

![Azure GitHub - New workflow](../Images/M14_Fig3.PNG?raw=true)

4.	Click in the extension, select Install. Choose appropriate Organization from the dropdown menu, select Install and Proceed to Organization.
5.	 you have it installed, you’ll notice the Extension under ‘Installed’ section in the organization level settings as shown the example below:

![Azure GitHub - Workflow](../Images/M14_Fig5.PNG?raw=true)

6.	Copy and paste the following sample action workflow into the **Edit new file** tab. 

~~~~~~
name: MSDO IaC Scan

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
    - uses: actions/checkout@v2
    
    - uses: actions/setup-dotnet@v1
      with:
        dotnet-version: |
          5.0.x
          6.0.x
          
    - name: Run Microsoft Security DevOps
      uses: microsoft/security-devops-action@preview
      continue-on-error: false
      id: msdo
      with:
        categories: 'IaC'

    - name: Upload alerts to Security tab
      uses: github/codeql-action/upload-sarif@v2
      with:
        sarif_file: ${{ steps.msdo.outputs.sarifFile }}
~~~~~~~

7.	Click on **Start Commit** **Commit new file**

![Azure GitHub - Commit](../Images/M14_Fig5.PNG?raw=true)

The process can take up to one minute to complete. 
A workflow gets created in your repositories github folder with the above copied yml file 

![Azure GitHub - Workflow example](../Images/M14_Fig5.PNG?raw=true)

8.	Select **Actions** and verify the new action is running/completed running. 

9.	Once this job completes running, navigate to the Security tab > Click on Code scanning 

NOTE: if you don’t see anything is because your code scanning feature is disabled in GitHub. Refer to the prerequisites section of this lab to review the instructions to enable. 

10.	If you see No code scanning alerts here, In the filter of Code scanning tab, choose is:open tool: Notice the available tools Defender for DevOps uses.

![Azure GitHub - Code Scanning](../Images/M14_Fig5.PNG?raw=true)

11.	Code scanning findings will be filtered by specific MSDO tools in GitHub. These code scanning results are also pulled into Defender for Cloud recommendations.

![Azure GitHub - Code Scanning Findins](../Images/M14_Fig5.PNG?raw=true)

