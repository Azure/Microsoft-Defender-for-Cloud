IdentityDashboard = { 
    IdentityPosture: {
        FailedPostureDonut:
        {
            NavigationQuery: "SecurityEvent | where AccountType == 'User' and EventID == {0}",
            Query: "SecurityEvent \
                    | where AccountType == 'User' and EventID in (4624, 4625) \
                    | summarize Value = count() by Group = EventID"
        },
        LogonsPostureTile:
        {
            NavigationQuery: "SecurityEvent | where EventID == 4624 and AccountType == 'User' | extend LowerAccount=tolower(Account) | summarize Logons = count() by LowerAccount",
            Query:
                "SecurityEvent \
                | where EventID == 4624 and AccountType == 'User'"
        },
        FailedLogonsPosture:
        {
            NavigationQuery: "SecurityEvent | where EventID == 4625 and AccountType == 'User' | extend LowerAccount=tolower(Account) | summarize Failed = count() by LowerAccount",
            Query: 
                "SecurityEvent \
                | where EventID == 4625 and AccountType == 'User'"
        },
        LockedPostureTile:
        {
            NavigationQuery: "SecurityEvent | where EventID == 4740 | extend LowerAccount=tolower(Account) | summarize count() by LowerAccount",
            Query: 
                "SecurityEvent \
                | where EventID == 4740"
        },
        PasswordChangePostureTile:
        {
            NavigationQuery: "SecurityEvent | where EventID in (4723, 4724) | extend LowerTargetAccount=tolower(TargetAccount) | summarize count() by LowerTargetAccount",
            Query: 
                "SecurityEvent \
                | where EventID in (4723, 4724)"
        }
    },
    FailedLogons: {
        FailedLoginList: {
            Query: 
                "SecurityEvent \
                | where AccountType == 'User' and EventID in (4624, 4625) \
                | summarize Failures = countif(EventID == 4625), Count = count() by AccountName \
                | where Failures > 0 \
                | project AccountName, Percentage = todouble(Failures) / Count, Count \
                | sort by Percentage desc, Count desc \
                | limit 10",
            NavigationQuery:
            "SecurityEvent | where EventID == 4625 and AccountType == 'User' | summarize count() by AccountName",
            ItemNavigationQuery:
            "SecurityEvent | where EventID == 4625 and AccountType == 'User' | where AccountName == {SelectedItem}"
        },
        FailedReasonTile: {
            Query: "SecurityEvent \
                    | where AccountType == 'User' and EventID == 4625 \
                    | extend Group = extract('%%(.+)', 1, FailureReason) \
                    | summarize Value = count() by Group",
            NavigationQueryFormat: "SecurityEvent | where AccountType == 'User' and EventID == 4625 and ({0})",
            IncludeReasonStatement: "FailureReason has '{0}'"
        }
    },
    LogonsOverTime:
    {
        LoginList: {
            ItemNavigationQuery: "SecurityEvent | where AccountType == 'User' and EventID in (4624, 4625) and {selected item}",
            NavigationQuery: "SecurityEvent | where AccountType == 'User' and EventID in (4624, 4625) | summarize Count=count() by Computer | sort by Count desc",
            Query: "SecurityEvent \
                    | where AccountType == 'User' and EventID in (4624, 4625) \
                    | summarize Count=count() by Computer \
                    | top 10 by Count"
        },
        TimeLine: {
            SuccessfulLoginTrend: 
                "SecurityEvent \
                | where AccountType == 'User' and EventID == 4624 \
                | summarize count() by Type",
            FailedLoginTrend: 
                "SecurityEvent \
                | where AccountType == 'User' and EventID == 4625 \
                | summarize count() by Type",
            NavigationQuery: "SecurityEvent | where AccountType == 'User' and EventID in (4624, 4625)"
        }
    }
};