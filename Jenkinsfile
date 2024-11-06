pipeline {
    agent any
    environment {
        AWS_ACCOUNT_ID = '481665085317'
        AWS_REGION = 'us-east-2'
        ECR_REPO = 'petclinic'
        IMAGE_TAG = "latest"
        ECR_URL = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}"
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
                    dependencyCheckPublisher pattern: '**/dependency-check-report*.xml',
                                            unstableTotalLow: 5,
                                            failedTotalLow: 0
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

        stage('Build') {
            steps {
                sh 'mvn clean package'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def commitId = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                    def buildNumber = env.BUILD_NUMBER
                    def dynamicTag = "${commitId}-${buildNumber}"
                    IMAGE_TAG = dynamicTag
                    
                    sh "docker build -t ${ECR_REPO}:${IMAGE_TAG} ."
                }
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
                    mail to: 'snehatrimukhe12@gmail.com', subject: "Pipeline Failed", body: "Check Jenkins for vulnerability scan details."
                }
            }
        }

        stage('OWASP ZAP Scan') {
            steps {
                script {
                    def scanType = params.SCAN_TYPE ?: 'Baseline'
                    if (scanType == 'FULL') {
                        sh 'docker run --rm owasp/zap2docker-stable zap-full-scan.py -t http://localhost:8080 -r zap-report.html'
                    } else if (scanType == 'API') {
                        sh 'docker run --rm owasp/zap2docker-stable zap-api-scan.py -t http://localhost:8080 -r zap-report.html'
                    } else {
                        sh 'docker run --rm owasp/zap2docker-stable zap-baseline.py -t http://localhost:8080 -r zap-report.html'
                    }
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
                withCredentials([usernamePassword(credentialsId: 'aws-credentials',
                                                  usernameVariable: 'AWS_ACCESS_KEY_ID',
                                                  passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    script {
                        // Configure AWS CLI for region and credentials
                        sh "aws configure set aws_access_key_id ${AWS_ACCESS_KEY_ID}"
                        sh "aws configure set aws_secret_access_key ${AWS_SECRET_ACCESS_KEY}"
                        sh "aws configure set region ${AWS_REGION}"

                        // Log in to ECR
                        sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_URL}"

                        // Tag and Push to ECR
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

