pipeline {
    agent any
    tools {
        maven 'Maven'  // Configure Maven in Jenkins tools
    }
    environment {
        SONAR_HOST_URL = 'http://18.191.157.196:9000'
        SONAR_AUTH_TOKEN = credentials('my-token')  // Reference your SonarQube token in Jenkins credentials
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
                    // Using the correct project key for SonarQube
                    sh "mvn sonar:sonar -Dsonar.projectKey=spring-framework-petclinic -Dsonar.host.url=$SONAR_HOST_URL -Dsonar.login=$SONAR_AUTH_TOKEN"
                }
            }
        }

        stage('Dependency Scanning') {
            steps {
                script {
                    // Run Dependency-Check Maven plugin
                    sh 'mvn dependency-check:check'
                }
            }
            post {
                always {
                    // Archive Dependency-Check report
                    archiveArtifacts artifacts: '**/dependency-check-report*.xml', allowEmptyArchive: true
                    // Publish Dependency-Check results
                    dependencyCheckPublisher pattern: '**/dependency-check-report*.xml', 
                                            unstableTotalLow: 5, // Mark build unstable if more than 5 low vulnerabilities
                                            failedTotalLow: 0    // Mark build as failed if any critical vulnerabilities are found
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
                    // Assuming Docker is installed and configured on your Jenkins instance
                    sh 'docker build -t petclinic:latest .'
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

