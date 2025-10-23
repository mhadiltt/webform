pipeline {
    agent {
        kubernetes {
            // keep jnlp as the agent container name expected by the kubernetes plugin
            defaultContainer 'jnlp'
            yaml """
apiVersion: v1
kind: Pod
spec:
  # run as root so containers that need privileged access can start (adjust for your security policy)
  securityContext:
    runAsUser: 0
  containers:
    - name: docker
      image: docker:24.0.6-dind
      imagePullPolicy: IfNotPresent
      # DinD requires privileged mode — your cluster must allow privileged pods
      securityContext:
        privileged: true
      env:
        - name: DOCKER_TLS_CERTDIR
          value: ""
      # dockerd will create the socket in /var/run inside the pod; share that directory with other containers
      volumeMounts:
        - name: docker-graph-storage
          mountPath: /var/lib/docker
        - name: docker-socket
          mountPath: /var/run
        - name: workspace-volume
          mountPath: /home/jenkins/agent
          readOnly: false
    - name: jnlp
      # pin a stable inbound-agent version; avoid 'latest' to reduce surprises
      image: jenkins/inbound-agent:4.11-4
      imagePullPolicy: IfNotPresent
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
                // run docker cli inside the docker container (which runs dockerd)
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
                // we run the argocd CLI inside the docker container to reuse the same pod and shared network
                container('docker') {
                    withCredentials([usernamePassword(credentialsId: env.ARGOCD_CREDS, usernameVariable: 'ARGOCD_USER', passwordVariable: 'ARGOCD_PASS')]) {
                        sh '''
                            # install small deps and argocd CLI
                            # docker image is based on alpine; install curl
                            apk add --no-cache curl ca-certificates
                            curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
                            chmod +x /usr/local/bin/argocd

                            # login to argocd
                            argocd login $ARGOCD_SERVER --username $ARGOCD_USER --password $ARGOCD_PASS --insecure

                            # update helm values and sync
                            argocd app set $ARGOCD_APP_NAME --helm-set phpImage=$PHP_IMAGE --helm-set nginxImage=$NGINX_IMAGE

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
