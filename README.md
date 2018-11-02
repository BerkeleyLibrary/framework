# Framework (aka Mission Control)

## Getting Started

```sh
# Scaffold secrets. More may exist -- see docker-compose.dev.yml for details.
touch secrets/{MAIL_PASSWORD,PRIVATE_KEY,SECRET_KEY_BASE}
touch secrets/{RECAPTCHA_SECRET_KEY,RECAPTCHA_SITE_KEY}

# Build the images
docker-compose build --pull

# Spin up everything except the updater service
docker-compose up -d --scale updater=0

# Run the updater service (migrates DBs, compiles assets, etc.)
docker-compose run --rm updater
```

Barring a port collision, the app will be up and running at http://localhost:3000/home.

## Documentation

Framework uses [yard](https://yardoc.org) for documentation. Annotate classes, modules, and methods with comments and yard automatically generates documentation for you. In development, you can view the documentation via:

```sh
docker-compose up --build -d yard
open http://localhost:8808/
```

Links:

- [Yardoc Tag Reference](https://www.rubydoc.info/gems/yard/file/docs/GettingStarted.md#Reference_Tags)
- [Yardoc Cheat Sheet](https://gist.github.com/chetan/1827484)

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
rails test:{models,controllers,mailed,…} # run a subset of tests
ruby -Itest test/path/to/my_test.rb # run a specific test
```

### Sending and Testing Emails

Rails offers [numerous facilities](https://guides.rubyonrails.org/action_mailer_basics.html) for handling emails. As you might expect, there's more than can be covered in the readme, so familiarize yourself with the docs. (It's okay — you'll pick this up over time and be a stronger/faster/better developer for it.)

Two critical aspects of email behavior are:

- Unit Testing: If you implement a feature that involves sending emails, make sure to write a test for it. See {ScanRequestOptInJobTest} for an example of how to test emails.
- QA: The staging environment uses {Interceptor::MailingListInterceptor} to route all outgoing emails to a [mailing list](https://groups.google.com/a/lists.berkeley.edu/forum/#!forum/lib-testmail), allowing you to test the behavior "live", using a real SMTP account, without accidentally emailing people. See that class's documentation for how to determine if it _would have_ emailed the correct people.

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

In general, logs are outputted directly to STDOUT/STDERR, conforming to the expectations of modern service managers like docker and systemd. To view the development logs, run:

```sh
docker-compose logs -f rails # tail the logs
docker-compose logs rails | less # pipe all of the logs to less
```

Things are different when testing, however, because testing frameworks use STDOUT/STDERR to display test results. Thus, the test logs can be found at `log/test.log`.

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
