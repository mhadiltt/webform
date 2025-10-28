pipeline {
    agent {
        kubernetes {
            defaultContainer 'builder'
            yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: jenkins-webform
spec:
  containers:
  - name: builder
    image: docker:24.0.6
    command:
    - cat
    tty: true
    securityContext:
      privileged: true
    volumeMounts:
    - name: docker-socket
      mountPath: /var/run/docker.sock
    - name: workspace-volume
      mountPath: /home/jenkins/agent

  - name: argocd
    image: hadil01/argocd-cli:latest
    command:
    - cat
    tty: true
    volumeMounts:
    - name: workspace-volume
      mountPath: /home/jenkins/agent

  volumes:
  - name: docker-socket
    hostPath:
      path: /var/run/docker.sock
  - name: workspace-volume
    emptyDir: {}
"""
        }
    }

    environment {
        DOCKER_USER = 'hadil01'
    }

    stages {
        stage('📥 Checkout Code') {
            steps {
                container('builder') {
                    checkout scm
                }
            }
        }

        stage('🔐 Docker Login') {
            steps {
                container('builder') {
                    withCredentials([string(credentialsId: 'docker-pass', variable: 'DOCKER_PASS')]) {
                        sh '''
                            set -e
                            echo "$DOCKER_PASS" | docker login -u $DOCKER_USER --password-stdin
                        '''
                    }
                }
            }
        }

        stage('🐘 Build & Push PHP Image') {
            steps {
                container('builder') {
                    sh '''
                        set -e
                        docker build -t $DOCKER_USER/webform-php:${BUILD_NUMBER} -f Dockerfile .
                        docker push $DOCKER_USER/webform-php:${BUILD_NUMBER}
                        docker tag $DOCKER_USER/webform-php:${BUILD_NUMBER} $DOCKER_USER/webform-php:latest
                        docker push $DOCKER_USER/webform-php:latest
                    '''
                }
            }
        }

        stage('🌐 Build & Push NGINX Image') {
            steps {
                container('builder') {
                    sh '''
                        set -e
                        docker build -t $DOCKER_USER/webform-nginx:${BUILD_NUMBER} -f docker/nginx/Dockerfile .
                        docker push $DOCKER_USER/webform-nginx:${BUILD_NUMBER}
                        docker tag $DOCKER_USER/webform-nginx:${BUILD_NUMBER} $DOCKER_USER/webform-nginx:latest
                        docker push $DOCKER_USER/webform-nginx:latest
                    '''
                }
            }
        }

        stage('🚀 Deploy via ArgoCD') {
            steps {
                container('argocd') {
                    withCredentials([usernamePassword(credentialsId: 'argocd-login', passwordVariable: 'ARGOCD_PASS', usernameVariable: 'ARGOCD_USER')]) {
                        sh '''
                            set -e
                            echo "🔗 Logging into ArgoCD..."
                            argocd login argocd-server.argocd.svc.cluster.local --username $ARGOCD_USER --password $ARGOCD_PASS --insecure

                            echo "🎯 Updating app with new image tags..."
                            argocd app set webform \
                              --helm-set php.image=$DOCKER_USER/webform-php:${BUILD_NUMBER} \
                              --helm-set nginx.image=$DOCKER_USER/webform-nginx:${BUILD_NUMBER}

                            echo "🚀 Syncing deployment..."
                            argocd app sync webform --force
                        '''
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ Deployment successful for build #${BUILD_NUMBER}"
        }
        failure {
            echo "❌ Pipeline Failed. Check logs above."
        }
    }
}
