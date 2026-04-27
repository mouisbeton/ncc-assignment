pipeline {
    agent {
        docker {
            image 'node:18-bookworm'
            args '''-u root \
                    -e HOME=/tmp \
                    -e NPM_CONFIG_CACHE=/tmp/.npm \
                    -v /var/jenkins_home/tools:/var/jenkins_home/tools'''
        }
    }

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
        SCANNER_HOME  = tool 'sonarqube8.0'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Setup') {
            steps {
                sh '''
                    git config --global --add safe.directory ${WORKSPACE}
                    apt-get update -qq
                    apt-get install -y -qq default-jre-headless curl
                    node --version
                    npm --version
                '''
            }
        }

        stage('Build') {
            steps {
                dir('src') {
                    sh 'npm ci --prefer-offline'
                }
            }
        }

        stage('Test') {
            parallel {
                stage('Unit Test') {
                    steps {
                        dir('src') {
                            sh 'npm run test --if-present'
                        }
                    }
                }
                stage('Endpoint Smoke Test') {
                    steps {
                        sh '''
                            node src/server.js &
                            APP_PID=$!
                            trap "kill $APP_PID" EXIT
                            for i in 1 2 3 4 5; do
                              curl -fsS http://127.0.0.1:3000/health && break
                              sleep 1
                            done
                        '''
                    }
                }
            }
        }

        stage('Analyze') {
            steps {
                withSonarQubeEnv("${SONARQUBE_ENV}") {
                    sh """
                        ${SCANNER_HOME}/bin/sonar-scanner \
                          -Dsonar.projectKey=${PROJECT_KEY} \
                          -Dsonar.projectName=${PROJECT_NAME} \
                          -Dsonar.sources=src \
                          -Dsonar.exclusions=**/node_modules/**
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
        always {
            cleanWs(deleteDirs: true, disableDeferredWipeout: true)
        }
    }
}