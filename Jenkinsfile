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

