#!/bin/bash

# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.



# Capture arguments from Python
PROJECT_ID=$1
REGION=$2
PASSWORD=$3
INSTANCE_ID=$4
DATABASE_VERSION=${5:-POSTGRES_15}
TIER=${6:-db-custom-1-3840}  # Dedicated-core required for Vertex AI ML integration

echo "Starting Cloud SQL deployment for Project: $PROJECT_ID..."

# 1. Config Project
gcloud config set project $PROJECT_ID

# 2. Enable APIs
echo "Enabling required APIs..."
gcloud services enable sqladmin.googleapis.com compute.googleapis.com cloudresourcemanager.googleapis.com

# 3. Create Cloud SQL Instance
if ! gcloud sql instances describe $INSTANCE_ID > /dev/null 2>&1; then
    echo "Creating Cloud SQL Instance $INSTANCE_ID..."
    if ! gcloud sql instances create $INSTANCE_ID \
        --database-version=$DATABASE_VERSION \
        --tier=$TIER \
        --region=$REGION \
        --root-password=$PASSWORD \
        --storage-type=SSD \
        --storage-size=10GB \
        --availability-type=zonal; then
        echo "ERROR: Failed to create Cloud SQL Instance."
        exit 1
    fi
else
    echo "Cloud SQL Instance $INSTANCE_ID already exists. Skipping creation."
fi

# 4. Configure authorized networks for public access 
echo ""
echo "Configuring authorized networks for public access..."
gcloud sql instances patch $INSTANCE_ID \
    --authorized-networks=0.0.0.0/0 \
    --quiet

# 5. Get instance connection info
echo ""
echo "============================================"
echo "Cloud SQL Instance Details:"
echo "============================================"
gcloud sql instances describe $INSTANCE_ID --format="table(name,region,databaseVersion,settings.tier,ipAddresses[0].ipAddress)"

echo ""
echo "   WARNING: Public access (0.0.0.0/0) is enabled for development."
echo "   Run this to disable it later:"
echo "   gcloud sql instances patch $INSTANCE_ID --clear-authorized-networks"
echo ""
echo "Deployment Complete. Check Console at: https://console.cloud.google.com/sql/instances"

