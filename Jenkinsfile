pipeline {
    agent any

    environment {
        DOCKERHUB_USERNAME = "hadil01"
        PHP_IMAGE = "hadil01/webform-php:latest"
        NGINX_IMAGE = "hadil01/webform-nginx:alpine"
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
                    echo "🧹 Cleaning containers..."
                    docker rm -f webform-nginx webform-php 2>/dev/null || true
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

        stage('Verify nginx Config') {
            steps {
                sh '''
                    echo "🔍 Verifying nginx configuration..."
                    echo "--- Current nginx config ---"
                    cat docker/nginx/nginx.conf
                    echo "--- Checking fastcgi_pass setting ---"
                    grep "fastcgi_pass" docker/nginx/nginx.conf || echo "fastcgi_pass not found"
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
                    sleep 10
                    
                    echo "🔍 Checking container networking..."
                    docker exec webform-nginx cat /etc/hosts | grep php || echo "PHP host entry not found"
                    
                    echo "📋 Copying nginx configuration..."
                    docker cp docker/nginx/nginx.conf webform-nginx:/etc/nginx/conf.d/default.conf
                    
                    echo "🔍 Verifying nginx config in container..."
                    docker exec webform-nginx grep "fastcgi_pass" /etc/nginx/conf.d/default.conf || echo "Cannot read nginx config"
                    
                    echo "🔄 Testing nginx configuration..."
                    docker exec webform-nginx nginx -t && echo "✅ Nginx config test passed" || echo "❌ Nginx config test failed"
                    
                    echo "🔄 Reloading nginx..."
                    docker exec webform-nginx nginx -s reload
                    
                    echo "⏳ Waiting for services to stabilize..."
                    sleep 10
                    
                    echo "🔍 Testing PHP-FPM connection..."
                    docker exec webform-nginx nc -z php 9000 && echo "✅ PHP-FPM connection OK" || echo "❌ PHP-FPM connection failed"
                '''
            }
        }

        stage('Test Deployment') {
            steps {
                sh '''
                    echo "🧪 Testing application..."
                    
                    echo "🔧 Method 1: Testing from inside nginx container..."
                    if docker exec webform-nginx curl -f http://localhost/; then
                        echo "✅ SUCCESS: Application works inside container"
                    else
                        echo "❌ Internal test failed"
                        echo "🔍 Checking nginx error logs..."
                        docker exec webform-nginx tail -20 /var/log/nginx/error.log || echo "No error log"
                        echo "🔍 Checking nginx access logs..."
                        docker exec webform-nginx tail -20 /var/log/nginx/access.log || echo "No access log"
                    fi
                    
                    echo "🔧 Method 2: Testing externally..."
                    if curl -f --retry 3 --retry-delay 2 http://localhost:8081/; then
                        echo "✅ SUCCESS: Application is live at http://localhost:8081"
                    else
                        echo "❌ External test failed"
                        echo "🔍 Final debug information:"
                        docker logs webform-nginx --tail=10
                        docker logs webform-php --tail=10
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
                        echo "📤 Pushing PHP image..."
                        docker push $PHP_IMAGE
                        echo "✅ PHP image pushed successfully"
                        docker logout
                    '''
                }
            }
        }

        stage('Final Verification') {
            steps {
                sh '''
                    echo "🎉 CI/CD Pipeline completed successfully!"
                    echo "📊 Running containers:"
                    docker ps --filter "name=webform" --format "table {{.Names}}\\t{{.Status}}\\t{{.Ports}}"
                    echo "🌐 Your web form is live at: http://localhost:8081"
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
    }
}
