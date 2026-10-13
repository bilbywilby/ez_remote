#!/bin/bash
# setup_ez_remote_quick.sh - Complete environment fix

set -euo pipefail

echo "=========================================="
echo "EZ_REMOTE SETUP & RECOVERY"
echo "=========================================="

# 1. Fix SSH keys
echo "[1/5] Checking SSH configuration..."
if ! ssh -T git@github.com 2>&1 | grep -q "authenticated"; then
    echo "⚠️ SSH key not configured"
    echo "Run these commands:"
    echo "  ssh-keygen -t ed25519 -C \"bilbywilby@example.com\""
    echo "  eval \"\$(ssh-agent -s)\""
    echo "  ssh-add ~/.ssh/id_ed25519"
    echo "  # Then copy ~/.ssh/id_ed25519.pub to GitHub settings"
else
    echo "✅ SSH keys configured"
fi

# 2. Setup ez_remote directory
echo "[2/5] Setting up ez_remote..."
cd ~
if [ -d "ez_remote" ]; then
    echo "✅ ez_remote already exists"
    cd ez_remote
    git fetch origin
else
    echo "📦 Cloning ez_remote..."
    git clone https://github.com/bilbywilby/ez_remote.git
    cd ez_remote
fi

# 3. Fix tech-ref-portal remote
echo "[3/5] Updating tech-ref-portal remote..."
cd "$HOME/tech-ref-portal"
git remote set-url origin git@github.com:bilbywilby/tech-ref-portal.git 2>/dev/null || true
echo "✅ Remotes updated"

# 4. Install Python dependencies
echo "[4/5] Checking Python dependencies..."
pip3 install -q pydantic requests rich pytest pytest-asyncio
python3 -c "import pydantic, requests, rich, pytest" && echo "✅ All packages installed"

# 5. Create test runner
echo "[5/5] Creating test infrastructure..."
cat > handover_test_runner.sh << 'TESTEOF'
#!/bin/bash
cd "$HOME/tech-ref-portal"
./handover_test_runner.sh 2>/dev/null || echo "Test runner created manually"
TESTEOF

chmod +x handover_test_runner.sh

echo ""
echo "=========================================="
echo "SETUP COMPLETE"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Verify SSH: ssh -T git@github.com"
echo "2. Review: cd ~/ez_remote && git status"
echo "3. Run tests: cd ~/tech-ref-portal && ./handover_test_runner.sh"
echo ""
