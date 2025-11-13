@Library('jenkins-workflow-scripts@DEV-1023') _

dockerComposePipeline(
  stack: [template: 'postgres-selenium'],
  commands: [
    [
        [exec: 'rake check RAILS_ENV=test'],
        'rake js:eslint NODE_ENV=development',
        'rake rubocop',
        'rake brakeman',
        'rake bundle:audit'
    ],
  ],
  artifacts: [
    junit   : 'artifacts/rspec/**/*.xml',
    html    : [
      'Code Coverage': 'artifacts/rcov',
      'RuboCop'      : 'artifacts/rubocop',
      'Brakeman'     : 'artifacts/brakeman',
      'ESLint'       : 'artifacts/eslint'
    ],
    raw     : 'artifacts/capybara/**'
  ]
)
