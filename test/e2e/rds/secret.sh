#!/usr/bin/env bash

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ROOT_DIR="$THIS_DIR/../../.."
SCRIPTS_DIR="$ROOT_DIR/scripts"

source "$SCRIPTS_DIR/lib/common.sh"
source "$SCRIPTS_DIR/lib/k8s.sh"
source "$SCRIPTS_DIR/lib/testutil.sh"

test_name="$( filenoext "${BASH_SOURCE[0]}" )"
ack_ctrl_pod_id=$( controller_pod_id "rds")
debug_msg "executing test: $test_name"

secret_name="test-secret"
db_instance_id="db-instance-id"

# PRE-CHECKS

# aws rds describe-db-instances --db-instance-identifier "$db_instance_id" --output json >/dev/null 2>&1
# if [ $? -ne 255 ]; then
#     echo "FAIL: expected $db_instance_id to not exist in RDS. Did previous test run cleanup?"
#     exit 1
# fi

if k8s_resource_exists "$db_instance_id"; then
    echo "FAIL: expected $db_instance_id to not exist. Did previous test run cleanup?"
    exit 1
fi

# TEST ACTIONS and ASSERTIONS

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: $secret_name
data:
  password: Mzk1MjgkdmRnN0pi
EOF

sleep 5

debug_msg "checking secret $secret_name"
kubectl describe secrets/test-secret "$secret_name"

cat <<EOF | kubectl apply -f -
apiVersion: rds.services.k8s.aws/v1alpha1
kind: DBInstance
metadata:
  name: $db_instance_id
spec:
  password:
    name: test-secret
    key: password
EOF

sleep 5

debug_msg "checking db instance $db_instance_id created in RDS"
aws rds describe-db-instances --db-instance-identifier $db_instance_id --output table
if [ $? -eq 255 ]; then
    echo "FAIL: expected $db_instance_id to have been created in RDS"
    kubectl logs -n ack-system "$ack_ctrl_pod_id"
    exit 1
fi

kubectl delete "$db_instance_id" 2>/dev/null
assert_equal "0" "$?" "Expected success from kubectl delete but got $?" || exit 1

aws rds describe-db-instances --db-instance-identifier "$db_instance_id" --output json >/dev/null 2>&1
if [ $? -ne 255 ]; then
    echo "FAIL: expected $db_instance_id to deleted in RDS"
    kubectl logs -n ack-system "$ack_ctrl_pod_id"
    exit 1
fi