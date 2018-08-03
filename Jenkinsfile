#!/usr/bin/env groovy

pipeline {
  agent {
    label "docker"
  }

  environment {
    COMPOSE_FILE         = "docker-compose.ci.yml"
    COMPOSE_PROJECT_NAME = "${GIT_COMMIT.take(8)}"
    DOCKER_REGISTRY      = credentials("0A792AEB-FA23-48AC-A824-5FF9066E6CA9")
  }

  stages {
    stage("Build") {
      steps {
        sh "env | sort"
        sh "docker-compose build --pull --force-rm"
      }
    }

    stage("Run") {
      steps {
        sh "docker-compose up -d"

        retry(5) {
          sh "docker-compose run --rm --entrypoint=setup rails"
          sleep 5
        }
      }
    }

    stage("Test") {
      steps {
        parallel(
          "Audit": {
            retry(5) {
              sh 'docker-compose run --rm --name `uuidgen` -e RAILS_ENV=test rails bundle:audit'
            }
          },
          "Brakeman": {
            retry(5) {
              sh 'docker-compose run --rm --name `uuidgen` -e RAILS_ENV=test rails brakeman'
            }
          },
          "Minitest": {
            retry(5) {
              sh 'docker-compose run --rm --name `uuidgen` -e RAILS_ENV=test rails test'
            }
          },
        )
      }
    }

    stage("Push") {
      when {
        branch "master"
      }
      stages {
        stage("Tag: latest") {
          steps {
            sh "bin/docker-push latest"
          }
        }
        stage("Tag: git-hash") {
          steps {
            sh "bin/docker-push 'git-${GIT_COMMIT.take(8)}'"
          }
        }
      }
    }

    stage("Deploy") {
      when {
        branch "master"
      }
      environment {
        DOCKER_HOST = 'tcp://vm244.lib.berkeley.edu:2376'
        DOCKER_TLS_VERIFY = '1'
      }
      steps {
        script {
          withCredentials([
            dockerCert(
              credentialsId: '5f3bdd53-05c4-4575-a438-7fe979425bb9',
              variable: 'DOCKER_CERT_PATH',
            )]
          ) {
            sh "bin/docker-deploy docker-compose.prod.yml"

            retry(5) {
              sh "curl --fail -q https://altmedia.lib.berkeley.edu/"
              sleep 4
            }
          }
        }
      }
    }
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

  options {
    ansiColor("xterm")
    buildDiscarder(logRotator(numToKeepStr: "60", daysToKeepStr: "7"))
    gitlabCommitStatus(name: 'Jenkins')
    gitLabConnection("git.lib.berkeley.edu")
    timeout(time: 10, unit: "MINUTES")
  }

  post {
    always {
      sh 'docker-compose down -v --remove-orphans || true'
    }
  }
}
