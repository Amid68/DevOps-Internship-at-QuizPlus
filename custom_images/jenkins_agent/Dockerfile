FROM jenkins/inbound-agent:latest

USER root

# Install Docker inside the container
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    sudo

# Install Docker
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io

# Allow jenkins user to use Docker
RUN usermod -aG docker jenkins
RUN echo 'jenkins ALL=(ALL) NOPASSWD: /usr/bin/dockerd' >> /etc/sudoers

# Create startup script
RUN echo '#!/bin/bash\n\
# Start Docker daemon\n\
sudo dockerd --host=unix:///var/run/docker.sock --host=tcp://0.0.0.0:2375 &\n\
# Wait for Docker to start\n\
sleep 5\n\
# Start Jenkins agent\n\
exec /usr/local/bin/jenkins-agent "$@"' > /usr/local/bin/start-agent.sh

RUN chmod +x /usr/local/bin/start-agent.sh

USER jenkins
ENTRYPOINT ["/usr/local/bin/start-agent.sh"]
