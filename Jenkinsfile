#!/usr/bin/env groovy

pipeline {
  agent {
    label "docker"
  }

  environment {
    COMPOSE_PROJECT_NAME = "${GIT_COMMIT.take(8)}"
    DOCKER_TARGET = "production"
  }

  stages {
    stage("Build") {
      steps {
        sh "env | sort"
        sh "ln -sf docker-compose.ci.yml docker-compose.override.yml"
        sh "docker-compose build --pull --force-rm"
      }
    }

    stage("Run") {
      steps {
        echo "docker-compose up -d"
      }
    }

    stage("Test") {
      stages {
        stage('Audit') {
          steps {
            sh 'docker-compose run --rm --name rails_audit rails bundle:audit'
          }
        }
        stage('Brakeman') {
          steps {
            sh 'docker-compose run --rm --name rails_brake rails brakeman'
          }
        }
      }
    }

    stage("Publish") {
      when {
        tag "release-*"
      }
      environment {
        DOCKER_REGISTRY_AUTH = credentials("0A792AEB-FA23-48AC-A824-5FF9066E6CA9")
        DOCKER_REGISTRY_HOST = "containers.lib.berkeley.edu"
      }
      steps {
        sh "docker login -u $DOCKER_REGISTRY_AUTH_USR -p $DOCKER_REGISTRY_AUTH_PSW $DOCKER_REGISTRY_HOST"
        sh "docker-compose push"

        // Tag w/branch name and push
        withEnv(["DOCKER_TAG=git-${env.GIT_COMMIT.take(8)}"]) {
          sh "docker-compose build"
          sh "docker-compose push"
        }
      }
    }
  }

  post {
    always {
      sh 'docker-compose down -v --remove-orphans || true'
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
}
