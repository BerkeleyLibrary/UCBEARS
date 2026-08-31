# =============================================================================
# Target: base
#
# The base stage scaffolds elements which are common to building and running
# the application, such as installing ca-certificates, creating the app user,
# and installing runtime system dependencies.
FROM ruby:3.4-slim AS base

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
    build-essential \
    curl \
    git \
    gpg \
    pkg-config \
    libyaml-dev \
    libxml2-dev \
    libxslt1-dev \
    libpq-dev \
    libvips42 && rm -rf /var/lib/apt/lists/*

ENV PNPM_HOME="/usr/local/pnpm"

RUN arch="$(uname -m)"; \
    case "$arch" in \
      aarch*) export pnpmArch="arm64";; \
      x86_64) export pnpmArch="x64";; \
      *) printf "Unsupported architecture %s\n" "$arch"; exit 1;; \
    esac; \
    pnpmVersion="12.0.0-rc.11"; \
    mkdir -p /tmp/pnpm; \
    curl -L https://github.com/pnpm/pnpm/releases/download/v${pnpmVersion}/pnpm-linux-${pnpmArch}.tar.gz | tar -C /tmp/pnpm -xzf -; \
    /usr/bin/env SHELL="sh" /tmp/pnpm/pnpm setup --force; \
    rm -rf /tmp/pnpm

# ------------------------------------------------------------
# Run configuration

# All subsequent commands are executed relative to this directory.
WORKDIR /opt/app

# Run as the application user to minimize risk to the host.
USER $APP_USER

RUN mkdir -p /opt/app/artifacts

# Add binstubs to the path.
ENV PATH="/usr/bin:/opt/app/bin:$PNPM_HOME/bin:$PATH"

# If run with no other arguments, the image will start the rails server by
# default. Note that we must bind to all interfaces (0.0.0.0) because when
# running in a docker container, the actual public interface is created
# dynamically at runtime (we don't know its address in advance).
#
# Note that at this point, the rails command hasn't actually been installed
# yet, so if the build fails before the `bundle install` step below, you
# will need to override the default command when troubleshooting the buggy
# image.
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]

# =============================================================================
# Target: development
#
# The development stage installs build dependencies (system packages needed to
# install all your gems) along with your bundle. It's "heavier" than the
# production target.
FROM base AS development

# ------------------------------------------------------------
# Install build packages

# Temporarily switch back to root
USER root

# Install system packages needed to build gems with C extensions.
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    g++ \
    make \
    gcc \
 && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------
# Install Ruby gems and JavaScript packages

# Drop back to $APP_USER.
USER $APP_USER

# Base image ships with an older version of bundler
RUN gem install bundler --version 2.4.10

# Install gems. We don't enforce the validity of the Gemfile.lock until the
# final (production) stage.
COPY --chown=$APP_USER:$APP_USER Gemfile* ./
RUN bundle install

# Copy the rest of the codebase. We do this after bundle-install so that
# changes unrelated to the gemset don't invalidate the cache and force a slow
# re-install.
COPY --chown=$APP_USER:$APP_USER . .

RUN pnpm install --frozen-lockfile

# =============================================================================
# Target: production
#
# The production stage extends the base image with the application and gemset
# built in the development stage. It includes runtime dependencies (including
# test dependencies, due to quirks of our Jenkins build) but tries to minimize
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
RUN pnpm install --frozen-lockfile -P
# ------------------------------------------------------------
# Precompile production assets

# Pre-compile assets so we don't have to do it after deployment.
RUN SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile --trace

# ------------------------------------------------------------
# Preserve build arguments

# passed in by Jenkins
ARG BUILD_TIMESTAMP
ARG BUILD_URL
ARG DOCKER_TAG
ARG GIT_REF_NAME
ARG GIT_SHA
ARG GIT_REPOSITORY_URL

# build arguments aren't persisted in the image, but ENV values are
ENV BUILD_TIMESTAMP="${BUILD_TIMESTAMP}"
ENV BUILD_URL="${BUILD_URL}"
ENV DOCKER_TAG="${DOCKER_TAG}"
ENV GIT_REF_NAME="${GIT_REF_NAME}"
ENV GIT_SHA="${GIT_SHA}"
ENV GIT_REPOSITORY_URL="${GIT_REPOSITORY_URL}"
