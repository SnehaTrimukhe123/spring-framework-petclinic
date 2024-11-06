pipeline {
    agent any
    environment {
        AWS_ACCOUNT_ID = '481665085317'
        AWS_REGION = 'us-east-2'
        ECR_REPO = 'petclinic'
        IMAGE_TAG = "${GIT_COMMIT}-${BUILD_NUMBER}"
        ECR_URL = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}"
    }
    parameters {
        choice(name: 'scanType', choices: ['Baseline', 'API', 'FULL'], description: 'Choose the OWASP ZAP scan type')
    }
    stages {
        stage('Checkout Code') {
            steps {
                git 'https://github.com/SnehaTrimukhe123/spring-framework-petclinic.git'
            }
        }

        stage('Unit Test') {
            steps {
                sh 'mvn clean test'
            }
            post {
                always {
                    junit '**/target/surefire-reports/*.xml'
                }
            }
        }

        stage('Static Code Analysis') {
            steps {
                sh "mvn sonar:sonar -Dsonar.projectKey=spring-framework-petclinic"
            }
        }

        stage('Dependency Scanning') {
            steps {
                sh 'mvn dependency-check:check'
            }
            post {
                always {
                    archiveArtifacts artifacts: '**/dependency-check-report*.xml', allowEmptyArchive: true
                }
            }
        }

        stage('Lint Dockerfile') {
            steps {
                sh 'docker run --rm -i hadolint/hadolint < Dockerfile > lint-report.txt'
            }
            post {
                always {
                    archiveArtifacts artifacts: 'lint-report.txt', allowEmptyArchive: true
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${ECR_REPO}:${IMAGE_TAG} ."
            }
        }

        stage('Vulnerability Scan with Trivy') {
            steps {
                script {
                    sh "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image --severity HIGH,CRITICAL --exit-code 1 --format json -o trivy-report.json ${ECR_REPO}:${IMAGE_TAG}"
                    sh "jq '.' trivy-report.json > trivy-report.txt"
                    sh "wkhtmltopdf trivy-report.txt trivy-report.pdf"
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'trivy-report.pdf', allowEmptyArchive: true
                }
                failure {
                    mail to: 'snehatrimukhe12@gmail.com', subject: "Pipeline Failed", body: "Check Jenkins for vulnerability details."
                }
            }
        }

        stage('OWASP ZAP Scan') {
            steps {
                script {
                    def zapScript = ""
                    switch (params.scanType) {
                        case "Baseline":
                            zapScript = "zap-baseline.py"
                            break
                        case "API":
                            zapScript = "zap-api-scan.py"
                            break
                        case "FULL":
                            zapScript = "zap-full-scan.py"
                            break
                    }
                    sh "docker run --rm -v $(pwd):/zap/wrk owasp/zap2docker-stable ${zapScript} -t http://localhost:8080 -r zap-report.html"
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'zap-report.html', allowEmptyArchive: true
                }
            }
        }

        stage('Push to ECR') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'aws-credentials', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    script {
                        sh "aws configure set aws_access_key_id ${AWS_ACCESS_KEY_ID}"
                        sh "aws configure set aws_secret_access_key ${AWS_SECRET_ACCESS_KEY}"
                        sh "aws configure set region ${AWS_REGION}"

                        sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_URL}"
                        sh "docker tag ${ECR_REPO}:${IMAGE_TAG} ${ECR_URL}:${IMAGE_TAG}"
                        sh "docker push ${ECR_URL}:${IMAGE_TAG}"
                    }
                }
            }
        }

        stage('Run Docker Container') {
            steps {
                sh "docker run -d -p 8080:8080 --name petclinic-container ${ECR_URL}:${IMAGE_TAG}"
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: '**/target/*.jar', allowEmptyArchive: true
        }
        failure {
            mail to: 'snehatrimukhe12@gmail.com', subject: "Pipeline Failed", body: "Check Jenkins for details."
        }
    }
}

