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
      command: ["cat"]
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
      command: ["cat"]
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
        REGISTRY = "hadil01"
        IMAGE_PHP = "${REGISTRY}/webform-php"
        IMAGE_NGINX = "${REGISTRY}/webform-nginx"
        BUILD_TAG = "${env.BUILD_NUMBER}"
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
                    withCredentials([string(credentialsId: 'docker-pass', variable: 'DOCKER_PASS')]) {
                        sh '''
                            set -e
                            echo $DOCKER_PASS | docker login -u ${REGISTRY} --password-stdin
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
                        docker build -t ${IMAGE_PHP}:${BUILD_TAG} -f Dockerfile .
                        docker push ${IMAGE_PHP}:${BUILD_TAG}
                        docker tag ${IMAGE_PHP}:${BUILD_TAG} ${IMAGE_PHP}:latest
                        docker push ${IMAGE_PHP}:latest
                    '''
                }
            }
        }

        stage('🌐 Build & Push NGINX Image') {
            steps {
                container('builder') {
                    sh '''
                        set -e
                        docker build -t ${IMAGE_NGINX}:${BUILD_TAG} -f docker/nginx/Dockerfile .
                        docker push ${IMAGE_NGINX}:${BUILD_TAG}
                        docker tag ${IMAGE_NGINX}:${BUILD_TAG} ${IMAGE_NGINX}:latest
                        docker push ${IMAGE_NGINX}:latest
                    '''
                }
            }
        }

        stage('🚀 Deploy via ArgoCD') {
            steps {
                container('argocd') {
                    withCredentials([usernamePassword(credentialsId: 'argocd-login', usernameVariable: 'ARGO_USER', passwordVariable: 'ARGO_PASS')]) {
                        sh '''
                            set -e
                            argocd login argocd-server.argocd.svc.cluster.local:443 \
                                --username $ARGO_USER \
                                --password $ARGO_PASS \
                                --insecure
                            argocd app sync webform
                        '''
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline executed successfully. Build Tag: ${BUILD_TAG}"
        }
        failure {
            echo "❌ Pipeline Failed. Check logs above."
        }
    }
}
