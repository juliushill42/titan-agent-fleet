#!/bin/bash
set -e
cd "/run/media/juliush/TITANSSD/titan-agent-fleet"
git init -b main 2>/dev/null || true
cp /run/media/juliush/TITANSSD/hackathon/titanu-a01-elastic-anomaly-detector/LICENSE ./LICENSE 2>/dev/null || echo "MIT License - Julius Cameron Hill - TitanU AI LLC - JCH-2026-001" > LICENSE
git add -A
git commit -m "feat: titan-agent-fleet — 100 agents — 6 tracks — JCH-2026-001" 2>/dev/null || true
gh repo create juliushill42/titan-agent-fleet --public \
  --description "TitanU AI — 100 Agent Fleet — Google Cloud Rapid Agent Hackathon — JCH-2026-001" \
  --source=. --remote=origin --push 2>/dev/null || \
  (git remote set-url origin https://github.com/juliushill42/titan-agent-fleet.git && git push -u origin main --force)
echo ""
echo "✅ https://github.com/juliushill42/titan-agent-fleet"
echo "🏆 100 agents. 6 tracks. TitanU AI — JCH-2026-001"
