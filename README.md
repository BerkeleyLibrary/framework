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

## Testing

The best way to run the tests is to shell into a test-only container:

```sh
docker-compose run --rm -e RAILS_ENV=test --entrypoint=ash rails
```

Then run `rails test`, or whatever you want, just as you normally would.

### Integration/Controller Testing

If you're having trouble with an `assert_select` or similar assertion, try debugging the raw response body:

```ruby
get '/some-page'
puts @response.body
assert_select 'problematic-assertion'
```

(When you call get/post/etc. methods, Rails' test case updates its copy of `@response`.)

## Documentation

Framework uses [yard](https://yardoc.org) for documentation. Annotate classes, modules, and methods with comments and yard automatically generates documentation for you. In development, you can view the documentation via:

```sh
docker-compose up -d yard
open http://localhost:8808/
```

Links:

- [yardoc tags](https://www.rubydoc.info/gems/yard/file/docs/GettingStarted.md#Reference_Tags)
- [cheat sheet](https://gist.github.com/chetan/1827484)

## Deploying

Every push to the master branch triggers staging and production deploys. Those environments are defined in three configuration files:

- docker-compose.yml: The basic configuration, which elements common to all environments.
- docker-compose.staging.yml: Staging-specific overrides. Always deploys ":latest".
- docker-compose.production.yml: Production-specific overrides. Deploys a specific tag.

The key thing to note is that most production deploys are a no-op. To deploy a new version to production, you _must_ update the `image:` declaration to use the tag you want to deploy. See [the registry](https://git.lib.berkeley.edu/lap/altmedia/container_registry) for a list of available tags.

By contrast, the staging environment is deployed on every commit to master because it is pinned to the ":latest" tag.

### Docker Tags

Commits to the master branch are given two tags:

- latest: The most recently-built commit to master is always tagged "latest", making this a moving target. When a new commit is pushed, it will override the last "latest" tag.
- git-<commit>: This is an immutable tag that will always point to the image built from the given commit of the codebase. You can rely on this existing forever.
