# Notable events queries

The following queries are used to populate the notable events dashboards.
In addition, the notable events dashboard queries are available under "Saved searches" in your workspace. They appear in 3 categories:

- [Security Critical Notable Issues](#Security-Critical-Notable-Issues)
- [Security Warning Notable Issues](#Security-Warning-Notable-Issues)
- [Security Info Notable Issues](#Security-Info-Notable-Issues)

## Security Critical Notable Issues

### Computer with guest account logons

`SecurityEvent
| where EventID == 4624 and TargetUserName == 'Guest' and LogonType in (10, 3)
| summarize count() by Computer`

### Computers missing security updates

`Update
| where UpdateState == 'Needed' and Optional == false and Classification == 'Security Updates' and Approved != false
| summarize count() by Computer`

### Computers with detected threats

`ProtectionStatus
| summarize (TimeGenerated, ThreatStatusRank) = argmax(TimeGenerated, ThreatStatusRank) by Computer
| where ThreatStatusRank > 199 and ThreatStatusRank != 470`

### Distinct malicious IP addresses accessed

`union isfuzzy=true (WireData
| where Direction == 'Outbound'), (WindowsFirewall
| where CommunicationDirection == 'SEND'), (CommonSecurityLog
| where CommunicationDirection == 'Outbound')
| where isnotempty(MaliciousIP)
| summarize by MaliciousIP`

### High priority Active Directory assessment security recommendations

`let schemaColumns = datatable(TimeGenerated:datetime, RecommendationId:string)[];
union isfuzzy=true schemaColumns, (ADAssessmentRecommendation
| where FocusArea == 'Security and Compliance' and RecommendationResult == 'Failed' and RecommendationScore>=35)
| summarize arg_max(TimeGenerated, *) by RecommendationId`

### High priority SQL assessment security recommendations

`let schemaColumns = datatable(TimeGenerated:datetime, RecommendationId:string)[];
union isfuzzy=true schemaColumns, (SQLAssessmentRecommendation
| where FocusArea == 'Security and Compliance' and RecommendationResult == 'Failed' and RecommendationScore>=35)
| summarize arg_max(TimeGenerated, *) by RecommendationId`

### Computers missing critical updates

`Update
| where UpdateState == 'Needed' and Optional == false and Classification == 'Critical Updates' and Approved != false
| summarize count() by Computer`

## Security Warning Notable Issues

### Computers missing critical updates

`Update
| where UpdateState == 'Needed' and Optional == false and Classification == 'Critical Updates' and Approved != false
| summarize count() by Computer`

### Computers with insufficient protection

`ProtectionStatus
| summarize (TimeGenerated, ProtectionStatusRank) = argmax(TimeGenerated, ProtectionStatusRank) by Computer
| where ProtectionStatusRank > 199 and ProtectionStatusRank != 550`

### Computers with system audit policy changes

`SecurityEvent
| where EventID == 4719
| summarize count() by Computer`

### Domain security policy changes

`SecurityEvent
| where EventID == 4739
| summarize count() by DomainPolicyChanged`

### Logons with a clear text password

`SecurityEvent
| where EventID == 4624 and LogonType == 8
| summarize count() by TargetAccount`

### Low priority AD assessment security recommendations

`let schemaColumns = datatable(TimeGenerated:datetime, RecommendationId:string)[];
union isfuzzy=true schemaColumns, (ADAssessmentRecommendation
| where FocusArea == 'Security and Compliance' and RecommendationResult == 'Failed' and RecommendationScore<35)
| summarize arg_max(TimeGenerated, *) by RecommendationId`

### Low priority SQL assessment security recommendations

`let schemaColumns = datatable(TimeGenerated:datetime, RecommendationId:string)[];
union isfuzzy=true schemaColumns, (SQLAssessmentRecommendation
| where FocusArea == 'Security and Compliance' and RecommendationResult == 'Failed' and RecommendationScore<35)
| summarize arg_max(TimeGenerated, *) by RecommendationId`

### Members added To security-enabled groups

`SecurityEvent
| where EventID in (4728, 4732, 4756)
| summarize count() by SubjectAccount`

### Suspicious executables

`SecurityEvent
| where EventID == 8002 and Fqbn == '-'
| summarize ExecutionCountHash=count() by FileHash
| where ExecutionCountHash <= 5`

## Security Info Notable Issues

### Accounts failed to log on

`SecurityEvent
| where EventID == 4625
| summarize count() by TargetAccount`

### Accounts failed to login (Linux)

`LinuxAuditLog
| where RecordType == 'user_login' and res != 'success'
| summarize count() by acct`

### Change or reset passwords attempts

`SecurityEvent
| where EventID in (4723, 4724)
| summarize count() by TargetAccount`

### Computers with cleaned event logs

`SecurityEvent
| where EventID in (1102, 517) and EventSourceName == 'Microsoft-Windows-Eventlog'
| summarize count() by Computer`

### Computers with failed Linux user password change

`Syslog
| where Facility == 'authpriv' and ((SyslogMessage has 'passwd:chauthtok' and SyslogMessage has 'authentication failure') or SyslogMessage has 'password change failed')
| summarize count() by Computer`

### Computers with failed ssh logons

`Syslog
| where (Facility == 'authpriv' and SyslogMessage has 'sshd:auth' and SyslogMessage has 'authentication failure') or (Facility == 'auth' and ((SyslogMessage has 'Failed' and SyslogMessage has 'invalid user' and SyslogMessage has 'ssh2') or SyslogMessage has 'error: PAM: Authentication failure'))
| summarize count() by Computer`

### Computers with failed su logons

`Syslog
| where (Facility == 'authpriv' and SyslogMessage has 'su:auth' and SyslogMessage has 'authentication failure') or (Facility == 'auth' and SyslogMessage has 'FAILED SU')
| summarize count() by Computer`

### Computers with failed sudo logons

`Syslog
| where (Facility == 'authpriv' and SyslogMessage has 'sudo:auth' and (SyslogMessage has 'authentication failure' or SyslogMessage has 'conversation failed')) or ((Facility == 'auth' or Facility == 'authpriv') and SyslogMessage has 'user NOT in sudoers')
| summarize count() by Computer`

### Computers with new Linux group created

`Syslog
| where Facility == 'authpriv' and SyslogMessage has 'new group'
| summarize count() by Computer`

### Computers with users added to a Linux group

`Syslog
| where Facility == 'authpriv' and SyslogMessage has 'to group' and (SyslogMessage has 'add' or SyslogMessage has 'added')
| summarize by Computer`

### Distinct clients resolving malicious domains

`let schemaColumns = datatable(ClientIP:string)[];
union isfuzzy=true schemaColumns, (DnsEvents
| where SubType == 'LookupQuery' and isnotempty(MaliciousIP))
| summarize count() by ClientIP`

### Distinct paths of Executed Commands (Linux)

`LinuxAuditLog
| where RecordType == 'syscall' and syscall == 'execve'
| summarize count() by exe`

### Executed Commands (Linux)

`LinuxAuditLog
| where RecordType == 'syscall' and syscall == 'execve'
| summarize count() by cmd`

### Loading or Unloading of Kernel modules (Linux)

`LinuxAuditLog
| where key == 'kernelmodules' and RecordType != 'CONFIG_CHANGE'`

### Locked accounts

`SecurityEvent
| where EventID == 4740
| summarize count() by TargetAccount`

### Remote procedure call(RPC) attempts

`SecurityEvent
| where EventID == 5712
| summarize count() by Computer`

### Security groups created or modified

`SecurityEvent
| where EventID in (4727, 4731, 4735, 4737, 4754, 4755)
| summarize count() by TargetAccount`

### User accounts created or enabled

`SecurityEvent
| where EventID in (4720, 4722)
| summarize by TargetAccount`