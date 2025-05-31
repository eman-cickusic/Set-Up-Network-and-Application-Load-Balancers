# Application Load Balancer (Layer 7) - Detailed Guide

## Overview

An Application Load Balancer operates at the application layer (Layer 7) of the OSI model, making routing decisions based on HTTP/HTTPS content such as URLs, headers, and cookies. It provides advanced traffic management capabilities with global distribution.

## Architecture Components

### 1. Global Static IP Address
- **Purpose**: Anycast IP that routes traffic to the nearest Google Point of Presence
- **Scope**: Global resource
- **Function**: Provides worldwide accessibility with optimal routing

### 2. HTTP(S) Proxy
- **Purpose**: Handles HTTP/HTTPS protocol termination
- **Function**: Processes requests and applies routing rules
- **Features**: SSL termination, request modification, security policies

### 3. URL Maps
- **Purpose**: Define routing rules based on request content
- **Function**: Route requests to different backend services
- **Capabilities**: 
  - Path-based routing
  - Host-based routing  
  - Header-based routing
  - Query parameter routing

### 4. Backend Services
- **Purpose**: Manage groups of backend instances
- **Function**: Handle load balancing algorithms, health checks, and capacity
- **Features**: Connection draining, session affinity, circuit breakers

### 5. Managed Instance Groups
- **Purpose**: Auto-scaling collections of identical VM instances
- **Function**: Automatic scaling, healing, and updating
- **Benefits**: High availability, automatic recovery, rolling updates

### 6. Health Checks
- **Type**: HTTP/HTTPS health checks
- **Function**: Monitor application-level health
- **Advanced Features**: Custom health check paths, protocol-specific checks

## Application Load Balancer Characteristics

### Advantages
- **Global Distribution**: Routes traffic to nearest healthy backend
- **Content-Based Routing**: Advanced routing based on HTTP content
- **SSL Termination**: Handles SSL/TLS encryption and decryption
- **Auto-Scaling**: Automatic capacity management
- **Advanced Health Checks**: Application-aware health monitoring
- **Security Features**: Cloud Armor integration, DDoS protection
- **Protocol Support**: HTTP/1.1, HTTP/2, WebSocket, gRPC

### Use Cases
- Modern web applications requiring global reach
- Microservices architectures
- Content-based routing requirements
- SSL termination needs
- API gateways
- Progressive deployment strategies (A/B testing, canary deployments)
- Applications requiring advanced security features

### Limitations
- **Higher Latency**: Additional processing overhead
- **HTTP/HTTPS Only**: Limited to web protocols
- **Higher Cost**: More expensive than Network Load Balancers
- **Complexity**: More components to configure and manage

## Implementation Steps

### Step 1: Create Instance Template
```bash
gcloud compute instance-templates create lb-backend-template \
    --region=us-central1 \
    --network=default \
    --subnet=default \
    --tags=allow-health-check \
    --machine-type=e2-medium \
    --image-family=debian-11 \
    --image-project=debian-cloud \
    --metadata=startup-script='#!/bin/bash
        apt-get update
        apt-get install apache2 -y
        systemctl restart apache2'
```

### Step 2: Create Managed Instance Group
```bash
gcloud compute instance-groups managed create lb-backend-group \
    --template=lb-backend-template \
    --size=2 \
    --zone=us-central1-c
```

### Step 3: Create Health Check Firewall Rule
```bash
gcloud compute firewall-rules create fw-allow-health-check \
    --network=default \
    --action=allow \
    --direction=ingress \
    --source-ranges=130.211.0.0/22,35.191.0.0/16 \
    --target-tags=allow-health-check \
    --rules=tcp:80
```

### Step 4: Reserve Global Static IP
```bash
gcloud compute addresses create lb-ipv4-1 \
    --ip-version=IPV4 \
    --global
```

### Step 5: Create HTTP Health Check
```bash
gcloud compute health-checks create http http-basic-check \
    --port 80 \
    --check-interval 10s \
    --timeout 5s \
    --unhealthy-threshold 3 \
    --healthy-threshold 2
```

### Step 6: Create Backend Service
```bash
gcloud compute backend-services create web-backend-service \
    --protocol=HTTP \
    --port-name=http \
    --health-checks=http-basic-check \
    --global
```

### Step 7: Add Instance Group to Backend Service
```bash
gcloud compute backend-services add-backend web-backend-service \
    --instance-group=lb-backend-group \
    --instance-group-zone=us-central1-c \
    --global
```

### Step 8: Create URL Map
```bash
gcloud compute url-maps create web-map-http \
    --default-service web-backend-service
```

### Step 9: Create HTTP Proxy
```bash
gcloud compute target-http-proxies create http-lb-proxy \
    --url-map web-map-http
```

### Step 10: Create Global Forwarding Rule
```bash
gcloud compute forwarding-rules create http-content-rule \
    --address=lb-ipv4-1 \
    --global \
    --target-http-proxy=http-lb-proxy \
    --ports=80
```

## Advanced Routing Configurations

### Path-Based Routing
Route requests based on URL paths:

```bash
# Create additional backend service for API
gcloud compute backend-services create api-backend-service \
    --protocol=HTTP \
    --health-checks=http-basic-check \
    --global

# Update URL map with path rules
gcloud compute url-maps add-path-matcher web-map-http \
    --path-matcher-name=path-matcher \
    --default-service=web-backend-service \
    --path-rules="/api/*=api-backend-service"
```

### Host-Based Routing
Route requests based on hostname:

```bash
# Add host rules to URL map
gcloud compute url-maps add-host-rule web-map-http \
    --hosts=api.example.com \
    --path-matcher-name=api-matcher
```

## Security Features

### Cloud Armor Integration
```bash
# Create security policy
gcloud compute security-policies create lb-security-policy \
    --description "Security policy for load balancer"

# Add rules to security policy
gcloud compute security-policies rules create 1000 \
    --security-policy lb-security-policy \
    --expression "origin.region_code == 'US'" \
    --action allow

# Apply to backend service
gcloud compute backend-services update web-backend-service \
    --security-policy lb-security-policy \
    --global
```

### SSL/TLS Configuration
```bash
# Create SSL certificate
gcloud compute ssl-certificates create lb-ssl-cert \
    --domains example.com \
    --global

# Create HTTPS proxy
gcloud compute target-https-proxies create https-lb-proxy \
    --url-map web-map-http \
    --ssl-certificates lb-ssl-cert

# Create HTTPS forwarding rule
gcloud compute forwarding-rules create https-content-rule \
    --address=lb-ipv4-1 \
    --global \
    --target-https-proxy=https-lb-proxy \
    --ports=443
```

## Monitoring and Troubleshooting

### Check Backend Health
```bash
gcloud compute backend-services get-health web-backend-service --global
```

### View Load Balancer Metrics
```bash
# Get forwarding rule details
gcloud compute forwarding-rules describe http-content-rule --global

# View URL map configuration
gcloud compute url-maps describe web-map-http
```

### Common Issues

1. **Backend Instances Unhealthy**
   - Verify health check firewall rules (130.211.0.0/22, 35.191.0.0/16)
   - Check instance group instances are running
   - Validate health check path returns 200 OK
   - Review health check logs

2. **SSL Certificate Issues**
   - Verify domain ownership for managed certificates
   - Check certificate provisioning status
   - Ensure DNS points to load balancer IP
   - Allow time for certificate provisioning (up to 60 minutes)

3. **Routing Problems**
   - Review URL map configuration
   - Check path matcher rules
   - Verify backend service associations
   - Test with curl to isolate issues

4. **Performance Issues**
   - Monitor backend utilization
   - Check connection draining settings
   - Review auto-scaling configuration
   - Analyze request patterns

## Auto-Scaling Configuration

### Configure Auto-Scaling
```bash
# Set autoscaling policy
gcloud compute instance-groups managed set-autoscaling lb-backend-group \
    --zone us-central1-c \
    --max-num-replicas 10 \
    --min-num-replicas 2 \
    --target-cpu-utilization 0.75 \
    --cool-down-period 90s
```

### Health Check Configuration
```bash
# Create custom health check
gcloud compute instance-groups managed set-autohealing lb-backend-group \
    --zone us-central1-c \
    --health-check http-basic-check \
    --initial-delay 300s
```

## Best Practices

### Performance Optimization
- Use appropriate instance types and sizes
- Configure proper health check intervals
- Implement connection draining for graceful shutdowns
- Enable auto-scaling based on metrics
- Use regional persistent disks for better performance

### Security Best Practices
- Implement Cloud Armor security policies
- Use managed SSL certificates for domains
- Configure appropriate firewall rules
- Enable access logging for audit trails
- Implement proper backend authentication

### Cost Optimization
- Right-size instance groups based on traffic patterns
- Use preemptible instances where appropriate
- Monitor and optimize data transfer costs
- Review load balancer configuration regularly
- Implement cost alerts and budgets

### High Availability
- Deploy across multiple zones
- Configure appropriate health checks
- Implement proper monitoring and alerting
- Use managed instance groups for auto-healing
- Test disaster recovery procedures

## Comparison: Network vs Application Load Balancer

| Aspect | Network LB | Application LB |
|--------|------------|----------------|
| **Latency** | Lower (L4) | Higher (L7) |
| **Throughput** | Higher | Lower |
| **Global Distribution** | No | Yes |
| **SSL Termination** | No | Yes |
| **Content Routing** | No | Yes |
| **Protocol Support** | TCP/UDP | HTTP/HTTPS |
| **Cost** | Lower | Higher |
| **Use Case** | High-performance, simple routing | Complex routing, global apps |

## Next Steps

After implementing your Application Load Balancer:

1. **Configure HTTPS**: Set up SSL certificates for secure communication
2. **Implement Security**: Add Cloud Armor policies for protection
3. **Set Up Monitoring**: Configure logging and alerting
4. **Optimize Performance**: Fine-tune auto-scaling and health checks
5. **Plan for Growth**: Design for scalability and global expansion

For high-performance, protocol-agnostic needs, consider also implementing a Network Load Balancer for specific use cases.