# Module 13 - Governance in Microsoft Defender for Cloud

<p align="left"><img src="../Images/asc-labs-advanced.gif?raw=true"></p>

#### 🎓 Level: 300 (Intermediate)
#### ⌛ Estimated time to complete this lab: 30 minutes

## Objectives
This exercise guides you on how to use the new Governance capabilities in Microsoft Defender for Cloud

### Exercise 1: Add a new Governance Rule in Microsoft Defender for Cloud 

To add a new governance rule for your recommendations, you need to go to the Governance rules on a specific subscription:

1. Sign in to the **Azure portal**.
2. Navigate to **Microsoft Defender for Cloud**, then **Environment settings**.
3. Select the relevant subscription.
4. Go to **Goverance rules** on the sidebar.
5. Click **+ Add Rule**
6. Fill in the following information:

Under General details-

**Rule name**: High severity recommendations set to [your name]

**Description**: High severity recommendations should be remediated asap.

**Priority**: 1

Under **Affected recommendations**- 
select **By severity**

Under **Set owner**,

**Owner**: By email address

**Email address**: fill in your own email address

Under **Set remediation timeframe**-

**Remediation timeframe**: 30 days
Tick **Apply grace period**

Under **Set email notifications**-
Select **Notify owners weekly on open and overdue tasks**.

Select **Create**

Now all your high severity recommendations in Microsoft defender for Cloud will have you as the owner, and you'll have 30 days from when they go unhealthy before SEcure Score is affected.

### Exercise 2: See recommendations that you're the owner of
 
1.	Navigate to **Microsoft Defender for Cloud**, then **Recommendations**.
2.  Click **Show my items only** which is found on the top left corner of the recommendations table.
3. Select one of the recommendations that you own
4. Remediate it.
