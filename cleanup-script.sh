#!/bin/bash

# Google Cloud Load Balancer Lab - Cleanup Script
# This script removes all resources created during the lab to avoid ongoing charges

set -e

# Source environment variables
if [ -f .env ]; then
    source .env
else
    echo "Error: .env file not found. Please run setup-environment.sh first."
    exit 1
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}=========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}=========================================${NC}"
}

# Confirmation prompt
print_header "Google Cloud Load Balancer Lab Cleanup"
print_warning "This will delete ALL resources created during the lab!"
echo ""
echo "Resources to be deleted:"
echo "- VM instances: www1, www2, www3"
echo "- Managed instance group and template"
echo "- Load balancers and forwarding rules"
echo "- Static IP addresses"
echo "- Health checks and firewall rules"
echo ""
read -p "Are you sure you want to proceed? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

# Function to safely delete resources
safe_delete() {
    local resource_type=$1
    local resource_name=$2
    local additional_flags=$3
    
    if gcloud compute $resource_type describe $resource_name $additional_flags &>/dev/null; then
        print_status "Deleting $resource_type: $resource_name"
        gcloud compute $resource_type delete $resource_name $additional_flags --quiet
    else
        print_warning "$resource_type $resource_name does not exist or already deleted"
    fi
}

print_header "Starting Cleanup Process"

# 1. Delete Application Load Balancer resources (in correct order)
print_status "Cleaning up Application Load Balancer resources..."

# Delete global forwarding rule
safe_delete "forwarding-rules" $FORWARDING_RULE_HTTP_NAME "--global"

# Delete HTTP proxy
safe_delete "target-http-proxies" $HTTP_PROXY_NAME ""

# Delete URL map
safe_delete "url-maps" $URL_MAP_NAME ""

# Delete backend service
safe_delete "backend-services" $BACKEND_SERVICE_NAME "--global"

# Delete managed instance group
safe_delete "instance-groups managed" $INSTANCE_GROUP_NAME "--zone=$ZONE"

# Delete instance template
safe_delete "instance-templates" $INSTANCE_TEMPLATE_NAME ""

# Delete HTTP health check for App LB
safe_delete "health-checks" $HEALTH_CHECK_HTTP_NAME ""

# Delete global static IP
safe_delete "addresses" $APP_LB_IP_NAME "--global"

# 2. Delete Network Load Balancer resources (in correct order)
print_status "Cleaning up Network Load Balancer resources..."

# Delete forwarding rule
safe_delete "forwarding-rules" $FORWARDING_RULE_NAME "--region=$REGION"

# Delete target pool
safe_delete "target-pools" $TARGET_POOL_NAME "--region=$REGION"

# Delete HTTP health check for Network LB
safe_delete "http-health-checks" $HEALTH_CHECK_NAME ""

# Delete regional static IP
safe_delete "addresses" $NETWORK_LB_IP_NAME "--region=$REGION"

# 3. Delete VM instances
print_status "Cleaning up VM instances..."
safe_delete "instances" "www1" "--zone=$ZONE"
safe_delete "instances" "www2" "--zone=$ZONE"
safe_delete "instances" "www3" "--zone=$ZONE"

# 4. Delete firewall rules
print_status "Cleaning up firewall rules..."
safe_delete "firewall-rules" "www-firewall-network-lb" ""
safe_delete "firewall-rules" "fw-allow-health-check" ""

# Wait a moment for cleanup to complete
sleep 10

print_header "Cleanup Verification"

# Verify cleanup
print_status "Verifying resource cleanup..."

echo ""
echo "Remaining instances (should be empty or not include www1, www2, www3):"
gcloud compute instances list --filter="name:(www1 OR www2 OR www3)" --format="table(name,zone,status)" || echo "No matching instances found (good!)"

echo ""
echo "Remaining forwarding rules (should not include lab resources):"
gcloud compute forwarding-rules list --filter="name:($FORWARDING_RULE_NAME OR $FORWARDING_RULE_HTTP_NAME)" --format="table(name,region,IPAddress)" || echo "No matching forwarding rules found (good!)"

echo ""  
echo "Remaining static IP addresses (should not include lab resources):"
gcloud compute addresses list --filter="name:($NETWORK_LB_IP_NAME OR $APP_LB_IP_NAME)" --format="table(name,region,address,status)" || echo "No matching addresses found (good!)"

print_header "Cleanup Complete"
print_status "All lab resources have been successfully deleted!"

echo ""
echo "Summary of deleted resources:"
echo "✓ Application Load Balancer components"
echo "✓ Network Load Balancer components" 
echo "✓ VM instances (www1, www2, www3)"
echo "✓ Instance groups and templates"
echo "✓ Static IP addresses"
echo "✓ Health checks"
echo "✓ Firewall rules"

echo ""
print_status "No ongoing charges should be incurred from this lab."
print_warning "Remember to check the Google Cloud Console to confirm all resources are deleted."

# Optional: Remove local environment file
read -p "Do you want to remove the local .env file as well? (yes/no): " remove_env
if [ "$remove_env" = "yes" ]; then
    rm -f .env
    print_status "Local .env file removed."
fi

echo ""
echo "Thank you for completing the Google Cloud Load Balancer Lab!"