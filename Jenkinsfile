pipeline {
    agent any

    environment {
        DOCKERHUB_USERNAME = "hadil01"
        PHP_IMAGE = "hadil01/webform-php:latest"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                sh 'echo "✅ Code checked out from GitHub"'
            }
        }

        stage('Clean Environment') {
            steps {
                sh '''
                    echo "🧹 Cleaning existing containers..."
                    docker rm -f webform-nginx webform-php 2>/dev/null || true
                    echo "✅ Environment cleaned"
                '''
            }
        }

        stage('Build PHP Image') {
            steps {
                sh '''
                    echo "🚀 Building PHP image..."
                    docker build -t $PHP_IMAGE .
                    echo "✅ PHP image built"
                '''
            }
        }

        stage('Deploy Application') {
            steps {
                sh '''
                    echo "🚀 Starting PHP container..."
                    docker run -d --name webform-php -v $(pwd)/src:/var/www/html $PHP_IMAGE
                    
                    echo "🚀 Starting Nginx container..."
                    # Start nginx without the problematic volume mount first
                    docker run -d --name webform-nginx -p 8081:80 \
                        -v $(pwd)/src:/var/www/html:ro \
                        --link webform-php:php \
                        nginx:alpine
                    
                    echo "📋 Copying nginx configuration..."
                    # Copy the nginx config into the running container
                    docker cp docker/nginx/nginx.conf webform-nginx:/etc/nginx/conf.d/default.conf
                    
                    echo "🔄 Reloading nginx configuration..."
                    docker exec webform-nginx nginx -s reload
                    
                    echo "⏳ Waiting for services to stabilize..."
                    sleep 25
                '''
            }
        }

        stage('Test Deployment') {
            steps {
                sh '''
                    echo "🧪 Testing application..."
                    if curl -f http://localhost:8081/; then
                        echo "✅ SUCCESS: Application is live at http://localhost:8081"
                    else
                        echo "❌ FAILED: Application not accessible"
                        echo "🔍 Checking container logs..."
                        docker logs webform-nginx
                        docker logs webform-php
                        exit 1
                    fi
                '''
            }
        }

        stage('Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-pass',
                    usernameVariable: 'DOCKERHUB_USER',
                    passwordVariable: 'DOCKERHUB_PASS'
                )]) {
                    sh '''
                        echo "🔑 Logging in to Docker Hub..."
                        echo $DOCKERHUB_PASS | docker login -u $DOCKERHUB_USER --password-stdin
                        echo "📤 Pushing PHP image to Docker Hub..."
                        docker push $PHP_IMAGE
                        echo "✅ Image pushed successfully"
                        docker logout
                    '''
                }
            }
        }

        stage('Final Verification') {
            steps {
                sh '''
                    echo "🔍 Final verification..."
                    echo "📊 Running containers:"
                    docker ps --format "table {{.Names}}\\t{{.Status}}\\t{{.Ports}}"
                    echo "🌐 Application URL: http://localhost:8081"
                    echo "🎉 CI/CD Pipeline completed successfully!"
                '''
            }
        }
    }

    post {
        always {
            echo "📈 Pipeline execution completed"
        }
        success {
            echo "✅ SUCCESS: Your web form is deployed and running!"
            sh 'echo "📍 Access: http://localhost:8081"'
        }
        failure {
            echo "❌ FAILURE: Pipeline execution failed"
            sh '''
                echo "🔍 Debug information:"
                docker ps -a
                docker-compose logs 2>/dev/null || echo "docker-compose not available"
            '''
        }
    }
}
