pipeline {
    agent any

    environment {
        COMPOSE_PROJECT_NAME = "webform"
        DOCKERHUB_USERNAME = "hadil01"
        PHP_IMAGE = "hadil01/webform-php:latest"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                sh 'echo "✅ Code checked out from GitHub"'
                sh 'ls -la'
            }
        }

        stage('Stop Webform Containers') {
            steps {
                sh '''
                    echo "🔨 Stopping only webform containers..."
                    # Stop only webform containers, not all containers
                    docker stop webform-nginx webform-php 2>/dev/null || true
                    docker rm webform-nginx webform-php 2>/dev/null || true
                    echo "✅ Webform containers stopped"
                '''
            }
        }

        stage('Build Docker Images') {
            steps {
                sh '''
                    echo "🚀 Building webform-php image..."
                    docker build -t $PHP_IMAGE .

                    echo "✅ Docker images built successfully"
                '''
            }
        }

        stage('Deploy with Docker Compose') {
            steps {
                sh '''
                    echo "🚀 Starting containers..."
                    docker-compose up -d --build
                    echo "⏳ Waiting for services to start..."
                    sleep 20

                    echo "🧪 Testing application..."
                    if curl -f http://localhost:8081/; then
                        echo "✅ Application is live at http://localhost:8081"
                    else
                        echo "❌ Application not accessible"
                        exit 1
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

                        echo "📤 Pushing webform-php image..."
                        docker push $PHP_IMAGE

                        echo "✅ Images pushed successfully"
                        docker logout
                    '''
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                    echo "🔍 Deployment verification..."
                    echo "📊 Running containers:"
                    docker-compose ps
                    echo "🌐 Application URL: http://localhost:8081"
                    echo "✅ CI/CD Pipeline completed successfully!"
                '''
            }
        }
    }

    post {
        always {
            echo "📈 Pipeline execution completed"
        }
        success {
            echo "🎉 SUCCESS: Deployment completed!"
            sh 'echo "📍 Your web form is live at: http://localhost:8081"'
        }
        failure {
            echo "❌ FAILED: Pipeline execution failed"
            sh 'docker-compose logs || true'
        }
    }
}
