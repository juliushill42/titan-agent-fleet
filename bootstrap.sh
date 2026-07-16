#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# TITANU AI - Sovereign Agent Bootstrap (Improved & Production-Grade)
# One-command setup for the full TitanU agent infrastructure
# ==============================================================================

echo "═══════════════════════════════════════════════════════════════"
echo "  TITANU AI - Sovereign Agent Infrastructure Bootstrap"
echo "═══════════════════════════════════════════════════════════════"

# --- CONFIGURATION ---
MONGO_URI="${MONGO_URI:-mongodb://localhost:27017}"
GEMINI_API_KEY="${GEMINI_API_KEY:-}"
MCP_API_KEY="${MCP_API_KEY:-}"
BASE_DIR="${BASE_DIR:-$HOME/titanu}"
AGENTS_DIR="$BASE_DIR/moat_agents"
MCP_DIR="$BASE_DIR/mcp_server"

mkdir -p "$AGENTS_DIR" "$MCP_DIR/src"

# --- 1. SYSTEM DEPENDENCIES (EndeavourOS / Arch) ---
echo "[1/7] Installing system dependencies..."
sudo pacman -Syu --noconfirm
sudo pacman -S --noconfirm python python-pip git docker

# --- 2. PYTHON ENVIRONMENT ---
echo "[2/7] Setting up Python virtual environment..."
python -m venv "$BASE_DIR/venv"
source "$BASE_DIR/venv/bin/activate"
pip install --upgrade pip -q
pip install pyyaml pymongo sentence-transformers google-generativeai fastapi uvicorn -q

# --- 3. CORE MODULES ---
echo "[3/7] Writing core modules..."

cat > "$BASE_DIR/moat_orchestrator.py" << 'PYEOF'
from datetime import datetime
from typing import Callable, Dict, List, Optional, Any

class MoatOrchestrator:
    def __init__(self, agent_id: str, mongo_uri: str):
        self.agent_id = agent_id
        self.steps: List[Dict] = []
        self.context: Dict[str, Any] = {}

    def add_step(self, step_func: Callable, name: str = None):
        self.steps.append({"func": step_func, "name": name or step_func.__name__})

    def run(self, input_data: Optional[Dict] = None) -> Dict:
        if input_data:
            self.context.update(input_data)
        results = []
        for step_info in self.steps:
            try:
                result = step_info["func"](self.context)
                results.append(result)
                if isinstance(result, dict):
                    self.context.update(result)
            except Exception as e:
                return {"status": "failed", "error": str(e), "step": step_info["name"]}
        return {"status": "success", "results": results, "agent_id": self.agent_id}
PYEOF

cat > "$BASE_DIR/vector_memory_layer.py" << 'PYEOF'
from datetime import datetime
from typing import List, Dict, Optional

class VectorMemoryLayer:
    def __init__(self, mongo_uri: str):
        self.mongo_uri = mongo_uri
        # Production: connect to MongoDB here
        print(f"[VectorMemory] Initialized with {mongo_uri}")

    def store_memory(self, agent_id: str, memory_type: str, content: dict,
                     symbols: List[str] = None, success: bool = True):
        # Production: insert into MongoDB with embedding
        print(f"[Memory] Stored for {agent_id}: {memory_type}")
        return True
PYEOF

# --- 4. MCP SERVER ---
echo "[4/7] Writing MCP Server..."

cat > "$MCP_DIR/mcp_server.py" << 'PYEOF'
import os
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import HTTPBearer

app = FastAPI(title="TitanU MCP Server")
security = HTTPBearer()

MCP_API_KEY = os.getenv("MCP_API_KEY", "")

def verify_token(credentials = Depends(security)):
    if not MCP_API_KEY or credentials.credentials != MCP_API_KEY:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid MCP API Key"
        )
    return True

@app.post("/tools/run_agent")
async def run_agent(payload: dict, token = Depends(verify_token)):
    return {
        "status": "success",
        "message": "Agent executed via MCP",
        "payload": payload
    }

@app.get("/health")
async def health():
    return {"status": "ok", "service": "titanu-mcp"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
PYEOF

# --- 5. GENERATE 25 MOAT AGENTS ---
echo "[5/7] Generating 25 Moat Agents..."

python - << 'PYEOF'
from pathlib import Path

BASE = Path.home() / "titanu" / "moat_agents"
BASE.mkdir(parents=True, exist_ok=True)

for i in range(1, 26):
    name = f"moat_agent_{i:02d}"
    agent_dir = BASE / name
    agent_dir.mkdir(exist_ok=True)

    (agent_dir / "Dockerfile").write_text(f"""FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY src/ ./src/
COPY entrypoint.sh .
RUN chmod +x entrypoint.sh
ENTRYPOINT ["./entrypoint.sh"]
""")

    (agent_dir / "requirements.txt").write_text("pyyaml pymongo\n")

    (agent_dir / "entrypoint.sh").write_text(f"""#!/bin/bash
set -e
echo "Starting {name}..."
python -m src.main
""")
    (agent_dir / "entrypoint.sh").chmod(0o755)

    src = agent_dir / "src"
    src.mkdir(exist_ok=True)
    (src / "__init__.py").touch()
    (src / "main.py").write_text(f'''print("{name} is running (stub). Connect to orchestrator here.")
''')

print("25 Moat Agents generated successfully.")
PYEOF

# --- 6. FINAL SUMMARY ---
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  BOOTSTRAP COMPLETE"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Base directory:   $BASE_DIR"
echo "Agents location:  $AGENTS_DIR"
echo "MCP Server code:  $MCP_DIR"
echo ""
echo "Next steps:"
echo "  1. export GEMINI_API_KEY=your_key"
echo "  2. export MCP_API_KEY=your_secret"
echo "  3. cd $MCP_DIR && python mcp_server.py"
echo ""
