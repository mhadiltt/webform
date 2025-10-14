# Web Form Application

A PHP web form with Nginx, containerized with Docker and automated with Jenkins CI/CD.

## 🚀 Features

- Contact form with validation
- Dockerized with Nginx + PHP-FPM
- Jenkins CI/CD pipeline
- Automated testing and deployment

## 📦 CI/CD Pipeline

![Jenkins Build Status](http://localhost:8080/job/webform-pipeline/badge/icon)

## 🛠️ Local Development

```bash
# Clone repository
git clone https://github.com/mhadiltt/webform.git

# Start application
docker-compose up -d

# Access application
open http://localhost:8081
