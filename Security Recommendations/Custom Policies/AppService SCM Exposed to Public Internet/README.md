# AppService SCM Exposed to Public Internet

App Service deploys Kudo or KudoLite SCM administration portal, by default deployment this portal is exposed to the public Internet but is secured around an AAD and RBAC identity boundary. To further secure this you may want to limit exposure of SCM administrator portal to your data center public ip address using Virtual Network ACL Restrictions.

Policy Supports: disabled, auditIfNotExists, or deployIfNotExists

https://docs.microsoft.com/en-us/azure/app-service/app-service-ip-restrictions#scm-site

Using Azure Security Center custom initiatives, you can create a Azure policy and assign to initiave for Custom Recommendations