# Preparing servers

```
$ cd /path/to/oauth2_authorization_server_for_client_credentials
$ ./mvnw spring-boot:run
```

Open another terminal and run the server.

```
$ cd /path/to/oauth2_resource_server_for_client_credentials
$ ./mvnw spring-boot:run
```

# Request

```
$ curl -u mobile-app-client:mobile-app-client-secret -d "grant_type=client_credentials&scope=read" http://localhost:9000/oauth2/token 2> /dev/null | jq | tee /tmp/token.json
$ JWT_TOKEN=$(jq -r '.access_token' /tmp/token.json); echo $JWT_TOKEN

$ curl -H "Authorization: Bearer ${JWT_TOKEN}" http://localhost:9001/api/protected/resource | jq
```

## JWK endpoint
Resource servers will introspect JWT tokens using the JWK endpoint of the authorization server.

```
$ curl http://localhost:9000/oauth2/jwks
```


