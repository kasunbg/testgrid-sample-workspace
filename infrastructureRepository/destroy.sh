#!/bin/bash


#-------------------------------------------------------------------------------
# Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#--------------------------------------------------------------------------------

set -o xtrace

#definitions
INPUT_DIR=$2
source $INPUT_DIR/deployment.properties

function delete_route53_entry() {
    env=${TESTGRID_ENVIRONMENT} || 'dev'
    if [[ "${env}" != "dev" ]] && [[ "${env}" != 'prod' ]]; then
        echo "Not deleting route53 DNS entries since the environment is not dev/prod."
        return;
    fi

    command -v aws >/dev/null 2>&1 || { echo >&2 "I optionally require aws but it's not installed. "; return; }
    echo "Adding route53 entry to access Kubernetes ingress from the AWS ec2 instances"
    testgrid_hosted_zone_id=$(aws route53 list-hosted-zones --query "HostedZones[?Name=='wso2testgrid.com.'].Id" --output text)

    cat > route53-delete-change-resource-record-sets.json << EOF
{
  "Comment": "testgrid job delete mapping for ${loadBalancerHostName}",
  "Changes": [
    {
      "Action": "DELETE",
      "ResourceRecordSet": {
        "Name": "${loadBalancerHostName}",
        "Type": "A",
        "TTL": 60,
        "ResourceRecords": [
          {
            "Value": "${external_ip}"
          }
        ]
      }
    }
  ]
}
EOF
cat route53-delete-change-resource-record-sets.json

change_id=$(aws route53 change-resource-record-sets --hosted-zone-id ${testgrid_hosted_zone_id} \
    --change-batch file://route53-delete-change-resource-record-sets.json \
    --query "ChangeInfo.Id" --output text)
time aws route53 wait resource-record-sets-changed --id ${change_id}

echo "AWS Route53 DNS mapping deleted for ${loadBalancerHostName}"
echo
}

function delete_resources() {
  echo "running destroy.sh"
  echo DEBUG: Temporarily disabling kubectl delete namespace
#  kubectl delete namespaces $namespace
  delete_route53_entry
}

#DEBUG parameters
#TESTGRID_ENVIRONMENT=dev
#loadBalancerHostName=test.gke.wso2testgrid.com
#external_ip=10.1.1.1
delete_resources