FROM ubuntu:24.04

# Build arguments for user UID/GID (defaults to 1000 if not provided)
ARG USER_UID=1000
ARG USER_GID=1000

# Avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install base dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    zip \
    unzip \
    build-essential \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    vim \
    nano \
    jq \
    tree \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20 (for Claude Code CLI)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install Python 3.12 and pip
RUN apt-get update && apt-get install -y \
    python3.12 \
    python3.12-dev \
    python3.12-venv \
    python3-pip \
    && rm -rf /var/lib/apt/lists/* \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1 \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3.12 1

# Install uv (fast Python package manager)
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.cargo/bin:${PATH}"

# Create a non-root user for safer operations
# Use USER_UID/USER_GID from build args to match host user
# If GID already exists, user will be added to that existing group
RUN useradd -u ${USER_UID} -g ${USER_GID} -m -s /bin/bash claude \
    && echo "claude ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install SDKMan as claude user
USER claude
WORKDIR /home/claude

RUN curl -s "https://get.sdkman.io" | bash

# Source SDKMan and install all LTS Java versions (17, 21, 25) + Maven
# Set Java 17 as default
RUN bash -c "source /home/claude/.sdkman/bin/sdkman-init.sh \
    && sdk install java 17.0.13-tem \
    && sdk install java 21.0.5-tem \
    && sdk install java 25.0.1-tem \
    && sdk default java 17.0.13-tem \
    && sdk install maven 3.9.9 \
    && sdk flush archives \
    && sdk flush temp"

# Set up SDKMan environment variables
ENV SDKMAN_DIR="/home/claude/.sdkman"
ENV PATH="${SDKMAN_DIR}/candidates/java/current/bin:${SDKMAN_DIR}/candidates/maven/current/bin:${PATH}"
ENV JAVA_HOME="${SDKMAN_DIR}/candidates/java/current"
ENV MAVEN_HOME="${SDKMAN_DIR}/candidates/maven/current"

# Install Claude Code CLI
USER root
RUN npm install -g @anthropic-ai/claude-code

# Install Protocol Buffer compiler and useful CLI tools
RUN apt-get update && apt-get install -y \
    protobuf-compiler \
    ripgrep \
    fd-find \
    bat \
    && rm -rf /var/lib/apt/lists/* \
    # Create symlinks for fd and bat (Ubuntu uses different names)
    && ln -s $(which fdfind) /usr/local/bin/fd \
    && ln -s $(which batcat) /usr/local/bin/bat

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# Install grpcurl (for testing gRPC APIs)
RUN curl -sSL "https://github.com/fullstorydev/grpcurl/releases/download/v1.9.1/grpcurl_1.9.1_linux_$(dpkg --print-architecture).tar.gz" \
    | tar -xz --no-same-owner -C /usr/local/bin grpcurl \
    && chmod +x /usr/local/bin/grpcurl

# Install additional Python development tools
USER claude
RUN pip3 install --user --no-cache-dir --break-system-packages \
    pre-commit \
    ruff \
    mypy \
    pytest \
    pytest-asyncio

# Set working directory
WORKDIR /workspace

# Copy entrypoint script
USER root
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Switch back to claude user for safer execution
USER claude

# Set default shell to bash with SDKMan
SHELL ["/bin/bash", "-c"]

# Entrypoint that sources SDKMan
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/bin/bash"]
