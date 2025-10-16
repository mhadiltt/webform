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

        stage('Verify Files') {
            steps {
                sh '''
                    echo "🔍 Verifying file structure..."
                    echo "Current directory: $(pwd)"
                    echo "nginx.conf exists: $(test -f docker/nginx/nginx.conf && echo 'YES' || echo 'NO')"
                    echo "src directory exists: $(test -d src && echo 'YES' || echo 'NO')"
                    ls -la docker/nginx/
                    ls -la src/
                '''
            }
        }

        stage('Deploy Application') {
            steps {
                sh '''
                    echo "🚀 Starting PHP container..."
                    docker run -d --name webform-php -v $(pwd)/src:/var/www/html $PHP_IMAGE
                    
                    echo "🚀 Starting Nginx container..."
                    docker run -d --name webform-nginx -p 8081:80 \
                        -v $(pwd)/src:/var/www/html:ro \
                        --link webform-php:php \
                        nginx:alpine
                    
                    echo "⏳ Waiting for containers to start..."
                    sleep 5
                    
                    echo "📋 Copying nginx configuration..."
                    # Ensure we're copying the file, not directory
                    docker cp docker/nginx/nginx.conf webform-nginx:/etc/nginx/conf.d/default.conf
                    
                    echo "🔄 Reloading nginx configuration..."
                    docker exec webform-nginx nginx -s reload
                    
                    echo "⏳ Waiting for services to stabilize..."
                    sleep 10
                '''
            }
        }

        stage('Debug Setup') {
            steps {
                sh '''
                    echo "🔍 Debugging deployment..."
                    echo "📊 Running containers:"
                    docker ps --format "table {{.Names}}\\t{{.Status}}\\t{{.Ports}}"
                    
                    echo "📁 Checking nginx config in container:"
                    docker exec webform-nginx cat /etc/nginx/conf.d/default.conf || echo "❌ Config not found"
                    
                    echo "📁 Checking files in PHP container:"
                    docker exec webform-php ls -la /var/www/html/ || echo "❌ Cannot access PHP files"
                    
                    echo "📁 Checking files in Nginx container:"
                    docker exec webform-nginx ls -la /var/www/html/ || echo "❌ Cannot access Nginx files"
                    
                    echo "🌐 Testing from inside nginx container:"
                    docker exec webform-nginx curl -f http://localhost/ || echo "❌ Internal test failed"
                '''
            }
        }

        stage('Test Deployment') {
            steps {
                sh '''
                    echo "🧪 Testing application externally..."
                    # Get Jenkins host IP
                    JENKINS_IP=$(hostname -i | awk '{print $1}')
                    echo "🔧 Testing on IP: $JENKINS_IP:8081"
                    
                    # Test the application
                    if curl -f --retry 3 --retry-delay 2 http://$JENKINS_IP:8081/; then
                        echo "✅ SUCCESS: Application is live at http://$JENKINS_IP:8081"
                    else
                        echo "❌ FAILED: Application not accessible externally"
                        echo "🔍 Checking nginx logs:"
                        docker logs webform-nginx
                        echo "🔍 Checking PHP logs:"
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
                    
                    JENKINS_IP=$(hostname -i | awk '{print $1}')
                    echo "🌐 Application URL: http://$JENKINS_IP:8081"
                    echo "🎉 CI/CD Pipeline completed successfully!"
                '''
            }
        }
    }

    post {
        always {
            echo "📈 Pipeline execution completed"
            sh '''
                echo "🧹 Cleaning up containers..."
                docker rm -f webform-nginx webform-php 2>/dev/null || true
            '''
        }
        success {
            echo "✅ SUCCESS: Your web form is deployed and running!"
            sh '''
                JENKINS_IP=$(hostname -i | awk '{print $1}')
                echo "📍 Access: http://$JENKINS_IP:8081"
            '''
        }
        failure {
            echo "❌ FAILURE: Pipeline execution failed"
            sh '''
                echo "🔍 Debug information:"
                docker ps -a
                echo "📝 Nginx logs:"
                docker logs webform-nginx 2>/dev/null || echo "Nginx container not available"
                echo "📝 PHP logs:"
                docker logs webform-php 2>/dev/null || echo "PHP container not available"
            '''
        }
    }
}
