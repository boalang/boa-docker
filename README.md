# Boa Docker

This Docker image provides a fully working Boa setup, including the front-end
web interface and all back-end scripts (including Hadoop).

## Requirements

These instructions assume you have Docker compose available.

## Building the Image

> docker-compose build

## Running a Container

By default, the compose file will make two directories `data` (containing the
HDFS data) and `mysql` (for the SQL data).  For a clean run, first do:

> rm -Rf mysql data

Then to run, just use compose:

> docker-compose up

Once it fully loads, you will see instructions on the URL to connect to and the
user/pw to use.  There should be a sample dataset installed as `live` that you
can use to test.

### Parameters

The compose file will pick up the following environment variables, if they
exist:

- `BOA_USER=boa` the admin username to login to Boa's web interface
- `BOA_PW=rocks` the admin password to login to Boa's web interface
- `WWW_PUBLISHED_PORT=3000` the local port to run the web interface on

