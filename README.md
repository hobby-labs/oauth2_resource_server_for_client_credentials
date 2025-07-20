# oauth2_resource_server_for_client_credentials

## Initializing the Project

```bash
curl https://start.spring.io/starter.zip \
  -d dependencies=web,security \
  -d type=maven-project \
  -d language=java \
  -d name=resource-server-demo \
  -d groupId=com.github.TsutomuNakamura \
  -d artifactId=resource-server-demo \
  -d version=0.0.1-SNAPSHOT \
  -o resource-server-demo.zip

mkdir oauth2_resource_server_for_client_credentials
mv resource-server-demo.zip oauth2_resource_server_for_client_credentials
cd oauth2_resource_server_for_client_credentials
unzip resource-server-demo.zip
```

