# Linux Namespaces

## What are Linux Namespaces?

Linux Namespaces are a fundamental feature of the Linux kernel that enable the separation and isolation of system resources for processes. They achieve this by providing each process with its own "isolated view" of global system resources, making changes within one namespace invisible to processes outside of it.

Namespaces are a key building block for containerization technologies like Docker, LXC, rkt, and Podman, allowing for the creation of lightweight, self-contained environments.

## How Namespaces Work

Namespaces work by isolating specific aspects of the system, such as the process tree, network interfaces, and file systems, from the host system and other processes. Each namespace instance has its own set of resources, and processes running within it generally cannot access resources outside of it.

### Key Principles
- **Isolation:** Changes made to a global resource within one namespace are visible to other processes within that same namespace, but are invisible to processes in other namespaces
- **Process Membership:** Each process on a Linux system belongs to exactly one instance of each namespace type at any given moment
- **Symbolic Links:** These relationships are represented as symbolic links under the `/proc/<pid>/ns` directory for each process
- **Inheritance:** When a process forks, the child inherits the namespaces of the parent

## Why are Namespaces Important?

### Process Isolation
- Prevent processes from interfering with each other's resources
- Enhance system stability and security
- Enable safe execution of untrusted code

### Containerization
- Provide the core isolation required for creating lightweight, self-contained environments
- Make containers significantly lighter and more efficient than traditional virtual machines
- Enable sharing of the host OS kernel while maintaining isolation

### Resource Sharing Efficiency
- Allow multiple services to run on the same hardware without interference
- Lead to efficient resource utilization
- Enable higher density deployments

### Security
- Limit a process's view and access to system resources
- Reduce the "blast radius" of security incidents
- Prevent privilege escalation attacks
- Create sandbox environments for applications

## Types of Linux Namespaces

### 1. PID (Process ID) Namespace

**Purpose:** Isolates the process ID number space

**Functionality:**
- Allows processes to have their own independent process tree
- A process can perceive itself as PID 1 (the root process) within its namespace, regardless of its actual PID on the host system
- Processes in a nested PID namespace cannot see or interact with processes in a parent or higher namespace
- Enables nested process trees where a process can only see and interact with processes within the same namespace or nested below it

**Real-world Example:** Allows multiple containers running identical software to each have their own PID 1, preventing conflicts and enabling proper process management within each container.

### 2. Mount (MNT) Namespace

**Purpose:** Isolates filesystem mount points

**Functionality:**
- Provides a process with an isolated view of the filesystem
- Each mount namespace has its own list of mount points
- Processes in different mount namespaces cannot view each other's files unless specifically mounted from the underlying filesystem
- Similar to chroot but more flexible and secure
- Changes to mount points within one namespace are not visible in others

**Real-world Example:** Containers have their own root filesystem, often managed by the container runtime using technologies like OverlayFS, allowing each container to have a completely different view of the filesystem.

### 3. Network (NET) Namespace

**Purpose:** Isolates network interfaces and network-related resources

**Functionality:**
- Gives a process its own private network stack, including:
  - Network interfaces
  - IP addresses
  - Routing rules and tables
  - Socket listings
  - Firewall rules (iptables)
  - `/proc/net` directory
  - Port numbers
- A newly created network namespace contains only a loopback interface
- Different network namespaces can be connected using virtual Ethernet pairs (veth) and Linux bridges

**Real-world Example:** Allows multiple web servers to run on the same physical host, each listening on port 80 or 443, without conflicts, because each exists in its own network namespace with its own IP address.

### 4. User Namespace

**Purpose:** Isolates UID/GID (User ID/Group ID) number spaces

**Functionality:**
- Enables processes to have a different mapping of user and group IDs than the host system
- Most importantly, allows a process to be root inside its namespace without being root on the host system
- Can be nested, providing additional layers of security
- Plays a significant role in how capabilities are handled for processes within them
- Crucial feature for secure containerization

**Real-world Example:** Docker's userns-remap feature leverages user namespaces to remap container root users to unprivileged high-number UIDs on the host, preventing privilege escalation if a container is compromised.

### 5. Cgroup Namespace

**Purpose:** Isolates the cgroup root directory and virtual cgroup filesystem

**Functionality:**
- Provides an isolated view of control groups
- Prevents information leakage about the container framework to containerized applications
- Aids in container migration between hosts
- Manages resource conflicts and isolation

**Real-world Example:** Used in containerization to reduce "noisy neighbors" by ensuring one container's excessive resource usage doesn't degrade the performance of others on the same host, while hiding cgroup implementation details from the containerized applications.

### 6. IPC (Interprocess Communication) Namespace

**Purpose:** Isolates interprocess communication (IPC) resources

**Functionality:**
- Isolates System V IPC objects:
  - Message queues
  - Semaphores
  - Shared memory segments
- Isolates POSIX message queues
- Container runtimes typically enable this by default for isolation

**Real-world Example:** Important for applications like databases that rely on shared memory for communication, ensuring their IPC resources are isolated from other processes and preventing data leakage between applications.

### 7. UTS (Unix Time-sharing System) Namespace

**Purpose:** Isolates domain name and hostname

**Functionality:**
- Allows a process to have its own hostname and NIS domain name, independent of the host system
- Isolates two system identifiers: nodename (hostname) and domainname
- Enables each container to have its own unique hostname

**Real-world Example:** Why containers can have different hostnames than the underlying VMs or host system, making them appear as separate machines with distinct identities.

### 8. Time Namespace (Newer)

**Purpose:** Allows groups of processes to have different time settings than the underlying host

**Functionality:**
- Can be useful for testing, development, or preventing time jumps when a container is snapshotted and restored
- More recent addition to the namespace family
- Support is still being added to some container runtimes
- Enables time-based testing scenarios

**Real-world Example:** Useful for testing time-sensitive applications, simulating different time zones, or ensuring consistent time when migrating containers between hosts.

## Key Use Cases for Namespaces

### Containerization
- Act as a foundational building block for container technologies like Docker, LXC, rkt, and Podman
- Provide the necessary isolation and resource management for lightweight, self-contained environments
- Unlike virtual machines, containers share the host OS kernel, making them significantly lighter and faster

### Process Isolation
- Create isolated environments for processes
- Each environment has its own set of resources separate from other environments
- Prevent interference between different applications or services
- Vital for running untrusted code safely

### Virtual Environments
- Create virtual environments within a single Linux instance
- Similar to virtual machines but more lightweight
- Useful for testing, development, or running multiple applications on a single system

### Network Isolation
- Network namespaces specifically isolate the network stack
- Enable containers to have their own network interfaces and IP addresses
- Can restrict or control external network access

### Sandboxing
- Utilized by modern sandboxing tools like Flatpak, Snap, and Firejail
- Isolate applications from the host system
- Often used in combination with seccomp and capabilities for enhanced security

### Debugging and Troubleshooting
- Standard Linux tools can interact with and inspect namespaces
- Aid in troubleshooting and security investigations of container instances
- Enable forensic analysis of isolated environments

## Creating and Managing Namespaces

### Command-Line Tools

#### unshare Command
- Creates new namespaces or runs a command in a new namespace
- Moves the current process into a new set of namespaces

```bash
# Create a new PID namespace
unshare --pid --fork /bin/bash

# Create multiple namespaces
unshare --mount --uts --ipc --net --pid --fork /bin/bash

# Create user namespace with root mapping
unshare --user --map-root-user /bin/bash
```

#### nsenter Command
- Execute commands inside existing namespaces
- Doesn't rely on container-specific CLIs

```bash
# Enter all namespaces of a process
nsenter --target <PID> --all /bin/bash

# Enter specific namespaces
nsenter --target <PID> --mount --net /bin/bash
```

#### lsns Command
- List all available namespaces on the host

```bash
# List all namespaces
lsns

# List specific namespace type
lsns --type net
```

### System Calls

#### clone() System Call
- Used to create new namespaces by specifying particular flags
- Example flags:
  - `CLONE_NEWPID` for a new PID namespace
  - `CLONE_NEWNET` for a new network namespace
  - `CLONE_NEWUSER` for a new user namespace

#### setns() System Call
- Enables a calling process to join an existing namespace
- Typically uses a file descriptor that refers to one of the `/proc/<pid>/ns` files

```bash
# Example: Join the network namespace of another process
echo $$ > /proc/<target_pid>/ns/net
```

### Namespace Files
Each process has namespace information available in `/proc/<pid>/ns/`:

```bash
# View namespaces for a process
ls -la /proc/self/ns/
# Output shows symbolic links to namespace instances
# lrwxrwxrwx 1 user user 0 Jul 12 10:00 ipc -> 'ipc:[4026531839]'
# lrwxrwxrwx 1 user user 0 Jul 12 10:00 mnt -> 'mnt:[4026531840]'
# lrwxrwxrwx 1 user user 0 Jul 12 10:00 net -> 'net:[4026531841]'
```

## Namespaces and Security

### Security Benefits
- **Resource Isolation:** Restricts a contained process's view of the host
- **Privilege Separation:** User namespaces enable root-like access within containers without host root privileges
- **Attack Surface Reduction:** Limits what system resources an attacker can access
- **Blast Radius Limitation:** Contains security incidents within namespace boundaries

### Security Limitations
- **Not a Complete Sandbox:** Namespaces provide resource accounting and limited isolation but are not considered a full security boundary
- **Kernel API Access:** Processes still have access to Linux kernel APIs, which may not be fully hardened
- **Shared Kernel:** All processes share the same kernel, creating potential attack vectors

### Additional Security Layers
For strong security boundaries, additional layers are often recommended:
- **SELinux or AppArmor:** Mandatory access control systems
- **Seccomp:** System call filtering
- **Capabilities:** Fine-grained privilege control
- **Container Security Tools:** Runtime security monitoring

## Namespaces and Cgroups

Namespaces and Control Groups (cgroups) are the two core kernel primitives that make lightweight virtualization and containers possible. They are complementary technologies:

### Namespaces vs. Cgroups
| Aspect | Namespaces | Cgroups |
|--------|------------|---------|
| **Purpose** | Isolate what a process can see | Limit how much of a resource a process can use |
| **Function** | Provide isolated views of system resources | Control and limit resource consumption |
| **Resources** | Process trees, filesystems, network, users | CPU, memory, disk I/O, network bandwidth |
| **Security** | Process isolation and privilege separation | Resource management and "noisy neighbor" prevention |

### Working Together
- **Container Creation:** Both are used together to create fully isolated containers
- **Resource Management:** Namespaces provide the isolation, cgroups provide the resource limits
- **Security:** Combined approach provides both process isolation and resource control
- **Orchestration:** Container runtimes like Docker and containerd use both primitives

### Cgroup Namespaces
- Introduced to ensure containers have their own isolated view of cgroups
- Prevent information leakage about the container framework
- Simplify container migration between hosts
- Provide clean separation between container and host cgroup hierarchies

## Practical Examples

### Docker Container Analysis
```bash
# Find Docker container process
docker ps
PID=$(docker inspect --format '{{.State.Pid}}' <container_name>)

# Examine container namespaces
ls -la /proc/$PID/ns/

# Compare with host namespaces
ls -la /proc/self/ns/

# Enter container namespaces
nsenter --target $PID --all /bin/bash
```

### Manual Container Creation
```bash
# Create isolated environment manually
unshare --user --map-root-user \
        --mount --uts --ipc --net --pid --fork \
        /bin/bash

# Inside the new namespaces:
hostname container-test
mount -t proc proc /proc
ip link show  # Only loopback interface
ps aux        # Only processes in this namespace
```

### Debugging Container Issues
```bash
# List all namespaces
lsns

# Find containers by namespace
lsns --type pid --output NS,PID,COMMAND | grep docker

# Enter specific namespace for debugging
nsenter --target <PID> --net ip addr show
nsenter --target <PID> --mount ls /
```

## Best Practices

### Security Best Practices
1. **Use User Namespaces:** Always use user namespaces for containers running untrusted code
2. **Minimize Capabilities:** Combine with capability dropping for defense in depth
3. **Regular Auditing:** Monitor namespace usage and configurations
4. **Layered Security:** Don't rely solely on namespaces for security

### Operational Best Practices
1. **Resource Monitoring:** Combine with cgroups for complete resource management
2. **Proper Cleanup:** Ensure namespaces are properly cleaned up when processes exit
3. **Documentation:** Document namespace configurations for complex setups
4. **Testing:** Thoroughly test namespace configurations before production use

### Development Best Practices
1. **Container Standards:** Follow OCI (Open Container Initiative) standards
2. **Minimal Privilege:** Use the minimum required namespaces for your use case
3. **Tool Integration:** Use established container runtimes rather than manual namespace management
4. **Monitoring:** Implement proper logging and monitoring for namespace-isolated processes
