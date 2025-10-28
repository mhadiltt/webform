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
    env:
      - name: DOCKER_TLS_CERTDIR
        value: ""
    volumeMounts:
      - name: docker-graph-storage
        mountPath: /var/lib/docker
      - name: workspace-volume
        mountPath: /home/jenkins/agent
  - name: argocd
    image: hadil01/argocd-cli:latest
    command: ['cat']
    tty: true
    volumeMounts:
      - name: workspace-volume
        mountPath: /home/jenkins/agent
  volumes:
    - name: docker-graph-storage
      emptyDir: {}
    - name: workspace-volume
      emptyDir: {}
"""
        }
    }

    environment {
        REGISTRY = "docker.io"
        DOCKER_USER = "hadil01"
        PHP_IMAGE = "hadil01/webform-php"
        NGINX_IMAGE = "hadil01/webform-nginx"
        BUILD_TAG = "${BUILD_NUMBER}"
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
                    withCredentials([string(credentialsId: 'docker-pass', variable: 'DOCKER_PASS')]) {
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
                        set -e
                        docker build -t $PHP_IMAGE:$BUILD_TAG -f Dockerfile .
                        docker push $PHP_IMAGE:$BUILD_TAG
                    '''
                }
            }
        }

        stage('🧱 Build & Push NGINX Image') {
            steps {
                container('docker') {
                    sh '''
                        set -e
                        docker build -t $NGINX_IMAGE:$BUILD_TAG -f nginx/Dockerfile .
                        docker push $NGINX_IMAGE:$BUILD_TAG
                    '''
                }
            }
        }

        stage('📝 Update values.yaml') {
            steps {
                sh '''
                sed -i "s|buildTag:.*|buildTag: $BUILD_TAG|g" kubernetes/values.yaml
                '''
            }
        }

        stage('🚀 ArgoCD Sync') {
            steps {
                container('argocd') {
                    withCredentials([string(credentialsId: 'argocd-pass', variable: 'ARGO_PASS')]) {
                        sh '''
                            argocd login argocd-server.argocd.svc.cluster.local:443 \
                                --username admin --password $ARGO_PASS --insecure
                            argocd app sync webform
                        '''
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ Build ${BUILD_NUMBER} completed successfully!"
        }
        failure {
            echo "❌ Build ${BUILD_NUMBER} failed!"
        }
    }
}
