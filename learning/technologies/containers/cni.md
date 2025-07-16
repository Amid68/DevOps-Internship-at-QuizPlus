## Container Network Interface (CNI)
The Container Network Interface (CNI) is a Cloud Native Computing Foundation (CNCF) project that provides a specification and libraries for configuring network interfaces in Linux containers. It primarily focuses on enabling network connectivity for containers and subsequently removing allocated resources when a container is deleted.

<span style="color:red">**Note:** Docker does not support CNI, instead it has its own Container Network Model (CNM). That's why you can't use cni plugins with docker</span>

##### This will not work:
```bash
docker run --network=cni-bridge nginx
```
##### But this will work:
```bash
docker run --network=none nginx
bridge add 2e34dcf34 /var/run/netns/2e34dcf34
```
This is a workaround to use CNI with Docker by creating a network namespace and adding a bridge to it. This is how Kubernetes uses CNI plugins to manage networking for containers.

### What is CNI?
- CNI is a framework for dynamically configuring network resources.
- It consists of Go-written libraries and specifications.
- A CNI plugin is responsible for inserting a network interface into a container's network namespace (e.g., one end of a virtual ethernet (veth) pair) and making necessary changes on the host (e.g., attaching the other end of the veth into a bridge).
- It then assigns an IP address to the interface and sets up routes, invoking an appropriate IP Address Management (IPAM) plugin. 

### Purpose and Importance of CNI
- CNI aims to standardize the interface between container runtimes and network plugins, enabling networking solutions to be integrated with a wide range of container orchestration systems and runtimes.
- It allows decoupling networking from the container runtime.
- CNI plays a crucial role in enabling communication between containers, whether they are on the same host or different hosts.
- It facilitates exposing services provided within containers to end-users or other systems.

### How CNI Works
- The container runtime (like Kubernetes' kubelet, Podman, CRI-O, etc) calls the CNI plugin with commands such as `ADD`, `DEL`, `CHECK`, or `VERSION`.
- The runtime provides related network configuration and container-specific data to the plugin, often via a JSON payload.
- The CNI plugin performs the required networking operations, such as creating network interfaces, assigning IP addresses, and setting up routes and reports the result back to the runtime.

### Types of CNI Plugins
1. **Main (Interface-creating) plugins:**
   - These plugins create network interfaces for containers.
   - Examples: `bridge`, `host-device`, `macvlan`, `ipvlan`, `ptp`, `vlan`.
2. **IP Address Management (IPAM) plugins:** 
   - These plugins manage IP address allocation for containers.
   - Examples: `host-local`, `static`, `dhcp`.
3. **Meta (Other) plugins:** 
    - These plugins perform additional tasks related to networking but do not create interfaces.
    - Examples: `tuning`, `portmap`, `bandwidth`, `sbr`, `firewall`.
