# =============================================================================
# Target: base
#
# The base stage scaffolds elements which are common to building and running
# the application, such as installing ca-certificates, creating the app user,
# and installing runtime system dependencies.
FROM ruby:3.3-slim AS base

# ------------------------------------------------------------
# Declarative metadata

# This declares that the container intends to listen on port 3000. It doesn't
# actually "expose" the port anywhere -- it is just metadata. It advises tools
# like Traefik about how to treat this container in staging/production.
EXPOSE 3000

# ------------------------------------------------------------
# Create the application user/group and installation directory

# UCBEARS uses the "altmedia" user and group because (historical/permissions) reasons
ENV APP_USER=altmedia
ENV APP_UID=40035

RUN groupadd --system --gid $APP_UID $APP_USER \
    && useradd --home-dir /opt/app --system --uid $APP_UID --gid $APP_USER $APP_USER

RUN mkdir -p /opt/app \
    && chown -R $APP_USER:$APP_USER /opt/app /usr/local/bundle

# ------------------------------------------------------------
# Install packages common to dev and prod.

# Get list of available packages
RUN apt-get update -qq

# Install standard packages from the Debian repository
RUN apt-get install -y --no-install-recommends \
    curl \
    git \
    gpg \
    libpq-dev \
    libyaml-dev

# Install Node.js and Yarn from their own repositories

# Add Node.js package repository (version 16 LTS release) & install Node.js
# -- note that the Node.js setup script takes care of updating the package list
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get install -y --no-install-recommends nodejs

# Use Yarn via Corepack to avoids using reops and GPG keys
RUN corepack enable \
    && corepack prepare yarn@stable --activate \
    && yarn -v

# Remove packages we only needed as part of the Node.js / Yarn repository
# setup and installation -- note that the Node.js setup scripts installs
# a full version of Python, but at runtime we only need a minimal version

RUN apt-mark manual python3.13-minimal \
    && apt-get autoremove --purge -y curl

# ------------------------------------------------------------
# Run configuration

# All subsequent commands are executed relative to this directory.
WORKDIR /opt/app

# Run as the altmedia user to minimize risk to the host.
USER $APP_USER

# Add binstubs to the path.
ENV PATH="/opt/app/bin:$PATH"

# If run with no other arguments, the image will start the rails server by
# default. Note that we must bind to all interfaces (0.0.0.0) because when
# running in a docker container, the actual public interface is created
# dynamically at runtime (we don't know its address in advance).
#
# Note that at this point, the rails command hasn't actually been installed
# yet, so if the build fails before the `bundle install` step below, you
# will need to override the default command when troubleshooting the buggy
# image.
CMD ["rails", "server", "-b", "0.0.0.0"]

# =============================================================================
# Target: development
#
# The development stage installs build dependencies (system packages needed to
# install all your gems) along with your bundle. It's "heavier" than the
# production target.
FROM base AS development

# Temporarily switch back to root to install build packages.
USER root

# Install system packages needed to build gems with C extensions.
RUN apt-get install -y --no-install-recommends \
    g++ \
    make

# ------------------------------------------------------------
# Install Ruby gems

# Drop back to $APP_USER.
USER $APP_USER

# Base image ships with an older version of bundler
RUN gem install bundler --version 2.7.2

# Install gems. We don't enforce the validity of the Gemfile.lock until the
# final (production) stage.
COPY --chown=$APP_USER:$APP_USER Gemfile* .ruby-version ./
RUN bundle install

# ------------------------------------------------------------
# Install JS packages

# Install JS packages
COPY --chown=$APP_USER:$APP_USER package.json yarn.lock ./
RUN yarn install

# ------------------------------------------------------------
# Copy codebase

# Copy the rest of the codebase. We do this after installing packages so that
# changes unrelated to the packages don't invalidate the cache and force a slow
# re-install.
COPY --chown=$APP_USER:$APP_USER . .

# =============================================================================
# Target: production
#
# The production stage extends the base image with the application and gemset
# built in the development stage. It includes runtime dependencies but not
# heavyweight build dependencies.
FROM base AS production

# ------------------------------------------------------------
# Configure for production

# Run the production stage in production mode.
ENV RAILS_ENV=production
ENV RAILS_SERVE_STATIC_FILES=true

# ------------------------------------------------------------
# Copy code and installed gems

# Copy the built codebase from the dev stage
COPY --from=development --chown=$APP_USER /opt/app /opt/app
COPY --from=development --chown=$APP_USER /usr/local/bundle /usr/local/bundle

# Ensure the bundle is installed and the Gemfile.lock is synced.
RUN bundle config set frozen 'true'
RUN bundle install --local

# Ensure JS modules are installed and yarn.lock is synced
RUN yarn install --immutable

# ------------------------------------------------------------
# Precompile production assets

# Pre-compile assets so we don't have to do it after deployment.
# NOTE: dummy SECRET_KEY_BASE to prevent spurious initializer issues
#       -- see https://github.com/rails/rails/issues/32947
RUN SECRET_KEY_BASE=1 rails assets:precompile --trace

# ------------------------------------------------------------
# Preserve build arguments

# passed in by Jenkins
ARG BUILD_TIMESTAMP
ARG BUILD_URL
ARG DOCKER_TAG
ARG GIT_BRANCH
ARG GIT_COMMIT
ARG GIT_URL

# build arguments aren't persisted in the image, but ENV values are
ENV BUILD_TIMESTAMP="${BUILD_TIMESTAMP}"
ENV BUILD_URL="${BUILD_URL}"
ENV DOCKER_TAG="${DOCKER_TAG}"
ENV GIT_BRANCH="${GIT_BRANCH}"
ENV GIT_COMMIT="${GIT_COMMIT}"
ENV GIT_URL="${GIT_URL}"
