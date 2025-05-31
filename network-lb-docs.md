# Network Load Balancer (Layer 4) - Detailed Guide

## Overview

A Network Load Balancer operates at the transport layer (Layer 4) of the OSI model, making routing decisions based on IP protocol data such as addresses and ports. It provides high-performance, low-latency load balancing for TCP and UDP traffic.

## Architecture Components

### 1. Static External IP Address
- **Purpose**: Entry point for incoming traffic
- **Scope**: Regional resource
- **Function**: Provides a consistent endpoint for clients

### 2. Health Checks
- **Type**: HTTP health checks
- **Function**: Monitor backend instance availability
- **Configuration**:
  - Check interval: 10 seconds
  - Timeout: 5 seconds
  - Healthy threshold: 2 consecutive successes
  - Unhealthy threshold: 3 consecutive failures

### 3. Target Pool
- **Purpose**: Groups backend instances in a region
- **Function**: Defines which instances receive traffic
- **Features**: 
  - Session affinity options
  - Health check integration
  - Automatic failover

### 4. Forwarding Rule
- **Purpose**: Routes traffic to target pools
- **Scope**: Regional
- **Configuration**: Maps IP:port combinations to target pools

## Network Load Balancer Characteristics

### Advantages
- **High Performance**: Minimal latency and high throughput
- **Protocol Support**: Handles TCP, UDP, and other IP protocols
- **Simple Configuration**: Fewer components to manage
- **Cost Effective**: Lower cost compared to Application Load Balancers
- **Preserve Client IP**: Can maintain original client IP addresses

### Use Cases
- High-performance applications requiring low latency
- Non-HTTP/HTTPS protocols (TCP, UDP)
- Gaming applications
- IoT device communication
- Legacy applications
- When you need to preserve client IP addresses

### Limitations
- **No Content-Based Routing**: Cannot route based on HTTP headers or URLs
- **No SSL Termination**: SSL/TLS must be handled by backend instances
- **Limited Health Checks**: Basic connectivity checks only
- **Regional Scope**: Cannot distribute traffic globally

## Implementation Steps

### Step 1: Create Static IP Address
```bash
gcloud compute addresses create network-lb-ip-1 \
    --region us-central1 \
    --description "Static IP for Network Load Balancer"
```

### Step 2: Create Health Check
```bash
gcloud compute http-health-checks create basic-check \
    --description "Basic HTTP health check" \
    --port 80 \
    --request-path "/" \
    --check-interval 10s \
    --timeout 5s \
    --unhealthy-threshold 3 \
    --healthy-threshold 2
```

### Step 3: Create Target Pool
```bash
gcloud compute target-pools create www-pool \
    --region us-central1 \
    --http-health-check basic-check \
    --description "Target pool for Network Load Balancer"
```

### Step 4: Add Instances to Target Pool
```bash
gcloud compute target-pools add-instances www-pool \
    --instances www1,www2,www3 \
    --instances-zone us-central1-c
```

### Step 5: Create Forwarding Rule
```bash
gcloud compute forwarding-rules create www-rule \
    --region us-central1 \
    --ports 80 \
    --address network-lb-ip-1 \
    --target-pool www-pool
```

## Traffic Distribution

### Load Balancing Algorithm
- **Default**: 5-tuple hash (source IP, source port, destination IP, destination port, protocol)
- **Session Affinity**: Can be configured for sticky sessions
- **Distribution**: Traffic is distributed based on connection hash

### Health Check Behavior
- Instances marked unhealthy are removed from rotation
- Health checks run every 10 seconds by default
- Failed instances are automatically added back when healthy

## Monitoring and Troubleshooting

### Check Forwarding Rule Status
```bash
gcloud compute forwarding-rules describe www-rule --region us-central1
```

### View Target Pool Health
```bash
gcloud compute target-pools get-health www-pool --region us-central1
```

### Test Load Balancer
```bash
# Get load balancer IP
IPADDRESS=$(gcloud compute forwarding-rules describe www-rule --region us-central1 --format="json" | jq -r .IPAddress)

# Test traffic distribution  
while true; do curl -m1 $IPADDRESS; done
```

### Common Issues

1. **Health Check Failures**
   - Verify instances are running and healthy
   - Check firewall rules allow health check traffic
   - Ensure web servers are responding on correct port

2. **Uneven Traffic Distribution**
   - Network Load Balancers use connection-based distribution
   - Long-lived connections may cause imbalance
   - Consider session affinity settings

3. **Connectivity Issues**
   - Verify static IP address is correctly assigned
   - Check forwarding rule configuration
   - Ensure target pool has healthy instances

## Best Practices

### Performance Optimization
- Use appropriate machine types for your workload
- Configure health checks appropriately for your application
- Monitor backend instance CPU and memory usage
- Consider auto-scaling for variable traffic loads

### Security Considerations
- Implement proper firewall rules
- Use VPC networks and subnets appropriately
- Consider private instance configurations
- Monitor access logs and traffic patterns

### Cost Optimization
- Right-size your instances based on actual usage
- Use preemptible instances for fault-tolerant workloads
- Monitor and optimize data transfer costs
- Consider regional vs. global load balancing needs

## Comparison with Application Load Balancer

| Feature | Network Load Balancer | Application Load Balancer |
|---------|----------------------|---------------------------|
| **OSI Layer** | Layer 4 (Transport) | Layer 7 (Application) |
| **Protocols** | TCP, UDP, other IP | HTTP, HTTPS |
| **Routing** | IP and port based | Content-based routing |
| **Performance** | Higher throughput, lower latency | Lower throughput, higher latency |
| **SSL Termination** | No | Yes |
| **Global Distribution** | Regional only | Global |
| **Cost** | Lower | Higher |
| **Health Checks** | Basic connectivity | Advanced HTTP checks |

## Next Steps

After setting up your Network Load Balancer:

1. **Monitor Performance**: Use Cloud Monitoring to track metrics
2. **Scale Backend**: Add or remove instances based on demand  
3. **Optimize Health Checks**: Fine-tune check intervals and thresholds
4. **Security Review**: Implement appropriate security measures
5. **Cost Analysis**: Review usage and optimize for cost efficiency

For advanced features and global distribution, consider implementing an Application Load Balancer as well.