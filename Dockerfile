FROM ubuntu:20.04

# Use Bash shell for Python venv script
SHELL ["/bin/bash", "-c"]

# To make it easier for build and release pipelines to run apt-get,
# configure apt to not require confirmation (assume the -y argument by default)
ENV DEBIAN_FRONTEND=noninteractive
RUN echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes

RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    dirmngr \
    git \
    gnupg \
    iputils-ping \
    jq \
    libcurl4 \
    libssl1.0 \
    libunwind8 \
    libxss1 \
    lsb-release \
    netcat \
    openjdk-11-jre-headless=11.0.14\* \
    python3 \
    python3-pip \
    python3-venv \
    software-properties-common \
    tzdata \
    zip \
    unzip \
# Install NodeJS 16.x and NPM 8.x
&& curl -fsSL https://deb.nodesource.com/setup_16.x | bash - \
&& apt-get install -y nodejs=16.\* \
# Preinstall components for EGMS deployments
&& python3 -m venv /ado-venv \
# Make this the default venv for root
&& echo "source /ado-venv/bin/activate" >> ~root/.bashrc \
&& source /ado-venv/bin/activate \
&& pip install wheel \
&& pip install ansible==5.2.0 foodx-devops-tools==0.12.1 \
# Install .NETCore runtime dependency for the agent
# See details of this here: https://github.com/dotnet/core/issues/4360#issuecomment-618784475
&& LIBICU_FILE="libicu66_66.1-2ubuntu2_amd64.deb" \
&& curl -fsSLo ${LIBICU_FILE} https://mirrors.edge.kernel.org/ubuntu/pool/main/i/icu/${LIBICU_FILE} \
&& dpkg -i ${LIBICU_FILE} \
# Install Mono
&& apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF \
&& apt-add-repository 'deb https://download.mono-project.com/repo/ubuntu stable-focal main' \
&& apt-get install -y --no-install-recommends mono-complete=6.12.\* \
# Install .NET 5, 6 and 3.1
&& curl -fsSLo packages-microsoft-prod.deb https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb \
&& dpkg -i packages-microsoft-prod.deb \
&& apt-get update \
&& apt-get install -y dotnet-sdk-6.0 \
&& apt-get install -y dotnet-sdk-5.0 \
&& apt-get install -y dotnet-sdk-3.1 \
&& rm packages-microsoft-prod.deb \
# Install Chrome
&& curl -LO https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
&& apt-get install -y ./google-chrome-stable_current_amd64.deb \
&& rm google-chrome-stable_current_amd64.deb \
# Install Azure CLI
&& curl -sL https://packages.microsoft.com/keys/microsoft.asc | \
    gpg --dearmor | \
    tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null \
&& AZ_REPO=$(lsb_release -cs) \
&& echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | \
    tee /etc/apt/sources.list.d/azure-cli.list \
&& apt-get update \
&& apt-get install -y --no-install-recommends azure-cli \
# Install Kubectl
&& curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg \
&& echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | \
    tee /etc/apt/sources.list.d/kubernetes.list \
&& apt-get update && apt-get install -y --no-install-recommends kubectl \
# Install Vault CLI
&& curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - \
&& apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
&& apt-get update && apt-get install -y vault=1.9.\* \
# Install Trivy
&& apt-get install wget apt-transport-https gnupg lsb-release \
&& wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | apt-key add - \
&& echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | tee -a /etc/apt/sources.list.d/trivy.list \
&& apt-get update && apt-get install trivy=0.27.\* \
# Give Vault the ability to use the mlock syscall without running the process as root. The mlock syscall prevents memory from being swapped to disk.
# Explanation: https://github.com/hashicorp/vault/issues/10048#issuecomment-700779263
&& setcap cap_ipc_lock= /usr/bin/vault \
# Install Docker CLI
&& curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
&& echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
&& apt-get update \
&& apt-get install -y --no-install-recommends \
    docker-ce=5:20.10.\* \
    docker-ce-cli=5:20.10.\*

WORKDIR /azp

COPY ./start.sh .
RUN chmod +x start.sh

CMD ["./start.sh"]
