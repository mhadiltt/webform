pipeline {
    agent any

    environment {
        DOCKERHUB_USERNAME = "hadil01"
        PHP_IMAGE = "hadil01/webform-php:${env.BUILD_NUMBER}"
        NGINX_IMAGE = "hadil01/webform-nginx:${env.BUILD_NUMBER}"
    }

    stages {
        stage('📥 Checkout Code') {
            steps {
                checkout scm
                sh '''
                    echo "Ensuring latest code..."
                    git pull origin main
                    echo "✅ Latest code: $(git log -1 --oneline)"
                '''
            }
        }

        stage('🧹 Clean Environment') {
            steps {
                sh '''
                    echo "Cleaning up..."
                    docker-compose down || true
                    docker rm -f webform-nginx webform-php 2>/dev/null || true
                '''
            }
        }

        stage('🏗️ Build Images') {
            steps {
                sh '''
                    echo "Building PHP image..."
                    docker build -t $PHP_IMAGE .
                    echo "Pulling Nginx image..."
                    docker pull nginx:alpine
                '''
            }
        }

        stage('🚀 Deploy Application') {
            steps {
                sh '''
                    echo "Starting services with Docker Compose..."
                    docker-compose up -d webform-php webform-nginx
                    echo "Waiting for services to start..."
                    sleep 10
                '''
            }
        }

        stage('🧪 Test Deployment') {
            steps {
                sh '''
                    echo "Testing application..."
                    if curl -f http://localhost:8081/; then
                        echo "✅ Application is accessible"
                    else
                        echo "❌ Application failed"
                        exit 1
                    fi
                '''
            }
        }

        stage('📤 Push Images') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-pass',
                    usernameVariable: 'DOCKERHUB_USER',
                    passwordVariable: 'DOCKERHUB_PASS'
                )]) {
                    sh '''
                        echo "Logging in to Docker Hub..."
                        echo $DOCKERHUB_PASS | docker login -u $DOCKERHUB_USER --password-stdin
                        echo "Pushing PHP image..."
                        docker push $PHP_IMAGE
                        echo "Tagging and pushing Nginx image..."
                        docker tag nginx:alpine $NGINX_IMAGE
                        docker push $NGINX_IMAGE
                        docker logout
                        echo "Logged out from Docker Hub"
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "🎉 DEPLOYMENT SUCCESS!"
            echo "📍 Your web form is live at: http://localhost:8081"
            echo "✅ Images pushed to Docker Hub with tag: ${env.BUILD_NUMBER}"
        }
        failure {
            echo "❌ PIPELINE FAILED"
            sh 'docker ps -a --filter "name=webform" || echo "No webform containers found"'
        }
    }
}
