# =============================================================================
# Target: base
#
# The base stage scaffolds elements which are common to building and running
# the application, such as installing ca-certificates, creating the app user,
# and installing runtime system dependencies.
FROM ruby:2.7.2-alpine AS base

# This declares that the container intends to listen on port 3000. It doesn't
# actually "expose" the port anywhere -- it is just metadata. It advises tools
# like Traefik about how to treat this container in staging/production.
EXPOSE 3000

# Create the application user/group and installation directory
RUN addgroup -S -g 40035 altmedia \
&&  adduser -S -u 40035 -G altmedia altmedia \
&&  mkdir -p /opt/app /var/opt/app \
&&  chown -R altmedia:altmedia /opt/app /var/opt/app /usr/local/bundle

# Install packages common to dev and prod.
RUN apk --no-cache --update upgrade && \
    apk --no-cache add \
      bash \
      ca-certificates \
      git \
      libc6-compat \
      nodejs \
      openssl \
      postgresql-libs \
      shared-mime-info \
      sqlite-libs \
      tzdata \
      xz-libs \
      vips \
      yarn \
      && \
    rm -rf /var/cache/apk/*

# ==============================
# Selenium testing

# Workaround for https://github.com/rails/rails/issues/41828
RUN mkdir -p /opt/app/tmp && \
    mkdir -p /opt/app/artifacts/screenshots && \
    ln -s ../artifacts/screenshots /opt/app/tmp/screenshots

# ==============================
# Run configuration

# All subsequent commands are executed relative to this directory.
WORKDIR /opt/app

# Run as the altmedia user to minimize risk to the host.
USER altmedia

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
RUN apk --update --no-cache add \
      build-base \
      coreutils \
      git \
      postgresql-dev \
      sqlite-dev \
&&  rm -rf /var/cache/apk/*

# Drop back to altmedia.
USER altmedia

# Install gems. We don't enforce the validity of the Gemfile.lock until the
# final (production) stage.
COPY --chown=altmedia:altmedia Gemfile* ./
RUN bundle install

# Copy the rest of the codebase. We do this after bundle-install so that
# changes unrelated to the gemset don't invalidate the cache and force a slow
# re-install.
COPY --chown=altmedia:altmedia . .

# =============================================================================
# Target: production
#
# The production stage extends the base image with the application and gemset
# built in the development stage. It includes runtime dependencies but not
# heavyweight build dependencies.
FROM base AS production

# Copy the built codebase from the dev stage
COPY --from=development --chown=altmedia /opt/app /opt/app
COPY --from=development --chown=altmedia /usr/local/bundle /usr/local/bundle
COPY --from=development --chown=altmedia /var/opt/app /var/opt/app

# Ensure the bundle is installed and the Gemfile.lock is synced.
RUN bundle config set frozen 'true'
RUN bundle install --local

# Run the production stage in production mode.
ENV RAILS_ENV=production
ENV RAILS_SERVE_STATIC_FILES=true

# Pre-compile assets so we don't have to do it in production.
RUN rails assets:precompile
