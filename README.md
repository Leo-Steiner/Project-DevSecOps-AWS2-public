# AWS DevSecOps Baseline

A hardened, monitored AWS environment built with DevSecOps principles, together with a controlled attack simulation that verifies the detection chain end to end.

## What this project does

- Deploys a private VPC with public/private subnet separation across two Availability Zones.
- Enforces least-privilege IAM with MFA, scoped roles and a deliberately weak test identity.
- Protects data with SSE-KMS, block-public-access and a separate evidence archive using S3 Object Lock.
- Monitors all activity with CloudTrail, CloudWatch alarms, GuardDuty and Security Hub.
- Runs a controlled attack (credential access, defense evasion, persistence) inside the sandbox.
- Validates CloudTrail log integrity over the whole exercise window.

## Architecture

![Architecture](docs/architecture.png)

## Results

## Results

| Test | Result |
|---|---|
| Identity | Pass — permitted upload succeeded; forbidden policy attachment refused |
| Network | Pass — private route table has no 0.0.0.0/0 route; app port admitted from the LB group only |
| Storage | Partial — permitted upload succeeded; wrong-key upload refused; foreign-identity object-read test not established |
| Log tampering | Partial — sacrificial application object deleted (version preserved by bucket versioning); evidence archive access refused with AccessDenied (IAM policy); no actual log file was modified |
| Logging | Pass — evidence archive refused tampering; 13/13 digests and 150/150 log files valid |
| Detection | **Partial — sign-in alarm delivered; two of three alarms stayed silent (see Report Section 6.2)** |
| Persistence | Pass — CreateUser refused; no second identity created |
| Recovery | Pass — baseline restored in 20 min 19 s |
| Pipeline checks | Passing with documented exceptions — see `.checkov.yaml` and `.cfn-lint` |
|

The Detection row reflects the most instructive finding of the exercise: two of three alarms were correctly specified and correctly deployed but never fired because the API call was never issued at all. See the report's Section 6.2 for the full analysis.

## Repository structure

- `infra/` — CloudFormation templates
- `policies/` — redacted IAM policies
- `detection/` — CloudWatch metric filter definitions
- `tests/` — acceptance test script
- `docs/` — architecture diagram, scope record, exercise runbook
- `evidence/redacted/` — redacted exercise summary
- `.github/workflows/` — CI pipeline

## Deploy it yourself

See `docs/Beginner_Guide.md` for step-by-step instructions.

## What I would do differently

- Use a separate security account for the evidence archive.
- Automate response actions instead of manual investigation.
- Test multi-AZ failover with a second application instance.

## Licence

MIT
