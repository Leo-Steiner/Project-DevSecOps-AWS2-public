# Scope Record — AWS DevSecOps Baseline

## Account and Region

| Field | Value |
|---|---|
| Account alias | `leodevsecops` |
| AWS Region | `eu-central-1` (Europe / Frankfurt) |
| Project start date | 2026-09-15 |
| Project end date | 2026-09-16 |

## Scope statement

All testing is confined to this account.

No resource outside this AWS account is accessed, modified or tested. No production, customer or third-party data is used. The account is a disposable sandbox created exclusively for this project.

## Budget

| Field | Value |
|---|---|
| Budget ceiling | EUR 25.00 |
| Alert threshold 1 | 40 % (EUR 10.00) |
| Alert threshold 2 | 80 % (EUR 20.00) |
| Actual cost | USD 0.35 |

## Repository

| Field | Value |
|---|---|
| Repository URL | `https://github.com/Leo-Steiner/Project-DevSecOps-AWS2` |
| Visibility | Private until S18 |
| Licence | MIT |

## Access model

- Root user: MFA enabled, no access keys, reserved for account recovery only.
- Administrative IAM user: MFA enabled, used for daily work.
- No credentials, account IDs, ARNs containing the account number, or raw logs are committed to the repository.
