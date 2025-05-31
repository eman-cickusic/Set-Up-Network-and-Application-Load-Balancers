#!/bin/bash

# Google Cloud Load Balancer Lab - Network Load Balancer Setup
# This script configures a Layer 4 Network Load Balancer

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

print_header "Setting up Network Load Balancer"

# Step 1: Create static external IP address
print_status "Creating static external IP address for Network Load Balancer..."
gcloud compute addresses create $NETWORK_LB_IP_NAME \
    --region $REGION \
    --description "Static IP for Network Load Balancer"

# Get the reserved IP address
NETWORK_LB_IP=$(gcloud compute addresses describe $NETWORK_LB_IP_NAME --region=$REGION --format="get(address)")
print_status "Reserved IP address: $NETWORK_LB_IP"

# Step 2: Create HTTP health check
print_status "Creating HTTP health check..."
gcloud compute http-health-checks create $HEALTH_CHECK_NAME \
    --description "Basic HTTP health check for Network Load Balancer" \
    --port 80 \
    --request-path "/" \
    --check-interval 10s \
    --timeout 5s \
    --unhealthy-threshold 3 \
    --healthy-threshold 2

# Step 3: Create target pool
print_status "Creating target pool..."
gcloud compute target-pools create $TARGET_POOL_NAME \
    --region $REGION \
    --http-health-check $HEALTH_CHECK_NAME \
    --description "Target pool for Network Load Balancer"

# Step 4: Add instances to target pool
print_status "Adding instances to target pool..."
gcloud compute target-pools add-instances $TARGET_POOL_NAME \
    --instances www1,www2,www3 \
    --instances-zone $ZONE

# Step 5: Create forwarding rule
print_status "Creating forwarding rule..."
gcloud compute forwarding-rules create $FORWARDING_RULE_NAME \
    --region $REGION \
    --ports 80 \
    --address $NETWORK_LB_IP_NAME \
    --target-pool $TARGET_POOL_NAME \
    --description "Forwarding rule for Network Load Balancer"

# Wait for configuration to propagate
print_status "Waiting for configuration to propagate..."
sleep 30

# Display load balancer information
print_header "Network Load Balancer Configuration"

echo "Load Balancer IP: $NETWORK_LB_IP"
echo "Target Pool: $TARGET_POOL_NAME"
echo "Health Check: $HEALTH_CHECK_NAME"
echo "Forwarding Rule: $FORWARDING_RULE_NAME"

# Display forwarding rule details
print_status "Forwarding rule details:"
gcloud compute forwarding-rules describe $FORWARDING_RULE_NAME --region $REGION

echo ""
print_status "Target pool instances:"
gcloud compute target-pools describe $TARGET_POOL_NAME --region $REGION --format="get(instances[])"

# Test the load balancer
print_header "Testing Network Load Balancer"
print_status "Load balancer IP: $NETWORK_LB_IP"
print_warning "Testing load balancer (may take a few minutes for health checks to pass)..."

echo ""
echo "Testing connectivity to load balancer..."
for i in {1..5}; do
    echo "Test #$i:"
    curl -m 10 http://$NETWORK_LB_IP || echo "Connection failed (health checks may still be initializing)"
    echo ""
    sleep 2
done

echo ""
print_status "To continuously test load balancer traffic distribution, run:"
echo "IPADDRESS=\$(gcloud compute forwarding-rules describe $FORWARDING_RULE_NAME --region $REGION --format=\"json\" | jq -r .IPAddress)"
echo "while true; do curl -m1 \$IPADDRESS; done"

echo ""
print_header "Network Load Balancer Setup Complete"
print_status "Network Load Balancer has been configured successfully!"

echo ""
echo "Created resources:"
echo "- Static IP: $NETWORK_LB_IP_NAME ($NETWORK_LB_IP)"
echo "- Health Check: $HEALTH_CHECK_NAME"
echo "- Target Pool: $TARGET_POOL_NAME"
echo "- Forwarding Rule: $FORWARDING_RULE_NAME"

echo ""
echo "Next step: Run ./scripts/app-lb-setup.sh to configure Application Load Balancer"