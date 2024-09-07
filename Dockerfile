FROM ubuntu

# Arguments for versions and user/group IDs
ARG TERRAFORM_VERSION=1.9.5
ARG PACKER_VERSION=1.11.1
ARG USER_ID=1009
ARG GROUP_ID=1009
ARG DEBIAN_FRONTEND=noninteractive

# Set environment variables
ENV ENV_TERRAFORM_VERSION=${TERRAFORM_VERSION}
ENV ENV_PACKER_VERSION=${PACKER_VERSION}

# Update and install necessary packages
RUN apt-get update --yes && \
    apt-get install --yes \
      coreutils \
      curl \
      direnv \
      expect \
      gawk \
      git \
      groff \
      less \
      lsb-release \
      moreutils \
      parallel \
      python3-pip \
      unzip \
      wget \
      software-properties-common \
    && apt-get clean --yes && \
    rm --recursive --force /var/lib/apt/lists/*

# Install Python packages via pip3
# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws

# Install Ansible
RUN apt-add-repository --yes --update ppa:ansible/ansible && \
    apt-get update && \
    apt-get install -y ansible && \
    rm -rf /var/lib/apt/lists/*

# Verify the installation of AWS CLI and Ansible
RUN aws --version && \
    ansible --version

# Install Terraform
RUN curl --output terraform.zip \
  --silent \
  --show-error \
  --location \
    "https://releases.hashicorp.com/terraform/${ENV_TERRAFORM_VERSION}/terraform_${ENV_TERRAFORM_VERSION}_linux_amd64.zip" && \
    unzip terraform.zip && \
    chmod +x terraform && \
    mv terraform /usr/local/bin/terraform && \
    rm --force terraform.zip

# Install Packer
RUN cd /tmp && curl --output packer.zip \
  --silent \
  --show-error \
  --location \
    "https://releases.hashicorp.com/packer/${ENV_PACKER_VERSION}/packer_${ENV_PACKER_VERSION}_linux_amd64.zip" && \
    unzip packer.zip && \
    chmod +x packer && \
    mv packer /usr/local/bin/packer && \
    rm --force packer.zip

# Create a user with specified UID and GID
RUN groupadd --gid "${GROUP_ID}" packer-users || true && \
    useradd --create-home --uid "${USER_ID}" --shell /bin/sh --gid packer-users packer-user || true

# Switch to the created user
USER packer-user

# Set the working directory
WORKDIR /home/packer-user

# Create the .ssh directory
RUN mkdir --parents /home/packer-user/.ssh/ && chmod 700 /home/packer-user/.ssh