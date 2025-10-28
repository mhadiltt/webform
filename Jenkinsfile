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
        IMAGE_TAG = "${env.BUILD_NUMBER}"                 // e.g., 278
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
                withCredentials([usernamePassword(credentialsId: env.DOCKERHUB_CREDS, usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                        set -e
                        echo "🔐 Logging into DockerHub..."
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                    '''
                }
            }
        }

        stage('🐘 Build & Push PHP Image') {
            steps {
                sh '''
                    set -e
                    echo "🐘 Building PHP Image: $PHP_IMAGE_REPO:$IMAGE_TAG ..."
                    docker build -t $PHP_IMAGE_REPO:$IMAGE_TAG -f Dockerfile .
                    docker push $PHP_IMAGE_REPO:$IMAGE_TAG
                '''
            }
        }

        stage('🌐 Build & Push NGINX Image') {
            steps {
                sh '''
                    set -e
                    echo "🌐 Building NGINX Image: $NGINX_IMAGE_REPO:$IMAGE_TAG ..."
                    docker build -t $NGINX_IMAGE_REPO:$IMAGE_TAG -f docker/nginx/Dockerfile .
                    docker push $NGINX_IMAGE_REPO:$IMAGE_TAG
                '''
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

                            echo "🧩 Updating Helm values with new image tags..."
                            argocd app set $ARGOCD_APP_NAME \
                                --helm-set php.image.tag=$IMAGE_TAG 
                                --helm-set nginx.image.tag=$IMAGE_TAG

                            echo "🔄 Syncing ArgoCD application..."
                            n=0
                            until [ "$n" -ge 5 ]
                            do
                              if argocd app sync $ARGOCD_APP_NAME --async --prune --force; then
                                echo "✅ ArgoCD sync started successfully!"
                                break
                              fi
                              echo "⚠️ Sync attempt $((n+1)) failed, retrying in 10s..."
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
            echo "✅ Build & ArgoCD deployment completed successfully!"
        }
        failure {
            echo "❌ Pipeline failed! Check logs for details."
        }
    }
}
