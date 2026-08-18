FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV ANSIBLE_HOST_KEY_CHECKING=False
ENV ANSIBLE_STDOUT_CALLBACK=yaml
ENV ANSIBLE_RETRY_FILES_ENABLED=False

RUN apt-get update && apt-get install -y \
    # Locales
    locales \
    # Outils de base
    curl wget git vim nano bash-completion \
    # Python et pip
    python3 python3-pip python3-venv pipx \
    # SSH
    openssh-client sshpass \
    # Outils réseau utiles
    iputils-ping dnsutils netcat-openbsd \
    # Divers
    jq tree less \
    && rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8 && update-locale LANG=en_US.UTF-8

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# ansible-core 2.17.x needed for Kubespray v2.30.0
RUN pip3 install --break-system-packages \
    "ansible-core>=2.17.3,<2.18.0" \
    ansible-lint \
    netaddr \
    jmespath \
    paramiko

# Autocomplete Ansible
RUN activate-global-python-argcomplete3 || true

WORKDIR /workspace
