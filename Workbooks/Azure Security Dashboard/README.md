# Deployment Guide
## For the successful deployment of the dashboard, Azure Defender should be enabled for the subscription and targeted workspace. Continuous export should be enabled too. Below is the stepwise guide along with snapshots.
 
### 1.	Configure subscription settings:
        1.Head to Management -> Pricing & Settings in the left panel. Select required targeted workspace
   <img src="./images/1.png" width=80%>    
       2.Select required subscription
   <img src="./images/2.png" width=80%>  
   
      3.Enable azure defender and save
   <img src="./images/3.png" width=80%>  
   
      4.Select “Auto provisioning”  from the left panel. Click “Edit configuration” in “Log Analytics agent Azure VMs"
   <img src="./images/4.png" width=80%>  
   
      5.Select the required target workspace -> Apply -> Save
   <img src="./images/6.png" width=80%>  
   
      6.Select “Continuous Export”  from the left panel and head to “Log Analytics workspace” tab
   <img src="./images/7.png" width=80%>  
   
      7.Enable “Export enabled”. Check all the boxes under this tab. Also select the required targeted resource group, workspace and subscription. Click Save
   <img src="./images/8.png" width=80%>  
   
   <img src="./images/9.png" width=80%>  
   
### 2.	Configure targeted workspace settings:
        1.Head to Management -> Pricing & Settings in the left panel. Select required targeted workspace
   <img src="./images/10.png" width=80%>  
   
        2.Enable Azure Defender and save
   <img src="./images/11.png" width=80%>  
   
        3.Select “Data collection” from the left panel. Select “All events” and Save
   <img src="./images/12.png" width=80%>  
   
        The pricing and settings tab should look like this now:
   <img src="./images/13.png" width=80%>  
        
## The environment is finally set for the deployment of the dashboard.

## Snapshots of Dashboard
        1.Overview Tab:
                a.Total resources
                b.Current score
                c.Max score
                d.Percentage secure score
                e.Total recommendations
                f.Total active security alerts
                g.Total unhealthy resources
                h.Current secure score over time
                i.Percentage secure score over time
   <img src="./images/14.png" width=80%> 
   <img src="./images/15.png" width=80%> 
   <img src="./images/16.png" width=80%> 
   
        2.Recommendations Tab:
                a.Total number of recommendations
                b.Total number of affected resources
                c.Resource health per secure control
                Filters: Severity, Health state, Resource name, Recommendations
                d.Count of recommendations
                e.Count of affected resources
                f.Number of resources affected under a recommendation
                g.Recommendations with remediation steps
   <img src="./images/17.png" width=80%>       
   <img src="./images/18.png" width=80%> 
   <img src="./images/19.png" width=80%> 
   <img src="./images/20.png" width=80%> 
   
        3.Compliance Tab:
                a.Compliance standards for a subscription
                b.Total compliance assessments
                c.Total affected resources
                d.Compliance state per compliance standard (passed, failed, skipped number of controls)
                Filters: Standards, Severity, Resource name, Compliance state, Health state
                e.Count of assessments
                f.Count of affected resources
                g.Control name with remediation steps and recommendation description (a/c filters)
   <img src="./images/21.png" width=80%>    
   <img src="./images/22.png" width=80%> 
   <img src="./images/23.png" width=80%> 
   
        4.Alerts Tab:
                a.Total number of security active alerts
                b.Total number of affected resources
                Filters: Severity, Resource Name
                c.Count of active security alerts
                d.Count of affected resources
                e.Security alerts with remediation steps
   <img src="./images/24.png" width=80%>       
   <img src="./images/25.png" width=80%> 
   
         5.Vulnerabilities Assessments Tab
                a.Unhealthy machines count
                b.Unhealthy containers count
                c.Unhealthy SQL count
                d.Machine vulnerabilities
                e.Container vulnerabilities
                f.SQL vulnerabilities
  <img src="./images/26.png" width=80%>      
   <img src="./images/27.png" width=80%> 
   
        6.System Updates Tab
                a.Resource health under system updates
                b.Count of unhealthy machines under system updates
                c.Count of missing system updates by severity 
                Filters: Severity
                d.List of missing system updates with remediation steps
   <img src="./images/28.png" width=80%>      
   <img src="./images/29.png" width=80%> 
