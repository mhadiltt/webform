pipeline {
    agent any

    environment {
        DOCKERHUB_USERNAME = "hadil01"
        PHP_IMAGE = "hadil01/webform-php:${env.BUILD_NUMBER}"
        NGINX_IMAGE = "hadil01/webform-nginx:${env.BUILD_NUMBER}"
        KUBE_NAMESPACE = "webform"
        HELM_CHART_PATH = "kubernetes/chart"
        ARGOCD_APP_NAME = "webform"
        ARGOCD_SERVER = "localhost:8082"  // your port-forwarded Argo CD server
        ARGOCD_AUTH_TOKEN = credentials('argocd-token')  // keep your Jenkins credential ID
    }

    stages {
        stage('📥 Checkout Code') {
            steps {
                checkout scm
                sh '''
                    echo "Ensuring latest code..."
                    git pull origin main
                    echo "✅ Latest code: $(git log -1 --oneline)"
                '''
            }
        }

        stage('🏗️ Build & Push Images') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-pass',
                    usernameVariable: 'DOCKERHUB_USER',
                    passwordVariable: 'DOCKERHUB_PASS'
                )]) {
                    sh '''
                        echo "Building PHP image..."
                        docker build -t $PHP_IMAGE .
                        echo "Logging in to Docker Hub..."
                        echo $DOCKERHUB_PASS | docker login -u $DOCKERHUB_USER --password-stdin
                        echo "Pushing PHP image..."
                        docker push $PHP_IMAGE
                        echo "Tagging and pushing Nginx image..."
                        docker tag nginx:alpine $NGINX_IMAGE
                        docker push $NGINX_IMAGE
                        docker logout
                        echo "✅ Images pushed to Docker Hub"
                    '''
                }
            }
        }

        stage('🚀 Deploy via Argo CD') {
            steps {
                sh '''
                    echo "Triggering Argo CD sync..."
                    argocd app sync $ARGOCD_APP_NAME --auth-token $ARGOCD_AUTH_TOKEN --server $ARGOCD_SERVER
                    argocd app wait $ARGOCD_APP_NAME --auth-token $ARGOCD_AUTH_TOKEN --server $ARGOCD_SERVER --timeout 300
                    echo "✅ Deployment completed via Argo CD"
                '''
            }
        }
    }

    post {
        success {
            echo "🎉 Deployment successful via Argo CD!"
            echo "✅ Docker images pushed: PHP=$PHP_IMAGE, Nginx=$NGINX_IMAGE"
        }
        failure {
            echo "❌ Pipeline failed!"
        }
    }
}
