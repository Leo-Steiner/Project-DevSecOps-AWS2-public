#!/usr/bin/env bash
# Deploy the DevSecOps lab. Run ONLY in the disposable account from S2.
#
#   ./deploy.sh <bucket-suffix> <alert-email> <lab-password>
#
# Example:
#   ./deploy.sh ls4417 leo@example.com 'Sommer2026!'
#
# Order matters: storage exports the bucket and key ARNs that identity and
# monitoring import. Each step waits for the previous one to finish.

set -euo pipefail

SUFFIX="${1:?usage: ./deploy.sh <bucket-suffix> <alert-email> <lab-password>}"
EMAIL="${2:?missing alert email}"
LABPW="${3:?missing lab user password}"

PROJECT="${PROJECT:-iu-devsecops}"
REGION="${AWS_REGION:-eu-central-1}"

echo "Account: $(aws sts get-caller-identity --query Account --output text)"
echo "Region : ${REGION}"
read -rp "Deploy to this account? Type yes to continue: " ok
[ "$ok" = "yes" ] || { echo "aborted"; exit 1; }

deploy () {
  local file="$1"; shift
  local name="$1"; shift
  echo ""
  echo "=== ${name} ==="
  aws cloudformation deploy \
    --region "${REGION}" \
    --template-file "${file}" \
    --stack-name "${name}" \
    --capabilities CAPABILITY_NAMED_IAM \
    --no-fail-on-empty-changeset \
    "$@"
}

deploy infra/01-network.yaml   "${PROJECT}-network" \
  --parameter-overrides ProjectName="${PROJECT}"

deploy infra/02-storage.yaml   "${PROJECT}-storage" \
  --parameter-overrides ProjectName="${PROJECT}" BucketSuffix="${SUFFIX}"

deploy infra/03-identity.yaml  "${PROJECT}-identity" \
  --parameter-overrides ProjectName="${PROJECT}" LabUserPassword="${LABPW}"

deploy infra/04-monitoring.yaml "${PROJECT}-monitoring" \
  --parameter-overrides ProjectName="${PROJECT}" AlertEmail="${EMAIL}"

echo ""
echo "=== stack outputs ==="
for s in network storage identity monitoring; do
  echo "--- ${PROJECT}-${s} ---"
  aws cloudformation describe-stacks --region "${REGION}" \
    --stack-name "${PROJECT}-${s}" \
    --query 'Stacks[0].Outputs[].[OutputKey,OutputValue]' --output table
done

cat <<'NEXT'

NEXT STEPS
  1. Confirm the SNS subscription email. Until you click it, no alarm is
     ever delivered and the S7 detection test fails for the wrong reason.
  2. Enable AWS Config, then Security Hub, in the console. These are NOT in
     the templates because they are the only chargeable part of this design
     (a few cents per day). Enable them for the evaluation window only.
  3. Run ./tests/acceptance.sh to capture the S11 evidence.
NEXT
