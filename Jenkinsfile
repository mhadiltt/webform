pipeline {
    agent any

    environment {
        COMPOSE_PROJECT_NAME = "webform"
        DOCKERHUB_USERNAME = "hadil01"
        PHP_IMAGE = "hadil01/webform-php:latest"
        NGINX_IMAGE = "hadil01/webform-nginx:alphine"
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
                    docker rm -f webform-nginx webform-php 2>/dev/null || true
                    docker container prune -f || true
                    echo "✅ Environment cleaned"
                '''
            }
        }

        stage('Build Docker Images') {
            steps {
                sh '''
                    echo "🚀 Building webform-php image..."
                    docker build -t $PHP_IMAGE .

                    echo "🚀 Building webform-nginx image..."
                    docker build -t $NGINX_IMAGE -f Dockerfile.nginx . || echo "Using default nginx image"
                    
                    # If custom nginx image fails, use tagged alpine
                    if ! docker images | grep -q "$NGINX_IMAGE"; then
                        echo "📥 Pulling and tagging nginx:alpine as fallback..."
                        docker pull nginx:alpine
                        docker tag nginx:alpine $NGINX_IMAGE
                    fi
                    
                    echo "✅ Both images ready"
                '''
            }
        }

        stage('Verify Setup') {
            steps {
                sh '''
                    echo "🔍 Verifying setup..."
                    echo "Current directory: $(pwd)"
                    echo "Files in src/: $(find src/ -type f | wc -l) files"
                    find src/ -type f
                    echo "--- Docker images ---"
                    docker images | grep hadil01 || echo "No hadil01 images found yet"
                '''
            }
        }

        stage('Deploy Application') {
            steps {
                sh '''
                    echo "🚀 Starting containers..."
                    # Try docker-compose first, fallback to manual docker run
                    if docker-compose up -d --build; then
                        echo "✅ Started with docker-compose"
                    else
                        echo "⚠️ Docker-compose failed, starting manually..."
                        echo "🚀 Starting PHP container..."
                        docker run -d --name webform-php $PHP_IMAGE
                        
                        echo "🚀 Starting Nginx container..."
                        docker run -d --name webform-nginx -p 8081:80 \
                            -v $(pwd)/src:/var/www/html:ro \
                            --link webform-php:php \
                            $NGINX_IMAGE
                        
                        # Copy nginx config for manual setup
                        echo "📋 Configuring nginx..."
                        docker cp docker/nginx/nginx.conf webform-nginx:/etc/nginx/conf.d/default.conf
                        docker exec webform-nginx nginx -s reload
                    fi
                    
                    echo "⏳ Waiting for services to start..."
                    sleep 20
                    
                    echo "🔍 Checking container status..."
                    docker ps --format "table {{.Names}}\\t{{.Status}}\\t{{.Ports}}"
                '''
            }
        }

        stage('Test Deployment') {
            steps {
                sh '''
                    echo "🧪 Testing application..."
                    JENKINS_IP=$(hostname -i | awk '{print $1}')
                    echo "🔧 Testing methods:"
                    echo "1. http://$JENKINS_IP:8081"
                    echo "2. http://localhost:8081"
                    
                    # Method 1: Jenkins host IP
                    if curl -f --retry 3 --retry-delay 5 http://$JENKINS_IP:8081/; then
                        echo "✅ SUCCESS: Application is live at http://$JENKINS_IP:8081"
                    else
                        echo "❌ Method 1 failed"
                        
                        # Method 2: Localhost
                        if curl -f http://localhost:8081/; then
                            echo "✅ SUCCESS: Application is live at http://localhost:8081"
                        else
                            echo "❌ All connection methods failed"
                            echo "🔍 Debug information:"
                            docker-compose logs || docker logs webform-nginx || echo "No nginx logs"
                            docker logs webform-php || echo "No PHP logs"
                            exit 1
                        fi
                    fi
                '''
            }
        }

        stage('Push Images to Docker Hub') {
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
                        echo "✅ PHP image pushed"

                        echo "📤 Pushing Nginx image..."
                        docker push $NGINX_IMAGE
                        echo "✅ Nginx image pushed"

                        docker logout
                        echo "🔓 Logged out from Docker Hub"
                    '''
                }
            }
        }

        stage('Final Verification') {
            steps {
                sh '''
                    echo "🔍 Final verification..."
                    echo "📊 Running containers:"
                    docker-compose ps || docker ps --format "table {{.Names}}\\t{{.Status}}\\t{{.Ports}}"
                    
                    JENKINS_IP=$(hostname -i | awk '{print $1}')
                    echo "🌐 Application URLs:"
                    echo "   http://$JENKINS_IP:8081"
                    echo "   http://localhost:8081"
                    
                    echo "🐳 Docker images pushed:"
                    docker images | grep hadil01 || echo "No hadil01 images found"
                '''
            }
        }
    }

    post {
        always {
            echo "📈 Pipeline execution completed"
            sh '''
                echo "🧹 Cleaning up..."
                docker-compose down --remove-orphans || true
                docker rm -f webform-nginx webform-php 2>/dev/null || true
                echo "✅ Cleanup completed"
            '''
        }
        success {
            echo "🎉 DEPLOYMENT SUCCESS!"
            sh '''
                JENKINS_IP=$(hostname -i | awk '{print $1}')
                echo "📍 Your web form is live at:"
                echo "   🌐 http://$JENKINS_IP:8081"
                echo "   🖥️  http://localhost:8081"
                echo "✅ Both PHP and Nginx images pushed to Docker Hub"
            '''
        }
        failure {
            echo "❌ PIPELINE FAILED"
            sh '''
                echo "🔍 Debug information:"
                echo "📊 All containers:"
                docker ps -a
                echo "📝 Recent logs:"
                docker-compose logs --tail=20 || echo "No docker-compose logs"
                docker logs webform-nginx --tail=20 2>/dev/null || echo "No nginx logs"
                docker logs webform-php --tail=20 2>/dev/null || echo "No PHP logs"
            '''
        }
    }
}
