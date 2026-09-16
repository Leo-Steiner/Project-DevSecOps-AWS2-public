# Detection rules

Three CloudWatch metric filters and alarms are configured in `04-monitoring.yaml`:

| Filter | Source | Threshold | Alarm |
|---|---|---|---|
| Failed console sign-ins | CloudTrail `ConsoleLogin` with `Failure` | >= 5 in 5 min | `iu-devsecops-console-login-failures` |
| Logging interference | `StopLogging`, `DeleteTrail`, `UpdateTrail`, `PutEventSelectors` | >= 1 in 1 min | `iu-devsecops-logging-interference` |
| Identity changes | `CreateUser`, `AttachUserPolicy`, `PutUserPolicy`, `CreateAccessKey`, `CreateLoginProfile`, `AttachRolePolicy` | >= 1 in 1 min | `iu-devsecops-identity-changes` |

All alarms deliver to the SNS topic `iu-devsecops-security-alerts`.
