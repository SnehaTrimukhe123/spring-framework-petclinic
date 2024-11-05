pipeline {
    agent any
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
                    def imageTag = "petclinic:latest"
                    sh "docker build -t ${imageTag} ."
                }
            }
        }

        stage('Vulnerability Scan with Trivy') {
            steps {
                script {
                    def imageTag = "petclinic:latest"
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

        stage('Run Docker Container') {
            steps {
                script {
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

