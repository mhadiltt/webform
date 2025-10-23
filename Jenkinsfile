pipeline {
    agent {
        kubernetes {
            defaultContainer 'docker'
            yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
    - name: docker
      image: docker:24.0.6-dind
      securityContext:
        privileged: true
      args: ["--host=tcp://0.0.0.0:2375"]
      env:
        - name: DOCKER_TLS_CERTDIR
          value: ""
      volumeMounts:
        - name: docker-graph-storage
          mountPath: /var/lib/docker
        - name: docker-socket
          mountPath: /var/run
        - name: workspace-volume
          mountPath: /home/jenkins/agent
          readOnly: false
    - name: jnlp
      image: jenkins/inbound-agent:latest
      tty: true
      volumeMounts:
        - name: workspace-volume
          mountPath: /home/jenkins/agent
        - name: docker-socket
          mountPath: /var/run
  volumes:
    - name: docker-socket
      emptyDir: {}
    - name: docker-graph-storage
      emptyDir: {}
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
        ARGOCD_SERVER = "argocd-server.argocd.svc.cluster.local:443"
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
                container('docker') {
                    withCredentials([usernamePassword(credentialsId: env.DOCKERHUB_CREDS, usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh '''
                            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        '''
                    }
                }
            }
        }

        stage('🐘 Build & Push PHP Image') {
            steps {
                container('docker') {
                    sh '''
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
                container('docker') {
                    sh '''
                        docker build -t $NGINX_IMAGE -f nginx/Dockerfile nginx
                        docker push $NGINX_IMAGE
                        docker tag $NGINX_IMAGE hadil01/webform-nginx:latest
                        docker push hadil01/webform-nginx:latest
                    '''
                }
            }
        }

        stage('🚀 ArgoCD Sync') {
            steps {
                container('docker') {
                    withCredentials([usernamePassword(credentialsId: env.ARGOCD_CREDS, usernameVariable: 'ARGOCD_USER', passwordVariable: 'ARGOCD_PASS')]) {
                        sh '''
                            # Install ArgoCD CLI inside container
                            apk add --no-cache curl
                            curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
                            chmod +x /usr/local/bin/argocd

                            # Login to ArgoCD
                            argocd login $ARGOCD_SERVER --username $ARGOCD_USER --password $ARGOCD_PASS --insecure

                            # Update Helm images
                            argocd app set $ARGOCD_APP_NAME --helm-set phpImage=$PHP_IMAGE --helm-set nginxImage=$NGINX_IMAGE

                            # Sync the app with retry logic
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
