@Library('jenkins-workflow-scripts@auto_previews') _

dockerComposePipeline(
  stack: [template: 'postgres-selenium'],
  commands: [
    // Scaffold the preview environment
    'rails assets:precompile db:create db:migrate',
    // Testing
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
