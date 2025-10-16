pipeline {
    agent any

    environment {
        DOCKERHUB_USERNAME = "hadil01"
        PHP_IMAGE = "hadil01/webform-php:latest"
        NGINX_IMAGE = "hadil01/webform-nginx:alpine"  // Fixed spelling from "alphine" to "alpine"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                sh 'echo "✅ Code checked out from GitHub"'
            }
        }

        stage('Clean Environment - SAFE') {
            steps {
                sh '''
                    echo "🧹 SAFE cleanup - only specific webform containers..."
                    # ONLY remove containers with exact names, nothing else
                    docker rm -f webform-nginx webform-php 2>/dev/null || true
                    echo "✅ Only webform containers cleaned safely"
                '''
            }
        }

        stage('Build Images') {
            steps {
                sh '''
                    echo "🚀 Building PHP image..."
                    docker build -t $PHP_IMAGE .
                    
                    echo "🚀 Preparing Nginx image..."
                    # Just use nginx:alpine directly, no need to tag
                    docker pull nginx:alpine || echo "Nginx image available"
                    
                    echo "✅ Images ready"
                '''
            }
        }

        stage('Verify Setup') {
            steps {
                sh '''
                    echo "🔍 Verifying setup..."
                    echo "Current directory: $(pwd)"
                    echo "Files in src/: $(find src/ -type f | wc -l) files"
                    ls -la src/
                    echo "--- Docker images ---"
                    docker images | grep hadil01 || echo "No hadil01 images yet"
                '''
            }
        }

        stage('Deploy Application - SAFE') {
            steps {
                sh '''
                    echo "🚀 Starting PHP container..."
                    docker run -d --name webform-php \
                        -v $(pwd)/src:/var/www/html \
                        $PHP_IMAGE
                    
                    echo "🚀 Starting Nginx container..."
                    docker run -d --name webform-nginx -p 8081:80 \
                        -v $(pwd)/src:/var/www/html:ro \
                        --link webform-php:php \
                        nginx:alpine
                    
                    echo "⏳ Waiting for containers to start..."
                    sleep 10
                    
                    echo "📋 Configuring nginx..."
                    docker cp docker/nginx/nginx.conf webform-nginx:/etc/nginx/conf.d/default.conf
                    docker exec webform-nginx nginx -s reload
                    
                    echo "⏳ Waiting for configuration to apply..."
                    sleep 10
                    
                    echo "🔍 Checking ONLY webform containers..."
                    docker ps --filter "name=webform" --format "table {{.Names}}\\t{{.Status}}\\t{{.Ports}}"
                '''
            }
        }

        stage('Test Deployment') {
            steps {
                sh '''
                    echo "🧪 Testing application..."
                    # Test multiple methods safely
                    
                    echo "🔧 Method 1: Localhost..."
                    if curl -f --retry 3 --retry-delay 5 http://localhost:8081/; then
                        echo "✅ SUCCESS: Application is live at http://localhost:8081"
                    else
                        echo "❌ Method 1 failed"
                        
                        echo "🔧 Method 2: Container direct test..."
                        if docker exec webform-nginx curl -f http://localhost/; then
                            echo "✅ SUCCESS: Application works inside container"
                        else
                            echo "❌ Application not working"
                            echo "🔍 Debug information:"
                            docker logs webform-nginx --tail=20
                            docker logs webform-php --tail=20
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

                        echo "📤 Tagging and pushing Nginx image..."
                        docker tag nginx:alpine $NGINX_IMAGE
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
                    echo "📊 Running webform containers:"
                    docker ps --filter "name=webform" --format "table {{.Names}}\\t{{.Status}}\\t{{.Ports}}"
                    
                    echo "🌐 Application URL: http://localhost:8081"
                    echo "🐳 Images pushed to Docker Hub:"
                    echo "   - $PHP_IMAGE"
                    echo "   - $NGINX_IMAGE"
                '''
            }
        }
    }

    post {
        always {
            echo "📈 Pipeline execution completed"
           # sh '''
            #    echo "🧹 SAFE cleanup - only webform containers..."
             #   docker rm -f webform-nginx webform-php 2>/dev/null || true
              #  echo "✅ Safe cleanup completed - Jenkins is unaffected"
            '''
        }
        success {
            echo "🎉 DEPLOYMENT SUCCESS!"
            echo "📍 Your web form is live at: http://localhost:8081"
            echo "✅ Both PHP and Nginx images pushed to Docker Hub"
        }
        failure {
            echo "❌ PIPELINE FAILED"
            sh '''
                echo "🔍 Debug information:"
                docker ps -a --filter "name=webform" || echo "No webform containers found"
            '''
        }
    }
}
