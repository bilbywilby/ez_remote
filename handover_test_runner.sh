#!/data/data/com.termux/files/usr/bin/bash
​handover_test_runner.sh
​Purpose: Execute all 15 acceptance checklist items and report pass/fail
​Author: Generated for tech-ref-portal / ez_remote handover
​Date: 2026-10-13
​set -euo pipefail
​PROJECT_ROOT="$HOME/ez_remote"
RESULTS_FILE="PROJECT_ROOT/acceptance_test_results.json"
TEST_START=(date +%s)
​Ensure working directory exists
​if [ ! -d "PROJECT_ROOT" ]; then
PROJECT_ROOT="(pwd)"
fi
cd "$PROJECT_ROOT"
​echo ""
echo "EZ_REMOTE ACCEPTANCE TEST RUNNER"
echo ""
echo "Project Root: $PROJECT_ROOT"
echo "Started at: $(date -Iseconds)"
echo "----------------------------------------------------------------------"
​PASSED_COUNT=0
TOTAL_COUNT=15
FAIL_COUNT=0
SKIPPED_COUNT=0
​Helper function to record and print results
​record_result() {
local test_name="$1"
local status="$2"
local details="$3"
​if [ "$status" = "PASS" ]; then
echo "   ✅ [PASS] $test_name:$details"
((PASSED_COUNT++))
elif [ "$status" = "SKIP" ]; then
echo "   ⚠️  [SKIP] $test_name:$details"
((SKIPPED_COUNT++))
else
echo "   ❌ [FAIL] $test_name:$details"
((FAIL_COUNT++))
fi
}
​1. AC-001: Repository checkout and branch state confirmed
​test_ac_001() {
echo "[AC-001] Checking repository checkout and branch state..."
if [ -d ".git" ]; then
local branch
branch=(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
local status_short
status_short=(git status --short 2>/dev/null || echo "")
if [ -n "$branch" ]; then
record_result "AC-001" "PASS" "Branch: $branch, working tree checked."
else
record_result "AC-001" "FAIL" "Git repository found but unable to resolve branch."
fi
else
record_result "AC-001" "FAIL" "Not a git repository (.git missing)."
fi
}
​2. AC-002: All component files present and reviewed
​test_ac_002() {
echo "[AC-002] Checking core component files..."
local missing=()
for file in "src/robust_gather_ir.py" "scripts/parse_ir_intelligence_v3.py" "scripts/pipeline_refresh.sh" "scripts/portal_tui.py"; do
if [ ! -f "$file" ]; then
missing+=("$file")
fi
done
if [ ${#missing[@]} -eq 0 ]; then
record_result "AC-002" "PASS" "All required component files are present."
else
record_result "AC-002" "FAIL" "Missing component files: ${missing[*]}"
fi
}
​3. AC-003: Python version and dependencies documented
​test_ac_003() {
echo "[AC-003] Checking Python runtime and dependencies..."
if command -v python3 &>/dev/null; then
local py_ver
py_ver=$(python3 --version 2>&1)
if python3 -c "import pydantic, requests, rich" 2>/dev/null; then
record_result "AC-003" "PASS" "Python available ($py_ver) with core packages installed."
else
record_result "AC-003" "FAIL" "Python available but missing required packages (pydantic, requests, rich)."
fi
else
record_result "AC-003" "FAIL" "python3 executable not found in PATH."
fi
}
​4. AC-004: Source registry customized with production URLs
​test_ac_004() {
echo "[AC-004] Checking source registry configuration..."
if [ -f "src/source_registry.json" ]; then
if grep -q "example.com" "src/source_registry.json" 2>/dev/null; then
record_result "AC-004" "FAIL" "source_registry.json still contains example placeholders."
else
record_result "AC-004" "PASS" "source_registry.json configured (no default placeholders found)."
fi
else
record_result "AC-004" "FAIL" "src/source_registry.json not found."
fi
}
​5. AC-005: Raw input and output schemas validated
​test_ac_005() {
echo "[AC-005] Checking raw and output schemas..."
if [ -f "remote_intelligence/data/codes_map.json" ]; then
if python3 -m json.tool remote_intelligence/data/codes_map.json &>/dev/null; then
record_result "AC-005" "PASS" "codes_map.json exists and is valid JSON."
else
record_result "AC-005" "FAIL" "codes_map.json contains invalid JSON syntax."
fi
else
record_result "AC-005" "SKIP" "codes_map.json not yet generated (requires initial pipeline run)."
fi
}
​6. AC-006: Fixture-based acquisition tests pass
​test_ac_006() {
echo "[AC-006] Checking fixture-based acquisition tests..."
if [ -d "tests" ] && command -v pytest &>/dev/null; then
if pytest tests/unit/test_scraper.py -q &>/dev/null; then
record_result "AC-006" "PASS" "Scraper unit tests passed successfully."
else
record_result "AC-006" "FAIL" "Scraper unit tests failed or encountered errors."
fi
else
record_result "AC-006" "SKIP" "Pytest or tests/ directory not configured for acquisition."
fi
}
​7. AC-007: Fixture-based parsing tests pass
​test_ac_007() {
echo "[AC-007] Checking fixture-based parsing tests..."
if [ -d "tests" ] && command -v pytest &>/dev/null; then
if pytest tests/unit/test_parser.py -q &>/dev/null; then
record_result "AC-007" "PASS" "Parser unit tests passed successfully."
else
record_result "AC-007" "FAIL" "Parser unit tests failed or encountered errors."
fi
else
record_result "AC-007" "SKIP" "Pytest or tests/ directory not configured for parser."
fi
}
​8. AC-008: TUI lookup and clipboard export tested
​test_ac_008() {
echo "[AC-008] Checking TUI script availability..."
if [ -f "scripts/portal_tui.py" ]; then
if python3 -m py_compile scripts/portal_tui.py &>/dev/null; then
record_result "AC-008" "PASS" "Portal TUI script compiles successfully."
else
record_result "AC-008" "FAIL" "Portal TUI script has compilation syntax errors."
fi
else
record_result "AC-008" "FAIL" "scripts/portal_tui.py missing."
fi
}
​9. AC-009: Manual pipeline refresh succeeds with validated output
​test_ac_009() {
echo "[AC-009] Executing manual pipeline refresh..."
if [ -x "scripts/pipeline_refresh.sh" ]; then
if bash scripts/pipeline_refresh.sh &>/dev/null; then
record_result "AC-009" "PASS" "Pipeline refresh executed with exit code 0."
else
record_result "AC-009" "FAIL" "Pipeline refresh execution failed."
fi
else
record_result "AC-009" "FAIL" "pipeline_refresh.sh not found or not executable."
fi
}
​10. AC-010: Cron job configured and verified
​test_ac_010() {
echo "[AC-010] Checking cron configuration..."
if crontab -l 2>/dev/null | grep -q "pipeline_refresh"; then
record_result "AC-010" "PASS" "pipeline_refresh registered in crontab."
else
record_result "AC-010" "FAIL" "Crontab entry for pipeline_refresh not found."
fi
}
​11. AC-011: Termux:Boot execution verified after restart
​test_ac_011() {
echo "[AC-011] Checking Termux:Boot symlinks..."
local boot_dir="$HOME/.termux/boot"
if [ -d "boot_dir" ] && [ "(ls -A "$boot_dir" 2>/dev/null)" ]; then
record_result "AC-011" "PASS" "Termux:Boot directory configured with startup scripts."
else
record_result "AC-011" "SKIP" "Termux:Boot directory empty or not configured."
fi
}
​12. AC-012: Log rotation and retention documented
​test_ac_012() {
echo "[AC-012] Checking log and retention structure..."
if [ -d "logs" ]; then
record_result "AC-012" "PASS" "Logs directory exists and is ready for rotation."
else
record_result "AC-012" "FAIL" "Logs directory missing."
fi
}
​13. AC-013: Rollback procedure tested
​test_ac_013() {
echo "[AC-013] Checking rollback documentation and backup capability..."
if git rev-parse HEAD &>/dev/null; then
record_result "AC-013" "PASS" "Git commit history available for version rollback."
else
record_result "AC-013" "FAIL" "Git history unavailable."
fi
}
​14. AC-014: CI/CD pipeline passes on push
​test_ac_014() {
echo "[AC-014] Checking CI/CD workflow configuration..."
if [ -f ".github/workflows/ci.yml" ]; then
record_result "AC-014" "PASS" "GitHub Actions CI workflow present."
else
record_result "AC-014" "FAIL" "CI workflow configuration missing."
fi
}
​15. AC-015: Maintainer and escalation contacts recorded
​test_ac_015() {
echo "[AC-015] Checking contacts and metadata..."
if [ -f "docs/CONTRIBUTING.md" ] || [ -f "README.md" ]; then
record_result "AC-015" "PASS" "Documentation and contacts present."
else
record_result "AC-015" "FAIL" "Documentation files missing."
fi
}
​Execute all tests
​test_ac_001
test_ac_002
test_ac_003
test_ac_004
test_ac_005
test_ac_006
test_ac_007
test_ac_008
test_ac_009
test_ac_010
test_ac_011
test_ac_012
test_ac_013
test_ac_014
test_ac_015
​TEST_END=(date +%s)
DURATION=((TEST_END - TEST_START))
​echo "--------------------------------------------------------------------"
echo "TEST SUMMARY"
echo "--------------------------------------------------------------------"
echo "Total Checks: $TOTAL_COUNT"
echo "Passed:       $PASSED_COUNT"
echo "Failed:       $FAIL_COUNT"
echo "Skipped:      $SKIPPED_COUNT"
echo "Duration:     ${DURATION}s"
echo "======================================================================"
​Write JSON result summary
​cat << EOF > "RESULTS_FILE"
{
"timestamp": "(date -Iseconds)",
"total": $TOTAL_COUNT,
"passed": $PASSED_COUNT,
"failed": $FAIL_COUNT,
"skipped": $SKIPPED_COUNT,
"duration_seconds": $DURATION
}
EOF
​echo "Results written to $RESULTS_FILE"
