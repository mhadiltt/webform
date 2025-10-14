pipeline {
    agent any
    
    environment {
        APP_NAME = 'webform'
        DOCKER_REGISTRY = 'mhadiltt'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                sh 'echo "✅ Checked out code from GitHub"'
                sh 'ls -la'
            }
        }
        
        stage('Build Docker Images') {
            steps {
                script {
                    sh 'echo "🔨 Building Docker images..."'
                    sh 'docker build -t ${APP_NAME}-php:latest .'
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
                        
                        # Test 3: Form submission
                        RESPONSE=$(curl -s -X POST http://localhost:8081/process-form.php \
                          -d "name=PipelineTest&email=test@pipe.com&message=Test+from+pipeline")
                        if echo "$RESPONSE" | grep -q "Thank You"; then
                            echo "✅ Form submission works"
                        else
                            echo "❌ Form submission failed"
                            echo "Response: $RESPONSE"
                            exit 1
                        fi
                    '''
                }
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
            sh 'docker-compose down || true'
        }
        success {
            echo "✅ PIPELINE SUCCESS"
            sh '''
                echo "🎊 All stages completed successfully!"
                echo "📍 Your web form is live at: http://localhost:8081"
            '''
        }
        failure {
            echo "❌ PIPELINE FAILED"
            sh 'docker-compose logs || true'
        }
    }
}
