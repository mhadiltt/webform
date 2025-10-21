pipeline {
    agent any

    environment {
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        PHP_IMG = "hadil01/webform-php:${IMAGE_TAG}"
        NGINX_IMG = "hadil01/webform-nginx:${IMAGE_TAG}"
        DOCKERHUB_CREDS = 'dockerhub-pass'
        ARGOCD_CREDS = 'argocd-jenkins-creds'
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Docker Login') {
            steps {
                withCredentials([usernamePassword(credentialsId: env.DOCKERHUB_CREDS, usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh 'echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin'
                }
            }
        }

        stage('Build & Push PHP Image') {
            steps {
                sh '''
                    docker build -t $PHP_IMG -f Dockerfile .
                    docker push $PHP_IMG
                    docker tag $PHP_IMG hadil01/webform-php:latest
                    docker push hadil01/webform-php:latest
                '''
            }
        }

        stage('Build & Push NGINX Image') {
            steps {
                sh '''
                    docker build -t $NGINX_IMG -f nginx/Dockerfile nginx
                    docker push $NGINX_IMG
                    docker tag $NGINX_IMG hadil01/webform-nginx:latest
                    docker push hadil01/webform-nginx:latest
                '''
            }
        }

        stage('ArgoCD Sync') {
            steps {
                withCredentials([usernamePassword(credentialsId: env.ARGOCD_CREDS, usernameVariable: 'ARGOCD_USER', passwordVariable: 'ARGOCD_PASS')]) {
                    sh '''
                        apt-get update -y && apt-get install -y curl
                        curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
                        chmod +x /usr/local/bin/argocd

                        argocd login argocd-server.argocd.svc.cluster.local:443 \
                            --username $ARGOCD_USER --password $ARGOCD_PASS --insecure

                        argocd app set webform --helm-set phpImage=$PHP_IMG --helm-set nginxImage=$NGINX_IMG

                        n=0
                        until [ "$n" -ge 5 ]
                        do
                            argocd app sync webform && break
                            echo "Sync failed, retrying..."
                            n=$((n+1))
                            sleep 10
                        done
                    '''
                }
            }
        }
    }

    post {
        success { echo "✅ Build & deployment successful!" }
        failure { echo "❌ Build failed!" }
    }
}
