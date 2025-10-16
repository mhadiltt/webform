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
                    echo "Files in src/:"
                    find src/ -type f
                    echo "--- nginx config ---"
                    cat docker/nginx/nginx.conf
                '''
            }
        }

        stage('Deploy Application') {
            steps {
                sh '''
                    echo "🚀 Starting PHP container..."
                    # Start without volume mounts initially
                    docker run -d --name webform-php $PHP_IMAGE
                    
                    echo "🚀 Starting Nginx container..."
                    docker run -d --name webform-nginx -p 8081:80 \
                        --link webform-php:php \
                        nginx:alpine
                    
                    echo "⏳ Waiting for containers to start..."
                    sleep 5
                    
                    echo "📁 Copying application files to PHP container..."
                    docker cp src/. webform-php:/var/www/html/
                    docker exec webform-php chown -R www-data:www-data /var/www/html
                    docker exec webform-php chmod -R 755 /var/www/html
                    echo "✅ Files copied to PHP container"
                    
                    echo "📁 Copying application files to Nginx container..."
                    docker cp src/. webform-nginx:/var/www/html/
                    echo "✅ Files copied to Nginx container"
                    
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
                    docker exec webform-php ls -la /var/www/html/
                    echo "PHP files found:"
                    docker exec webform-php find /var/www/html/ -type f
                    
                    echo "📁 Checking Nginx container files:"
                    docker exec webform-nginx ls -la /var/www/html/
                    echo "Nginx files found:"
                    docker exec webform-nginx find /var/www/html/ -type f
                    
                    echo "🔧 Testing PHP-FPM connection:"
                    docker exec webform-nginx nc -z php 9000 && echo "✅ PHP-FPM connection OK" || echo "❌ PHP-FPM connection failed"
                    
                    echo "🌐 Testing from inside nginx container:"
                    if docker exec webform-nginx curl -f http://localhost/; then
                        echo "✅ Internal test passed"
                    else
                        echo "❌ Internal test failed"
                        echo "Checking nginx error log:"
                        docker exec webform-nginx cat /var/log/nginx/error.log 2>/dev/null || echo "No error log found"
                    fi
                '''
            }
        }

        stage('Test Deployment') {
            steps {
                sh '''
                    echo "🧪 Testing application externally..."
                    JENKINS_IP=$(hostname -i | awk '{print $1}')
                    echo "🔧 Testing on: http://$JENKINS_IP:8081"
                    
                    if curl -f --retry 3 --retry-delay 2 http://$JENKINS_IP:8081/; then
                        echo "✅ SUCCESS: Application is live at http://$JENKINS_IP:8081"
                    else
                        echo "❌ FAILED: Application not accessible"
                        echo "🔍 Debug information:"
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
                    echo "🎉 CI/CD Pipeline completed successfully!"
                    echo "📊 Final container status:"
                    docker ps --format "table {{.Names}}\\t{{.Status}}\\t{{.Ports}}"
                    
                    JENKINS_IP=$(hostname -i | awk '{print $1}')
                    echo "🌐 Your web form is live at: http://$JENKINS_IP:8081"
                    echo "💡 You can access it from your browser using the above URL"
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
            echo "✅ SUCCESS: CI/CD Pipeline completed successfully!"
        }
        failure {
            echo "❌ FAILURE: Pipeline execution failed"
            sh '''
                echo "🔍 Debug information:"
                docker ps -a
                docker logs webform-nginx 2>/dev/null || echo "Nginx container not available"
                docker logs webform-php 2>/dev/null || echo "PHP container not available"
            '''
        }
    }
}
