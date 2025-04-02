#!/bin/bash

SERVER_DIR="/home/hearn/projects/npc/npc"
echo "==============================================="
echo "NPC MCP Server Launcher - Diagnostic Information"
echo "==============================================="

if [ ! -d "$SERVER_DIR" ]; then
  echo "ERROR: Server directory does not exist: $SERVER_DIR"
  exit 1
fi

cd "$SERVER_DIR"
export MCP_PORT=3000
echo "Starting MCP server on port $MCP_PORT"
echo "Working directory: $(pwd)"

# Check if virtual environment exists
if [ ! -d ".venv" ]; then
  echo "ERROR: Virtual environment not found at $(pwd)/.venv"
  echo "Please ensure the Python environment is set up correctly"
  exit 1
fi

# Verify Python module exists
if [ -f "src/npc/mcp_server.py" ]; then
  echo "Found server module at: src/npc/mcp_server.py"
else
  echo "WARNING: Server module not found at expected location"
  find src -name "*mcp_server*"
fi

echo "Starting server:"
.venv/bin/python src/npc/mcp_server.py --port $MCP_PORT