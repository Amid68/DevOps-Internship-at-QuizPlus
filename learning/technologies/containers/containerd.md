## Docker vs containerd

### What is Docker?
Docker is best understood as a container engine. It provides a comprehensive set of tools and services that make it easy for developers and system administrators to build, deploy, and run applications in containerized environments. The Docker Engine includes a command-line interface (CLI) and a daemon process (dockerd). From an end-user perspective, when you run `docker run`, you are interacting with Docker Engine. Docker also packages software into standardized units and facilitates their development, shipment, and deployment. It was instrumental in popularizing container technology.

### What is containerd?
Containerd is a high-level container runtime that originated from Docker itself. It functions as a daemon for both Linux and Windows. Its primary responsibility is to manage the complete lifecycle of containers on a host system, including:
- Image transfer and storage
- Container execution and supervision
- Low-level storage and network attachments
- Managing container health and restarting failed containers
- Cleaning up resources after rasks are completed

Containerd implements the Container Runtime Interface (CRI) specification, making it a popular choice for Kubernetes environments. It typically relies on a low-level runtime like `runc` to perform the actual process creation and interaction with Linux kernel features.

### Docker uses containerd
Initially, Docker was a monolithic project. Over time, its internal runtime was extracted and open-sourced as containerd. This modularization allowed Docker to run its "flavor" of containers in more environments, including Kubernetes, without needing the entire Docker daemon or CLI tool.

When you execute a Docker command to run a container, such as `docker run`, the Docker CLI interacts with the Docker daemon (dockerd). The `dockerd` daemon then communicates with containerd, which in turn uses a low-level runtime like `runc` to create and run the container process directly on the Linux kernel. So, containerd is a foundational component within the Docker stack.

### Docker and Kubernetes' Evolving Relationship
Originally, Kubernetes used Docker (Docker Engine) to run containers. However, Kubernetes evolved to be more container-agnostic and introduced the Container Runtime Interface (CRI). The CRI is an API that allows different container runtimes to be "plugged in" to Kubernetes.

Because Docker Engine did not directly implement CRI, Kubernetes used a component called `dockershim` to bridge this communication gap. However, as of Kubernetes 1.24, `dockershim` was deprecated and subsequently removed. This meant Kubernetes no longer directly supports Docker Engine as a container runtime.

Instead, Kubernetes now requires a CRI-compliant runtime like containerd or CRI-O. This transition did not mean Kubernetes stopped running Docker-formatted images. Both containerd and CRI-O are capable of running Docker-formatted and OCI-formatted images without needing the `docker` command or the Docker daemon. This shift promotes standardization and flexibility within the container ecosystem.

### Open Container Initiative (OCI) Standards
The interoperability between various container tools and runtimes is largely thanks to the Open Container Initiative (OCI), founded in 2015 by Docker and other industry leaders. OCI defines open standards for container formats and runtimes based on 3 key specifications:
- **Image Content**: what a container includes (application code, dependencies, libraries, configurations)
- **Image Retrieval**: protocols for runtimes to fetch images from registeries.
- **Image Execution**: how images are unpacked, layered, mounted, and executed.

Containerd and low-level runtimes like `runc` are OCI-compliant, ensuring that images built with one tool can be run by another that adheres to the standard.

### Summary
Docker provides the user-facing experience and higher-level management of containers and images, while containerd operates as a core, underlying component, specifically a high-level container runtime, responsible for the actual lifecycle management of containers on a host, often orchestrated by platforms like Kubernetes.
