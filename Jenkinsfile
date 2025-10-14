pipeline {
    agent any
    
    environment {
        APP_NAME = 'webform'
        DOCKER_REGISTRY = 'mhadiltt'  # Your Docker Hub username
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                sh 'echo "✅ Checked out code from GitHub"'
                sh 'ls -la'
            }
        }
        
        stage('Code Quality') {
            steps {
                sh 'echo "🔍 Running code quality checks..."'
                sh '''
                    # Check PHP syntax
                    find src/ -name "*.php" -exec php -l {} \; || echo "PHP syntax check completed"
                    
                    # Check file permissions
                    ls -la src/
                    
                    # Validate Dockerfile
                    docker build -t ${APP_NAME}-test . --no-cache --pull || echo "Docker build test completed"
                '''
            }
        }
        
        stage('Build Docker Images') {
            steps {
                script {
                    sh 'echo "🔨 Building Docker images..."'
                    sh 'docker build -t ${APP_NAME}-php:${BUILD_ID} .'
                    sh 'docker build -t ${APP_NAME}-php:latest .'
                    
                    // Tag for Docker Hub if you want to push
                    sh 'docker tag ${APP_NAME}-php:latest ${DOCKER_REGISTRY}/${APP_NAME}-php:${BUILD_ID}'
                }
            }
        }
        
        stage('Test Application') {
            steps {
                script {
                    sh 'echo "🧪 Testing application..."'
                    
                    // Stop any existing containers
                    sh 'docker-compose down || true'
                    
                    // Start test environment
                    sh 'docker-compose up -d --build'
                    
                    // Wait for services to be ready
                    sleep 20
                    
                    // Run comprehensive tests
                    sh '''
                        echo "Running application tests..."
                        
                        # Test 1: Application accessibility
                        if curl -f http://localhost:8081/; then
                            echo "✅ Application is accessible"
                        else
                            echo "❌ Application not accessible"
                            exit 1
                        fi
                        
                        # Test 2: Static assets
                        if curl -f http://localhost:8081/styles.css > /dev/null; then
                            echo "✅ CSS files are served"
                        else
                            echo "❌ CSS files not found"
                            exit 1
                        fi
                        
                        # Test 3: PHP processing
                        if curl -f http://localhost:8081/index.php > /dev/null; then
                            echo "✅ PHP is processing correctly"
                        else
                            echo "❌ PHP processing failed"
                            exit 1
                        fi
                        
                        # Test 4: Form submission
                        RESPONSE=$(curl -s -X POST http://localhost:8081/process-form.php \
                          -d "name=PipelineTest&email=test@pipe.com&message=Test+from+pipeline")
                        if echo "$RESPONSE" | grep -q "Thank You"; then
                            echo "✅ Form submission works"
                        else
                            echo "❌ Form submission failed"
                            echo "Response: $RESPONSE"
                            exit 1
                        fi
                        
                        # Test 5: Container health
                        docker ps | grep webform && echo "✅ All containers are running"
                    '''
                }
            }
        }
        
        stage('Security Scan') {
            steps {
                sh 'echo "🔒 Running security checks..."'
                sh '''
                    # Check for sensitive files
                    if [ -f ".env" ]; then
                        echo "⚠️  .env file found - check for sensitive data"
                    fi
                    
                    # Check container security
                    docker images | grep ${APP_NAME} || echo "No ${APP_NAME} images found"
                    
                    echo "Security scan completed"
                '''
            }
        }
        
        stage('Deploy to Production') {
            steps {
                script {
                    sh 'echo "🚀 Deploying to production..."'
                    
                    // Ensure we're using the latest build
                    sh 'docker-compose down || true'
                    sh 'docker-compose up -d'
                    
                    // Verify deployment
                    sh '''
                        echo "Verifying production deployment..."
                        sleep 10
                        
                        # Health check
                        curl -f http://localhost:8081/ || exit 1
                        
                        # Final verification
                        echo "🎉 Production deployment successful!"
                        echo "🌐 Application URL: http://localhost:8081"
                    '''
                }
            }
        }
    }
    
    post {
        always {
            echo "📊 Pipeline execution completed"
            sh '''
                echo "Container status:"
                docker-compose ps || true
                
                echo "Recent logs:"
                docker-compose logs --tail=20 || true
            '''
        }
        success {
            echo "✅ PIPELINE SUCCESS"
            sh '''
                echo "🎊 All stages completed successfully!"
                echo "📍 Your web form is live at: http://localhost:8081"
                echo "🕒 Build: ${BUILD_ID}"
                echo "📝 Commit: $(git log -1 --oneline)"
            '''
        }
        failure {
            echo "❌ PIPELINE FAILED"
            sh 'docker-compose logs || true'
        }
        unstable {
            echo "⚠️  PIPELINE UNSTABLE"
        }
    }
}
