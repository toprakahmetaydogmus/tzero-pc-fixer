#!/usr/bin/env bash
# ==============================================================================
# T-Zero PC-Fixer & Codebase Doctor Universal 1-Click Installer (Linux & macOS)
# ==============================================================================
# Installs pc-fixer CLI and configures MCP for Claude Desktop, Cursor, and Windsurf.
# 100% Free & Local Offline | Zero Cloud Cost ($0.00)
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/toprakahmetaydogmus/tzero-pc-fixer/main/install.sh | bash
# ==============================================================================

set -e

echo ""
echo "🩺 \033[1;36mInitializing T-Zero PC-Fixer & Codebase Doctor Installer...\033[0m"
echo "------------------------------------------------------------------"

# 1. Check Python 3
if ! command -v python3 &>/dev/null; then
    echo "\033[1;31m[ERROR] python3 is required but not found on your system PATH.\033[0m"
    echo "Please install Python 3.9+ from https://www.python.org/downloads/ and try again."
    exit 1
fi

PY_VER=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
echo "✔ Found Python: v${PY_VER}"

# 2. Target installation directory
INSTALL_DIR="$HOME/.local/bin"
mkdir -p "$INSTALL_DIR"

EXECUTABLE_URL="https://raw.githubusercontent.com/toprakahmetaydogmus/tzero-pc-fixer/main/tzero_pc_fixer.py"
MCP_URL="https://raw.githubusercontent.com/toprakahmetaydogmus/tzero-pc-fixer/main/pc_fixer_mcp.py"

echo "📥 Downloading standalone monolithic executable..."
curl -fsSL "$EXECUTABLE_URL" -o "$INSTALL_DIR/tzero_pc_fixer.py"
curl -fsSL "$MCP_URL" -o "$INSTALL_DIR/pc_fixer_mcp.py"
chmod +x "$INSTALL_DIR/tzero_pc_fixer.py"
chmod +x "$INSTALL_DIR/pc_fixer_mcp.py"

# Create symlinks
cat << 'EOF' > "$INSTALL_DIR/pc-fixer"
#!/usr/bin/env bash
exec python3 "$HOME/.local/bin/tzero_pc_fixer.py" "$@"
EOF
chmod +x "$INSTALL_DIR/pc-fixer"

cat << 'EOF' > "$INSTALL_DIR/pc-fixer-mcp"
#!/usr/bin/env bash
exec python3 "$HOME/.local/bin/pc_fixer_mcp.py" "$@"
EOF
chmod +x "$INSTALL_DIR/pc-fixer-mcp"

# 3. Check PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    SHELL_RC=""
    if [[ "$SHELL" == *"zsh"* ]]; then
        SHELL_RC="$HOME/.zshrc"
    elif [[ "$SHELL" == *"bash"* ]]; then
        SHELL_RC="$HOME/.bashrc"
    fi
    if [ -n "$SHELL_RC" ] && [ -f "$SHELL_RC" ]; then
        if ! grep -q "$INSTALL_DIR" "$SHELL_RC"; then
            echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$SHELL_RC"
            echo "✔ Added $INSTALL_DIR to $SHELL_RC"
        fi
    fi
fi

# 4. Configure Claude Desktop MCP if present
CLAUDE_CONFIG="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    CLAUDE_CONFIG="$HOME/.config/Claude/claude_desktop_config.json"
fi

if [ -f "$CLAUDE_CONFIG" ]; then
    echo "✔ Found Claude Desktop configuration at $CLAUDE_CONFIG"
    python3 -c "
import json, os
cfg_p = '$CLAUDE_CONFIG'
try:
    with open(cfg_p, 'r') as f:
        data = json.load(f)
    servers = data.setdefault('mcpServers', {})
    servers['pc-fixer'] = {
        'command': os.path.expanduser('~/.local/bin/pc-fixer-mcp')
    }
    with open(cfg_p, 'w') as f:
        json.dump(data, f, indent=2)
    print('✔ Successfully injected pc-fixer into Claude Desktop MCP config!')
except Exception as e:
    print('Notice: Manual MCP registration needed:', e)
"
fi

echo ""
echo "✨ \033[1;32mT-Zero PC-Fixer installed successfully!\033[0m"
echo "Run: \033[1;33mpc-fixer --help\033[0m to get started."
echo "MCP Server available at: \033[1;33mpc-fixer-mcp\033[0m"
echo ""

