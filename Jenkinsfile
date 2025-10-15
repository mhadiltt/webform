pipeline {
    agent any
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                sh 'echo "✅ Code checked out from GitHub"'
                sh 'ls -la'
            }
        }
        
        stage('Build and Deploy') {
            steps {
                script {
                    sh 'echo "🔨 Stopping existing containers..."'
                    sh 'docker-compose down || true'
                    
                    sh 'echo "🚀 Building and starting new containers..."'
                    sh 'docker-compose up -d --build'
                    
                    sh 'echo "⏳ Waiting for services to start..."'
                    sleep 20
                    
                    sh '''
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
        
        stage('Verify Deployment') {
            steps {
                sh '''
                    echo "🔍 Verifying deployment..."
                    echo "📊 Container status:"
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
            echo "🎉 DEPLOYMENT SUCCESSFUL!"
            sh 'echo "📍 Your web form is live at: http://localhost:8081"'
        }
        failure {
            echo "💥 DEPLOYMENT FAILED"
            sh 'docker-compose logs || true'
        }
    }
}
