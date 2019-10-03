# Framework (aka Mission Control)

[Original spec](https://docs.google.com/document/d/1wB4MGg-8mp1DdYjvCuFGs3n9Q6g0HBaESdTlqPUzCo4) (Google docs).

## Table of Contents

- [Getting Started](#getting-started)
- [Dependencies](#dependencies)
- [Testing](#testing)
- [CI / Deployment](#ci--deployment)
- [Documentation](#documentation)
- [Logging](#logging)

## Getting Started

```sh
# Build images. This takes ~5m if building from complete scratch, no cache.
docker-compose build --pull

# Spin up everything except the updater service
docker-compose up -d --scale updater=0

# Run the updater service (migrates DBs, compiles assets, etc.)
docker-compose run --rm updater
```

Barring port collisions (possible, if you're running multiple development stacks), this will spin up two services:

- `rails` (http://localhost:3000/home), the application itself.
- `yard` (http://localhost:8808/), a documentation server.

### Simulating production

To (somewhat) simulate a production environment, you can pass `RAILS_ENV` into the `docker-compose run` command:

```
docker-compose build --pull && \
  docker-compose run --rm -p3000:3000 -e RAILS_ENV=production rails
```

This tells docker-compose to:

- run `rails` on the stack defined in `docker-compose.yml`
- exposing container port 3000 as host port 3000 (`-p3000:3000`)
- passing the environment variable `RAILS_ENV=production` into the container
- removing (`-rm)

(You won't be able to get anywhere since the app will redirect to CAS, which won't see
`localhost` as a valid application, but you'll at least be able to run with, e.g., a
production logging configuration.)

## Dependencies

Framework is a Ruby on Rails application deployed in an Alpine Linux Docker container. That implies two different dependency managers:

- For Ruby/Rails, we use [Bundler](https://bundler.io), whose config files are [Gemfile](https://git.lib.berkeley.edu/lap/altmedia/blob/master/Gemfile) (a developer-oriented listing of Ruby dependencies) and [Gemfile.lock](https://git.lib.berkeley.edu/lap/altmedia/blob/master/Gemfile.lock) (a machine-oriented listing of _precise_ Ruby dependencies).
- For Alpine, we use [apk](https://wiki.alpinelinux.org/wiki/Alpine_Linux_package_management). The [Dockerfile](https://git.lib.berkeley.edu/lap/altmedia/blob/master/Dockerfile) shows exactly what apk commands were executed to install our system-level dependencies.

---

> **Why APK?** We need APK because Ruby applications (and Python, Perl, PHP, …) often depend on having underlying C libraries for functionality. For example, Ruby's famous Nokogiri XML parsing library relies on libxml2 to do the actual parsing work, for performance and de-duplication reasons.
>
> We use Alpine Linux, specifically, because it's tiny: 5MB to start, versus 100MBs for Ubuntu or CentOS, making it easier to [package, store, and distribute](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#from) our application images.

---

### Adding RubyGems

First update the Gemfile to include your dependency, then shell into the test container to run bundle update:

```sh
bin/docker-shell
bundle install --no-deployment
```

## Testing

Tests are written using [RSpec](https://rspec.info/). Rails offers [extensive documentation](https://guides.rubyonrails.org/testing.html) on testing, much more than can be covered here, so take a look at it. (The Rails docs are based on Minitest, the default Rails test framework, but the general advice there still applies.) See the [rspec-rails](https://github.com/rspec/rspec-rails) documentation for additional features that support testing Rails applications with RSpec.

After following the steps above to build your application, the easiest way to test it is to shell into a container running in "test mode":

```sh
docker-compose run --rm -u root -e RAILS_ENV=test --entrypoint=ash rails
```

---

> **Shortcut:** Use the `bin/docker-shell <env=test> <user=root>` utility script to avoid having to type all that. (But you should still know what it's doing.)

---

That boots you into a shell inside of the container, where all of your application code and dependencies live in (partial) isolation from your workstation. From there, you can spin up a rails console or run the test suite:

```sh
rails c # open a rails console
rails spec # run the whole test suite
rails spec:{models,controllers,mailers,…} # run a subset of specs
rails spec SPEC=spec/path/to/my_spec.rb # run a specific spec
```

To generate a test coverage report, you can either use the `cal:test:coverage` task, or set the `COVERAGE` environment variable:

```sh
rails cal:test:coverage
COVERAGE=true rails spec
```

Note that when running commands via `rails`, what you're really doing is running something called a rake task. (Get it? "Rake" as in "Make", but for Ruby!) As per usual, the [rails documentation](https://guides.rubyonrails.org/command_line.html#custom-rake-tasks) provides some good info.

### Sending and Testing Emails

Rails offers [numerous facilities](https://guides.rubyonrails.org/action_mailer_basics.html) for handling emails. As you might expect, there's more than can be covered in the readme, so familiarize yourself with the docs. (It's okay — you'll pick this up over time and be a stronger/faster/better developer for it.)

Two critical aspects of email behavior are:

- Unit Testing: If you implement a feature that involves sending emails, make sure to write a test for it. Most of the [job specs](spec/jobs)
  include email tests, using an RSpec [shared example](https://relishapp.com/rspec/rspec-core/docs/example-groups/shared-examples) in the file [jobs_helper.rb](spec/jobs_helper.rb).
- QA: The staging environment uses [Interceptor::MailingListInterceptor](app/mailers/interceptor/mailing_list_interceptor.rb) to route all outgoing emails to a [mailing list](https://groups.google.com/a/lists.berkeley.edu/forum/#!forum/lib-testmail), allowing you to test the behavior "live", using a real SMTP account, without accidentally emailing people. See that class's documentation for how to determine if it _would have_ emailed the correct people.

In development (the default) and test mode, Framework uses a [`:test` delivery method](https://guides.rubyonrails.org/action_mailer_basics.html#action-mailer-configuration). That means it will only simulate sending emails by logging their delivery and storing them in an in-memory array. In production and staging, we use the `:smtp` delivery method with a [SPA email account](https://git.lib.berkeley.edu/lap/workflow/wikis/CreateSPAwithEmail).

## CI / Deployment

Every commit is built, tested, and optionally deployed by [Jenkins](https://jenkins.lib.berkeley.edu/) using the [Jenkinsfile](Jenkinsfile) configuration in this repository. Builds can be found in Jenkins at [GitLab > lap > lap/altmedia](https://jenkins.lib.berkeley.edu/job/gitlab/job/lap/job/lap%252Faltmedia/).

The job defined by the Jenkinsfile:

- Builds the application by overlaying the [base](docker-compose.yml) and [CI-specific](docker-compose.ci.yml) stack configurations.
- Runs the `cal:test:ci` Rake task, which:
  - runs all specs, checking for 100% coverage
  - verifies code style consistency with RuboCop
  - checks for security vulnerabilities with Brakeman
- Runs the `bundle:audit` Rake task, which checks bundled gems for known vulnerabilities
- Tags and pushes built container images to the [the registry](https://git.lib.berkeley.edu/lap/altmedia/container_registry).
- For `master` and `production` branches, uses a Portainer webhook to trigger deployment.

If any step fails, the build is aborted, further steps are cancelled, and the commit status is marked with a red "x" in the GitLab UI. If the overall build succeeds, your commit is marked with a green checkmark in the GitLab UI.

It's good practice to run `rails cal:test:ci` before pushing, so you can find problems before Jenkins does.

> **Failed Pipelines** If the pipeline fails, then most likely there was a failed test or failed style check. This is a good thing — the tests (partially) protect you from pushing bad code. Go view the Jenkins Console output to see what happened.

You can follow the build progress on the Jenkins [job page](https://jenkins.lib.berkeley.edu/job/apps/job/framework-rails/).

### Deployment to production

To deploy to the production environment (https://framework.lib.berkeley.edu/home):

1. Make sure the `master` branch has been successfully built, tested, and deployed to stage (see above).
2. Merge from `master` to `production`.

Jenkins should take it from there.

### Docker Tags

Commits to the master branch are given two tags:

- latest: The most recently-built commit to master is always tagged "latest", making this a moving target. When a new commit is pushed, it will override the last "latest" tag.
- git-<commit>: This is an immutable tag that will always point to the image built from the given commit of the codebase. You can rely on this existing forever.

## Documentation

Use [yard](https://yardoc.org) to document your code. Our built-in Yard server (see above) automatically parses your comments, modules, classes, and methods to generate documentation, which you can view via:

```sh
docker-compose up --build -d yard
open http://localhost:8808/
```

Check the existing classes for examples, but in a nutshell:

```rb
# Foos are like bars but different
#
# @see https://some-external-link.com Description of link
class Foo
  class << self
    # Finds a foo by its ID
    #
    # Write some more info about your method here. Don't go crazy, though.
    # Short and sweet is usually more accurate and maintainable than some long
    # diatribe.
    #
    # @return [Foo] the corresponding Foo
    # @raise [FooNotFoundError] if the Foo does not exist
    # @todo For some reason this fails if given id="bar", gotta fix that
    def find(id)
      # ...
    end
  end
end
```

See? Just comments. Nothing too fancy. All of RubyDoc is built like this!

Links:

- [Yardoc Tag Reference](https://www.rubydoc.info/gems/yard/file/docs/GettingStarted.md#Reference_Tags)
- [Yardoc Cheat Sheet](https://gist.github.com/chetan/1827484)

## Logging

In general, logs are piped directly to STDOUT/STDERR, conforming to [12-Factor App guidelines](https://12factor.net/logs) and the expectations of modern service managers like Docker and Systemd.

In development, use docker-compose to view logs:

```sh
docker-compose logs -f rails # tail the logs
docker-compose logs rails | less # pipe all of the logs to less
```

In testing, things are a bit different. Because the test framework hijacks STDOUT/STDERR to display test results, we must use a traditional logfile:

```sh
rails test
tail -f log/test.log # in a separate shell
```

Traditionally, Rails projects will output production logs to a file. Framework opts to log consistently across environments and  will go directly to STDOUT/ERR.

### Viewing staging and production logs in CloudWatch

Staging and production logs are aggregated in Amazon CloudWatch.

- [staging](https://us-west-1.console.aws.amazon.com/cloudwatch/home?region=us-west-1#logStream:group=staging/framework/rails;streamFilter=typeLogStreamPrefix)
- [production](https://us-west-1.console.aws.amazon.com/cloudwatch/home?region=us-west-1#logStream:group=production/framework/rails;streamFilter=typeLogStreamPrefix)

You'll need to sign in with the IAM account alias `uc-berkeley-library-it`
and then with your IAM user name and password (created by the DevOps team).

You can also navigate to the logs by:

- logging into the [AWS Management console](https://uc-berkeley-library-it.signin.aws.amazon.com/console)
  (using the `uc-berkeley-library-it` alias and IAM username/password as above)
- selecting "CloudWatch" under "Management and Governance"
- clicking "Logs" in the left sidebar menu
- selecting "staging/framework/rails" or "production/framework/rails" as appropriate.

### Viewing logs from a Docker swarm manager node

Staging and production logs are only slightly different from development, and can be accessed either via journald (RHEL7's default logging service) or docker service logs:

```sh
# Aggregates logs from all nodes
docker service logs -f altmedia_rails

# Faster to update, but restricted to a single node
journalctl COM_DOCKER_SWARM_SERVICE_NAME=altmedia_rails -f
```
