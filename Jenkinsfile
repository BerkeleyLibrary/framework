dockerComposePipeline(
  stack: [template: 'postgres-selenium'],
  commands: [
    [
        'rake js:eslint NODE_ENV=development',
        'rake brakeman',
        'rake bundle:audit'
    ],
  ],
  artifacts: [
    html    : [
      'Brakeman'     : 'artifacts/brakeman',
      'ESLint'       : 'artifacts/eslint'
    ],
    raw     : 'artifacts/capybara/**'
  ]
)
