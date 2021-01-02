# Azure DevOps Agent, Linux Docker
From Microsoft: [DevOps Agent](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/docker?view=azure-devops)

## Configuration
```
docker run -e AZP_URL=<Azure DevOps instance> -e AZP_TOKEN=<PAT token> -e AZP_AGENT_NAME=mydockeragent foodx/devops:latest
```