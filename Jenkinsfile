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
  }

  stages {
    stage("Setup") {
      steps {
        // For debugging
        sh 'env | sort'
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
              junit 'test/reports/SPEC-*.xml'
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
          // Portainer doesn't offer a "stack" webhook, so we need to trigger
          // updates for each environment and service that uses the image.
          //
          // @see https://git.lib.berkeley.edu/lap/altmedia/merge_requests/161
          //  for discussion
          webhookUrls = [
            "https://portainer.swarm-ewh-prod.devlib.berkeley.edu/api/webhooks/a92205e4-4709-493f-82aa-5a30eec86621", // production/framework_rails
            "https://portainer.swarm-ewh-prod.devlib.berkeley.edu/api/webhooks/8b2ec4f2-da74-4c2a-8834-b8317871aae4", // production/framework_updater
            "https://portainer.swarm-ewh-prod.devlib.berkeley.edu/api/webhooks/a3d40ccd-3d48-464e-b9cb-4c02748c5c78", // staging/framework_rails
            "https://portainer.swarm-ewh-prod.devlib.berkeley.edu/api/webhooks/d186c5d9-03eb-4fd8-8e5f-6bb29f115b53", // staging/framework_updater
          ]
          webhookUrls.each { httpRequest(httpMode: 'POST', url: it) }
        }
      }
    }
  }

  options {
    ansiColor("xterm")
    timeout(time: 10, unit: "MINUTES")
  }
}
