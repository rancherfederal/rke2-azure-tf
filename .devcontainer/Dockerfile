# See here for image contents: https://github.com/microsoft/vscode-dev-containers/tree/v0.177.0/containers/python-3/.devcontainer/base.Dockerfile
# [Choice] Python version: 3, 3.9, 3.8, 3.7, 3.6
ARG VERSION="20.04"
FROM ubuntu:${VERSION}

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID
ARG TERRAFORM_VERSION=1.0.1
ARG TFLINT_VERSION=0.30.0

# Set up non-root user
COPY scripts/non-root-user.sh /tmp/
RUN bash /tmp/non-root-user.sh "${USERNAME}" "${USER_UID}" "${USER_GID}"

# Install system tools
RUN apt-get update && \
    apt-get -y install --no-install-recommends sudo git zsh ca-certificates \
    zip unzip curl jq openvpn

# Install Az CLI.
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Install Terraform
RUN mkdir -p /tmp/docker-downloads \
    && curl -sSL -o /tmp/docker-downloads/terraform.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && unzip /tmp/docker-downloads/terraform.zip \
    && mv terraform /usr/local/bin \
    && rm /tmp/docker-downloads/terraform.zip

# Install TFlint
RUN curl -sSL -o /tmp/docker-downloads/tflint.zip https://github.com/wata727/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_amd64.zip \
    && unzip /tmp/docker-downloads/tflint.zip \
    && mv tflint /usr/local/bin \
    && rm /tmp/docker-downloads/tflint.zip
