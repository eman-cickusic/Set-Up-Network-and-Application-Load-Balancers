# Google Cloud Load Balancer Setup Guide

This repository contains a comprehensive hands-on lab guide for setting up and configuring Network Load Balancers and Application Load Balancers on Google Cloud Platform using Compute Engine virtual machines.

## Video

https://youtu.be/CKTiiyFfTEw

## Overview

This project demonstrates the differences between Network Load Balancers and Application Load Balancers, providing step-by-step instructions to implement both load balancing solutions on Google Cloud.

### Load Balancers Covered
- **Network Load Balancer** (Layer 4) - Routes traffic based on IP protocol data
- **Application Load Balancer** (Layer 7) - Routes traffic based on HTTP/HTTPS content

## Prerequisites

- Access to Google Cloud Platform account
- Basic understanding of cloud computing concepts
- Familiarity with command line interfaces
- Web browser (Chrome recommended)

## Project Structure

```
├── README.md                    # This file
├── scripts/
│   ├── setup-environment.sh    # Initial environment setup
│   ├── create-instances.sh     # Web server instances creation
│   ├── network-lb-setup.sh     # Network Load Balancer configuration
│   ├── app-lb-setup.sh         # Application Load Balancer configuration
│   └── cleanup.sh              # Resource cleanup script
├── docs/
│   ├── network-load-balancer.md # Network LB detailed guide
│   ├── app-load-balancer.md     # Application LB detailed guide
│   └── troubleshooting.md       # Common issues and solutions
└── examples/
    └── startup-scripts/         # VM startup script examples
```

## Quick Start

### 1. Environment Setup

```bash
# Clone this repository
git clone <your-repo-url>
cd google-cloud-load-balancer-lab

# Make scripts executable
chmod +x scripts/*.sh

# Set up your environment
./scripts/setup-environment.sh
```

### 2. Create Web Server Instances

```bash
# Create three web server instances
./scripts/create-instances.sh
```

### 3. Configure Network Load Balancer

```bash
# Set up Layer 4 Network Load Balancer
./scripts/network-lb-setup.sh
```

### 4. Configure Application Load Balancer

```bash
# Set up Layer 7 Application Load Balancer
./scripts/app-lb-setup.sh
```

## Learning Objectives

By completing this lab, you will learn to:

- ✅ Configure default regions and zones for Google Cloud resources
- ✅ Create multiple web server instances using Compute Engine
- ✅ Set up and configure Network Load Balancing services
- ✅ Create and manage Application Load Balancers
- ✅ Understand the differences between Layer 4 and Layer 7 load balancing
- ✅ Test load balancer functionality and traffic distribution

## Architecture Overview

### Network Load Balancer Architecture
```
Internet → Network Load Balancer → Target Pool → VM Instances (www1, www2, www3)
```

### Application Load Balancer Architecture
```
Internet → Global Load Balancer → Backend Service → Managed Instance Group → VM Instances
```

## Key Components Explained

### Network Load Balancer Components
- **Static External IP**: Entry point for incoming traffic
- **Health Checks**: Monitor instance availability
- **Target Pool**: Group of backend instances
- **Forwarding Rules**: Route traffic to target pools

### Application Load Balancer Components
- **Global Static IP**: Anycast IP for global reach
- **HTTP(S) Proxy**: Handles protocol termination
- **URL Maps**: Define routing rules
- **Backend Services**: Manage instance groups
- **Managed Instance Groups**: Auto-scaling VM collections

## Testing Your Load Balancers

### Network Load Balancer Testing
```bash
# Get the load balancer IP
IPADDRESS=$(gcloud compute forwarding-rules describe www-rule --region [REGION] --format="json" | jq -r .IPAddress)

# Test traffic distribution
while true; do curl -m1 $IPADDRESS; done
```

### Application Load Balancer Testing
Access your Application Load Balancer through a web browser using the reserved static IP address. You should see responses from different backend instances.

## Important Notes

- **Resource Costs**: Remember to clean up resources after testing to avoid unnecessary charges
- **Health Check Delays**: Allow 3-5 minutes for health checks to complete
- **Instance Startup**: VM instances may take a few minutes to fully initialize
- **Regional Resources**: Ensure all resources are created in the same region for network connectivity

## Security Considerations

### Firewall Rules Created
- `www-firewall-network-lb`: Allows HTTP traffic (port 80) to Network LB instances
- `fw-allow-health-check`: Allows Google Cloud health checking systems access

### IP Ranges for Health Checks
- `130.211.0.0/22`
- `35.191.0.0/16`

## Troubleshooting

Common issues and solutions can be found in [`docs/troubleshooting.md`](docs/troubleshooting.md).

### Quick Fixes
- **Instances not responding**: Check firewall rules and startup scripts
- **Health checks failing**: Verify Apache is running and port 80 is accessible
- **Load balancer not working**: Allow 5-10 minutes for configuration propagation

## Cleanup

To avoid ongoing charges, clean up all resources when finished:

```bash
./scripts/cleanup.sh
```

## Additional Resources

- [Google Cloud Load Balancing Documentation](https://cloud.google.com/load-balancing/docs)
- [Compute Engine Networking](https://cloud.google.com/compute/docs/networking)
- [Health Check Concepts](https://cloud.google.com/load-balancing/docs/health-checks)

## Contributing

Feel free to submit issues and enhancement requests!

## License

This project is licensed under the MIT License - see the LICENSE file for details.

---
