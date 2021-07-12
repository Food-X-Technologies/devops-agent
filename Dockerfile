FROM ubuntu:20.04

# To make it easier for build and release pipelines to run apt-get,
# configure apt to not require confirmation (assume the -y argument by default)
ENV DEBIAN_FRONTEND=noninteractive
RUN echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes

RUN apt-get update \
&& apt-get install -y --no-install-recommends \
        apt-transport-https \
        ca-certificates \
        curl \
        git \
        gnupg \
        iputils-ping \
        jq \
        libcurl4 \
        libssl1.0 \
        libunwind8 \
        lsb-release \
        netcat \
        nodejs \
        npm \
        tzdata \
# Install .NETCore runtime dependency for the agent
# See details of this here: https://github.com/dotnet/core/issues/4360#issuecomment-618784475
&& LIBICU_FILE="libicu66_66.1-2ubuntu2_amd64.deb" \
&& curl -fsSLo ${LIBICU_FILE} https://mirrors.edge.kernel.org/ubuntu/pool/main/i/icu/${LIBICU_FILE} \
&& dpkg -i ${LIBICU_FILE} \
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
&& apt-get update && apt-get install -y --no-install-recommends kubectl

WORKDIR /azp

COPY ./start.sh .
RUN chmod +x start.sh

CMD ["./start.sh"]
