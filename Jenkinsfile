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
      - name: dockersock
        mountPath: /var/run/docker.sock
  - name: argocd
    image: argoproj/argocd-cli:v2.9.10
  volumes:
    - name: dockersock
      hostPath:
        path: /var/run/docker.sock
"""
        }
    }

    environment {
        REGISTRY = "hadil01"
        BUILD_TAG = "${BUILD_NUMBER}"
        NAMESPACE = "new"
        CHART_PATH = "./webform/kubernetes/chart"
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/mhadiltt/webform.git'
            }
        }

        stage('Build PHP Image') {
            steps {
                container('docker') {
                    sh '''
                    docker build -t $REGISTRY/webform-php:$BUILD_TAG -f php/Dockerfile .
                    docker push $REGISTRY/webform-php:$BUILD_TAG
                    '''
                }
            }
        }

        stage('Build NGINX Image') {
            steps {
                container('docker') {
                    sh '''
                    docker build -t $REGISTRY/webform-nginx:$BUILD_TAG -f nginx/Dockerfile .
                    docker push $REGISTRY/webform-nginx:$BUILD_TAG
                    '''
                }
            }
        }

        stage('Update values.yaml') {
            steps {
                sh '''
                sed -i "s|hadil01/webform-php:.*|hadil01/webform-php:$BUILD_TAG|g" $CHART_PATH/values.yaml
                sed -i "s|hadil01/webform-nginx:.*|hadil01/webform-nginx:$BUILD_TAG|g" $CHART_PATH/values.yaml
                '''
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                container('docker') {
                    sh '''
                    microk8s helm upgrade --install webform $CHART_PATH -n $NAMESPACE
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "✅ Build #${BUILD_NUMBER} and deployment successful!"
        }
        failure {
            echo "❌ Build #${BUILD_NUMBER} failed. Check logs for details."
        }
    }
}
