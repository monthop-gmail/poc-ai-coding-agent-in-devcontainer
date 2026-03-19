FROM ubuntu:24.04

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# ===========================================
# System dependencies
# ===========================================
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    git \
    openssh-client \
    sudo \
    bash \
    jq \
    ripgrep \
    fd-find \
    python3 \
    python3-pip \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# ===========================================
# Create non-root user
# ===========================================
RUN useradd -m -s /bin/bash dev \
    && echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# ===========================================
# Install OpenCode
# ===========================================
RUN curl -fsSL https://opencode.ai/install | bash

# ===========================================
# Setup workspace
# ===========================================
USER dev
WORKDIR /workspace

# Pre-create config directories
RUN mkdir -p /home/dev/.config/opencode/agents \
    && mkdir -p /home/dev/.local/share/opencode

# Copy global agent definitions
COPY --chown=dev:dev .opencode/agents/ /home/dev/.config/opencode/agents/

ENTRYPOINT ["/bin/bash"]
