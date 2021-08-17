# Developer guidelines for contributing to Framework

## Table of Contents

- [Working with git](#working-with-git)
- [Maintaining code quality](#maintaining-code-quality)
- [Setting up a Docker development environment](#setting-up-a-docker-development-environment)
   - [Requirements](#requirements)
   - [Instructions](#instructions)
      - [Building the Docker stack](#building-the-docker-stack)
      - [Starting the Docker stack](#starting-the-docker-stack)
      - [Accessing the server](#accessing-the-server)
      - [Running commands in the application container](#running-commands-in-the-application-container)
- [Setting up a standalone development environment](#setting-up-a-standalone-development-environment)
   - [Requirements](#requirements-1)
   - [Instructions](#instructions-1)
      - [Accessing the server](#accessing-the-server-1)

## Working with git

Create a [feature
branch](https://martinfowler.com/bliki/FeatureBranch.html) for any
development, ideally tied to a JIRA ticket (e.g.
`LIT-1234-frob-patron-whatnots`). When the feature is complete, make a
[merge request](https://martinfowler.com/bliki/PullRequest.html) to the
[mainline
branch](https://martinfowler.com/articles/branching-patterns.html#mainline)
(currently `master`).

## Maintaining code quality

Before submitting a merge request, make sure:

1. all tests pass (`rake spec`)
2. code complies with [RuboCop](https://rubocop.org/) style guidelines
   as configured in [.rubocop.yml](.rubocop.yml)
   - `bundle exec rubocop` to run the checks
   - `bundle exec rubocop -a` to auto-fix the easy ones (use with caution!)
3. all code is covered by tests (`rake coverage`)

It's good practice to make sure existing tests pass even before committing
to your feature branch, as it's easiest to fix failures immediately after
they're introduced. Likewise with style checks.

Ideally, all development would be
[test-driven](https://martinfowler.com/bliki/TestDrivenDevelopment.html)
and code coverage would be 100% even on your feature branch, but this isn't
always feasible, especially when you're still experimenting with an
implementation or with a UI.

That said, it's better to commit code (to a feature branch!) with a build
that doesn't pass, than to lose your work to a disk failure or to your
own mistakes. 🙂

## Setting up a Docker development environment

### Requirements

- [Docker Desktop](https://www.docker.com/products/docker-desktop)

Windows developers should also consider installing the 
[Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/). 
See “[Docker Desktop WSL 2 backend](https://docs.docker.com/docker-for-windows/wsl/)”
for instructions on integrating Docker Desktop with WSL.

### Instructions

#### Building the Docker stack

To build a Docker stack based on the included
[`docker-compose.yml`](docker-compose.yml) file, run the command:

```sh
docker-compose build --pull
```

This will build or pull images for the following services:

| Service           | Ports | Protocol     | Description                                                                                  |
| ---               | ---   | ---          | ---                                                                                          |
| `adminer`         | 8080  | http         | a web-based database administration tool (used for debugging)                                |
| `db`              | 5432  | native (api) | a PostgreSQL database                                                                        |
| `app`             | 3000  | http         | the Rails application (built from the [Dockerfile](Dockerfile) in this repository            |
| `iipsrv`          | 8180  | http         | IIPImage server (used for controlled digital lending)
| `selenium`        | 4444  | http (api)   | [Selenium Grid](https://www.selenium.dev/documentation/en/grid/) hub (used for system tests) |
| `selenium-chrome` | 55900 | vnc          | Selenium Grid node running Chrome (used for system tests)                                    |
| `updater`         |       |              | temporary Rails application instance used to run `rails setup`                               |

**Note:** The "Port" column indicates the host port (i.e., the port as seen
from outside the Docker stack).

#### Starting the Docker stack

To start up the Docker stack, run the command:

```sh
docker-compose up
```

**Note:** If anything else is already running on one of the ports listed
above, that service will fail to start.

#### Accessing the server

Navigate to [`http://localhost:3000/home`](http://localhost:3000/home).

**Note:** On first run, the database will not exist and assets (javascript/css) will not be precompiled.
To set up the database and precompile the assets, you can use `docker-compose exec` to run the relevant
Rake tasks in the application container.

```sh
docker compose exec -u root app rails db:setup assets:precompile
```

#### Running commands in the application container

With the Docker stack up and running, use `docker-compose exec app` and follow
it with the command, e.g.:

| command                                       | purpose                                 |
| ---                                           | ---                                     |
| `docker-compose exec app rake -T`             | list available Rake tasks               |
| `docker-compose exec app rails console`       | open the running server's Rails console |
| `docker-compose exec app bundle exec rubocop` | run RuboCop style checks                |

#### Debugging system test failures

The Selenium node running Chrome has a VNC server running on port 55900. To access it,
open [vnc://localhost:55900](vnc://localhost:55900) in the macOS Screen Sharing app, or
any other VNC client.

To launch your own instance of Chrome inside the Selenium node:

```sh
docker-compose exec -u root selenium-chrome \
  sudo -u seluser google-chrome \
    --disable-dev-shm-usage \
    --disable-gpu \
    --auto-open-devtools-for-tabs
```

(You'll see a bunch of `Failed to connect to the bus` errors, which can be safely
ignored.)

To run just the system tests in the app container:

```sh
docker-compose exec -e RAILS_ENV=test app rake spec:system
```

It may be convenient to also include `-e CAPYBARA_SERVER_PORT=<some port>` so it's
easier to navigate to the server Capybara starts.

## Setting up a standalone development environment

### Requirements

- Ruby (see [`.ruby-version`](.ruby-version) for the required version
  - recommended: a Ruby version manager such as [RVM](https://rvm.io/), 
    [rbenv](https://github.com/rbenv/rbenv), [chruby](https://github.com/postmodern/chruby), 
    or [asdf-ruby](https://github.com/asdf-vm/asdf-ruby).
- [node.js](https://nodejs.org/en/)
  - recommended: a Node version manager such as [nvm](https://github.com/nvm-sh/nvm)
- [PostgreSQL](https://www.postgresql.org/)
  - **Note:** In some cases it may be more convenient to keep the database in
    Docker even while running the app locally, as it avoids having to switch
    the database URL between test and development environments.
- For system tests: [ChromeDriver](https://chromedriver.chromium.org/)
  and [Google Chrome](https://www.google.com/chrome)
- For controlled digital lending: [IIPImage](https://github.com/ruven/iipsrv)
  or another IIIF-compatible image server

MacOS developers should consider installing [Homebrew](https://brew.sh),
which makes downloading and installing these other tools much simpler.

Windows developers should considering installing the [Windows
Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/).

### Instructions


1. Set up the development database:

   ```sh
   DATABASE_URL='postgres://<user>:<password>@<host>/<database-name>' rails db:setup
   ```

2. Start the server:

   ```sh
   DATABASE_URL='postgres://<user>:<password>@<host>/<database-name>' rails s
   ```

**Note:** Placing `DATABASE_URL` and other environment variables in a 
[`.env` file](https://github.com/bkeepers/dotenv) can simplify development.
However, you may run into issues using the same database for development and
testing. You can work around this using Docker for just the database -- see 
below.

> #### TODO: Document LIT_IIIF_BASE_URL config, incl. hybrid w/Dockerized image server

##### Using a Dockerized database for local development

For local development against a Docker database, you can start just the
database service from the `docker-compose.yml` stack:

1. ensure Postgres is not running, or at any rate not running on its default
   port of 5432.
2. run `docker compose up -d db` to start the Postgres service, and only
   the Postgres service, in detached (background) mode.
3. Edit `/etc.hosts` and add the line:

   ```none
   127.0.0.1 db
   ```

   so that `db` now resolves to your local machine.

You should now be able to run `rails db:setup` from the project root to
create dev and test databases in the Dockerized Postgres.

#### Accessing the server

Navigate to [`http://localhost:3000/home`](http://localhost:3000/home).
