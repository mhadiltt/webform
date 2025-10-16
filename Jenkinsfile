pipeline {
    agent any

    environment {
        DOCKERHUB_USERNAME = "hadil01"
        PHP_IMAGE = "hadil01/webform-php:latest"
    }

    stages {
        stage('Checkout & Setup') {
            steps {
                checkout scm
                sh '''
                    echo "✅ Code checked out from GitHub"
                    echo "🔍 Verifying nginx config:"
                    grep "fastcgi_pass" docker/nginx/nginx.conf
                '''
            }
        }

        stage('Clean & Build') {
            steps {
                sh '''
                    echo "🧹 Cleaning containers..."
                    docker rm -f webform-nginx webform-php 2>/dev/null || true
                    
                    echo "🚀 Building PHP image..."
                    docker build -t $PHP_IMAGE .
                '''
            }
        }

        stage('Quick Deploy & Test') {
            steps {
                sh '''
                    echo "🚀 Starting containers..."
                    # Use volume mounts for reliable file sharing
                    docker run -d --name webform-php -v $(pwd)/src:/var/www/html $PHP_IMAGE
                    docker run -d --name webform-nginx -p 8081:80 \
                        -v $(pwd)/src:/var/www/html:ro \
                        --link webform-php:php \
                        nginx:alpine
                    
                    echo "⏳ Waiting 10 seconds..."
                    sleep 10
                    
                    echo "📋 Quick nginx setup..."
                    # Simple nginx config
                    docker exec webform-nginx sh -c 'cat > /etc/nginx/conf.d/default.conf << "NGINX_CONFIG"
server {
    listen 80;
    root /var/www/html;
    index index.php index.html;
    location / { try_files \\$uri \\$uri/ /index.php; }
    location ~ \\.php$ {
        fastcgi_pass php:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \\$document_root\\$fastcgi_script_name;
        include fastcgi_params;
    }
}
NGINX_CONFIG'
                    
                    docker exec webform-nginx nginx -s reload
                    sleep 5
                    
                    echo "🧪 Quick test..."
                    if curl -f --retry 2 http://localhost:8081/; then
                        echo "✅ SUCCESS: Application is live!"
                    else
                        echo "❌ Application failed - quick debug:"
                        docker exec webform-nginx ls -la /var/www/html/ 2>/dev/null || echo "Cannot check nginx files"
                        docker exec webform-php ls -la /var/www/html/ 2>/dev/null || echo "Cannot check PHP files"
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
                        echo "✅ Image pushed successfully"
                        docker logout
                    '''
                }
            }
        }

        stage('Final Check') {
            steps {
                sh '''
                    echo "🎉 Pipeline completed successfully!"
                    echo "🌐 Application URL: http://localhost:8081"
                    echo "🐳 Image pushed: $PHP_IMAGE"
                '''
            }
        }
    }

    post {
        always {
            sh '''
                echo "🧹 Final cleanup..."
                docker rm -f webform-nginx webform-php 2>/dev/null || true
            '''
        }
    }
}
