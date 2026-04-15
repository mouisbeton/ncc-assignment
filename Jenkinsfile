pipeline {
    agent {
        docker {
            image 'golang:1.23-bookworm'
            args '''-u root \
                    -e HOME=/tmp \
                    -e GOCACHE=/tmp/go-cache \
                    -e GOPATH=/tmp/go \
                    --network jenkins_jenkins-network \
                    -v /var/jenkins_home/tools:/var/jenkins_home/tools'''
        }
    }

    environment {
        SONARQUBE_ENV = 'sonarserver'
        PROJECT_KEY   = 'go-project'
        PROJECT_NAME  = 'go-project'
        SCANNER_HOME  = '/tmp/sonar-scanner'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'jenkins-demo',
                    url: 'https://github.com/mouisbeton/ncc-assignment',
                    credentialsId: 'mouisbeton'
            }
        }

        stage('Setup') {
            steps {
                sh '''
                    git config --global --add safe.directory ${WORKSPACE}
                    apt-get update -qq
                    apt-get install -y -qq default-jre-headless wget unzip
                    wget -q https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip -O /tmp/sonar-scanner.zip
                    unzip -q /tmp/sonar-scanner.zip -d /tmp
                    mv /tmp/sonar-scanner-5.0.1.3006-linux /tmp/sonar-scanner
                    go version
                    go mod download
                '''
            }
        }

        stage('Build') {
            steps {
                sh 'go build -v ./...'
            }
        }

        stage('Test') {
            steps {
                sh 'go test ./... -v -coverprofile=coverage.out'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv("${SONARQUBE_ENV}") {
                    sh """
                        ${SCANNER_HOME}/bin/sonar-scanner \
                          -Dsonar.projectKey=${PROJECT_KEY} \
                          -Dsonar.projectName=${PROJECT_NAME} \
                          -Dsonar.sources=. \
                          -Dsonar.go.coverage.reportPaths=coverage.out
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
