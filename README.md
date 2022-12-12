How to locally test the `live_listening_event_producer` lambda function.

1. Go to directory `live_listening_event_producer`.
2. Build the docker image for the `live_listening_event_producer`.
- `docker-compose -f docker-compose.development.yml build`
3. Bring up all the services
- `docker-compose -f docker-compose.development.yml up -d`
4. Invoke the function with some payload that includes a random `broadcastId`:
- `curl -v -X POST "http://localhost:9000/2015-03-31/functions/function/invocations" -H 'Content-Type: application/json' -d '{"broadcastId": "123"}'`
