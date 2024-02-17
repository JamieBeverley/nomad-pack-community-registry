# Django pack

Example pack for running a Django app via the `docker` driver. Database
migrations are run as a `prestart` task prior to the web server.

Requires `django_image` variable to be defined which indicates a docker image of
the Django app. There are 2 requirements/expectations of this image:
1. The image's `WORKDIR` should be the root of the Django app (required so that
   the pre-start task can `./manage.py migrate`)
2. The image's `CMD` should launch the webserver (e.g. via `gunicorn` or some
   other asgi/wsgi server)

## Dependencies
- Presently assumes database is run separately (a database is not currently
  included in the pack).
- Requires docker driver.

## How Migrations Are Handled
- `./manage.py migrate` should be run prior to the app starting up, this is
  achieved via `prestart = true`
- When multiple allocations are requested (`count>1`) only one allocation should
  attempt to run migrations (it might be okay if multiple allocations try to 
  migrate around the same time - databases should keep this safe but it would be
  a bit ugly).
- To achieve this:
  - if `NOMAD_ALLOC_INDEX=0` the prestart task will run `./manage.py migrate`
  - otherwise, the prestart task will check every `migration_poll_seconds` if
    migrations have been applied yet up to a maximum of `migration_poll_iters`
    attempts before failing.

## Variables

Please see `variables.hcl` for details.

## Trying This Pack
1. Run a Postgres db. You may or may not want to run with the bind mount for
testing (if not, exclude the `-v` option):
```
docker run \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=password \
  -e POSTGRES_DB=django_pack_postgres \
  -p 5432:5432 \
  -v "`pwd`/db_contents:/var/lib/postgresql/data" \
  --name django_pack_postgres \
  -d \
  postgres:12
```

2. Run the pack. The only required variable is `django_image`. For testing/
demonstration you may use [jamiebeverley/django-testing](https://hub.docker.com/repository/docker/jamiebeverley/django-testing/general)
(a docker image that runs a small django app, expecting a Postgres db).
```
nomad-pack run \
  --var-file example.variables.hcl \
  --var django_image=jamiebeverley/django-testing:latest \
  .
```

### Trying a Redeployment That Includes a New Migration:
This example uses a Django Docker image intended for testing
[jamiebeverley/django-testing](https://hub.docker.com/repository/docker/jamiebeverley/django-testing/general).

1. Run a postgres db (see 1 above)
2. Run an example definition of this pack using
`jamiebeverley/django-testing:v1` (note the `v1` tag).
```
nomad-pack run \
  --var-file example.variables.hcl \
  --var django_image=jamiebeverley/django-testing:v1 \
  django
```
(confirm healthy)

3. Redeploy with `v2` tag of the testing image. `v2` includes 1 dummy migration
that takes ~15s to complete (artificially with sleeps).
```
nomad-pack run \
  --var-file example.variables.hcl \
  --var django_image=jamiebeverley/django-testing:v2 \
  django
```

[pack-registry]: https://github.com/hashicorp/nomad-pack-community-registry
