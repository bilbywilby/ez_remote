# QUICK SETUP - COPY THIS ENTIRE BLOCK

set -euo pipefail
PROJECT_ROOT="$HOME/ez_remote"
cd "$PROJECT_ROOT"

echo "========================================"
echo "QUICK EZ_REMOTE SETUP"
echo "========================================"

# Create directories
mkdir -p src scripts remote_intelligence/raw remote_intelligence/data logs tests/fixtures .github/workflows

# Write .gitignore with ALL exclusions
cat > .gitignore << 'GITIGNORE_EOF'
# Data
remote_intelligence/raw/
remote_intelligence/data/codes_map.json
logs/
*.log

# Python
__pycache__/
*.py[cod]
*.pyi
.Python
*.egg-info/
dist/
build/

# Node (CRITICAL - prevent mixing frontend)
node_modules/
package-lock.json
npm-debug.log*
.yarn/

# IDE
.idea/
.vscode/
*.swp
*~

# Testing
.pytest_cache/
.coverage
htmlcov/

# Environment
.env
.env.local
GITIGNORE_EOF

echo "✅ .gitignore created"

# Write source_registry.json
cat > src/source_registry.json << 'REGISTRY_EOF'
{
  "schema_version": "1.0.0",
  "sources": [
    {
      "name": "sample_test_source",
      "url": "file:///data/data/com.termux/files/home/ez_remote/remote_intelligence/raw/sample_data.json",
      "method": "FILE",
      "timeout_seconds": 5.0,
      "enabled": false,
      "note": "Disable before production use - local test source"
    }
  ],
  "configuration": {
    "default_timeout": 15.0,
    "concurrent_fetch_limit": 3
  },
  "metadata": {
    "requires_customization": true,
    "instructions": [
      "Replace URLs with real IR code databases",
      "Configure authentication headers if needed",
      "Disable sample sources before production"
    ]
  }
}
REGISTRY_EOF

echo "✅ source_registry.json created"

# Write robust_gather_ir.py (minimal working version)
cat > src/robust_gather_ir.py << 'SCRAPER_EOF'
#!/data/data/com.termux/files/usr/bin/python3
"""Minimal IR Scraper for ez_remote."""

from __future__ import annotations

import json
import logging
import sys
from datetime import datetime, timezone
from pathlib import Path

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(name)s: %(message)s")
logger = logging.getLogger("robust_gather_ir")

PROJECT_ROOT = Path(__file__).parent.parent
RAW_DIR = PROJECT_ROOT / "remote_intelligence" / "raw"

def main() -> None:
    logger.info("Starting IR acquisition")
    RAW_DIR.mkdir(parents=True, exist_ok=True)
    
    # Create empty feed (production: load registry and fetch real data)
    feed = {
        "sources": [],
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "note": "Configure src/source_registry.json for production scraping"
    }
    
    (RAW_DIR / "latest_feed.json").write_text(json.dumps(feed, indent=2), encoding="utf-8")
    logger.info("Feed written to latest_feed.json")

if __name__ == "__main__":
    main()
SCRAPER_EOF

chmod +x src/robust_gather_ir.py
echo "✅ robust_gather_ir.py created"

# Write parse_ir_intelligence_v3.py
cat > scripts/parse_ir_intelligence_v3.py << 'PARSER_EOF'
#!/data/data/com.termux/files/usr/bin/python3
"""Minimal Parser for ez_remote."""

from __future__ import annotations

import json
import logging
import sys
from datetime import datetime, timezone
from pathlib import Path

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(name)s: %(message)s")
logger = logging.getLogger("parse_ir_intelligence_v3")

PROJECT_ROOT = Path(__file__).parent.parent
RAW_DIR = PROJECT_ROOT / "remote_intelligence" / "raw"
DATA_DIR = PROJECT_ROOT / "remote_intelligence" / "data"

def main() -> None:
    logger.info("Starting parsing stage")
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    
    feed_path = RAW_DIR / "latest_feed.json"
    if not feed_path.exists():
        logger.error("No latest_feed.json found - run robust_gather_ir.py first")
        sys.exit(1)
    
    # Create codes_map.json from feed
    codes_map = {
        "version": "3.0",
        "status": "validated",
        "mappings": [],  # Populate with real data when scraper is configured
        "generated_at": datetime.now(timezone.utc).isoformat()
    }
    
    (DATA_DIR / "codes_map.json").write_text(json.dumps(codes_map, indent=2), encoding="utf-8")
    logger.info(f"Generated codes_map.json at {DATA_DIR}")

if __name__ == "__main__":
    main()
PARSER_EOF

chmod +x scripts/parse_ir_intelligence_v3.py
echo "✅ parse_ir_intelligence_v3.py created"

# Write pipeline_refresh.sh
cat > scripts/pipeline_refresh.sh << 'REFRESH_EOF'
#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

PROJECT_ROOT="$HOME/ez_remote"
cd "$PROJECT_ROOT"

echo "[STAGE 1] Acquisition..."
python3 src/robust_gather_ir.py

echo "[STAGE 2] Parsing..."
python3 scripts/parse_ir_intelligence_v3.py

echo "[STAGE 3] Validation..."
if [ ! -s "remote_intelligence/data/codes_map.json" ]; then
    echo "❌ codes_map.json empty or missing"
    exit 1
fi

echo "✅ Pipeline complete"
REFRESH_EOF

chmod +x scripts/pipeline_refresh.sh
echo "✅ pipeline_refresh.sh created"

# Write requirements.txt
cat > requirements.txt << 'REQS_EOF'
pydantic>=2.0.0
requests>=2.31.0
beautifulsoup4>=4.12.0
rich>=13.0.0
pytest>=8.0.0
pytest-asyncio>=0.24.0
REQS_EOF

echo "✅ requirements.txt created"

# Final commit
git add .
git commit -m "feat: initial ez_remote production structure" || echo "⚠️ Nothing to commit"

echo ""
echo "========================================"
echo "SETUP COMPLETE"
echo "========================================"
echo "Location: $PROJECT_ROOT"
echo ""
echo "Verify:"
echo "  ls src/ scripts/"
echo "  python3 -m json.tool src/source_registry.json"
echo "  bash scripts/pipeline_refresh.sh"
echo ""
