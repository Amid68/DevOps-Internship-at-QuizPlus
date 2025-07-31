# Week 2 Report - July 13-19, 2025

## Introduction
This week I focused on Linux system services and containerization fundamentals. I implemented an automated system monitoring solution using systemd while expanding my understanding of the container ecosystem.

## Tasks
**Container Technology Study:** I spent significant time learning container fundamentals including Container Network Interface (CNI), Container Storage Interface (CSI), and various container runtimes like containerd and runc. Studied Docker architecture extensively, focusing on image layering concepts and optimization best practices that improve build performance and caching efficiency.

**SystemD Service Implementation:** Built an automated daily email reporting system using systemd service and timer units. The service collects system metrics including CPU usage, memory consumption, disk utilization, and uptime, then emails a formatted report to my trainer every day at 1:00 PM using Gmail SMTP integration with proper authentication.

**Docker Image Optimization:** Completed practical exercises with Docker layers, discovering how instruction ordering affects build cache efficiency and learning firsthand how poor layer structure can slow development workflows.

**API Development:** Introduction to FastAPI framework and RESTful API design patterns. I built a simple FastAPI application that returns current running processes on the server along with their memory consumption

## Skills Developed
- systemd service management
- secure email automation
- container runtime architecture
- Docker optimization techniques
- Linux system monitoring
- API development with FastAPI

## Challenges Faced and Mitigation
Had trouble understanding some of the complex concepts from documentation alone. Supplemented my learning by taking online courses and using AI tools to generate practical exercises on these topics, which I then solved step by step. This hands-on approach with AI-generated scenarios helped me understand the concepts much better than just reading articles and documentation.

## Next Week Tasks
Probably deeper study of container orchestration and Kubernetes fundamentals.
