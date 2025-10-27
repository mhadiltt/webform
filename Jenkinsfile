pipeline {
    agent {
        kubernetes {
            defaultContainer 'docker'
            yaml """
apiVersion: v1
kind: Pod
spec:
  securityContext:
    runAsUser: 0
  containers:
    - name: docker
      image: docker:24.0.6-dind
      securityContext:
        privileged: true
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

    - name: argocd
      image: hadil01/argocd-cli:latest
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
                withCredentials([usernamePassword(credentialsId: env.DOCKERHUB_CREDS, usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                        set -e
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                    '''
                }
            }
        }

        stage('🐘 Build & Push PHP Image') {
            steps {
                container('docker') {
                    sh '''
                        set -e
                        echo "🚀 Building PHP image: $PHP_IMAGE"
                        docker build -t $PHP_IMAGE -f Dockerfile .
                        docker push $PHP_IMAGE
                        echo "✅ Pushed PHP image: $PHP_IMAGE"
                    '''
                }
            }
        }

        stage('🌐 Build & Push NGINX Image') {
            steps {
                container('docker') {
                    sh '''
                        set -e
                        echo "🚀 Building NGINX image: $NGINX_IMAGE"
                        docker build -t $NGINX_IMAGE -f docker/nginx/Dockerfile .
                        docker push $NGINX_IMAGE
                        echo "✅ Pushed NGINX image: $NGINX_IMAGE"
                    '''
                }
            }
        }

        stage('🚀 Update ArgoCD Deployment') {
            steps {
                container('argocd') {
                    withCredentials([usernamePassword(credentialsId: env.ARGOCD_CREDS, usernameVariable: 'ARGOCD_USER', passwordVariable: 'ARGOCD_PASS')]) {
                        sh '''
                            set -e
                            echo "🔑 Logging into ArgoCD..."
                            argocd login $ARGOCD_SERVER --username $ARGOCD_USER --password $ARGOCD_PASS --insecure

                            echo "⚙️ Updating ArgoCD app with build-numbered images..."
                            argocd app set $ARGOCD_APP_NAME \
                                --helm-set phpImage=$PHP_IMAGE \
                                --helm-set nginxImage=$NGINX_IMAGE

				# 👇 Add this new section to update build number tags
                    argocd app set $ARGOCD_APP_NAME \
                        --helm-set hadil01/webform-php.tag=$IMAGE_TAG \
                        --helm-set hadil01/webform-nginx.tag=$IMAGE_TAG

                            echo "🔄 Syncing and waiting for ArgoCD deployment to update..."
                            argocd app sync $ARGOCD_APP_NAME --force
                            argocd app wait $ARGOCD_APP_NAME --health --timeout 300

                            echo "✅ Deployment successfully updated to build #$IMAGE_TAG!"
                        '''
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ New build successfully pushed and deployed with BUILD_NUMBER-tagged images!"
        }
        failure {
            echo "❌ Pipeline failed!"
        }
    }
}
