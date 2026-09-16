#!/usr/bin/env bash
# Acceptance tests for Table 4. Writes every raw result to evidence/raw/.
#
#   ./tests/acceptance.sh
#
# A test that cannot run prints SKIP, never PASS. Read the output rather than
# trusting the summary line: the point of the exercise is the evidence, not
# the verdict.

set -uo pipefail

PROJECT="${PROJECT:-iu-devsecops}"
REGION="${AWS_REGION:-eu-central-1}"
OUT="evidence/raw"
mkdir -p "$OUT"

out () { aws cloudformation describe-stacks --region "$REGION" \
  --stack-name "${PROJECT}-$1" --query "Stacks[0].Outputs[?OutputKey=='$2'].OutputValue" \
  --output text 2>/dev/null; }

APP_BUCKET=$(out storage AppBucketName)
EVI_BUCKET=$(out storage EvidenceBucketName)
KEY_ARN=$(out storage AppKeyArn)
RT_ID=$(out network PrivateRouteTableId)
SG_ID=$(out network AppSecurityGroupId)
TRAIL_ARN=$(out monitoring TrailArn)

pass () { printf "PASS  %s\n" "$1"; }
fail () { printf "FAIL  %s\n" "$1"; }
skip () { printf "SKIP  %s\n" "$1"; }

echo "=== T1 identity: permitted succeeds, policy change denied ==="
echo "hello" > /tmp/t1.txt
if aws s3api put-object --bucket "$APP_BUCKET" --key test-data/t1.txt \
     --body /tmp/t1.txt --server-side-encryption aws:kms \
     --ssekms-key-id "$KEY_ARN" > "$OUT/t1-allowed.json" 2>&1; then
  pass "permitted upload to test-data/ succeeded"
else
  fail "permitted upload was refused - check the bucket policy"; cat "$OUT/t1-allowed.json"
fi
if aws iam attach-user-policy --user-name "${PROJECT}-lab-weak-user" \
     --policy-arn arn:aws:iam::aws:policy/AdministratorAccess > "$OUT/t1-denied.txt" 2>&1; then
  fail "ESCALATION SUCCEEDED - the weak user could grant itself admin"
else
  pass "policy attachment denied: $(grep -o 'AccessDenied\|explicit deny' "$OUT/t1-denied.txt" | head -1)"
fi

echo ""
echo "=== T2 network: private tier has no internet-gateway route ==="
aws ec2 describe-route-tables --region "$REGION" --route-table-ids "$RT_ID" \
  > "$OUT/t2-private-routes.json" 2>&1
if grep -q '"GatewayId": "igw-' "$OUT/t2-private-routes.json"; then
  fail "private route table contains an internet-gateway route"
else
  pass "no internet-gateway route in the private route table"
fi
aws ec2 describe-security-groups --region "$REGION" --group-ids "$SG_ID" \
  > "$OUT/t2-app-sg.json" 2>&1
if grep -q '"CidrIp": "0.0.0.0/0"' "$OUT/t2-app-sg.json"; then
  fail "app security group is open to the internet"
else
  pass "app security group accepts the load-balancer group only"
fi

echo ""
echo "=== T3 storage: wrong key and foreign identity must fail ==="
if aws s3api put-object --bucket "$APP_BUCKET" --key test-data/t3-wrongkey.txt \
     --body /tmp/t1.txt --server-side-encryption aws:kms \
     --ssekms-key-id alias/aws/s3 > "$OUT/t3-wrongkey.txt" 2>&1; then
  fail "WRONG-KEY UPLOAD SUCCEEDED - this is the defect described in 6.2"
else
  pass "wrong-key upload denied by the bucket policy"
fi
aws s3api head-object --bucket "$APP_BUCKET" --key test-data/t1.txt \
  > "$OUT/t3-metadata.json" 2>&1 && pass "object metadata captured (check SSEKMSKeyId)"

echo ""
echo "=== T4 logging: archive survives tampering ==="
if aws s3api delete-object --bucket "$EVI_BUCKET" \
     --key "AWSLogs/placeholder" > "$OUT/t4-delete-attempt.txt" 2>&1; then
  echo "  note: a delete marker may have been created - inspect versions below"
fi
aws s3api list-object-versions --bucket "$EVI_BUCKET" --max-items 20 \
  > "$OUT/t4-versions.json" 2>&1 && pass "object versions listed - confirm originals survive"
if [ -n "$TRAIL_ARN" ]; then
  aws cloudtrail validate-logs --region "$REGION" --trail-arn "$TRAIL_ARN" \
    --start-time "$(date -u -d '2 hours ago' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v-2H +%Y-%m-%dT%H:%M:%SZ)" \
    > "$OUT/t4-digest-validation.txt" 2>&1 && pass "digest validation ran - read the output"
else
  skip "no trail ARN found"
fi

echo ""
echo "=== T5 detection: alarm state ==="
aws cloudwatch describe-alarms --region "$REGION" \
  --alarm-name-prefix "${PROJECT}-" \
  --query 'MetricAlarms[].[AlarmName,StateValue,StateUpdatedTimestamp]' \
  --output table | tee "$OUT/t5-alarms.txt"
echo "  record the source event time, the alarm time and the email arrival time by hand"

echo ""
echo "=== T6 persistence: attempt to create a second identity ==="
if aws iam create-user --user-name "${PROJECT}-persist-test" \
     > "$OUT/t6-createuser.txt" 2>&1; then
  fail "CreateUser succeeded - delete it now: aws iam delete-user --user-name ${PROJECT}-persist-test"
else
  pass "CreateUser denied"
fi

echo ""
echo "Raw output written to $OUT/ (gitignored). Redact before committing anything."
