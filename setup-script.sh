#!/bin/bash

# Google Cloud Load Balancer Lab - Environment Setup Script
# This script sets up the initial environment for the load balancer lab

set -e

echo "========================================="
echo "Google Cloud Load Balancer Lab Setup"
echo "========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if gcloud is installed and authenticated
if ! command -v gcloud &> /dev/null; then
    print_error "gcloud CLI is not installed. Please install it first."
    exit 1
fi

# Check authentication
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    print_error "No active gcloud authentication found. Please run 'gcloud auth login' first."
    exit 1
fi

print_status "Setting up Google Cloud environment..."

# Get current project ID
PROJECT_ID=$(gcloud config get-value project)
if [ -z "$PROJECT_ID" ]; then
    print_error "No project set. Please set a project with: gcloud config set project PROJECT_ID"
    exit 1
fi

print_status "Using project: $PROJECT_ID"

# Prompt for region and zone if not set
REGION=$(gcloud config get-value compute/region)
ZONE=$(gcloud config get-value compute/zone)

if [ -z "$REGION" ]; then
    echo "Available regions:"
    gcloud compute regions list --format="table(name,status)" | head -10
    echo ""
    read -p "Enter your preferred region (e.g., us-central1): " REGION
    gcloud config set compute/region $REGION
fi

if [ -z "$ZONE" ]; then
    echo "Available zones in $REGION:"
    gcloud compute zones list --filter="region:($REGION)" --format="table(name,status)"
    echo ""
    read -p "Enter your preferred zone (e.g., us-central1-c): " ZONE
    gcloud config set compute/zone $ZONE
fi

print_status "Region set to: $REGION"
print_status "Zone set to: $ZONE"

# Enable required APIs
print_status "Enabling required Google Cloud APIs..."
gcloud services enable compute.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com

# Verify APIs are enabled
print_status "Verifying API enablement..."
sleep 10

# Create environment variables file
cat > .env << EOF
# Google Cloud Load Balancer Lab Environment Variables
PROJECT_ID=$PROJECT_ID
REGION=$REGION
ZONE=$ZONE

# Instance Configuration
MACHINE_TYPE=e2-small
IMAGE_FAMILY=debian-11
IMAGE_PROJECT=debian-cloud

# Network Load Balancer Configuration
NETWORK_LB_IP_NAME=network-lb-ip-1
TARGET_POOL_NAME=www-pool
FORWARDING_RULE_NAME=www-rule
HEALTH_CHECK_NAME=basic-check

# Application Load Balancer Configuration
APP_LB_IP_NAME=lb-ipv4-1
BACKEND_SERVICE_NAME=web-backend-service
INSTANCE_TEMPLATE_NAME=lb-backend-template
INSTANCE_GROUP_NAME=lb-backend-group
URL_MAP_NAME=web-map-http
HTTP_PROXY_NAME=http-lb-proxy
FORWARDING_RULE_HTTP_NAME=http-content-rule
HEALTH_CHECK_HTTP_NAME=http-basic-check
EOF

print_status "Environment variables saved to .env file"

# Display current configuration
echo ""
echo "========================================="
echo "Current Configuration:"
echo "========================================="
echo "Project ID: $PROJECT_ID"
echo "Region: $REGION"
echo "Zone: $ZONE"
echo ""

print_status "Environment setup complete!"
print_warning "Make sure to source the .env file in your other scripts: source .env"

echo ""
echo "Next steps:"
echo "1. Run ./scripts/create-instances.sh to create web server instances"
echo "2. Run ./scripts/network-lb-setup.sh to configure Network Load Balancer"
echo "3. Run ./scripts/app-lb-setup.sh to configure Application Load Balancer"