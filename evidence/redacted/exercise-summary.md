# Controlled Exercise Summary (S11)

- Account alias: `leodevsecops` (real account ID redacted)
- Region: `eu-central-1`
- Exercise window: see `docs/runbook-exercise.md` for exact UTC timestamps.

## Stage 1 — Credential Access
- 6 failed `ConsoleLogin` attempts as `iu-devsecops-lab-weak-user`
- 1 successful `ConsoleLogin`
- CloudWatch alarm `iu-devsecops-console-login-failures` transitioned to ALARM
- SNS notification delivered to the configured email address

## Stage 2 — Defense Evasion

| Action | Result |
|---|---|
| `sacrificial.txt` delete | Succeeded (Delete Marker created, version preserved) |
| Evidence bucket access | Access Denied |
| CloudTrail stop-logging | Access Denied |
| S3 console warning | "You don't have permission to get the Bucket Versioning setting" |

## Stage 3 — Persistence
- `CreateUser` attempt as weak identity: Access Denied
- No `backdoor-admin` user was created

## CloudTrail log integrity
- 13/13 digest files valid
- 150/150 log files valid

## Recovery
- Weak identity disabled
- Baseline least-privilege policy restored
- Permitted access: works
- Prohibited access: fails
- Total recovery time: 20 minutes 19 seconds
