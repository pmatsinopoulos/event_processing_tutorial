## Initialize DB Locally

*Important*: Docker daemon should be running

Execute:

```
$ DB_HOST=localhost DB_PORT=25432 DB_USERNAME=postgres DB_DATABASE=analytics_development PGPASSWORD=postgres ./initialize_db.sh
```

in order to create and initialize the database when working locally
