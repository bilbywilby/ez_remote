# Project Handover: ez_remote (v1.0.0-beta)

* **Generated At:** 2026-10-13T03:45:00Z
* **Technical Lead:** Carter (`bilbywilby`)
* **Target Platform:** Android / Termux
* **Primary Language:** Python 3.11+
* **Status Assessment:** Production Ready Pending Validation

---

## 1. Project Overview & Repository Configuration

`ez_remote` is an automated IR code acquisition, parsing, and management pipeline designed to run natively on Android via Termux. It scrapes external IR code databases, validates payloads against strict Pydantic schemas, and provides both a terminal user interface (TUI) and scheduled background execution.

### Repository Details
* **Repository Name:** `ez_remote`
* **SSH URL:** `git@github.com:bilbywilby/ez_remote.git`
* **HTTPS URL:** `https://github.com/bilbywilby/ez_remote`
* **Default Branch:** `main`
* **Working Directory:** `$HOME/ez_remote`

### Clone & Setup Commands
```bash
git clone git@github.com:bilbywilby/ez_remote.git
cd ez_remote
git checkout main
git remote -v
```

---

## 2. Directory Structure & Core Components

```text
$HOME/ez_remote/
├── src/
│   ├── robust_gather_ir.py         # IR code acquisition scraper (Production)
│   └── source_registry.json        # Configurable source registry (Needs Customization)
├── scripts/
│   ├── parse_ir_intelligence_v3.py # Intelligence parser and data structurer (Production)
│   ├── pipeline_refresh.sh         # Unified refresh wrapper for cron/Termux:Boot (Executable)
│   ├── portal_tui.py               # Interactive IR code lookup TUI with clipboard export (Optional)
│   └── sync_repo.sh                # Repository synchronization utility (Executable)
├── remote_intelligence/
│   ├── raw/                        # Raw acquisition feeds (Git ignored, 7-day retention)
│   └── data/                       # Processed codes_map.json (Schema v3.0)
├── logs/                           # Pipeline and application logs (Weekly rotation, 30 days)
├── tests/                          # Unit and integration tests with fixtures
├── .github/workflows/              # CI/CD pipelines (ci.yml)
└── documentation/                  # Project documentation (README, CONTRIBUTING, SECURITY, CHANGELOG)
```

### Core Components Summary
1. **Acquisition Scraper (`src/robust_gather_ir.py`):** Loads source registry, fetches IR data with exponential backoff, validates response codes, and outputs `remote_intelligence/raw/latest_feed.json`.
2. **Intelligence Parser (`scripts/parse_ir_intelligence_v3.py`):** Reads the raw feed, normalizes protocols, validates against Schema v3.0, and writes `remote_intelligence/data/codes_map.json`.
3. **Pipeline Refresh Wrapper (`scripts/pipeline_refresh.sh`):** Orchestrates scraper and parser execution sequentially with pre-flight checks, safe error handling, and robust logging.
4. **Portal TUI (`scripts/portal_tui.py`):** Rich-powered interactive terminal interface for searching IR codes, viewing statistics, and exporting to the Termux clipboard (`termux-clipboard-set`).

---

## 3. Deployment & Environment Configuration

### Environment Requirements
* **OS:** Android (Termux $\ge$ 0.118.0, Android API Level $\ge$ 24)
* **Runtime:** Python 3.11+, Bash 5.x
* **Required System Packages:** `git`, `python`, `cronie`, `termux-services`, `coreutils`
* **Python Dependencies:** `pydantic>=2.0.0`, `requests>=2.31.0`, `rich>=13.0.0`, `pytest>=8.0.0`

### Automated Scheduling
* **Cron Job:** Configured to run every 2 hours (`0 */2 * * *`). Managed via `termux-services` (`sv up crond`).
* **Termux:Boot:** Automated startup via symlink in `~/.termux/boot/` to restore background execution after device reboots.

---

## 4. Data Contracts & Schemas

### Raw Feed Schema (`remote_intelligence/raw/latest_feed.json`)
* **Sources:** Array of objects containing `name` (string), `success` (boolean), `status_code` (integer, optional), and `error_message` (string, optional).
* **Metadata:** `timestamp` (ISO 8601), `total_sources` (integer), `successful` (integer).

### Codes Map Schema v3.0 (`remote_intelligence/data/codes_map.json`)
* **Version:** Must match pattern `^3\.`.
* **Status:** `validated`, `empty`, `no_input`, or `error`.
* **Mappings:** Array of entries containing non-empty `brand`, `model`, `codes` (array of integers, length $\ge 1$), `protocol` (e.g., `NEC`, `RC5`), and optional `revision`.

---

## 5. Known Risks & Mitigations

| Risk ID | Title | Category | Severity | Summary & Mitigation |
| :--- | :--- | :--- | :--- | :--- |
| **R-001** | Scraper Target Changes or Blocks Requests | Acquisition | High | Monitor logs for HTTP 403/429; maintain fallback sources and user-agent rotation. |
| **R-002** | Parser Produces Empty Output | Parsing | Critical | Parser enforces strict fail-on-empty checks when sources are configured. |
| **R-003** | Termux Runtime Changes After Updates | Infrastructure | High | Use absolute paths in all scripts and re-validate cron wrappers post-update. |
| **R-004** | Storage Exhaustion from Raw Data Growth | Infrastructure | High | Enforce 7-day raw retention and 30-day log rotation with automated cleanup. |
| **R-005** | Git Repository Contamination | Version Control | Medium | Strict `.gitignore` rules for node modules and temporary build artifacts. |
| **R-006** | Dependency Vulnerabilities | Security | Medium | Monthly Dependabot updates and CI security scanning via `bandit` and `safety`. |
| **R-007** | SSH Credential Exposure | Security | Critical | Zero secrets in source files or git history; quarterly key rotation. |

---

## 6. Action Items & Acceptance Checklist

### Immediate Handover Actions (HA-001 to HA-007)
* **HA-001 (P1):** Inspect repository and replace UNVERIFIED status fields with evidence (Deadline: 2026-10-20).
* **HA-002 (P1):** Document actual branch, commit, runtime versions, and dependencies (Deadline: 2026-10-15).
* **HA-003 (P1):** Confirm functional vs. placeholder status for acquisition and parser (Deadline: 2026-10-15).
* **HA-004 (P1):** Define `codes_map.json` data governance and update policy (Deadline: 2026-10-16).
* **HA-005 (P2):** Test log/raw-data retention, storage monitoring, and recovery procedures (Deadline: 2026-10-25).
* **HA-006 (P1):** Review dependency vulnerabilities and SSH credential exposure risks (Deadline: 2026-10-18).
* **HA-007 (P2):** Execute fixture-based test suite and achieve $>80\%$ code coverage (Deadline: 2026-10-22).

### Acceptance Checklist Summary
* Total Items: 15
* Completed: 0 / 15 (Pending team validation)
* Blocking Items: 6 (AC-002, AC-003, AC-004, AC-005, AC-009, AC-014)

---

## 7. Operational Procedures & Rollback

### Manual Pipeline Refresh
```bash
bash ~/ez_remote/scripts/pipeline_refresh.sh
```
* **Pre-flight Checks:** Verify working directory is `$HOME/ez_remote`, `python3` is available, and `logs/` directory has write permissions.
* **Success Criteria:** Exit code `0`, successful log completion, and a non-empty `codes_map.json`.

### Rollback Procedure
1. Record current commit: `git rev-parse HEAD`
2. Backup last known-good output: `cp remote_intelligence/data/codes_map.json remote_intelligence/data/codes_map.backup.$(date +%Y%m%d)`
3. Revert code state: `git checkout <previous_good_commit>`
4. Restore data map: `cp remote_intelligence/data/codes_map.backup.* remote_intelligence/data/codes_map.json`
