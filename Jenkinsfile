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
      image: fahadfadhi/jenkins-agent-docker:latest
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
        PHP_IMG = "hadil01/webform-php:${IMAGE_TAG}"
        NGINX_IMG = "hadil01/webform-nginx:${IMAGE_TAG}"
        DOCKERHUB_CREDS = 'dockerhub-pass'  // your DockerHub Jenkins credential
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Docker Login') {
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

        stage('Build & Push PHP Image') {
            steps {
                container('docker') {
                    sh '''
                        docker build -t $PHP_IMG -f Dockerfile .
                        docker push $PHP_IMG
                        docker tag $PHP_IMG hadil01/webform-php:latest
                        docker push hadil01/webform-php:latest
                    '''
                }
            }
        }

        stage('Build & Push NGINX Image') {
            steps {
                container('docker') {
                    sh '''
                        docker build -t $NGINX_IMG -f nginx/Dockerfile nginx
                        docker push $NGINX_IMG
                        docker tag $NGINX_IMG hadil01/webform-nginx:latest
                        docker push hadil01/webform-nginx:latest
                    '''
                }
            }
        }

        stage('ArgoCD Sync') {
            steps {
                container('docker') {
                    withCredentials([usernamePassword(credentialsId: 'argocd-jenkins-creds', usernameVariable: 'ARGOCD_USER', passwordVariable: 'ARGOCD_PASS')]) {
                        sh '''
                            apk add --no-cache curl
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
    }

    post {
        success { echo "✅ Build and deployment successful!" }
        failure { echo "❌ Build failed!" }
    }
}
