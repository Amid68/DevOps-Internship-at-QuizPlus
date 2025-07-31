# Week 3 Report - July 20-26, 2025

## Introduction
This week I focused on API development and CI/CD pipeline implementation. I completed a FastAPI application while establishing a full Jenkins automation workflow for containerized application deployment.

## Tasks
**FastAPI Application Development:** Completed a process monitoring API that returns running processes with memory consumption data, implementing proper RESTful API design patterns and health check endpoints.

**OSI Network Model Study:** Studied the seven-layer network model fundamentals to understand how data flows through network protocols and infrastructure.

**Docker Layer Optimization:** Learned best practices for Docker image layers, focusing on instruction ordering, caching strategies, and build performance optimization techniques.

**Jenkins CI/CD Implementation:** Studied both scripted and declarative pipeline approaches, understanding the differences and use cases for each methodology.

**Pipeline Development:** Built a complete Jenkins scripted pipeline that automatically pulls code from GitHub, builds the FastAPI application using a Jenkins agent, runs tests, and pushes the final Docker image to DockerHub.

## Skills Developed
- FastAPI framework and RESTful API design
- Docker layer optimization techniques  
- Jenkins pipeline development (scripted approach)
- CI/CD workflow implementation
- GitHub integration with Jenkins
- DockerHub registry management

## Challenges Faced and Mitigation
Encountered issues connecting Jenkins to GitHub, resolved by generating a GitHub access token and configuring proper credentials in Jenkins. Also faced difficulties connecting the Jenkins agent to the controller, solved by installing the appropriate Jenkins plugin for agent management.

## Next Week Tasks
Prepare a comprehensive presentation on VPN (Virtual Private Network) technology, explaining how VPNs work, their protocols, and security implementations.
