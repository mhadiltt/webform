pipeline {
    agent any

    environment {
        DOCKERHUB_USERNAME = "hadil01"
        PHP_IMAGE = "hadil01/webform-php:${env.BUILD_NUMBER}"
        NGINX_IMAGE = "hadil01/webform-nginx:${env.BUILD_NUMBER}"
        KUBE_NAMESPACE = "webform"
        HELM_CHART_PATH = "kubernetes/chart"
        ARGOCD_APP_NAME = "webform"
        ARGOCD_SERVER = "argocd-server.argocd.svc.cluster.local:443"
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
                withCredentials([usernamePassword(
                    credentialsId: 'argocd-jenkins-creds',
                    usernameVariable: 'ARGOCD_USER',
                    passwordVariable: 'ARGOCD_PASS'
                )]) {
                    sh '''
                        echo "🔧 Installing ArgoCD CLI..."
                        apt-get update -y && apt-get install -y curl
                        curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
                        chmod +x /usr/local/bin/argocd

                        echo "🔐 Logging in to ArgoCD..."
                        argocd login $ARGOCD_SERVER \
                            --username $ARGOCD_USER \
                            --password $ARGOCD_PASS \
                            --insecure

                        echo "🚀 Syncing application in ArgoCD..."
                        n=0
                        until [ "$n" -ge 5 ]
                        do
                          argocd app sync $ARGOCD_APP_NAME && break
                          echo "Sync failed (maybe operation in progress), retrying in 10 seconds..."
                          n=$((n+1))
                          sleep 10
                        done

                        echo "✅ Deployment synced via ArgoCD!"
                    '''
                }
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
