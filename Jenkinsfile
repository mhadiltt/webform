pipeline {
    agent any

    environment {
        COMPOSE_PROJECT_NAME = "webform"
        DOCKERHUB_USERNAME = "hadil01"
        DOCKERHUB_PASSWORD = credentials("dockerhub-pass") // Add Docker Hub password in Jenkins
        PHP_IMAGE = "hadil01/webform-php:latest"
        NGINX_IMAGE = "hadil01/webform-nginx:latest"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                sh 'echo "✅ Code checked out from GitHub"'
                sh 'ls -la'
            }
        }

        stage('Stop Existing Containers') {
            steps {
                sh '''
                    echo "🔨 Stopping and removing existing containers..."
                    docker-compose down --remove-orphans || true
                    docker container prune -f || true
                    docker image prune -f || true
                '''
            }
        }

        stage('Build Docker Images') {
            steps {
                sh '''
                    echo "🚀 Building webform-php image..."
                    docker build -t $PHP_IMAGE -f Dockerfile .

                    echo "🚀 Pulling nginx image..."
                    docker pull nginx:alpine
                    docker tag nginx:alpine $NGINX_IMAGE
                '''
            }
        }

        stage('Deploy with Docker Compose') {
            steps {
                sh '''
                    echo "🚀 Starting containers..."
                    docker-compose up -d --build
                    echo "⏳ Waiting for services..."
                    sleep 20

                    echo "🧪 Testing application..."
                    if curl -f http://localhost:8081/; then
                        echo "✅ Application is live!"
                    else
                        echo "❌ Application not accessible"
                        exit 1
                    fi
                '''
            }
        }

        stage('Push Images to Docker Hub') {
            steps {
                sh '''
                    echo "🔑 Logging in to Docker Hub..."
                    echo $DOCKERHUB_PASSWORD | docker login -u $DOCKERHUB_USERNAME --password-stdin

                    echo "📤 Pushing webform-php..."
                    docker push $PHP_IMAGE

                    echo "📤 Pushing nginx image..."
                    docker push $NGINX_IMAGE

                    docker logout
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                    echo "🔍 Deployment verification..."
                    docker-compose ps
                    echo "🌐 Application URL: http://localhost:8081"
                '''
            }
        }
    }

    post {
        always {
            script {
                // Wrap in node block to avoid MissingContextVariableException
                node {
                    echo "📈 Pipeline finished"
                    sh 'docker-compose logs || true'
                }
            }
        }

        success {
            echo "🎉 Deployment & push SUCCESS!"
            echo "📍 Your web form is live at http://localhost:8081"
        }

        failure {
            script {
                node {
                    echo "💥 PIPELINE FAILED!"
                    sh 'docker-compose logs || true'
                }
            }
        }
    }
}
