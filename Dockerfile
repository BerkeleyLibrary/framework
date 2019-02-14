# =============================================================================
# Target: base
#

FROM ruby:2.5.1-alpine AS base

# Create the application user/group and installation directory
RUN addgroup -S -g 40035 altmedia && \
    adduser -S -u 40035 -G altmedia altmedia && \
    mkdir -p /opt/app /var/opt/app && \
    chown -R altmedia:altmedia /opt/app /var/opt/app /usr/local/bundle

# Install packages common to dev and prod.
RUN apk --no-cache --update upgrade && \
    apk --no-cache add \
        ca-certificates \
        libc6-compat \
        nodejs \
        openssl \
        sqlite-libs \
        tzdata \
        xz-libs \
        yarn && \
    rm -rf /var/cache/apk/*

# All subsequent commands are executed relative to this directory.
WORKDIR /opt/app

# Run as the altmedia user to minimize risk to the host.
USER altmedia

# Environment
ENV PATH="/opt/app/bin:$PATH" \
    RAILS_LOG_TO_STDOUT=yes

# Specifies the "rails" command as the entrypoint. This allows you to treat the
# `docker run` command as essentially a frontend to Rails. Whatever you pass as
# argument is forwarded to rails, e.g.:
#   docker run <image> assets:precompile db:create db:migrate
#
# Note that we use tini, a small process manager, because the application
# forks.
ENTRYPOINT ["/opt/app/bin/docker-entrypoint.sh"]

# Sets "server" as the default command. If you docker-run this image with no
# additional arguments, it simply starts the server.
CMD ["server"]

# =============================================================================
# Target: development
#

FROM base AS development

# Temporarily switch back to root to install build packages.
USER root

# Install system packages needed to build gems with C extensions.
RUN apk --update --no-cache add \
        build-base \
        coreutils \
        git \
        sqlite-dev && \
    rm -rf /var/cache/apk/*

# Drop back to altmedia.
USER altmedia

# Install gems.
COPY --chown=altmedia Gemfile* ./
RUN bundle install --jobs=$(nproc) --deployment --path=/usr/local/bundle

# Copy the rest of the codebase.
COPY --chown=altmedia . .

# =============================================================================
# Target: production
#

FROM base AS production

# Run as a non-root user by default to limit potential damage to the host.
USER altmedia

# Copy the built codebase from the dev stage
COPY --from=development --chown=altmedia /opt/app /opt/app
COPY --from=development --chown=altmedia /usr/local/bundle /usr/local/bundle
COPY --from=development --chown=altmedia /var/opt/app /var/opt/app

# Sanity-check gems
RUN bundle check

# Indicate that the server listens on port 3000.
EXPOSE 3000

# Mark the public directory as a volume. The first time this is run, the volume
# is created with the current contents of that directory. On subsequent runs
# only the volume's data is used.
VOLUME ["/opt/app/public"]

# Adds metadata we can query in production. The idea is to use this for routing
# alerts and triggering auto-scaling, but it's currently unused.
LABEL edu.berkeley.lib.author-1="Dave Zuckerman <dzuckerm@berkeley.edu>"
LABEL edu.berkeley.lib.author-2="Dan Schmidt <dcschmidt@berkeley.edu>"
LABEL edu.berkeley.lib.maintainer="Dave Zuckerman <dzuckerm@berkeley.edu>"
LABEL edu.berkeley.lib.project-url="https://git.lib.berkeley.edu/lap/altmedia"
LABEL edu.berkeley.lib.support-tier="business-hours"

# Run the production stage in production mode.
ENV RACK_ENV=production RAILS_ENV=production RAILS_SERVE_STATIC_FILES=true
