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



FROM alpine:3.18

# Minimal image with argocd CLI
RUN apk add --no-cache ca-certificates curl \
 && curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64 \
 && chmod +x /usr/local/bin/argocd \
 && apk del curl

ENTRYPOINT ["/bin/sh", "-c"]
CMD ["while true; do sleep 3600; done"]
