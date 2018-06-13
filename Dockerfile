# Target: development
# ===================
FROM ruby:2.5-alpine as development

# Install runtime system dependencies and create the blightmgr user
RUN apk --update --no-cache add \
        bash \
        build-base \
        ca-certificates \
        coreutils \
        libc6-compat \
        nodejs \
        openssl \
        sqlite-dev \
        sqlite-libs \
        tzdata \
        xz-libs \
        nodejs

# Bundle install
WORKDIR /opt/altscan
COPY Gemfile* ./
RUN bundle install --jobs=$(nproc)

# Setup the rest of the codebase
COPY . .
RUN bin/rails log:clear tmp:create tmp:clear assets:clobber assets:precompile
RUN mkdir /var/opt/altscan

RUN addgroup -Sg 40017 altscan 
RUN adduser -Sg 40017 altscan 
RUN chown -R altscan:altscan /opt/altscan
USER altscan

# Specify entrypoint
#ENTRYPOINT ["docker-entrypoint.sh"]
#CMD ["rails server -b 0.0.0.0"]
CMD rails s -b 0.0.0.0

# Environment
ENV PATH="$PATH:/opt/altscan/bin" \
    RAILS_ENV=development

# Target: production
# ==================
FROM ruby:2.5-alpine as production
RUN apk --update --no-cache add \
        bash \
        ca-certificates \
        libc6-compat \
        nodejs \
        openssl \
        sqlite-libs \
        tzdata \
        xz-libs && \
    rm -rf /var/cache/apk/*

# Add user/group
#RUN addgroup -Sg 20 altscan && altscan -Su 505 -G altscan altscan 
RUN addgroup -Sg 40017 altscan 
RUN adduser -Sg 40017 altscan 


# Copy the built codebase from the dev stage
COPY --from=development --chown=altscan /opt/altscan /opt/altscan
COPY --from=development --chown=altscan /usr/local/bundle /usr/local/bundle
COPY --from=development --chown=altscan /var/opt/altscan /var/opt/altscan

# Run as altscan 
USER altscan 
WORKDIR /opt/altscan
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["server"]

# Metadata / documentation
EXPOSE 3000
VOLUME ["/opt/altscan/public"]

# Environment
ENV PATH="$PATH:/opt/altscan/bin" \
    RAILS_ENV=production
