#!/bin/bash

# Google Cloud Load Balancer Lab - Create Web Server Instances
# This script creates three web server instances for load balancer testing

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

print_header "Creating Web Server Instances"

# Startup script for web servers
STARTUP_SCRIPT='#!/bin/bash
apt-get update
apt-get install apache2 -y
service apache2 restart
echo "<h3>Web Server: $(hostname)</h3>" | tee /var/www/html/index.html
echo "<p>Instance Zone: $(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/zone | cut -d/ -f4)</p>" >> /var/www/html/index.html
echo "<p>Instance Name: $(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/name)</p>" >> /var/www/html/index.html
echo "<p>Internal IP: $(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)</p>" >> /var/www/html/index.html
echo "<p>External IP: $(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)</p>" >> /var/www/html/index.html'

# Create first web server instance (www1)
print_status "Creating web server instance: www1"
gcloud compute instances create www1 \
    --zone=$ZONE \
    --tags=network-lb-tag \
    --machine-type=$MACHINE_TYPE \
    --image-family=$IMAGE_FAMILY \
    --image-project=$IMAGE_PROJECT \
    --metadata=startup-script="$STARTUP_SCRIPT"

# Create second web server instance (www2)
print_status "Creating web server instance: www2"
gcloud compute instances create www2 \
    --zone=$ZONE \
    --tags=network-lb-tag \
    --machine-type=$MACHINE_TYPE \
    --image-family=$IMAGE_FAMILY \
    --image-project=$IMAGE_PROJECT \
    --metadata=startup-script="$STARTUP_SCRIPT"

# Create third web server instance (www3)
print_status "Creating web server instance: www3"
gcloud compute instances create www3 \
    --zone=$ZONE \
    --tags=network-lb-tag \
    --machine-type=$MACHINE_TYPE \
    --image-family=$IMAGE_FAMILY \
    --image-project=$IMAGE_PROJECT \
    --metadata=startup-script="$STARTUP_SCRIPT"

# Create firewall rule to allow HTTP traffic
print_status "Creating firewall rule for HTTP traffic"
gcloud compute firewall-rules create www-firewall-network-lb \
    --target-tags network-lb-tag \
    --allow tcp:80 \
    --description "Allow HTTP traffic to network load balancer instances"

# Wait for instances to start up
print_status "Waiting for instances to start up..."
sleep 30

# List created instances
print_status "Listing created instances:"
gcloud compute instances list --filter="name:(www1 OR www2 OR www3)" --format="table(name,zone,machineType,status,networkInterfaces[0].accessConfigs[0].natIP:label=EXTERNAL_IP)"

echo ""
print_status "Getting external IP addresses..."

# Get and display external IPs
WWW1_IP=$(gcloud compute instances describe www1 --zone=$ZONE --format="get(networkInterfaces[0].accessConfigs[0].natIP)")
WWW2_IP=$(gcloud compute instances describe www2 --zone=$ZONE --format="get(networkInterfaces[0].accessConfigs[0].natIP)")
WWW3_IP=$(gcloud compute instances describe www3 --zone=$ZONE --format="get(networkInterfaces[0].accessConfigs[0].natIP)")

echo "WWW1 External IP: $WWW1_IP"
echo "WWW2 External IP: $WWW2_IP"
echo "WWW3 External IP: $WWW3_IP"

# Test each instance
print_status "Testing web server instances (this may take a minute for startup scripts to complete)..."
sleep 60

echo ""
echo "Testing www1:"
curl -m 10 http://$WWW1_IP || print_warning "www1 not responding yet (startup script may still be running)"

echo ""
echo "Testing www2:"
curl -m 10 http://$WWW2_IP || print_warning "www2 not responding yet (startup script may still be running)"

echo ""
echo "Testing www3:"
curl -m 10 http://$WWW3_IP || print_warning "www3 not responding yet (startup script may still be running)"

echo ""
print_header "Instance Creation Complete"
print_status "Three web server instances have been created successfully!"
print_warning "If instances are not responding, wait a few more minutes for startup scripts to complete."

echo ""
echo "Created resources:"
echo "- www1 instance with external IP: $WWW1_IP"
echo "- www2 instance with external IP: $WWW2_IP" 
echo "- www3 instance with external IP: $WWW3_IP"
echo "- Firewall rule: www-firewall-network-lb"

echo ""
echo "Next step: Run ./scripts/network-lb-setup.sh to configure Network Load Balancer"