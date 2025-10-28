pipeline {
    agent {
        kubernetes {
            defaultContainer 'docker'
            yaml """
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: jenkins
  securityContext:
    runAsUser: 0
  containers:
    - name: docker
      image: docker:24.0.6
      command:
        - cat
      tty: true
      volumeMounts:
        - name: docker-socket
          mountPath: /var/run/docker.sock
        - name: workspace-volume
          mountPath: /home/jenkins/agent
          readOnly: false

    - name: dind
      image: docker:24.0.6-dind
      securityContext:
        privileged: true
      args:
        - --host=tcp://0.0.0.0:2375
      env:
        - name: DOCKER_TLS_CERTDIR
          value: ""
      volumeMounts:
        - name: docker-graph-storage
          mountPath: /var/lib/docker
        - name: docker-socket
          mountPath: /var/run
          
    - name: argocd
      image: hadil01/argocd-cli:latest
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
    - name: docker-graph-storage
      emptyDir: {}
    - name: docker-socket
      emptyDir: {}
    - name: workspace-volume
      emptyDir: {}
"""
        }
    }

    environment {
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        PHP_IMAGE_REPO = "hadil01/webform-php"
        NGINX_IMAGE_REPO = "hadil01/webform-nginx"
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
                            set -e
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
                        set -e
                        docker build -t $PHP_IMAGE_REPO:$IMAGE_TAG -f Dockerfile .
                        docker push $PHP_IMAGE_REPO:$IMAGE_TAG
                    '''
                }
            }
        }

        stage('🌐 Build & Push NGINX Image') {
            steps {
                container('docker') {
                    sh '''
                        set -e
                        docker build -t $NGINX_IMAGE_REPO:$IMAGE_TAG -f docker/nginx/Dockerfile .
                        docker push $NGINX_IMAGE_REPO:$IMAGE_TAG
                    '''
                }
            }
        }

        stage('🚀 ArgoCD Sync') {
            steps {
                container('argocd') {
                    withCredentials([usernamePassword(credentialsId: env.ARGOCD_CREDS, usernameVariable: 'ARGOCD_USER', passwordVariable: 'ARGOCD_PASS')]) {
                        sh '''
                            set -e
                            echo "🔑 Logging into ArgoCD..."
                            argocd login $ARGOCD_SERVER --username $ARGOCD_USER --password $ARGOCD_PASS --insecure

                            echo "🧩 Updating Helm values..."
                            argocd app set $ARGOCD_APP_NAME \
                                --helm-set php.image.repository=$PHP_IMAGE_REPO \
                                --helm-set php.image.tag=$IMAGE_TAG \
                                --helm-set nginx.image.repository=$NGINX_IMAGE_REPO \
                                --helm-set nginx.image.tag=$IMAGE_TAG

                            echo "🚀 Syncing ArgoCD Application..."
                            argocd app sync $ARGOCD_APP_NAME
                        '''
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ Build & Deployment Successful!"
        }
        failure {
            echo "❌ Pipeline Failed!"
        }
    }
}
