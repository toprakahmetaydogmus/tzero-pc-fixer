# Production Container for T-Zero PC-Fixer & Codebase Doctor MCP Server
# 100% Free, Local Offline, Zero-Leak Certified
FROM python:3.12-slim

WORKDIR /app

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1

# Install runtime utilities & node/npm for mcp-proxy compatibility
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    ca-certificates \
    curl \
    nodejs \
    npm \
    && npm install -g mcp-proxy@6.9.0 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy workspace files
COPY pyproject.toml README.md LICENSE ./
COPY tzero_fixer/ ./tzero_fixer/
COPY tzero_pc_fixer.py pc_fixer_mcp.py ./

# Install package
RUN pip install --no-cache-dir .

EXPOSE 3000

# Default entrypoint: Direct stdio MCP Server
CMD ["pc-fixer-mcp"]
