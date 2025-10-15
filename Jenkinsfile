pipeline {
    agent any

    environment {
        COMPOSE_PROJECT_NAME = "webform"
        DOCKERHUB_USERNAME = "hadil01"
        DOCKERHUB_PASSWORD = credentials("mhadiltt@123") // Add Docker Hub password in Jenkins credentials
        PHP_IMAGE = "hadil01/webform-php:latest"
        NGINX_IMAGE = "hadil01/webform-nginx:latest"
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
                script {
                    sh '''
                        echo "🔨 Stopping and removing existing containers..."
                        docker-compose down --remove-orphans || true
                        docker container prune -f || true
                        docker image prune -f || true
                    '''
                }
            }
        }

        stage('Build Docker Images') {
            steps {
                script {
                    sh '''
                        echo "🚀 Building webform-php image..."
                        docker build -t $PHP_IMAGE -f Dockerfile .
                        
                        echo "🚀 Pulling and tagging nginx image..."
                        docker pull nginx:alpine
                        docker tag nginx:alpine $NGINX_IMAGE
                    '''
                }
            }
        }

        stage('Deploy with Docker Compose') {
            steps {
                script {
                    sh '''
                        echo "🚀 Starting containers with docker-compose..."
                        docker-compose up -d --build
                        
                        echo "⏳ Waiting for services to start..."
                        sleep 20
                        
                        echo "🧪 Testing application deployment..."
                        if curl -f http://localhost:8081/; then
                            echo "✅ SUCCESS: Application deployed at http://localhost:8081"
                        else
                            echo "❌ FAILED: Application not accessible"
                            exit 1
                        fi
                    '''
                }
            }
        }

        stage('Push Images to Docker Hub') {
            steps {
                script {
                    sh '''
                        echo "🔑 Logging in to Docker Hub..."
                        echo $DOCKERHUB_PASSWORD | docker login -u $DOCKERHUB_USERNAME --password-stdin
                        
                        echo "📤 Pushing webform-php image..."
                        docker push $PHP_IMAGE
                        
                        echo "📤 Pushing nginx image..."
                        docker push $NGINX_IMAGE
                        
                        docker logout
                    '''
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                    echo "🔍 Verifying deployment..."
                    docker-compose ps
                    echo "🌐 Application URL: http://localhost:8081"
                    echo "✅ CI/CD Pipeline Completed Successfully!"
                '''
            }
        }
    }

    post {
        always {
            echo "📈 Pipeline execution finished"
        }
        success {
            echo "🎉 DEPLOYMENT & PUSH SUCCESSFUL!"
            sh 'echo "📍 Your web form is live at: http://localhost:8081"'
        }
        failure {
            echo "💥 PIPELINE FAILED"
            sh 'docker-compose logs || true'
        }
    }
}
