// @see https://git.lib.berkeley.edu/ops/jenkins-workflow-scripts/-/blob/master/vars/dockerComposePipeline.groovy
@Library("jenkins-workflow-scripts@LIT-2325-selenium-chrome") _

dockerComposePipeline(
  stack: [template: 'postgres-selenium'],
  commands: [
    'rake check',
    'rake rubocop',
    'rake brakeman',
    'rake bundle:audit'
  ],
  artifacts: [
    junit   : 'artifacts/rspec/**/*.xml',
    html    : [
      'Code Coverage': 'artifacts/rcov',
      'RuboCop'      : 'artifacts/rubocop',
      'Brakeman'     : 'artifacts/brakeman'
    ],
    raw     : 'artifacts/screenshots/**/*.png'
  ],
  debug: true
)
