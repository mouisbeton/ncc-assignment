pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '20'))
    }

    triggers {
        githubPush()
    }

    parameters {
        booleanParam(name: 'RUN_DEPLOY', defaultValue: false, description: 'Deploy with docker compose after quality gate')
    }

    environment {
        SONARQUBE_ENV = 'sonarserver'
        PROJECT_KEY   = 'ncc-assignment-js'
        PROJECT_NAME  = 'ncc-assignment-js'
        NPM_CONFIG_CACHE = "${WORKSPACE}/.npm"
        HOST_WORKSPACE = "/var/lib/docker/volumes/jenkins-data/_data/workspace/${JOB_NAME}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Debug Workspace') {
            steps {
                sh '''
                    pwd
                    ls -la
                    ls -la src || true
                    find . -maxdepth 2 -type f | sort
                '''
            }
        }

        stage('Setup') {
            steps {
                sh '''
                    git config --global --add safe.directory ${WORKSPACE}
                    export DOCKER_HOST=unix:///var/run/docker.sock
                    unset DOCKER_TLS_VERIFY DOCKER_CERT_PATH
                    docker version
                '''
            }
        }

        stage('Build') {
            steps {
                sh '''
                    export DOCKER_HOST=unix:///var/run/docker.sock
                    unset DOCKER_TLS_VERIFY DOCKER_CERT_PATH
                    docker run --rm \
                      --user root \
                      -e NPM_CONFIG_CACHE=/tmp/.npm \
                      -v "$HOST_WORKSPACE":/workspace \
                      -w /workspace/src \
                      node:18-bookworm \
                      npm ci --no-audit --no-fund
                '''
            }
        }

        stage('Test') {
            parallel {
                stage('Unit Test') {
                    steps {
                        sh '''
                            export DOCKER_HOST=unix:///var/run/docker.sock
                            unset DOCKER_TLS_VERIFY DOCKER_CERT_PATH
                            docker run --rm \
                                                            --user root \
                                                            -v "$HOST_WORKSPACE":/workspace \
                              -w /workspace/src \
                              node:18-bookworm \
                              npm run test --if-present
                        '''
                    }
                }
                stage('Endpoint Smoke Test') {
                    steps {
                        sh '''
                            export DOCKER_HOST=unix:///var/run/docker.sock
                            unset DOCKER_TLS_VERIFY DOCKER_CERT_PATH
                            docker run --rm \
                              --user root \
                              -v "$HOST_WORKSPACE":/workspace \
                              -w /workspace/src \
                              node:18-bookworm \
                              sh -lc "node server.js & \
                                for i in 1 2 3 4 5; do \
                                  sleep 1; \
                                  curl -fsS http://127.0.0.1:3000/health && break; \
                                done; \
                                exit \$?"
                        '''
                    }
                }
            }
        }

        stage('Analyze') {
            steps {
                withSonarQubeEnv("${SONARQUBE_ENV}") {
                    sh """
                        export DOCKER_HOST=unix:///var/run/docker.sock
                        unset DOCKER_TLS_VERIFY DOCKER_CERT_PATH
                                                export SONAR_HOST_URL=http://127.0.0.1:9000
                        TOKEN_OPT=''
                        if [ -n "\${SONAR_AUTH_TOKEN:-}" ]; then
                          TOKEN_OPT="-Dsonar.token=\${SONAR_AUTH_TOKEN}"
                        fi
                        docker run --rm \
                            --network host \
                            -e SONAR_HOST_URL="\${SONAR_HOST_URL}" \
                            -v "\$HOST_WORKSPACE":/usr/src \
                          -w /usr/src \
                          sonarsource/sonar-scanner-cli:latest \
                          sonar-scanner \
                            -Dsonar.projectKey=${PROJECT_KEY} \
                            -Dsonar.projectName=${PROJECT_NAME} \
                            -Dsonar.sources=src \
                            -Dsonar.exclusions=**/node_modules/** \
                            \$TOKEN_OPT

                            mkdir -p "\$WORKSPACE/.scannerwork"
                                                docker run --rm \
                                                    -v "\$HOST_WORKSPACE":/usr/src \
                                                    alpine:3.20 \
                                                    sh -lc "test -f /usr/src/.scannerwork/report-task.txt"
                    """
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 20, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Deploy') {
            when {
                expression { return params.RUN_DEPLOY }
            }
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                        export DOCKER_HOST=unix:///var/run/docker.sock
                        unset DOCKER_TLS_VERIFY DOCKER_CERT_PATH
                        command -v docker >/dev/null 2>&1 || { echo "Docker CLI tidak tersedia di Jenkins agent"; exit 1; }
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker compose down || true
                        docker compose up -d --build
                    '''
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline sukses'
        }
        failure {
            echo 'Pipeline gagal'
        }
    }
}