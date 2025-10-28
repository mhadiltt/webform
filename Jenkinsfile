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
      imagePullPolicy: IfNotPresent
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
      imagePullPolicy: IfNotPresent
      volumeMounts:
        - name: workspace-volume
          mountPath: /home/jenkins/agent

    - name: jnlp
      image: jenkins/inbound-agent:latest
      imagePullPolicy: IfNotPresent
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
                sh '''
                    set -e
                    docker build -t $PHP_IMAGE -f Dockerfile .
                    docker push $PHP_IMAGE
                    docker tag $PHP_IMAGE hadil01/webform-php:latest
                    docker push hadil01/webform-php:latest
                '''
            }
        }

        stage('🌐 Build & Push NGINX Image') {
            steps {
                sh '''
                    set -e
                    docker build -t $NGINX_IMAGE -f docker/nginx/Dockerfile .
                    docker push $NGINX_IMAGE
                    docker tag $NGINX_IMAGE hadil01/webform-nginx:latest
                    docker push hadil01/webform-nginx:latest
                '''
            }
        }

        stage('🚀 ArgoCD Sync') {
            steps {
                container('argocd') {
                    withCredentials([usernamePassword(credentialsId: env.ARGOCD_CREDS, usernameVariable: 'ARGOCD_USER', passwordVariable: 'ARGOCD_PASS')]) {
                        sh '''
                            set -e
                            argocd login $ARGOCD_SERVER --username $ARGOCD_USER --password $ARGOCD_PASS --insecure
                            
                            # Update image tags in Helm via ArgoCD
                            argocd app set $ARGOCD_APP_NAME \
                                --helm-set php.image.repository=hadil01/webform-php \
                                --helm-set php.image.tag=$IMAGE_TAG \
                                --helm-set nginx.image.repository=hadil01/webform-nginx \
                                --helm-set nginx.image.tag=$IMAGE_TAG
                            
                            # Sync deployment
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
