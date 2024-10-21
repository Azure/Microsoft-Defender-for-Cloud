## Enhancing Server and Container Risk Analysis in Power BI - Summary

Microsoft Defender for Cloud offers robust vulnerability assessments for servers and container images. To enhance this assessment, we developed a Power BI model that incorporates additional factors like exploitability, vulnerability age, and contextual risk, such as the number of attack paths and risk factors.

The model built in this Power BI follows a Deterministic Approach, meaning that conditions and weights used are fixed by the consumer but can be adjusted, providing flexibility in risk scoring. The integration of these factors allows for a more in-depth prioritization, creating a comprehensive risk score for each resource and enabling better-targeted remediation.

Key factors in our model include CVE severity, exploit information, contextual resource risk, and attack path details. Scores are aggregated for multiple CVEs, and logarithmic scaling is used to prevent disproportionate weight for resources with numerous vulnerabilities. Additionally, percentiles are applied to dynamically classify risk levels, ensuring clarity and actionability in prioritizing critical assets.

This enhanced Power BI solution supports additional insights into prioritization of remediation across server and container vulnerabilities, helping security teams efficiently improve their cloud security posture.



