## Container Runtime
A container runtime is a software program designed to unpack a container image and translate that into a running process on a computer. It operates at the operating system level, providing an execution environment for processes in an isolated manner.

### Function and Responsibilities of Container Runtime
- **Container Execution**: Runtimes execute containers and manage their full lifecycle, from creation to termination. This includes monitoring container health and restarting them if they fail, as well as cleaning up resources once tasks are complete.
- **Interaction with the Host OS**: Runtimes use specific features of the Linux kernel, such as namespaces and control groups (cgroups), to isolate and manage resources for container workloads. This ensures that processes inside containers cannot disrupt the host system or other containers, creating a secure environment.
- **Resource Allocation and Management**: They allocate and regulate CPU, memory, and I/O for each container, preventing any single container from monopolizing resources.

### How Container Runtimes Work
The interoperability and consistent operation of container runtimes are largely due to Open Container Initiative (OCI) standards, which were launced in 2015 by Docker and other industry leaders, and are backed by the Linux Foundation. OCI defines standards for continaer formats and runtimes based on three key specifications:
1. **Image Content**: defines what a container image includes, such as application code, dependencies, libraries, and configurations.
2. **Image Retrieval**: specifies protocols for runtimes to fetch container images from registries or repos.
3. **Image Execution**: details how container images are unpacked, layered, mounted, and executed efficiently on any OCI-complaint platform.

The basic process flow for a runtime based on OCI standards involves:
1. Recieving a request to create a container instance with an image location and unique identifier.
2. Reading and verifying the container image's configuration.
3. Mounting the container's root filesystem and applying namespaces for isolation.
4. Enforcing resource limits using cgroups.
5. Issuing a start command to launch the main process within the container's isolated environment.
6. Issuing a stop command to shut down the instance once finished.
7. Deleting the container instance, which removes all references and cleans up the filesystem.

