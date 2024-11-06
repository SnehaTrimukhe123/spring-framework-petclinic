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
                script {
                    sh 'mvn clean test'
                }
            }
            post {
                always {
                    junit '**/target/surefire-reports/*.xml'
                }
            }
        }

        stage('Static Code Analysis') {
            steps {
                script {
                    sh "mvn sonar:sonar -Dsonar.projectKey=spring-framework-petclinic"
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
                    dependencyCheckPublisher pattern: '**/dependency-check-report*.xml',
                                            unstableTotalLow: 5,
                                            failedTotalLow: 0
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

        stage('Build Docker Image') {
            steps {
                script {
                    sh 'mvn clean package'
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
                    mail to: 'snehatrimukhe12@gmail.com', subject: "Pipeline Failed", body: "Check the Jenkins job for vulnerability details."
                }
            }
        }

        stage('ZAP Baseline Scan') {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                    script {
                        def status = sh(script: '''#!/bin/bash
                        docker run -v $PWD:/zap/wrk/:rw -t ghcr.io/zaproxy/zaproxy:stable zap-baseline.py \
                        -t http://3.145.98.239:8080 > zap_baselinereport.html
                        ''', returnStatus: true)

                        if (status == 0) {
                            echo "ZAP scan completed successfully."
                        } else {
                            error "ZAP scan failed with status code: ${status}"
                        }
                    }
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'zap_baselinereport.html', allowEmptyArchive: true
                }
            }
        }

        stage('Push to ECR') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'aws-credentials',
                                                  usernameVariable: 'AWS_ACCESS_KEY_ID',
                                                  passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
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
                script {
                    sh "docker run -d -p 8080:8080 --name petclinic-container ${ECR_URL}:${IMAGE_TAG}"
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

