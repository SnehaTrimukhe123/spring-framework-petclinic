pipeline {
    agent any
    tools {
        maven 'Maven'  // Make sure Maven is configured in Jenkins
    }
    environment {
        SONAR_HOST_URL = 'http://18.191.157.196:9000'
        SONAR_AUTH_TOKEN = credentials('my-token')  // Reference your SonarQube token in Jenkins credentials
        AWS_ECR_REPO_URI = '481665085317.dkr.ecr.us-east-2.amazonaws.com/petclinic'  // Replace with your ECR repository URI
        AWS_DEFAULT_REGION = 'us-east-2'  // Replace with your AWS region
    }
    stages {
        stage('Checkout Code') {
            steps {
                git 'https://github.com/SnehaTrimukhe123/spring-framework-petclinic.git'
            }
        }

        stage('Unit Test') {
            steps {
                script {
                    sh 'mvn clean test'
                }
            }
            post {
                always {
                    junit '**/target/surefire-reports/*.xml'  // Capture test reports
                }
            }
        }

        stage('Static Code Analysis') {
            steps {
                script {
                    sh "mvn sonar:sonar -Dsonar.projectKey=spring-framework-petclinic -Dsonar.host.url=$SONAR_HOST_URL -Dsonar.login=$SONAR_AUTH_TOKEN"
                }
            }
        }

        stage('Dependency Scanning') {
            steps {
                script {
                    sh 'mvn dependency-check:check'
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: '**/dependency-check-report*.xml', allowEmptyArchive: true
                }
            }
        }

        stage('Lint Dockerfile') {
            steps {
                script {
                    sh 'docker run --rm -i hadolint/hadolint < Dockerfile > lint-report.txt'
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'lint-report.txt', allowEmptyArchive: true
                }
            }
        }

        stage('Build') {
            steps {
                script {
                    sh 'mvn clean package'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def commitId = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
                    def imageTag = "petclinic:${commitId}-${env.BUILD_NUMBER}"
                    sh "docker build -t petclinic:latest -t ${AWS_ECR_REPO_URI}:${imageTag} ."
                }
            }
        }

        stage('Vulnerability Scan with Trivy') {
            steps {
                script {
                    def commitId = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
                    def imageTag = "${AWS_ECR_REPO_URI}:${commitId}-${env.BUILD_NUMBER}"
                    sh "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image --severity HIGH,CRITICAL --exit-code 1 --format json -o trivy-report.json ${imageTag}"
                    sh "jq '.' trivy-report.json > trivy-report.txt"
                    sh "wkhtmltopdf trivy-report.txt trivy-report.pdf"
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'trivy-report.pdf', allowEmptyArchive: true
                }
                failure {
                    mail to: 'snehatrimukhe12@gmail.com', subject: "Pipeline Failed", body: "Check the Jenkins job for vulnerability details."
                }
            }
        }

        stage('Push to ECR') {
            steps {
                script {
                    // Authenticate Docker to ECR
                    sh '''
                    aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ECR_REPO_URI
                    '''
                    // Push the Docker image to ECR
                    def commitId = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
                    def imageTag = "${AWS_ECR_REPO_URI}:${commitId}-${env.BUILD_NUMBER}"
                    sh "docker push ${imageTag}"
                    sh "docker push ${AWS_ECR_REPO_URI}:latest"
                }
            }
        }

        stage('Deploy Docker Container') {
            steps {
                script {
                    // Deploy the container (for local testing or if you have a remote environment ready)
                    sh 'docker run -d -p 8080:8080 --name petclinic-container petclinic:latest'
                }
            }
        }
    }
    post {
        always {
            archiveArtifacts artifacts: '**/target/*.jar', allowEmptyArchive: true
        }
        failure {
            mail to: 'snehatrimukhe12@gmail.com', subject: "Pipeline Failed", body: "Check the Jenkins job for details."
        }
    }
}

