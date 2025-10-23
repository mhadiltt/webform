pipeline {
    agent {
        kubernetes {
            // jenkins inbound (jnlp) is required by the plugin; pipeline steps run in specific containers
            defaultContainer 'jnlp'
            yaml """
apiVersion: v1
kind: Pod
spec:
  # If your registry requires credentials create regcred and uncomment imagePullSecrets
  # imagePullSecrets:
  #   - name: regcred

  securityContext:
    runAsUser: 0

  containers:
    - name: kaniko
      # use the official kaniko executor image. You can mirror this to your local registry if needed.
      image: gcr.io/kaniko-project/executor:latest
      imagePullPolicy: IfNotPresent
      volumeMounts:
        - name: kaniko-secret
          mountPath: /kaniko/.docker
        - name: workspace-volume
          mountPath: /workspace

    - name: argocd
      # This must point to the image you will push to your local registry
      image: 192.168.68.136:32000/hadil01/argocd-cli:latest
      imagePullPolicy: IfNotPresent
      volumeMounts:
        - name: workspace-volume
          mountPath: /home/jenkins/agent

    - name: jnlp
      image: 192.168.68.136:32000/jenkins/inbound-agent:latest
      imagePullPolicy: IfNotPresent
      tty: true
      volumeMounts:
        - name: workspace-volume
          mountPath: /home/jenkins/agent

  volumes:
    - name: kaniko-secret
      secret:
        secretName: regcred-kaniko
    - name: workspace-volume
      emptyDir: {}
"""
        }
    }

    environment {
        IMAGE_TAG = "${env.BUILD_NUMBER}"
        PHP_IMAGE = "192.168.68.136:32000/hadil01/webform-php:${IMAGE_TAG}"
        NGINX_IMAGE = "192.168.68.136:32000/hadil01/webform-nginx:${IMAGE_TAG}"
        PHP_LATEST = "192.168.68.136:32000/hadil01/webform-php:latest"
        NGINX_LATEST = "192.168.68.136:32000/hadil01/webform-nginx:latest"
        DOCKERHUB_CREDS = 'dockerhub-pass'                // optional if you push to Docker Hub
        ARGOCD_CREDS = 'argocd-jenkins-creds'
        ARGOCD_SERVER = "argocd-server.argocd.svc.cluster.local:443"
        ARGOCD_APP_NAME = "webform"
    }

    stages {
        stage('Checkout') {
            steps { checkout scm }
        }

        stage('Build & Push PHP (kaniko)') {
            steps {
                container('kaniko') {
                    // kaniko expects a config at /kaniko/.docker/config.json
                    // it will read the Docker credentials from the mounted secret
                    sh '''
                      set -e
                      # copy repo into workspace path
                      cp -r /home/jenkins/agent/* /workspace || true
                      # build and push using kaniko
                      /kaniko/executor \
                        --context ${WORKSPACE} \
                        --dockerfile ${WORKSPACE}/Dockerfile \
                        --destination ${PHP_IMAGE} \
                        --destination ${PHP_LATEST} \
                        --verbosity info
                    '''
                }
            }
        }

        stage('Build & Push NGINX (kaniko)') {
            steps {
                container('kaniko') {
                    sh '''
                      set -e
                      # context points to nginx folder
                      /kaniko/executor \
                        --context ${WORKSPACE}/nginx \
                        --dockerfile ${WORKSPACE}/nginx/Dockerfile \
                        --destination ${NGINX_IMAGE} \
                        --destination ${NGINX_LATEST} \
                        --verbosity info
                    '''
                }
            }
        }

        stage('Argocd sync') {
            steps {
                container('argocd') {
                    withCredentials([usernamePassword(credentialsId: env.ARGOCD_CREDS, usernameVariable: 'ARGOCD_USER', passwordVariable: 'ARGOCD_PASS')]) {
                        sh '''
                          set -e
                          if ! command -v argocd >/dev/null 2>&1; then
                            echo "argocd CLI not found in the image"
                            exit 1
                          fi

                          argocd login $ARGOCD_SERVER --username $ARGOCD_USER --password $ARGOCD_PASS --insecure
                          argocd app set $ARGOCD_APP_NAME --helm-set phpImage=${PHP_IMAGE} --helm-set nginxImage=${NGINX_IMAGE}
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
        success { echo "✅ Pipeline finished" }
        failure { echo "❌ Pipeline failed" }
    }
}
