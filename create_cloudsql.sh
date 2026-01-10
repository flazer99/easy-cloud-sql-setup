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
TIER=${6:-db-custom-1-3840}  

# Network names 
VPC_NAME="easy-cloudsql-vpc"
SUBNET_NAME="easy-cloudsql-subnet"
PSA_RANGE_NAME="easy-cloudsql-psa-range"

echo "Starting Cloud SQL deployment for Project: $PROJECT_ID..."

# 1. Config Project
gcloud config set project $PROJECT_ID

# 2. Enable APIs
echo "Enabling required APIs..."
gcloud services enable sqladmin.googleapis.com servicenetworking.googleapis.com compute.googleapis.com cloudresourcemanager.googleapis.com

# 3. Network Setup
# Check if VPC exists to avoid errors on re-runs
if ! gcloud compute networks describe $VPC_NAME > /dev/null 2>&1; then
    echo "Creating VPC $VPC_NAME..."
    gcloud compute networks create $VPC_NAME --subnet-mode=custom --bgp-routing-mode=regional
else
    echo "VPC $VPC_NAME already exists. Skipping."
fi

if ! gcloud compute networks subnets describe $SUBNET_NAME --region=$REGION > /dev/null 2>&1; then
    echo "Creating Subnet $SUBNET_NAME..."
    gcloud compute networks subnets create $SUBNET_NAME \
        --region=$REGION \
        --network=$VPC_NAME \
        --range="10.0.0.0/24"
else
    echo "Subnet $SUBNET_NAME already exists. Skipping."
fi

# 4. Private Services Access (PSA) - VPC Peering
if ! gcloud compute addresses describe $PSA_RANGE_NAME --global > /dev/null 2>&1; then
    echo "Creating Private Services Access Range..."
    gcloud compute addresses create $PSA_RANGE_NAME \
        --global \
        --purpose=VPC_PEERING \
        --prefix-length=16 \
        --network=$VPC_NAME
    
    echo "Connecting VPC peering to Google services..."
    gcloud services vpc-peerings connect \
        --service=servicenetworking.googleapis.com \
        --ranges=$PSA_RANGE_NAME \
        --network=$VPC_NAME
else
    echo "PSA Range $PSA_RANGE_NAME already exists. Skipping."
fi

# 5. Create Cloud SQL Instance with Private IP
if ! gcloud sql instances describe $INSTANCE_ID > /dev/null 2>&1; then
    echo "Creating Cloud SQL Instance $INSTANCE_ID with Private IP..."
    if ! gcloud sql instances create $INSTANCE_ID \
        --database-version=$DATABASE_VERSION \
        --tier=$TIER \
        --region=$REGION \
        --root-password=$PASSWORD \
        --storage-type=SSD \
        --storage-size=10GB \
        --availability-type=zonal \
        --no-assign-ip \
        --network=projects/$PROJECT_ID/global/networks/$VPC_NAME; then
        echo "ERROR: Failed to create Cloud SQL Instance."
        exit 1
    fi
else
    echo "Cloud SQL Instance $INSTANCE_ID already exists. Skipping creation."
fi

# 6. Display Instance Details
echo ""
echo "============================================"
echo "Cloud SQL Instance Details:"
echo "============================================"
gcloud sql instances describe $INSTANCE_ID --format="table(name,region,databaseVersion,settings.tier)"

# Get the private IP
PRIVATE_IP=$(gcloud sql instances describe $INSTANCE_ID --format="value(ipAddresses[0].ipAddress)")
CONNECTION_NAME=$(gcloud sql instances describe $INSTANCE_ID --format="value(connectionName)")

echo ""
echo "============================================"
echo "Connection Information:"
echo "============================================"
echo "VPC Network:       $VPC_NAME"
echo "Subnet:            $SUBNET_NAME"
echo "Private IP:        $PRIVATE_IP"
echo "Connection Name:   $CONNECTION_NAME"
echo ""
echo "============================================"
echo "How to Connect:"
echo "============================================"
echo ""
echo "FROM CLOUD RUN (recommended):"
echo "  gcloud run deploy YOUR_SERVICE \\"
echo "      --source . \\"
echo "      --region=$REGION \\"
echo "      --network=$VPC_NAME \\"
echo "      --subnet=$SUBNET_NAME \\"
echo "      --vpc-egress=all-traffic"
echo ""
echo "FOR LOCAL DEVELOPMENT (use Cloud SQL Auth Proxy):"
echo "  ./cloud-sql-proxy $CONNECTION_NAME"
echo "  Then connect to: localhost:5432"
echo ""
echo "Deployment Complete. Check Console at: https://console.cloud.google.com/sql/instances"
