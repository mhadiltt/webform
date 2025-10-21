# Dockerfile
FROM jenkins/jenkins:lts-jdk11

# Disable setup wizard
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"

# Switch to root to install dependencies
USER root

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install Kaniko executor
RUN mkdir -p /kaniko \
    && curl -sSL -o /kaniko/executor \
       https://github.com/GoogleContainerTools/kaniko/releases/latest/download/executor \
    && chmod +x /kaniko/executor

# Switch back to Jenkins user
USER jenkins

# Expose ports
EXPOSE 8080 50000

# Start Jenkins
CMD ["jenkins"]
