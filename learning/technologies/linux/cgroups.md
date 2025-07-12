# Linux Cgroups (Control Groups)

## What are Linux Cgroups?

Control Groups (cgroups), originally known as "process containers", are a Linux kernel mechanism designed to organize processes hierarchically and distribute system resources along the hierarchy in a controlled and configurable manner. They allow administrators to limit, account for, and isolate the resource usage of a collection of processes.

Cgroups are a facility built into the kernel that allows administrators to set resource utilization limits on any process on the system. Unlike traditional process management, cgroups allow for fine-grained control over how much CPU, memory, I/O, and network bandwidth a group of processes can consume, preventing any single process or group from monopolizing system resources.

## Key Features and Capabilities

### 1. Resource Limiting
**Primary function:** Ensuring programs running on the system stay within acceptable boundaries for various resources.

**Examples:**
- `cpu.max` - Limit CPU usage to a specific percentage
- `memory.max` - Cap memory consumption
- `io.max` - Limit block device I/O throughput
- `pids.max` - Restrict number of processes/threads

### 2. Prioritization
**Purpose:** Setting priorities to ensure fair resource distribution based on importance.

**How it works:**
- Process X can always have more system time than process Y, regardless of available resources
- Proportional resource distribution based on weights

**Examples:**
- `cpu.weight` - Proportionally distribute CPU cycles
- `cpu.weight.nice` - Nice-level based CPU priority
- `io.weight` - I/O bandwidth prioritization

### 3. Accounting
**Purpose:** Measuring a group's resource usage for monitoring, optimization, and billing.

**Use cases:**
- Diagnosing performance issues
- Optimizing resource allocation
- Billing in multi-tenant environments
- Capacity planning

**Examples:**
- `memory.current` - Real-time memory usage
- `cpu.stat` - CPU usage statistics
- `io.stat` - I/O operation statistics

### 4. Process Control
**Advanced capabilities:** Managing process lifecycle and state.

**Features:**
- **Freezer:** Take snapshots of processes for migration
- **Kill operations:** Terminate entire cgroup as a single unit
- **State management:** Pause and resume process groups

**Examples:**
- `cgroup.freeze` - Freeze/unfreeze processes in cgroup v2
- `cgroup.kill` - Kill all processes in a cgroup

### 5. Device Control
**Security component:** Controlling device access permissions.

**Capabilities:**
- Control read, write, and mknod operations on devices
- Key component in comprehensive security strategies
- Prevent unauthorized device access

## Cgroup Versions: v1 vs. v2

### Cgroup v1 (Legacy)

**Architecture:**
- Allowed arbitrary number of hierarchies
- Each hierarchy could host any number of controllers
- Flexible but problematic in practice

**Issues:**
- Controllers not movable between hierarchies
- Lack of unified view across controllers
- Threads of a process could belong to different cgroups
- API confusion between applications and system management
- Complex management due to multiple hierarchies

**Current Status:** Still supported but deprecated in favor of v2

### Cgroup v2 (Unified Hierarchy)

**Architecture:**
- Single, unified hierarchy design
- All subsystems are part of one tree
- Simpler management and better controller cooperation

**Key Improvements:**
- **Process-centric:** Discriminates between processes, not threads
- **Thread consistency:** All threads of a process must belong to the same cgroup
- **Clear boundaries:** Well-defined resource domain boundaries
- **Better cooperation:** Controllers work together more effectively
- **Simplified API:** Cleaner interface for both applications and management tools

**No Internal Process Constraint:**
- Non-root cgroups can only distribute domain resources to children when they have no processes of their own
- Ensures processes are always on the leaves of the hierarchy when domain controllers are enabled
- Prevents competition between parent and children
- Root cgroup is exempt from this constraint

## How Cgroups Work: The cgroupfs Pseudo-Filesystem

The fundamental interface for interacting with cgroups is a pseudo-filesystem called cgroupfs, typically mounted at `/sys/fs/cgroup`. Following the Unix philosophy of "everything is a file," there are no dedicated system calls for cgroup operations.

### Basic Operations

#### Hierarchy Creation
```bash
# Creating a subdirectory automatically creates a new cgroup
mkdir /sys/fs/cgroup/my-cgroup

# This creates a new cgroup with relevant control files
ls /sys/fs/cgroup/my-cgroup/
# cgroup.controllers  cgroup.procs  cgroup.subtree_control  cpu.max  memory.max
```

#### Controllers
Each specific resource (CPU, memory, I/O, etc.) is managed by a controller that manifests as files within the cgroup directory.

**Common Controllers:**
- `cpu.max` - CPU bandwidth limit
- `memory.max` - Memory usage limit
- `io.weight` - I/O priority weight
- `pids.max` - Process/thread count limit

#### Process Assignment
```bash
# Assign process to cgroup by writing PID to cgroup.procs
echo $$ > /sys/fs/cgroup/my-cgroup/cgroup.procs

# Verify assignment
cat /sys/fs/cgroup/my-cgroup/cgroup.procs
```

#### Hierarchical Inheritance
- Each child inherits and is restricted by limits set on parent cgroups
- Top-down constraint ensures hierarchical resource distribution
- Children cannot exceed parent limits

### Example: Creating and Using a Cgroup

```bash
# Create a new cgroup
mkdir /sys/fs/cgroup/webserver

# Set memory limit to 512MB
echo 512M > /sys/fs/cgroup/webserver/memory.max

# Set CPU limit to 50% (50000 out of 100000 microseconds per 100ms period)
echo "50000 100000" > /sys/fs/cgroup/webserver/cpu.max

# Assign current shell to the cgroup
echo $$ > /sys/fs/cgroup/webserver/cgroup.procs

# Start a process that will inherit these limits
./my-webserver &

# Monitor resource usage
cat /sys/fs/cgroup/webserver/memory.current
cat /sys/fs/cgroup/webserver/cpu.stat
```

## Integration with Higher-Level Tools

### libcgroup Tools (Legacy)

**Commands:**
- `cgcreate` - Create new cgroups
- `cgset` - Set cgroup parameters
- `cgexec` - Execute commands in specific cgroup
- `cgclassify` - Move running processes to cgroups

**Note:** Some distributions have deprecated libcgroup in favor of systemd integration.

```bash
# Example libcgroup usage
cgcreate -g cpu,memory:/webserver
cgset -r memory.max=512M /webserver
cgexec -g cpu,memory:/webserver ./my-webserver
```

### Systemd Integration

**Modern approach:** systemd assumes exclusive access to the cgroups facility and provides superior integration.

#### Automatic Cgroup Creation
- systemd automatically creates cgroups for services it monitors
- Services are typically organized under `system.slice`
- User sessions get their own slice hierarchy

#### systemd Tools

**systemd-run:** Launch processes with transient cgroup limits
```bash
# Run command with memory limit
systemd-run --scope -p MemoryMax=512M ./my-webserver

# Run with CPU and memory limits
systemd-run --scope -p CPUQuota=50% -p MemoryMax=1G ./my-application
```

**systemd-cgls:** Inspect systemd-managed cgroups
```bash
# Show cgroup hierarchy
systemd-cgls

# Show specific slice
systemd-cgls system.slice
```

**systemd-cgtop:** Monitor cgroup resource usage
```bash
# Real-time cgroup monitoring
systemd-cgtop

# Sort by memory usage
systemd-cgtop --order=memory
```

#### Systemd Slice Units
Create persistent cgroups for multiple processes that survive reboots:

```ini
# /etc/systemd/system/webserver.slice
[Unit]
Description=Web Server Slice
Before=slices.target

[Slice]
MemoryMax=2G
CPUQuota=150%
```

#### Delegation
- systemd can delegate cgroups to non-root users
- Allows users to configure and manage sub-hierarchies
- Crucial feature for containerization
- Enables unprivileged container management

### Container Runtime Integration

#### Cgroup Driver
For container runtimes, it's highly recommended to use the systemd cgroup driver:

```bash
# Configure runc to use systemd cgroup driver
runc --systemd-cgroup run container-name

# This ensures compatibility and proper resource management
```

**Why systemd driver is recommended:**
- Better integration with systemd-managed systems
- Proper resource management with cgroup v2
- Consistent behavior across different workloads
- Simplified debugging and monitoring

## Cgroups and Containerization

Cgroups are a critical component for modern Kubernetes workloads and other containerization solutions like Docker. They provide the resource management foundation that makes containers possible.

### Under the Hood: Container Creation Process

1. **Docker Command:** `docker run` is executed
2. **Docker Daemon:** Passes request to containerd
3. **containerd:** Delegates to runc (OCI runtime)
4. **runc:** Directly interfaces with Linux kernel features:
   - Creates namespaces for isolation
   - **Creates and configures cgroups** for resource management
   - Writes to files under `/sys/fs/cgroup` to set limits
   - Moves container process into its cgroup

### Resource Enforcement in Kubernetes

**How it works:**
- Kubernetes uses cgroups to enforce resource requests and limits configured for Pods and containers
- Ensures containers adhere to allocated CPU, memory, and other resources
- Prevents "noisy neighbor" problems
- Improves overall system stability

**Example Pod with resource limits:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: resource-limited-pod
spec:
  containers:
  - name: app
    image: nginx
    resources:
      requests:
        memory: "256Mi"
        cpu: "250m"
      limits:
        memory: "512Mi"
        cpu: "500m"
```

### Cgroup v2 Adoption in Kubernetes

**Status:** Kubernetes achieved general availability for cgroup v2 support as of version 1.25.

**Benefits of cgroup v2 in Kubernetes:**
- Better resource management and accounting
- Improved memory management with unified hierarchy
- Enhanced security with better isolation
- More efficient resource distribution

**Migration considerations:**
- Requires kernel support for cgroup v2
- Container runtime must support cgroup v2
- May require configuration changes in existing clusters

## Cgroups vs. Namespaces

While often used together in containerization, cgroups and namespaces serve distinct purposes:

| Aspect | Cgroups | Namespaces |
|--------|---------|------------|
| **Primary Function** | Limit and distribute resources | Isolate and provide separate views |
| **What they manage** | How much of a resource a process can use | What a process can see |
| **Resource types** | CPU, memory, I/O, network bandwidth | Process trees, filesystems, network, users |
| **Purpose** | Resource management and control | Process isolation and privilege separation |
| **Security role** | Prevent resource exhaustion attacks | Prevent information disclosure and privilege escalation |

### Complementary Nature
Together, cgroups and namespaces provide a robust solution for containerization:
- **Namespaces:** Create isolated environments
- **Cgroups:** Control resource usage within those environments
- **Combined:** Form the core of Linux container technology

## Benefits of Using Cgroups

### 1. Improved Resource Allocation
- Efficiently allocate resources based on current needs
- Prevent resource starvation scenarios
- Enable fair sharing among competing processes
- Support for complex allocation policies

### 2. Enhanced System Stability
- Isolate applications to prevent resource monopolization
- Prevent single processes from causing system-wide instability
- Enable graceful degradation under high load
- Protect critical system processes

### 3. Effective Monitoring and Observability
- Gain detailed insights into resource usage patterns
- Enable performance optimization based on real data
- Facilitate troubleshooting of resource-related issues
- Support capacity planning and forecasting

### 4. Better Load Balancing
- Distribute workloads more consistently across resources
- Enable sophisticated scheduling algorithms
- Support for priority-based resource allocation
- Facilitate elastic scaling of applications

### 5. Enhanced Security Posture
- Impose restrictions on process resource access
- Control access to specific devices and resources
- Contribute to "defense-in-depth" security strategy
- Limit attack impact through resource constraints

### 6. Greater Server Density
- Allow more workloads on single servers through careful resource management
- Optimize hardware utilization
- Reduce infrastructure costs
- Enable efficient multi-tenancy

### 7. Performance Tuning
- Achieve significant performance improvements through fine-tuned resource allocation
- Critical for latency-sensitive environments
- Essential for meeting Service Level Agreements (SLAs)
- Enable workload-specific optimizations

## Challenges and Considerations

### 1. Migration of Stateful Resources
**Issue:** Migrating a process to a different cgroup does not move stateful resources like memory, which remain charged to the original cgroup.

**Implications:**
- Memory accounting may become inaccurate after process migration
- Resource limits may not apply as expected
- Careful planning needed for process migration

### 2. Complexity
**Issue:** While simplified in v2, cgroups can still be complex, particularly with manual configurations or deeply nested hierarchies.

**Challenges:**
- Understanding controller interactions
- Managing hierarchical resource distribution
- Debugging complex cgroup configurations
- Balancing flexibility with simplicity

### 3. Error Messages and Debugging
**Issue:** The kernel's error messages for invalid cgroup operations can sometimes be vague, making troubleshooting challenging.

**Common problems:**
- Cryptic error messages from kernel
- Difficulty identifying root cause of failures
- Limited debugging tools for complex scenarios

### 4. Dynamic Changes
**Issue:** While possible, dynamically moving controllers or frequently migrating processes across cgroups is generally discouraged.

**Reasons:**
- Performance overhead of frequent migrations
- State implications and resource accounting issues
- Potential for inconsistent behavior
- Complexity in automation and orchestration

### 5. Filesystem Specifics
**Issue:** Cgroup writeback, which manages dirty memory, requires explicit support from the underlying filesystem.

**Considerations:**
- Not all filesystems support cgroup-aware writeback
- May impact I/O performance and memory management
- Requires careful filesystem selection for optimal performance

### 6. Kernel Version Requirements
**Issue:** Different cgroup features and versions have specific kernel version requirements.

**Planning considerations:**
- Compatibility across different kernel versions
- Feature availability varies by kernel version
- Upgrade planning for new cgroup features
- Testing requirements for kernel updates

## Practical Examples

### Basic Cgroup Management

```bash
# Create a cgroup for a web application
mkdir /sys/fs/cgroup/webapp

# Set resource limits
echo "2G" > /sys/fs/cgroup/webapp/memory.max
echo "1000000 1000000" > /sys/fs/cgroup/webapp/cpu.max  # 100% of 1 CPU
echo "100" > /sys/fs/cgroup/webapp/pids.max

# Run application in the cgroup
echo $$ > /sys/fs/cgroup/webapp/cgroup.procs
./my-webapp &

# Monitor resource usage
watch cat /sys/fs/cgroup/webapp/memory.current
```

### systemd Integration Example

```bash
# Run a service with resource limits using systemd
systemd-run --uid=webuser --gid=webuser \
           --scope \
           -p MemoryMax=1G \
           -p CPUQuota=50% \
           -p IOWeight=100 \
           ./my-webserver

# Create a persistent slice for related services
cat > /etc/systemd/system/myapp.slice << EOF
[Unit]
Description=My Application Slice

[Slice]
MemoryMax=4G
CPUQuota=200%
EOF

# Reload systemd and start the slice
systemctl daemon-reload
systemctl start myapp.slice
```

### Container Resource Management

```bash
# Docker container with cgroup limits
docker run -d \
  --memory=512m \
  --cpus=0.5 \
  --pids-limit=100 \
  nginx

# Kubernetes pod with resource management
kubectl apply -f - << EOF
apiVersion: v1
kind: Pod
metadata:
  name: resource-demo
spec:
  containers:
  - name: app
    image: nginx
    resources:
      requests:
        memory: "256Mi"
        cpu: "250m"
      limits:
        memory: "512Mi"
        cpu: "500m"
EOF
```

## Best Practices

### 1. Design and Planning
- **Start simple:** Begin with basic resource limits and add complexity as needed
- **Understand workloads:** Profile applications before setting limits
- **Plan hierarchy:** Design cgroup hierarchy based on organizational structure
- **Document configuration:** Maintain clear documentation of cgroup policies

### 2. Resource Management
- **Set realistic limits:** Base limits on actual application requirements
- **Monitor regularly:** Continuously monitor resource usage and adjust as needed
- **Use both requests and limits:** In orchestration systems, set both resource requests and limits
- **Plan for peaks:** Account for resource spikes in limit settings

### 3. Security and Isolation
- **Combine with namespaces:** Use cgroups together with namespaces for complete isolation
- **Principle of least privilege:** Give processes only the resources they need
- **Regular auditing:** Review and audit cgroup configurations regularly
- **Monitor for abuse:** Watch for processes trying to exceed their limits

### 4. Operational Excellence
- **Use systemd integration:** Prefer systemd cgroup management over manual configuration
- **Automate management:** Use configuration management tools for cgroup setup
- **Test thoroughly:** Test cgroup configurations before production deployment
- **Plan for failures:** Have strategies for handling cgroup-related failures

### 5. Performance Optimization
- **Profile before limiting:** Understand baseline resource usage before applying limits
- **Gradual implementation:** Roll out cgroup limits gradually
- **Monitor impact:** Watch for performance impacts after implementing limits
- **Tune iteratively:** Adjust limits based on real-world performance data
