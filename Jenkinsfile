pipeline {
    agent any

    environment {
        scannerHome = tool name: "sonar_scanner_dotnet", type: "hudson.plugins.sonar.MsBuildSQRunnerInstallation"
        dockerRegistry = "dtr.nagarro.com:443"
        userName = "rhythmraj"
        appName = "WebApplication4"
    }

    options {
        //Prepend all console output generated during stages with the time at which the line was emitted.
        timestamps ()

        //Set a timeout period for the pipeline run, after which Jenkins should abort the Pipeline.
        timeout (time: 1, unit: "HOURS")

        //Discard old builds after 5 days or 3 builds count.
        buildDiscarder (logRotator (
            // history to keep the build in days
            daysToKeepStr: "5",
            // number of build logs to keep
            numToKeepStr: "3"
        ))
    }

    stages {
        stage ("nuget restore") {
            steps {
                //Initial message
                echo "Deployment pipeline started for - ${BRANCH_NAME} branch"

                echo "Nuget Restore step"
                bat "dotnet restore"
            }
        }
        stage ("Start sonarqube analysis") {          
            steps {
                echo "Start sonarqube analysis step"
                withSonarQubeEnv ("Test_Sonar") {
                    bat "${scannerHome}\\SonarScanner.MSBuild.exe begin /k:nagp-exam-${userName}-${BRANCH_NAME} /n:nagp-exam-${userName}-${BRANCH_NAME} /v:1.0"
                }
            }
        }

        stage ("Code build") {
            steps {
                //Cleans the output of previous build
                echo "Clean previous build"
                bat "dotnet clean"

                //Builds the project and all of its dependencies
                echo "Code build"
                bat "dotnet build -c Release -o ${appName}/app/build"
            }
        }

        stage ("Stop sonarqube analysis") {
            steps {
                echo "Stop sonarqube analysis step"
                withSonarQubeEnv ("Test_Sonar") {
                    bat "${scannerHome}\\SonarScanner.MSBuild.exe end"
                }
            }
        }

        stage ("Release artifact") { 
            steps {
                echo "Release artifact step"
                bat "dotnet publish -c Release -o ${appName}/app/${userName}"
            }
        }

        stage ("Docker Image") {
            steps {
                //For master publish before creating docker image
                script {
                    if (BRANCH_NAME == "master") {
                        bat "dotnet publish -c Release -o ${appName}/app/${userName}"
                    }
                }
                echo "Docker Image step"
                bat "docker build -t i-${userName}-${BRANCH_NAME} --no-cache -f Dockerfile ."
            }
        }
        stage ("Containers") {
            failFast true
            parallel {
                stage ("PrecontainerCheck") {
                    steps {
                        echo "PrecontainerCheck step"
                        script {
                            def containerId = powershell (returnStdout: true, script: "docker ps -a | Select-String c-${userName}-${BRANCH_NAME} | %{ (\$_ -split \" \")[0]}")
                            if (containerId != null && containerId != "") {
                                bat "docker stop ${containerId}"
                                bat "docker rm -f ${containerId}"
                            }
                        }
                    }
                }

                stage ("PushtoDTR") {
                    steps {
                        echo "PushtoDTR step"
                        //To push an image to a private registry and not the central Docker registry we need to tag it with the registry hostname and port.
                        bat "docker tag i-${userName}-${BRANCH_NAME} ${dockerRegistry}/i-${userName}-${BRANCH_NAME}"
                        bat "docker push ${dockerRegistry}/i-${userName}-${BRANCH_NAME}"
                    }
                }
            }
        }

        stage ("Docker deployment") {
            steps {
                echo "Docker deployment step"
                bat "docker run --name c-${userName}-${BRANCH_NAME} -d -p ${getDockerPort(BRANCH_NAME)}:80 ${dockerRegistry}/i-${userName}-${BRANCH_NAME}"
            }
        }
    }
}
Integer getDockerPort (branchName) {
    if (branchName.equalsIgnoreCase ("master")) {
        return 8082
    } else {
        return 9092
    }
}
Integer getNodePort (branchName) {
    if (branchName.equalsIgnoreCase ("master")) {
        return 8081
    } else {
        return 9090
    }
}