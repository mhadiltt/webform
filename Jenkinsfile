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
                    echo "--- src/ directory contents ---"
                    ls -la src/
                    echo "--- File count in src/: $(find src/ -type f | wc -l)"
                    echo "--- nginx config ---"
                    cat docker/nginx/nginx.conf
                '''
            }
        }

        stage('Deploy Application') {
            steps {
                sh '''
                    echo "🚀 Starting PHP container..."
                    # Use absolute path for volume mount
                    docker run -d --name webform-php -v /var/jenkins_home/workspace/webform-pipeline/src:/var/www/html $PHP_IMAGE
                    
                    echo "🚀 Starting Nginx container..."
                    # Use absolute path for volume mount
                    docker run -d --name webform-nginx -p 8081:80 \
                        -v /var/jenkins_home/workspace/webform-pipeline/src:/var/www/html:ro \
                        --link webform-php:php \
                        nginx:alpine
                    
                    echo "⏳ Waiting for containers to start..."
                    sleep 5
                    
                    echo "📋 Copying nginx configuration..."
                    docker cp docker/nginx/nginx.conf webform-nginx:/etc/nginx/conf.d/default.conf
                    
                    echo "🔄 Reloading nginx configuration..."
                    docker exec webform-nginx nginx -s reload
                    echo "✅ Nginx configured successfully"
                    
                    echo "⏳ Waiting for services to stabilize..."
                    sleep 10
                '''
            }
        }

        stage('Debug Containers') {
            steps {
                sh '''
                    echo "🔍 Debugging container setup..."
                    echo "📊 Running containers:"
                    docker ps --format "table {{.Names}}\\t{{.Status}}\\t{{.Ports}}"
                    
                    echo "📁 Checking PHP container files:"
                    docker exec webform-php ls -la /var/www/html/ || echo "Cannot access PHP files"
                    docker exec webform-php find /var/www/html/ -type f || echo "No files found in PHP container"
                    
                    echo "📁 Checking Nginx container files:"
                    docker exec webform-nginx ls -la /var/www/html/ || echo "Cannot access Nginx files"
                    docker exec webform-nginx find /var/www/html/ -type f || echo "No files found in Nginx container"
                    
                    echo "🔧 Testing PHP-FPM connection:"
                    docker exec webform-nginx nc -z php 9000 && echo "✅ PHP-FPM connection OK" || echo "❌ PHP-FPM connection failed"
                    
                    echo "🌐 Testing from inside nginx container:"
                    docker exec webform-nginx curl -f http://localhost/ || echo "Internal test failed - checking error"
                    docker exec webform-nginx curl -v http://localhost/ 2>&1 | head -20 || echo "Detailed curl failed"
                '''
            }
        }

        stage('Test Deployment') {
            steps {
                sh '''
                    echo "🧪 Testing application externally..."
                    JENKINS_IP=$(hostname -i | awk '{print $1}')
                    echo "🔧 Testing on: http://$JENKINS_IP:8081"
                    
                    # Try multiple connection methods
                    echo "🔧 Method 1: Direct connection..."
                    if curl -f --retry 2 --retry-delay 3 http://$JENKINS_IP:8081/; then
                        echo "✅ SUCCESS: Application is live at http://$JENKINS_IP:8081"
                    else
                        echo "❌ Method 1 failed"
                        
                        # Method 2: Try container IP
                        echo "🔧 Method 2: Container IP..."
                        NGINX_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' webform-nginx)
                        if [ -n "$NGINX_IP" ] && curl -f http://$NGINX_IP/; then
                            echo "✅ SUCCESS: Application is live via container IP: http://$NGINX_IP"
                        else
                            echo "❌ FAILED: Application not accessible via any method"
                            echo "🔍 Checking nginx error logs:"
                            docker exec webform-nginx cat /var/log/nginx/error.log 2>/dev/null || echo "No error log available"
                            exit 1
                        fi
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
    }

    post {
        always {
            echo "📈 Pipeline execution completed"
            sh '''
                echo "🧹 Cleaning up containers..."
                docker rm -f webform-nginx webform-php 2>/dev/null || true
            '''
        }
    }
}
