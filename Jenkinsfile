#!/usr/bin/env groovy

pipeline {
  agent {
    label "docker"
  }

  environment {
    COMPOSE_FILE = "docker-compose.yml:docker-compose.ci.yml"
    COMPOSE_PROJECT_NAME = "${GIT_COMMIT.take(8)}"
    DOCKER_REGISTRY = credentials("0A792AEB-FA23-48AC-A824-5FF9066E6CA9")
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
        sh "docker-compose up -d --scale updater=0"
        retry(5) { sh "docker-compose run --rm updater" }
      }
    }

    stage("Test") {
      steps {
        // Note: ci_reporter_minitest deletes the test/reports directory before
        // running, so you should run the tests *first*. Otherwise, brakeman
        // results would be deleted!
        sh 'docker-compose exec -Tu root rails rails test:junit'
        sh 'docker-compose exec -Tu root rails rails brakeman'
        sh 'docker-compose exec -Tu root rails rails bundle:audit'
        sh 'docker-compose exec -T rails wget --spider http://localhost:3000/home'
      }
      post {
        always {
          sh 'docker cp $(docker-compose ps -q rails):/opt/app/test/reports test/'
          junit 'test/reports/*.xml'
          publishBrakeman 'test/reports/brakeman.json'
          publishHTML(target: [
            allowMissing: false,
            alwaysLinkToLastBuild: false,
            keepAll: true,
            reportDir: 'test/reports/rcov',
            reportFiles: 'index.html',
            reportName: 'Code Coverage Report',
          ])
        }
      }
    }

    stage("Deploy") {
      when {
        branch "master"
      }

      stages {
        stage("Push Images") {
          steps {
            sh "bin/docker-push latest"
            sh "bin/docker-push 'git-${GIT_COMMIT.take(8)}'"
          }
        }

        stage('Deploy Staging') {
          environment {
            COMPOSE_FILE = "docker-compose.yml:docker-compose.staging.yml"
            DOCKER_HOST = 'tcp://vm242.lib.berkeley.edu:2376'
            DOCKER_TLS_VERIFY = '1'
          }
          steps {
            withCredentials([
              dockerCert(
                credentialsId: 'b4a13a4f-8e28-4f1c-b13d-d02d899fbfd8',
                variable: 'DOCKER_CERT_PATH',
              ),
            ]) {
              sh "docker-compose config > tmp/staging-stack.yml"
              sh "bin/docker-deploy tmp/staging-stack.yml altmedia"
            }
          }
        }

        stage('Deploy Production') {
          environment {
            COMPOSE_FILE = "docker-compose.yml:docker-compose.production.yml"
            DOCKER_HOST = 'tcp://vm244.lib.berkeley.edu:2376'
            DOCKER_TLS_VERIFY = '1'
          }
          steps {
            withCredentials([
              dockerCert(
                credentialsId: '5f3bdd53-05c4-4575-a438-7fe979425bb9',
                variable: 'DOCKER_CERT_PATH',
              ),
            ]) {
              sh "docker-compose config > tmp/production-stack.yml"
              sh "bin/docker-deploy tmp/production-stack.yml altmedia"
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
