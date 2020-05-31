# Secure score dashboard
Author: Amit Magen

This template uses the secure score and assessments data you exported to log analytics, to create a power BI dashboard that will help you track your secure score and investigate changes in the score. 

### Template content:
- Aggragated secure score over all selected subscriptions - current score and over time. 
- Secure score over time.
- Security controls score over time.
- Current state of security controls - comparison between healthy and unhealthy resources for each control. The controls are sorted by the control max score, to help you focus on the most important controls.
- Trends in your score per subscription - total change in the last week and in the last month.
- Detected changes that may affected your secure score - to help you investigate the reasons for increase/decrease in the score, we present evry day the changes which potentially affected the score: remediated resources, deleted resources, new deployed resources and resources that changed their status from 'Healthy' to 'Unhealthy' for one of the recommendations.
- Current state of each recommendation - number of healthy, unhealthy and non-applicable resources for each recommendation.
- Recommendation status over time - number of unhealthy resources for each recommendation over time.
- Healthy vs. unhealthy resources over time.

### Steps for publishing your dashboard:
1. Deploy `Get-SecureScoreData` playbook. Make sure to use manged identity as described in the playbook Readme file for the subscriptions you want to display in the dashboard. You have 3 options to assign the managed identity:
    1. Manually Assign reader permissions at the management group level for the managed identity. (preferred)
    2. Manually assign reader permissions for the managed identity for the selected subscription.
    2. Use `Grant-SubscriptionPermissions.ps1` script to add the identity to all subscriptions (you can find the script under 'Get-SecureScoreData' folder).
2. Open `Secure Score Dashboard` and enter your log analytics workspace id.
4. Publish the template to Power BI Service to share with your colleagues. 
5. Scheduale refresh for the data once in a day.

##### Importent notes:
- The template can work only with data exported to log analytics using the required workbook. 
- Some of the visualization may seem incomplete on the first day. Date should be exported at least for two days in order to see changes over time. 
- Make sure to authorize the API connections created.
- Make sure all selected subscriptions registered to Azure Security Center.