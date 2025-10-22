pipeline {
    agent any

    environment {
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        PHP_IMAGE = "hadil01/webform-php:${IMAGE_TAG}"
        NGINX_IMAGE = "hadil01/webform-nginx:${IMAGE_TAG}"
        DOCKERHUB_CREDS = 'dockerhub-pass'
        ARGOCD_CREDS = 'argocd-jenkins-creds'
        ARGOCD_SERVER = "argocd-server.argocd.svc.cluster.local:443"
        ARGOCD_APP_NAME = "webform"
    }

    stages {

        stage('📥 Checkout Code') {
            steps {
                git credentialsId: 'github-creds', url: 'https://github.com/mhadiltt/webform.git', branch: 'main'
            }
        }

        stage('Docker Login') {
            steps {
                container('jnlp') { // Using the default 'jnlp' container
                    withCredentials([usernamePassword(credentialsId: env.DOCKERHUB_CREDS, usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh 'echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin'
                    }
                }
            }
        }

        stage('Build & Push PHP Image') {
            steps {
                container('jnlp') {
                    sh '''
                        docker build -t $PHP_IMAGE -f Dockerfile .
                        docker push $PHP_IMAGE
                        docker tag $PHP_IMAGE hadil01/webform-php:latest
                        docker push hadil01/webform-php:latest
                    '''
                }
            }
        }

        stage('Build & Push NGINX Image') {
            steps {
                container('jnlp') {
                    sh '''
                        docker build -t $NGINX_IMAGE -f nginx/Dockerfile nginx
                        docker push $NGINX_IMAGE
                        docker tag $NGINX_IMAGE hadil01/webform-nginx:latest
                        docker push hadil01/webform-nginx:latest
                    '''
                }
            }
        }

        stage('ArgoCD Sync') {
            steps {
                container('jnlp') {
                    withCredentials([usernamePassword(credentialsId: env.ARGOCD_CREDS, usernameVariable: 'ARGOCD_USER', passwordVariable: 'ARGOCD_PASS')]) {
                        sh '''
                            apt-get update -y && apt-get install -y curl
                            curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
                            chmod +x /usr/local/bin/argocd
                            argocd login $ARGOCD_SERVER --username $ARGOCD_USER --password $ARGOCD_PASS --insecure
                            argocd app set $ARGOCD_APP_NAME --helm-set phpImage=$PHP_IMAGE --helm-set nginxImage=$NGINX_IMAGE

                            # Retry sync up to 5 times
                            n=0
                            until [ "$n" -ge 5 ]
                            do
                              argocd app sync $ARGOCD_APP_NAME && break
                              echo "Sync failed, retrying..."
                              n=$((n+1))
                              sleep 10
                            done
                        '''
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ Build & deployment successful!"
        }
        failure {
            echo "❌ Pipeline failed!"
        }
    }
}
