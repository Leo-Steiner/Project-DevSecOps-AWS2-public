#!/usr/bin/env bash
# Remove the lab. Export evidence BEFORE running this.
set -uo pipefail
PROJECT="${PROJECT:-iu-devsecops}"
REGION="${AWS_REGION:-eu-central-1}"

echo "This deletes all four stacks in $(aws sts get-caller-identity --query Account --output text)."
read -rp "Type delete to continue: " ok; [ "$ok" = "delete" ] || exit 1

APP=$(aws cloudformation describe-stacks --region "$REGION" --stack-name "${PROJECT}-storage" \
  --query "Stacks[0].Outputs[?OutputKey=='AppBucketName'].OutputValue" --output text 2>/dev/null)
[ -n "${APP:-}" ] && aws s3 rm "s3://${APP}" --recursive

for s in monitoring identity storage network; do
  echo "deleting ${PROJECT}-${s}"
  aws cloudformation delete-stack --region "$REGION" --stack-name "${PROJECT}-${s}"
  aws cloudformation wait stack-delete-complete --region "$REGION" --stack-name "${PROJECT}-${s}" 2>/dev/null
done

cat <<'NOTE'
Done, with two deliberate exceptions:
  - the evidence archive is RetainPolicy: Retain, so it survives. Object Lock
    blocks deletion until retention expires. Delete it manually afterwards.
  - AWS Config and Security Hub were enabled by hand; disable them by hand.
Check Billing tomorrow and record the actual cost for Section 3.
NOTE
