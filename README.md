# Framework (aka Mission Control)

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

## Dependencies

Framework is a Ruby on Rails application deployed in an Alpine Linux Docker container. That implies two different dependency managers:

- For Ruby/Rails, we use [Bundler](https://bundler.io), whose config files are {https://git.lib.berkeley.edu/lap/altmedia/blob/master/Gemfile Gemfile} (a developer-oriented listing of Ruby dependencies) and {https://git.lib.berkeley.edu/lap/altmedia/blob/master/Gemfile.lock Gemfile.lock} (a machine-oriented listing of _precise_ Ruby dependencies).
- For Alpine, we use [apk](https://wiki.alpinelinux.org/wiki/Alpine_Linux_package_management). The {https://git.lib.berkeley.edu/lap/altmedia/blob/master/Dockerfile Dockerfile} shows exactly what apk commands were executed to install our system-level dependencies.

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

Tests are written using Rails' default minitest framework. Rails offers [extensive documentation](https://guides.rubyonrails.org/testing.html) on testing, much more than can be covered here, so take a look at it.

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
rails t # run the whole test suite
rails test:{models,controllers,mailers,…} # run a subset of tests
ruby -Itest test/path/to/my_test.rb # run a specific test
```

Note that when running commands via `rails`, what you're really doing is running something called a rake task. (Get it? "Rake" as in "Make", but for Ruby!) As per usual, the [rails documentation](https://guides.rubyonrails.org/command_line.html#custom-rake-tasks) provides some good info.

### Sending and Testing Emails

Rails offers [numerous facilities](https://guides.rubyonrails.org/action_mailer_basics.html) for handling emails. As you might expect, there's more than can be covered in the readme, so familiarize yourself with the docs. (It's okay — you'll pick this up over time and be a stronger/faster/better developer for it.)

Two critical aspects of email behavior are:

- Unit Testing: If you implement a feature that involves sending emails, make sure to write a test for it. See {ScanRequestOptInJobTest} for an example of how to test emails.
- QA: The staging environment uses {Interceptor::MailingListInterceptor} to route all outgoing emails to a [mailing list](https://groups.google.com/a/lists.berkeley.edu/forum/#!forum/lib-testmail), allowing you to test the behavior "live", using a real SMTP account, without accidentally emailing people. See that class's documentation for how to determine if it _would have_ emailed the correct people.

In development (the default) and test mode, Framework uses a [`:test` delivery method](https://guides.rubyonrails.org/action_mailer_basics.html#action-mailer-configuration). That means it will only simulate sending emails by logging their delivery and storing them in an in-memory array. In production and staging, we use the `:smtp` delivery method with a [SPA email account](https://git.lib.berkeley.edu/lap/workflow/wikis/CreateSPAwithEmail).

### Integration/Controller Testing

If you're having trouble with an `assert_select` or similar assertion, try debugging the raw response body:

```ruby
get '/some-page'
puts @response.body
assert_select 'problematic-assertion'
```

(When you call get/post/etc. methods, Rails' test case updates its copy of `@response`.)

### Auth(n|z)

TODO

### Patron Updates

TODO

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

Staging and production logs are only slightly different from development, and can be accessed either via journald (RHEL7's default logging service) or docker service logs:

```sh
# Aggregates logs from all nodes
docker service logs -f altmedia_rails

# Faster to update, but restricted to a single node
journalctl COM_DOCKER_SWARM_SERVICE_NAME=altmedia_rails -f
```

## CI / Deployment

Every commit is built, tested, and optionally deployed by [Jenkins](https://jenkins.lib.berkeley.edu/) using the {file:Jenkinsfile} configuration in this repository. As of writing, this file instructs Jenkins to:

- Build the application by overlaying the {file:docker-compose.yml base} and {file:docker-compose.ci.yml CI-specific} stack configurations.
- Run the test suite (`rails test`) as well as security-related checks.
- For the master branch:
    - Tag and push the built application images to [the registry](https://git.lib.berkeley.edu/lap/altmedia/container_registry).
    - Deploy the staging (https://framework.ucblib.org/home) and production (https://framework.lib.berkeley.edu/home) environments.

If any step fails, the build is aborted, further steps are cancelled, and the commit status is marked with a red "x" in the GitLab UI. If the overall build succeeds, your commit is marked with a green checkmark in the GitLab UI.

---

> **Failed Pipelines** If the pipeline fails, then most likely there was a failed test. This is a good thing — the tests (partially) protect you from pushing bad code. Go view the Jenkins Console output to see what happened.

---

### Staging

Staging is pinned to the ":latest" version of the application. To deploy it:

- Push to the master branch.
- Wait for GitLab to notify the #altmedia slack channel that the pipeline has succeeded, or visit the [job page](https://jenkins.lib.berkeley.edu/job/altmedia/) to track progress.
- Open up the site and test: https://framework.ucblib.org/home.

### Production

The production stack is pinned to a specific version of the application. To deploy it, you must:

- Visit [the registry](https://git.lib.berkeley.edu/lap/altmedia/container_registry) and find the version (tag) of the application that you with to deploy.
- Update the {file:docker-compose.production.yml production stack} to reference that new version.

Each master commit is tagged in the registry as `git-########`, where "###" refers to the first eight characters of the commit hash. You can find that by running `git rev-parse --short HEAD` in your console, or by viewing the [master commit logs](https://git.lib.berkeley.edu/lap/altmedia/commits/master).

---

> **Double-Check Tags:** Make sure to verify that the desired tag is actually in the registry!

---

For example, suppose we want to deploy the latest master. Make sure you're on _exactly_ the version of master that's in GitLab, then get its commit hash:

```sh
git fetch origin
git reset --hard origin/master
git rev-parse --short HEAD # "fbdd4bb"
```

Then update the production config:

```yml
services:
  rails:
    image: containers.lib.berkeley.edu/lap/altmedia/altmedia-rails:git-fbdd4bb
    # ... SNIP ...

  updater:
    image: containers.lib.berkeley.edu/lap/altmedia/altmedia-rails:git-fbdd4bb
    # ... SNIP ...
```

Finally, commit your change and push:

```sh
git add docker-compose.production.yml
git commit -m 'Deploying rails:git-fbdd4bb to production'
```

---

> **Small Commits:** It's always a good idea to write small commits, but it is especially important that production deploys be a single, isolated commit, so that you can easily rollback if needed.

---

### Docker Tags

Commits to the master branch are given two tags:

- latest: The most recently-built commit to master is always tagged "latest", making this a moving target. When a new commit is pushed, it will override the last "latest" tag.
- git-<commit>: This is an immutable tag that will always point to the image built from the given commit of the codebase. You can rely on this existing forever.
