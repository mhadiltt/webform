pipeline {
    agent {
        kubernetes {
            yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: jenkins-build
spec:
  containers:
  - name: docker
    image: docker:24.0.6
    command:
      - cat
    tty: true
    volumeMounts:
      - name: docker-socket
        mountPath: /var/run/docker.sock

  - name: dind
    image: docker:24.0.6-dind
    securityContext:
      privileged: true
    volumeMounts:
      - name: docker-socket
        mountPath: /var/run/docker.sock

  - name: argocd
    image: hadil01/argocd-cli:latest
    command:
      - cat
    tty: true

  volumes:
  - name: docker-socket
    emptyDir: {}
            """
        }
    }

    environment {
        DOCKER_HOST = "unix:///var/run/docker.sock"
        DOCKER_CLI_HINTS = "false"
        DOCKER_BUILDKIT = "1"
        REGISTRY = "hadil01"
    }

    stages {
        stage('📥 Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/mhadiltt/webform.git'
            }
        }

        stage('🔐 Docker Login') {
            steps {
                withCredentials([string(credentialsId: 'docker-pass', variable: 'DOCKER_PASS')]) {
                    sh '''
                        echo $DOCKER_PASS | docker login -u $REGISTRY --password-stdin
                    '''
                }
            }
        }

        stage('🐘 Build & Push PHP Image') {
            steps {
                container('docker') {
                    sh '''
                        BUILD_NUMBER=${BUILD_NUMBER}
                        docker build -t $REGISTRY/webform-php:${BUILD_NUMBER} -f Dockerfile .
                        docker push $REGISTRY/webform-php:${BUILD_NUMBER}
                    '''
                }
            }
        }

        stage('🌐 Build & Push NGINX Image') {
            steps {
                container('docker') {
                    sh '''
                        BUILD_NUMBER=${BUILD_NUMBER}
                        docker build -t $REGISTRY/webform-nginx:${BUILD_NUMBER} -f nginx/Dockerfile .
                        docker push $REGISTRY/webform-nginx:${BUILD_NUMBER}
                    '''
                }
            }
        }

        stage('🧾 Update values.yaml') {
            steps {
                container('docker') {
                    sh '''
                        sed -i "s|image: .*|image: $REGISTRY/webform-php:${BUILD_NUMBER}|" kubernetes/chart/values.yaml
                        sed -i "s|image: .*|image: $REGISTRY/webform-nginx:${BUILD_NUMBER}|" kubernetes/chart/values.yaml
                    '''
                }
            }
        }

        stage('🚀 ArgoCD Sync') {
            steps {
                container('argocd') {
                    sh '''
                        argocd login argocd-server.argocd.svc.cluster.local --username admin --password <your-argo-password> --insecure
                        argocd app sync webform
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline completed successfully!"
        }
        failure {
            echo "❌ Pipeline failed!"
        }
    }
}
