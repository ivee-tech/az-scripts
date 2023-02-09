## Run Azure DevOps agent in a docker container

Follow instructions here:
[https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/docker?view=azure-devops](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/docker?view=azure-devops)


### Create image on Windows
``` shell
docker build -t dockeragent-win:latest -f win.dockerfile .

docker build -t dockeragent-win:latest --build-arg AZP_URL=https://dev.azure.com/daradu --build-arg AZP_TOKEN=*** -f win3.dockerfile .
```

### Create image on Linux
``` shell
docker build -t dockeragent:latest -f linux.dockerfile .
```

### Start container
``` shell
docker run -e AZP_URL=<Azure DevOps instance> -e AZP_TOKEN=<PAT token> -e AZP_AGENT_NAME=mydockeragent dockeragent:latest

docker run -e AZP_URL=https://dev.azure.com/daradu -e AZP_TOKEN=*** -e AZP_AGENT_NAME=dockeragent-win-001 -e AZP_POOL=AWEPool dockeragent-win:latest
```

