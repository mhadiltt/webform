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
            }
        }

        stage('🧹 Clean Environment') {
            steps {
                sh 'docker rm -f webform-nginx webform-php 2>/dev/null || true'
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
                    echo "Starting PHP container..."
                    docker run -d --name webform-php -v $(pwd)/src:/var/www/html $PHP_IMAGE
                    echo "Starting Nginx container..."
                    docker run -d --name webform-nginx -p 8081:80 -v $(pwd)/src:/var/www/html:ro --link webform-php:php nginx:alpine
                    echo "Waiting for containers to start..."
                    sleep 10
                    echo "Configuring Nginx..."
                    docker cp docker/nginx/nginx.conf webform-nginx:/etc/nginx/conf.d/default.conf
                    docker exec webform-nginx nginx -s reload
                    sleep 5
                '''
            }
        }

        stage('🧪 Test Deployment') {
            steps {
                sh '''
                    echo "Testing application..."
                    if docker exec webform-nginx curl -f http://localhost/; then
                        echo "✅ Application works inside container"
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
