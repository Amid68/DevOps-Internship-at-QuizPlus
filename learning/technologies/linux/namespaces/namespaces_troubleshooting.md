# Linux Namespaces: Troubleshooting and Tools Guide

## Overview

This guide provides practical troubleshooting techniques, diagnostic tools, and debugging strategies for Linux namespaces in production environments. When containers misbehave, understanding how to inspect and manipulate namespaces is crucial for rapid problem resolution.

## Essential Namespace Tools

### Core System Tools

#### lsns - List Namespaces
The `lsns` command provides a comprehensive view of all namespaces on the system, showing which processes belong to which namespaces.

```bash
# List all namespaces
lsns

# List specific namespace types
lsns -t net     # Network namespaces only
lsns -t pid     # PID namespaces only
lsns -t mnt     # Mount namespaces only

# Show detailed information with process commands
lsns -l

# Focus on specific namespace
lsns -n 4026531840  # Show processes in specific namespace

# Output formats for scripting
lsns -o NS,TYPE,NPROCS,PID,COMMAND
lsns --json  # JSON output for parsing
```

**Example Output Analysis:**
```bash
$ lsns -t net
        NS TYPE NPROCS   PID USER   NETNSID NSFS COMMAND
4026531992  net     85     1 root unassigned      /sbin/init
4026532241  net      2  1234 root          0      /usr/bin/dockerd
4026532301  net      3  5678 root          1      nginx: master process

# This shows:
# - Host network namespace (4026531992) with 85 processes
# - Docker daemon's network namespace (4026532241)
# - Container network namespace (4026532301) running nginx
```

#### nsenter - Enter Namespaces
The `nsenter` command allows you to enter existing namespaces, essential for debugging running containers.

```bash
# Enter all namespaces of a process
nsenter --target <PID> --all /bin/bash

# Enter specific namespaces
nsenter --target <PID> --mount --pid --net /bin/bash

# Short form options
nsenter -t <PID> -m -p -n /bin/bash

# Practical examples for container debugging
container_pid=$(docker inspect --format '{{.State.Pid}}' container_name)
nsenter -t $container_pid -a /bin/bash  # Enter all namespaces
nsenter -t $container_pid -n ip addr    # Check network config
nsenter -t $container_pid -m mount      # Check mount points
nsenter -t $container_pid -p ps aux     # Check processes
```

**Advanced nsenter Usage:**
```bash
# Enter namespace and preserve environment
nsenter -t <PID> -a --preserve-credentials /bin/bash

# Execute single command in namespace
nsenter -t <PID> -n netstat -tulpn

# Enter namespace with specific working directory
nsenter -t <PID> -m --wd=/app /bin/bash
```

#### unshare - Create New Namespaces
The `unshare` command creates new namespaces, useful for testing and isolation.

```bash
# Create new PID namespace
unshare --pid --fork /bin/bash

# Create multiple namespaces
unshare --mount --uts --ipc --net --pid --fork /bin/bash

# Create user namespace with root mapping
unshare --user --map-root-user /bin/bash

# Create mount namespace and change root
unshare --mount /bin/bash
mount --bind /tmp /mnt
chroot /mnt /bin/bash  # Now in isolated environment
```

### Container Runtime Debugging Tools

#### Docker Debugging
Docker provides several ways to inspect container namespaces and troubleshoot issues.

```bash
# Get container process ID for namespace operations
docker inspect --format '{{.State.Pid}}' container_name

# Check container's namespace IDs
docker inspect container_name | jq '.[0].State.Pid'
ls -la /proc/<pid>/ns/

# Debug network issues
docker exec container_name ip addr show
docker exec container_name netstat -tulpn
docker exec container_name ping external_host

# Debug mount issues  
docker exec container_name mount | column -t
docker exec container_name df -h

# Debug process issues
docker exec container_name ps aux
docker top container_name
```

**Docker Namespace Sharing for Debugging:**
```bash
# Share network namespace with existing container
docker run -it --network container:target_container ubuntu /bin/bash

# Share PID namespace for process debugging
docker run -it --pid container:target_container ubuntu /bin/bash

# Share multiple namespaces
docker run -it --network container:web --pid container:web ubuntu /bin/bash
```

#### Kubernetes Debugging
Kubernetes provides several mechanisms for namespace debugging through kubectl and container runtimes.

```bash
# Execute commands in Pod's namespace
kubectl exec -it pod_name -- /bin/bash
kubectl exec -it pod_name -c container_name -- /bin/bash

# Debug with ephemeral containers (requires Kubernetes 1.25+)
kubectl debug pod_name -it --image=busybox --target=main_container
kubectl debug pod_name -it --image=nicolaka/netshoot --share-processes

# Get Pod's process information from host
kubectl get pod pod_name -o jsonpath='{.status.containerStatuses[0].containerID}'
# Use container ID to find PID on node
```

**Kubernetes Namespace Troubleshooting:**
```bash
# Check Pod network configuration
kubectl exec pod_name -- ip addr show
kubectl exec pod_name -- ip route show
kubectl exec pod_name -- nslookup kubernetes.default.svc.cluster.local

# Check Pod filesystem mounts
kubectl exec pod_name -- mount | grep -v "tmpfs\|devtmpfs"
kubectl exec pod_name -- df -h

# Check Pod processes
kubectl exec pod_name -- ps aux
kubectl top pod pod_name
```

## Common Troubleshooting Scenarios

### Network Namespace Issues

Network problems are among the most common namespace-related issues in container environments.

#### Scenario 1: Container Cannot Reach External Services

**Symptoms:**
- Container processes cannot connect to external hosts
- DNS resolution fails inside container
- Service discovery not working

**Diagnostic Steps:**
```bash
# Check container's network configuration
docker exec container_name ip addr show
docker exec container_name ip route show

# Test connectivity from inside container
docker exec container_name ping 8.8.8.8
docker exec container_name nslookup google.com
docker exec container_name curl -v http://example.com

# Compare with host network
ip addr show
ip route show
ping 8.8.8.8

# Check Docker network configuration
docker network ls
docker network inspect bridge
```

**Common Solutions:**
```bash
# Check Docker daemon DNS configuration
cat /etc/docker/daemon.json
# Should contain DNS servers: {"dns": ["8.8.8.8", "8.8.4.4"]}

# Restart container with custom DNS
docker run --dns=8.8.8.8 --dns=8.8.4.4 image_name

# Check for iptables rules blocking traffic
iptables -L -n | grep docker
iptables -t nat -L -n | grep docker
```

#### Scenario 2: Port Conflicts Between Containers

**Symptoms:**
- Multiple containers trying to bind to same port
- "Address already in use" errors
- Service not accessible from expected ports

**Diagnostic Steps:**
```bash
# Check which processes are using ports
netstat -tulpn | grep :80
ss -tulpn | grep :80

# Check container port mappings
docker ps  # Shows port mappings
docker port container_name

# Inspect specific container networking
docker exec container_name netstat -tulpn
```

**Solutions:**
```bash
# Use different host ports for containers
docker run -p 8080:80 nginx
docker run -p 8081:80 nginx

# Use Docker networks for container-to-container communication
docker network create app_network
docker run --network app_network --name web nginx
docker run --network app_network --name api python:app
# Containers can communicate using container names as hostnames
```

### Mount Namespace Issues

Mount namespace problems often manifest as missing files, permission errors, or unexpected filesystem views.

#### Scenario 3: Volume Mounts Not Working

**Symptoms:**
- Files not appearing in expected locations
- Changes to mounted volumes not persisting
- Permission denied errors on volume access

**Diagnostic Steps:**
```bash
# Check mount points inside container
docker exec container_name mount | grep -v "tmpfs\|proc\|sys"
docker exec container_name df -h

# Verify volume configuration
docker inspect container_name | jq '.[0].Mounts'

# Check host filesystem permissions
ls -la /host/volume/path
```

**Solutions:**
```bash
# Fix permission issues with user mapping
docker run -u $(id -u):$(id -g) -v /host/path:/container/path image

# Use named volumes for persistence
docker volume create my_volume
docker run -v my_volume:/data image

# Set proper SELinux contexts (if applicable)
docker run -v /host/path:/container/path:Z image
```

#### Scenario 4: Container Cannot Access Expected Files

**Symptoms:**
- Application fails to find configuration files
- Libraries or dependencies missing
- Different filesystem view than expected

**Diagnostic Steps:**
```bash
# Compare filesystem view between container and host
docker exec container_name ls -la /
ls -la /

# Check if files exist in expected locations
docker exec container_name find / -name "missing_file" 2>/dev/null

# Verify mount namespace isolation
container_pid=$(docker inspect --format '{{.State.Pid}}' container_name)
nsenter -t $container_pid -m /bin/bash
# Now you're in the container's mount namespace
ls -la /expected/path
```

### PID Namespace Issues

PID namespace problems typically involve process visibility, signal handling, or init process management.

#### Scenario 5: Process Management Issues

**Symptoms:**
- Cannot kill processes inside container
- Zombie processes accumulating
- Process monitoring tools show unexpected results

**Diagnostic Steps:**
```bash
# Check process tree inside container
docker exec container_name ps auxf
docker exec container_name pstree

# Compare with host view
ps aux | grep container_process
pstree -p <container_pid>

# Check process signals and state
docker exec container_name kill -0 <pid>  # Check if process exists
```

**Solutions:**
```bash
# Use proper init process in containers
docker run --init image_name  # Uses tini as init

# Handle signals properly in application
# Ensure main process handles SIGTERM for graceful shutdown

# Use multi-stage approach for complex containers
FROM base AS init
RUN apt-get install -y tini
FROM base AS final
COPY --from=init /usr/bin/tini /usr/bin/tini
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["your-application"]
```

### User Namespace Issues

User namespace problems often involve permission errors, file ownership issues, or security constraints.

#### Scenario 6: Permission Denied Errors

**Symptoms:**
- Cannot write to mounted volumes
- Process cannot access required files
- Unexpected permission errors inside container

**Diagnostic Steps:**
```bash
# Check user/group inside container
docker exec container_name id
docker exec container_name whoami

# Check file ownership on mounted volumes
docker exec container_name ls -la /mounted/volume
ls -la /host/volume/path

# Check user namespace mapping (if enabled)
cat /proc/<container_pid>/uid_map
cat /proc/<container_pid>/gid_map
```

**Solutions:**
```bash
# Run container as specific user
docker run -u 1000:1000 image_name

# Fix ownership on host
sudo chown 1000:1000 /host/volume/path

# Use user namespace remapping
# Edit /etc/docker/daemon.json:
{
  "userns-remap": "default"
}
```

## Advanced Debugging Techniques

### Multi-Namespace Debugging

When dealing with complex issues, you may need to debug across multiple namespaces simultaneously.

```bash
# Create debugging environment with access to multiple namespaces
container_pid=$(docker inspect --format '{{.State.Pid}}' target_container)

# Terminal 1: Network debugging
nsenter -t $container_pid -n /bin/bash
ip addr show
netstat -tulpn
tcpdump -i any

# Terminal 2: Filesystem debugging  
nsenter -t $container_pid -m /bin/bash
mount | column -t
lsof +L1  # Show open files

# Terminal 3: Process debugging
nsenter -t $container_pid -p /bin/bash
ps auxf
strace -p <pid>
```

### System-Wide Namespace Analysis

For complex environments with many containers, system-wide analysis helps identify patterns and issues.

```bash
#!/bin/bash
# Comprehensive namespace analysis script

echo "=== Namespace Overview ==="
lsns | head -20

echo -e "\n=== Network Namespace Details ==="
for ns in $(lsns -t net -o NS --noheadings); do
    echo "Network namespace: $ns"
    nsenter --net=/proc/1/fd/3 3< <(echo $ns) ip addr show | head -5
    echo "---"
done

echo -e "\n=== Mount Namespace Analysis ==="
for ns in $(lsns -t mnt -o NS --noheadings | head -10); do
    echo "Mount namespace: $ns"
    nsenter --mount=/proc/1/fd/3 3< <(echo $ns) df -h | head -5
    echo "---"
done

echo -e "\n=== Container Namespace Mapping ==="
for container in $(docker ps --format "{{.Names}}"); do
    pid=$(docker inspect --format '{{.State.Pid}}' $container)
    echo "Container: $container (PID: $pid)"
    ls -la /proc/$pid/ns/
    echo "---"
done
```

### Performance Impact Analysis

Namespace operations can impact performance, especially in high-scale environments.

```bash
# Measure namespace creation overhead
time docker run --rm alpine echo "test"

# Monitor namespace-related system calls
strace -e trace=clone,unshare,setns docker run --rm alpine echo "test"

# Check namespace resource usage
systemd-cgtop
cat /proc/meminfo | grep -i namespace

# Monitor namespace creation rate
watch 'lsns | wc -l'
```

## Automation and Monitoring

### Automated Namespace Health Checks

```bash
#!/bin/bash
# Namespace health monitoring script

check_namespace_health() {
    local container_name=$1
    local pid=$(docker inspect --format '{{.State.Pid}}' $container_name 2>/dev/null)
    
    if [ -z "$pid" ]; then
        echo "ERROR: Container $container_name not found"
        return 1
    fi
    
    echo "Checking container: $container_name (PID: $pid)"
    
    # Check namespace files exist
    for ns in net pid mnt ipc uts; do
        if [ ! -e "/proc/$pid/ns/$ns" ]; then
            echo "ERROR: $ns namespace missing for $container_name"
        else
            echo "OK: $ns namespace present"
        fi
    done
    
    # Check network connectivity
    if docker exec $container_name ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        echo "OK: Network connectivity"
    else
        echo "ERROR: Network connectivity failed"
    fi
    
    # Check mount points
    mount_count=$(docker exec $container_name mount | wc -l)
    if [ $mount_count -lt 5 ]; then
        echo "WARNING: Low mount count ($mount_count) for $container_name"
    else
        echo "OK: Mount namespace ($mount_count mounts)"
    fi
}

# Check all running containers
for container in $(docker ps --format "{{.Names}}"); do
    check_namespace_health $container
    echo "---"
done
```

### Namespace Monitoring with Prometheus

```bash
# Example metrics collection for namespace monitoring
#!/bin/bash
# namespace_metrics.sh - Collect namespace metrics for Prometheus

METRICS_FILE="/var/lib/node_exporter/textfile_collector/namespaces.prom"

{
    echo "# HELP namespace_count Total number of namespaces by type"
    echo "# TYPE namespace_count gauge"
    
    for type in net pid mnt ipc uts user; do
        count=$(lsns -t $type --noheadings | wc -l)
        echo "namespace_count{type=\"$type\"} $count"
    done
    
    echo "# HELP docker_namespace_count Docker container namespaces"
    echo "# TYPE docker_namespace_count gauge"
    docker_count=$(docker ps -q | wc -l)
    echo "docker_namespace_count $docker_count"
    
} > $METRICS_FILE

# Run this script via cron every minute
# */1 * * * * /usr/local/bin/namespace_metrics.sh
```

## Best Practices for Troubleshooting

### Systematic Debugging Approach

1. **Identify the Scope**: Determine which namespace types might be involved in the issue
2. **Gather Information**: Use `lsns`, `docker inspect`, and namespace-aware tools to collect data
3. **Isolate the Problem**: Test in isolated environments to rule out external factors
4. **Compare States**: Compare working vs. non-working configurations
5. **Document Findings**: Keep detailed logs of debugging steps and solutions

### Tool Selection Guidelines

- **Use `lsns`** for initial namespace overview and identification
- **Use `nsenter`** when you need to debug from inside a namespace
- **Use `docker exec`** for container-specific debugging
- **Use `kubectl debug`** for Kubernetes Pod issues
- **Use `unshare`** for testing namespace configurations

### Prevention Strategies

```bash
# Regular namespace health checks
crontab -e
# Add: */5 * * * * /usr/local/bin/check_namespace_health.sh

# Monitor namespace resource usage
# Set up alerts for:
# - Excessive namespace creation
# - Namespace resource exhaustion  
# - Orphaned namespace files

# Log namespace operations
auditctl -w /proc/self/ns -p rwxa -k namespace_ops
```

### Emergency Recovery Procedures

```bash
# Emergency namespace cleanup
#!/bin/bash
# emergency_namespace_cleanup.sh

echo "WARNING: This will forcefully clean up namespaces"
read -p "Continue? (y/N): " confirm
if [ "$confirm" != "y" ]; then
    exit 1
fi

# Stop all containers
docker stop $(docker ps -q)

# Remove all containers
docker rm $(docker ps -aq)

# Clean up namespace files
find /var/run/netns -type f -delete 2>/dev/null || true

# Restart container runtime
systemctl restart docker

echo "Namespace cleanup completed"
```

## Conclusion

Effective namespace troubleshooting requires understanding both the theoretical concepts and practical tools available for debugging. The key to successful troubleshooting is systematic analysis, proper tool usage, and maintaining detailed documentation of issues and solutions.

Regular practice with these tools and techniques in non-production environments helps build the expertise needed for rapid problem resolution in production scenarios. Remember that namespace issues often involve multiple systems working together, so a holistic approach to debugging is essential for success.
