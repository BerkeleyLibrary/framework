// @see https://git.lib.berkeley.edu/ops/jenkins-workflow-scripts/-/blob/master/vars/dockerComposePipeline.groovy
dockerComposePipeline(
  stack: [template: 'postgres'],
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
    ]
  ]
)
