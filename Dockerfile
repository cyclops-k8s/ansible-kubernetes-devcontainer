FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04 AS build

ARG devcontainercli
RUN if [ -z "$devcontainercli" ]; then printf "\nERROR: This Dockerfile needs to be built with VS Code!" && exit 1; else printf "VS Code is detected: $devcontainercli"; fi

RUN apt-get update \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get dist-upgrade --auto-remove --purge --yes \
    && apt-get install --no-install-recommends --yes pipx

USER vscode

COPY assets/ansible-galaxy-requirements.yaml /tmp/ansible-galaxy-requirements.yaml
COPY --chmod=755 --chown=vscode:vscode assets/update-bash_completions /home/vscode/.local/bin/update-bash_completions
COPY --chmod=755 --chown=vscode:vscode assets/update-binaries /home/vscode/.local/bin/update-binaries

RUN pipx install --include-deps ansible-core \
 && pipx inject --include-apps --include-deps ansible-core ansible-dev-tools ansible-lint \
 && pipx inject ansible-core dnspython \
 && PATH="${PATH}:/home/vscode/.local/bin" ansible-galaxy collection install -r /tmp/ansible-galaxy-requirements.yaml

RUN /home/vscode/.local/bin/update-binaries \
 && /home/vscode/.local/bin/update-bash_completions

FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

RUN apt-get update \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get dist-upgrade --auto-remove --purge --yes \
    && yes | unminimize \
    && apt-get install --no-install-recommends --yes \
            bind9 \
            bind9-dnsutils \
            bridge-utils \
            cloud-utils \
            curl \
            firewalld \
            genisoimage \
            git \
            iputils-ping \
            iputils-tracepath \
            jq \
            kubectx \
            libguestfs-tools \
            # libonig-dev \
            man-db \
            net-tools \
            ovmf \
            pipx \
            qemu-system-arm \
            qemu-system-x86 \
            sshpass \
            traceroute \
            vim \
            wget \
            yq \
    && apt-get distclean \
    && rm -rf /var/lib/apt/lists/*

COPY --chmod=755 --chown=root:root assets/entrypoint /entrypoint
COPY --from=build --chown=vscode:vscode /home/vscode/.ansible/collections /home/vscode/.ansible/collections
COPY --from=build --chown=vscode:vscode /home/vscode/.local/bin /home/vscode/.local/bin
COPY --from=build --chown=vscode:vscode /home/vscode/.local/share/bash-completion /home/vscode/.local/share/bash-completion
COPY --from=build --chown=vscode:vscode /home/vscode/.local/share/pipx /home/vscode/.local/share/pipx
COPY --chmod=600 --chown=vscode:vscode assets/vimrc /home/vscode/.vimrc

USER vscode

WORKDIR /workspace

ENTRYPOINT ["/entrypoint"]
