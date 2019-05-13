#!/usr/bin/env groovy

pipeline {
  agent {
    label "docker"
  }

  environment {
    COMPOSE_FILE      = "docker-compose.ci.yml"
    DOCKER_REPO       = "containers.lib.berkeley.edu/lap/altmedia/altmedia-rails/${env.GIT_BRANCH.toLowerCase()}"
    DOCKER_TAG        = "${DOCKER_REPO}:build-${BUILD_NUMBER}"
    DOCKER_TAG_LATEST = "${DOCKER_REPO}:latest"

    // Hooks executed after a successful build. These tell tracking
    // environments to pull the latest image version.
    SUCCESS_WEBHOOKS = credentials("framework-success-webhook-urls")
  }

  stages {
    stage("Setup") {
      steps {
        script {
          def targetBranch = env.GIT_BRANCH == "master" ?
            "origin/production" :
            "origin/master"

          def targetCommit = sh(
            script: "git rev-parse ${targetBranch}",
            returnStdout: true,
          )

          def gitlog = sh(
            script: "git log --pretty=format:'* %h: %s (%ar by %ae)' ${targetBranch}..",
            returnStdout: true,
          )

          env.SLACK_THREAD_ID = slackSend(
            message: "Building <${env.BUILD_URL}console|${env.JOB_NAME}/${env.BUILD_NUMBER}>",
            attachments: [
              [
                title: "git-log (${env.GIT_BRANCH}@${env.GIT_COMMIT.take(8)} .. ${targetBranch}@${targetCommit.take(8)})",
                text: "${gitlog}",
              ],
            ],
          ).threadId

          // For debugging
          sh 'env | sort'
        }
      }
    }

    stage("Build") {
      steps {
        withDockerRegistry(url: "https://${DOCKER_REPO}", credentialsId: "0A792AEB-FA23-48AC-A824-5FF9066E6CA9") {
          sh 'docker-compose build --pull'
          sh 'docker push "${DOCKER_TAG}"'
        }
      }
    }

    stage("Test") {
      stages {
        stage("Run") {
          steps {
            // Start the test stack
            sh 'docker-compose up --detach --scale updater=0'

            // Run the updater to scaffold DB, solr, assets, etc.
            retry(5) {
              sh 'docker-compose run --rm updater'
            }

            // Sanity-check the homepage
            sh 'docker-compose exec -T rails wget --spider http://localhost:3000/home'
          }
        }
        stage("RSpec") {
          steps {
            // Run the tests
            sh 'docker-compose run --rm rails cal:test:ci'
          }
          post {
            always {
              // Copy test results (if any) before exiting
              sh 'docker cp "$(docker-compose ps -q rails):/opt/app/test/reports" test/reports'

              // Archive test reports
              junit 'test/reports/*.xml'
              publishBrakeman 'test/reports/brakeman.json'

              // Publish code coverage reports (if any)
              publishHTML([
                allowMissing: true,
                alwaysLinkToLastBuild: false,
                keepAll: true,
                reportDir: 'test/reports/rcov',
                reportFiles: 'index.html',
                reportName: 'Code Coverage',
              ])
            }
          }
        }
        stage("Audit") {
          steps {
            // Run audit checks against rubygems dependencies
            sh 'docker-compose run --rm rails bundle:audit'
          }
        }
      }
      post {
        always {
          // Spin down the stack and cleanup volumes
          sh 'docker-compose down --remove-orphans --volumes'
        }
      }
    }

    stage("Push") {
      steps {
        withDockerRegistry(url: "https://${DOCKER_REPO}", credentialsId: "0A792AEB-FA23-48AC-A824-5FF9066E6CA9") {
          sh 'docker tag "${DOCKER_TAG}" "${DOCKER_TAG_LATEST}"'
          sh 'docker push "${DOCKER_TAG_LATEST}"'
        }
      }
    }

    stage("Deploy") {
      when {
        anyOf {
          branch "master"
          branch "production"
        }
      }
      steps {
        script {
          readFile(env.SUCCESS_WEBHOOKS).split('\n').each {
            httpRequest(httpMode: 'POST', url: it)
          }
        }
      }
    }
  }

  post {
    success {
      slackSend(
        message: "Woot! Finished without errors.",
        channel: "${env.SLACK_THREAD_ID}",
        color: 'good',
      )
    }
    unsuccessful {
      slackSend(
        message: "The build failed or was aborted. Check the link above for details.",
        channel: "${env.SLACK_THREAD_ID}",
        color: 'danger',
      )
    }
  }

  options {
    ansiColor("xterm")
    buildDiscarder(logRotator(numToKeepStr: "60", daysToKeepStr: "7"))
    gitlabCommitStatus(name: 'Jenkins')
    gitLabConnection("git.lib.berkeley.edu")
    timeout(time: 10, unit: "MINUTES")
  }

  triggers {
    gitlab(
      acceptMergeRequestOnSuccess: false,
      addCiMessage: true,
      addNoteOnMergeRequest: true,
      addVoteOnMergeRequest: true,
      ciSkip: true,
      noteRegex: ".*buildme.*",
      secretToken: "ad26a53bcd18b6318b43caebcc05a5aa",
      setBuildDescription: true,
      skipWorkInProgressMergeRequest: false,
      triggerOnMergeRequest: true,
      triggerOnNoteRequest: true,
      triggerOnPush: true,
      triggerOpenMergeRequestOnPush: "both",
    )
  }
}
