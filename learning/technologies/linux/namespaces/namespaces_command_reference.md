# Linux Namespaces: Command Reference

## Quick Reference Guide

This command reference provides ready-to-use commands for working with Linux namespaces in DevOps environments. Commands are organized by use case and include practical examples for Docker, Kubernetes, and system administration.

## Core Namespace Commands

### lsns - List and Inspect Namespaces

```bash
# Basic namespace listing
lsns                           # List all namespaces
lsns -l                        # Long format with detailed information
lsns --json                    # JSON output for scripting

# Filter by namespace type
lsns -t net                    # Network namespaces only
lsns -t pid                    # PID namespaces only
lsns -t mnt                    # Mount namespaces only
lsns -t ipc                    # IPC namespaces only
lsns -t uts                    # UTS namespaces only
lsns -t user                   # User namespaces only
lsns -t cgroup                 # Cgroup namespaces only

# Custom output formats
lsns -o NS,TYPE,NPROCS,PID,USER,COMMAND
lsns -o +NETNSID,NSFS          # Add network namespace ID and filesystem info

# Filter by specific criteria
lsns -p 1234                   # Show namespaces for specific PID
lsns -n 4026531840            # Show processes in specific namespace
lsns -t net -o NS,NPROCS | sort -n -k2  # Sort network namespaces by process count
```

### nsenter - Enter Existing Namespaces

```bash
# Enter all namespaces of a process
nsenter --target <PID> --all /bin/bash
nsenter -t <PID> -a /bin/bash  # Short form

# Enter specific namespaces
nsenter -t <PID> --mount /bin/bash          # Mount namespace only
nsenter -t <PID> --net /bin/bash            # Network namespace only
nsenter -t <PID> --pid /bin/bash            # PID namespace only
nsenter -t <PID> --mount --net /bin/bash    # Multiple namespaces

# Execute single commands in namespaces
nsenter -t <PID> -n ip addr show            # Check network configuration
nsenter -t <PID> -m mount                   # Check mount points
nsenter -t <PID> -p ps aux                  # Check processes
nsenter -t <PID> -n netstat -tulpn          # Check listening ports

# Advanced options
nsenter -t <PID> -a --preserve-credentials /bin/bash  # Preserve user credentials
nsenter -t <PID> -m --wd=/app /bin/bash     # Set working directory
nsenter -t <PID> -n -r /app tcpdump -i any  # Change root directory
```

### unshare - Create New Namespaces

```bash
# Create single namespaces
unshare --mount /bin/bash      # New mount namespace
unshare --net /bin/bash        # New network namespace
unshare --pid --fork /bin/bash # New PID namespace (requires --fork)
unshare --user /bin/bash       # New user namespace
unshare --ipc /bin/bash        # New IPC namespace
unshare --uts /bin/bash        # New UTS namespace

# Create multiple namespaces
unshare --mount --net --pid --fork /bin/bash
unshare -m -n -p --fork /bin/bash           # Short form
unshare --mount --uts --ipc --net --pid --fork /bin/bash  # Full isolation

# User namespace with root mapping
unshare --user --map-root-user /bin/bash

# Advanced user namespace mapping
unshare --user --map-user=1000 --map-group=1000 /bin/bash
unshare --user --map-users=1000,1000,1 --map-groups=1000,1000,1 /bin/bash

# Execute commands in new namespaces
unshare -n ip link set lo up   # Bring up loopback in new network namespace
unshare -m mount --bind /tmp /mnt  # Create bind mount in new mount namespace
```

## Docker Integration Commands

### Container Namespace Inspection

```bash
# Get container process ID
docker inspect --format '{{.State.Pid}}' <container_name>
docker inspect <container_name> | jq '.[0].State.Pid'

# List container's namespace files
container_pid=$(docker inspect --format '{{.State.Pid}}' <container_name>)
ls -la /proc/$container_pid/ns/

# Compare container namespaces with host
ls -la /proc/1/ns/        # Host namespaces
ls -la /proc/$container_pid/ns/  # Container namespaces

# Get namespace IDs for comparison
stat -c %i /proc/1/ns/net                    # Host network namespace ID
stat -c %i /proc/$container_pid/ns/net       # Container network namespace ID

# Check if namespaces are shared
diff <(ls -la /proc/1/ns/) <(ls -la /proc/$container_pid/ns/)
```

### Container Debugging with Namespaces

```bash
# Enter all container namespaces
container_pid=$(docker inspect --format '{{.State.Pid}}' <container_name>)
nsenter -t $container_pid -a /bin/bash

# Debug specific namespace issues
nsenter -t $container_pid -n ip addr show              # Network configuration
nsenter -t $container_pid -n netstat -tulpn           # Network connections
nsenter -t $container_pid -m mount | column -t        # Mount points
nsenter -t $container_pid -p ps auxf                  # Process tree
nsenter -t $container_pid -n tcpdump -i any           # Network traffic

# Execute container-specific commands
docker exec <container_name> ip addr show
docker exec <container_name> mount | grep -v tmpfs
docker exec <container_name> ps aux
docker exec <container_name> netstat -tulpn
```

### Container Namespace Sharing

```bash
# Share network namespace between containers
docker run -d --name web nginx
docker run -it --network container:web ubuntu /bin/bash

# Share PID namespace for debugging
docker run -d --name app myapp
docker run -it --pid container:app ubuntu ps aux

# Share IPC namespace
docker run -it --ipc container:app ubuntu ipcs

# Share UTS namespace
docker run -it --uts container:app ubuntu hostname

# Share multiple namespaces
docker run -it --network container:web --pid container:web ubuntu

# Use host namespaces (use with caution)
docker run -it --network host ubuntu           # Host network
docker run -it --pid host ubuntu              # Host PID
docker run -it --ipc host ubuntu              # Host IPC
docker run --privileged --pid host --net host ubuntu  # Multiple host namespaces
```

## Kubernetes Integration Commands

### Pod Namespace Inspection

```bash
# Execute commands in Pod namespaces
kubectl exec -it <pod_name> -- /bin/bash
kubectl exec -it <pod_name> -c <container_name> -- /bin/bash

# Check Pod networking (shared among containers)
kubectl exec <pod_name> -- ip addr show
kubectl exec <pod_name> -- ip route show
kubectl exec <pod_name> -- netstat -tulpn

# Check Pod filesystem (per container)
kubectl exec <pod_name> -c <container_name> -- mount | grep -v tmpfs
kubectl exec <pod_name> -c <container_name> -- df -h

# Check Pod processes
kubectl exec <pod_name> -- ps aux
kubectl exec <pod_name> -c <container_name> -- ps aux
```

### Kubernetes Debugging with Ephemeral Containers

```bash
# Create ephemeral container for debugging (Kubernetes 1.25+)
kubectl debug <pod_name> -it --image=busybox --target=<container_name>
kubectl debug <pod_name> -it --image=nicolaka/netshoot --share-processes

# Debug with specific tools
kubectl debug <pod_name> -it --image=busybox --target=app -- sh
kubectl debug <pod_name> -it --image=nicolaka/netshoot -- bash

# Debug networking issues
kubectl debug <pod_name> -it --image=nicolaka/netshoot -- nslookup kubernetes.default.svc.cluster.local
kubectl debug <pod_name> -it --image=nicolaka/netshoot -- tcpdump -i any

# Debug with shared process namespace
kubectl debug <pod_name> -it --image=busybox --share-processes --target=app
```

### Pod Namespace Configuration

```yaml
# Share process namespace within Pod
apiVersion: v1
kind: Pod
metadata:
  name: shared-process-pod
spec:
  shareProcessNamespace: true
  containers:
  - name: app
    image: myapp
  - name: sidecar
    image: busybox
    command: ['sleep', '3600']

# Use host namespaces (requires privileges)
apiVersion: v1
kind: Pod
metadata:
  name: host-namespace-pod
spec:
  hostNetwork: true    # Use host network namespace
  hostPID: true        # Use host PID namespace
  hostIPC: true        # Use host IPC namespace
  containers:
  - name: privileged-container
    image: ubuntu
    securityContext:
      privileged: true
```

## System Administration Commands

### Namespace Monitoring and Analysis

```bash
# Monitor namespace creation/deletion
watch 'lsns | wc -l'                    # Count total namespaces
watch 'lsns -t net | wc -l'            # Count network namespaces
watch 'docker ps | wc -l'              # Monitor container count

# Find orphaned namespaces
lsns | awk '$3 == 0'                   # Namespaces with no processes
find /proc/*/ns -name 'net' -exec ls -la {} \; 2>/dev/null | sort | uniq -c

# Namespace resource usage
systemd-cgtop                          # Show cgroup resource usage
systemd-cgls                           # Show cgroup hierarchy
cat /proc/meminfo | grep -i namespace  # Memory usage related to namespaces

# Network namespace specific monitoring
ip netns list                          # List manually created network namespaces
for ns in $(ip netns list); do
  echo "Namespace: $ns"
  ip netns exec $ns ip addr show
done
```

### Manual Network Namespace Management

```bash
# Create and manage network namespaces manually
ip netns add test_ns                   # Create network namespace
ip netns list                          # List network namespaces
ip netns delete test_ns                # Delete network namespace

# Execute commands in network namespace
ip netns exec test_ns ip addr show
ip netns exec test_ns ip link set lo up

# Connect namespaces with veth pairs
ip link add veth0 type veth peer name veth1
ip link set veth1 netns test_ns
ip netns exec test_ns ip addr add 192.168.1.2/24 dev veth1
ip netns exec test_ns ip link set veth1 up
ip addr add 192.168.1.1/24 dev veth0
ip link set veth0 up

# Test connectivity between namespaces
ping 192.168.1.2                      # From host to namespace
ip netns exec test_ns ping 192.168.1.1  # From namespace to host
```

### User Namespace Management

```bash
# Check user namespace support
cat /proc/sys/kernel/unprivileged_userns_clone  # Should be 1

# Create user namespace with manual mapping
unshare --user /bin/bash
echo $$ > /proc/self/uid_map           # This will fail without privileges

# Proper user namespace setup requires root
echo "1000 1000 1" > /proc/<pid>/uid_map
echo "1000 1000 1" > /proc/<pid>/gid_map

# Check current user namespace mappings
cat /proc/self/uid_map
cat /proc/self/gid_map

# Test user namespace isolation
unshare --user --map-root-user /bin/bash
id                                     # Shows root inside namespace
cat /proc/self/uid_map                 # Shows mapping
```

## Troubleshooting Commands

### Network Namespace Debugging

```bash
# Debug container network connectivity
container_pid=$(docker inspect --format '{{.State.Pid}}' <container>)
nsenter -t $container_pid -n ip addr show
nsenter -t $container_pid -n ip route show
nsenter -t $container_pid -n ping 8.8.8.8
nsenter -t $container_pid -n nslookup google.com
nsenter -t $container_pid -n netstat -tulpn

# Debug Docker networking
docker network ls
docker network inspect bridge
iptables -L -n | grep docker
iptables -t nat -L -n | grep docker

# Capture network traffic in container namespace
nsenter -t $container_pid -n tcpdump -i any -w /tmp/capture.pcap
nsenter -t $container_pid -n tcpdump -i any port 80

# Test network namespace isolation
ip netns add test1
ip netns add test2
ip netns exec test1 ip addr show        # Should only show loopback
ip netns exec test2 ip addr show        # Should only show loopback
```

### Mount Namespace Debugging

```bash
# Debug mount issues in containers
container_pid=$(docker inspect --format '{{.State.Pid}}' <container>)
nsenter -t $container_pid -m mount | column -t
nsenter -t $container_pid -m df -h
nsenter -t $container_pid -m findmnt

# Compare mounts between host and container
diff <(mount | sort) <(nsenter -t $container_pid -m mount | sort)

# Check overlay filesystem layers (Docker)
docker inspect <container> | jq '.[0].GraphDriver'
ls -la /var/lib/docker/overlay2/<layer-id>/

# Debug volume mount issues
docker exec <container> ls -la /mounted/path
ls -la /host/volume/path
docker inspect <container> | jq '.[0].Mounts'
```

### PID Namespace Debugging

```bash
# Debug process visibility issues
container_pid=$(docker inspect --format '{{.State.Pid}}' <container>)
nsenter -t $container_pid -p ps auxf
nsenter -t $container_pid -p pstree

# Compare process trees
diff <(ps auxf) <(nsenter -t $container_pid -p ps auxf)

# Debug init process issues
nsenter -t $container_pid -p ps aux | head -1
docker exec <container> ps aux | head -1

# Check for zombie processes
nsenter -t $container_pid -p ps aux | grep -E "<defunct>|Z"
```

## Performance and Monitoring Commands

### Namespace Performance Analysis

```bash
# Measure namespace creation overhead
time unshare --mount --net --pid --fork /bin/true
time docker run --rm alpine /bin/true

# Monitor namespace system calls
strace -e trace=clone,unshare,setns <command>
strace -e trace=clone,unshare,setns docker run --rm alpine echo test

# Count namespace operations
perf stat -e 'syscalls:sys_enter_clone' docker run --rm alpine echo test
perf stat -e 'syscalls:sys_enter_unshare' docker run --rm alpine echo test

# Monitor namespace file descriptor usage
lsof | grep "/proc/.*/ns/"
find /proc/*/fd -type l -exec readlink {} \; 2>/dev/null | grep "/proc/.*/ns/" | sort | uniq -c
```

### Resource Monitoring

```bash
# Monitor namespace resource consumption
systemd-cgtop
systemd-cgls
cat /sys/fs/cgroup/memory/memory.usage_in_bytes

# Monitor Docker container resource usage
docker stats
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"

# Monitor Kubernetes Pod resource usage
kubectl top pods
kubectl top nodes
kubectl describe node <node-name>
```

## Automation and Scripting

### Namespace Inventory Scripts

```bash
#!/bin/bash
# namespace_inventory.sh - Comprehensive namespace analysis

echo "=== System Namespace Overview ==="
echo "Total namespaces: $(lsns | wc -l)"
echo "Network namespaces: $(lsns -t net | wc -l)"
echo "PID namespaces: $(lsns -t pid | wc -l)"
echo "Mount namespaces: $(lsns -t mnt | wc -l)"

echo -e "\n=== Docker Container Namespaces ==="
for container in $(docker ps --format "{{.Names}}"); do
    pid=$(docker inspect --format '{{.State.Pid}}' $container)
    echo "Container: $container (PID: $pid)"
    echo "  Network NS: $(stat -c %i /proc/$pid/ns/net)"
    echo "  PID NS: $(stat -c %i /proc/$pid/ns/pid)"
    echo "  Mount NS: $(stat -c %i /proc/$pid/ns/mnt)"
done

echo -e "\n=== Namespace Resource Usage ==="
echo "Memory usage by namespace type:"
for type in net pid mnt ipc uts user; do
    count=$(lsns -t $type --noheadings | wc -l)
    echo "  $type: $count namespaces"
done
```

### Container Debugging Helper

```bash
#!/bin/bash
# debug_container.sh - Enter container namespaces for debugging

if [ $# -ne 1 ]; then
    echo "Usage: $0 <container_name>"
    exit 1
fi

container_name=$1
container_pid=$(docker inspect --format '{{.State.Pid}}' $container_name 2>/dev/null)

if [ -z "$container_pid" ]; then
    echo "Error: Container '$container_name' not found or not running"
    exit 1
fi

echo "Entering namespaces for container: $container_name (PID: $container_pid)"
echo "Available commands after entering:"
echo "  ip addr show     - Check network configuration"
echo "  mount | column -t - Check filesystem mounts"
echo "  ps auxf          - Check running processes"
echo "  netstat -tulpn   - Check network connections"
echo ""

exec nsenter -t $container_pid -a /bin/bash
```

### Kubernetes Pod Debugger

```bash
#!/bin/bash
# debug_pod.sh - Debug Kubernetes Pod with ephemeral container

if [ $# -lt 1 ]; then
    echo "Usage: $0 <pod_name> [namespace]"
    exit 1
fi

pod_name=$1
namespace=${2:-default}

echo "Creating debug session for Pod: $pod_name in namespace: $namespace"

kubectl debug $pod_name -n $namespace -it --image=nicolaka/netshoot --share-processes --target=$(kubectl get pod $pod_name -n $namespace -o jsonpath='{.spec.containers[0].name}')
```

## Quick Reference Summary

### Most Common Commands
```bash
# List all namespaces
lsns

# Enter container namespaces
nsenter -t $(docker inspect --format '{{.State.Pid}}' <container>) -a /bin/bash

# Debug Kubernetes Pod
kubectl exec -it <pod> -- /bin/bash

# Create isolated environment
unshare --mount --net --pid --fork /bin/bash

# Check container network
docker exec <container> ip addr show
```

### Emergency Debugging
```bash
# Quick container network check
docker exec <container> ping 8.8.8.8

# Quick container filesystem check
docker exec <container> df -h

# Quick container process check
docker exec <container> ps aux

# Quick namespace overview
lsns | head -20
```

This command reference serves as a practical guide for daily namespace operations in DevOps environments. Keep it handy for quick lookups during troubleshooting sessions and container management tasks.
