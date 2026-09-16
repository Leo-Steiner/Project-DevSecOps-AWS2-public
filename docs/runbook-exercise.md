# Controlled Exercise Runbook

## Scope
- Account alias: leodevsecops
- Region: eu-central-1
- Start time (UTC): 2026-09-14T21:07:31Z
- Configuration revision: 4ac57fd 

## Recovery plan
- Primary: still signed in as leo-admin in main browser window
- Fallback: root user with MFA

## Rules
- All actions confined to this account
- No resource outside this account is touched
- Every action is recorded with a UTC timestamp

## Sacrificial resources
- S3 object: s3://iu-devsecops-app-ls9971/test-data/sacrificial.txt
- Version ID: 1LwPUgHjhg4l97sGNPcmMvFeXSzTwWkx
- Encryption: SSE-KMS with the project key (ARN redacted)
