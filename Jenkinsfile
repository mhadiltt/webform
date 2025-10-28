pipeline {
    agent {
        kubernetes {
            defaultContainer 'builder'
            yaml """
apiVersion: v1
kind: Pod
spec:
  securityContext:
    runAsUser: 0
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

    - name: jnlp
      image: jenkins/inbound-agent:latest
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
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        PHP_IMAGE = "hadil01/webform-php:${IMAGE_TAG}"
        NGINX_IMAGE = "hadil01/webform-nginx:${IMAGE_TAG}"
        DOCKERHUB_CREDS = 'dockerhub-pass'
        ARGOCD_CREDS = 'argocd-jenkins-creds'
        ARGOCD_SERVER = "argocd-server.argocd.svc.cluster.local"
        ARGOCD_APP_NAME = "webform"
    }

    stages {
        stage('📥 Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('🔐 Docker Login') {
            steps {
                container('builder') {
                    withCredentials([usernamePassword(credentialsId: env.DOCKERHUB_CREDS, usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh '''
                            set -e
                            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
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
                        docker build -t $PHP_IMAGE -f Dockerfile .
                        docker push $PHP_IMAGE
                        docker tag $PHP_IMAGE hadil01/webform-php:latest
                        docker push hadil01/webform-php:latest
                    '''
                }
            }
        }

        stage('🌐 Build & Push NGINX Image') {
            steps {
                container('builder') {
                    sh '''
                        set -e
                        docker build -t $NGINX_IMAGE -f docker/nginx/Dockerfile .
                        docker push $NGINX_IMAGE
                        docker tag $NGINX_IMAGE hadil01/webform-nginx:latest
                        docker push hadil01/webform-nginx:latest
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
                              --helm-set php.image=hadil01/webform-php:${BUILD_NUMBER} \
                              --helm-set nginx.image=hadil01/webform-nginx:${BUILD_NUMBER}

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
            echo "✅ Build & Deployment Successful! (Tag: ${IMAGE_TAG})"
        }
        failure {
            echo "❌ Pipeline Failed. Check logs above."
        }
    }
}
