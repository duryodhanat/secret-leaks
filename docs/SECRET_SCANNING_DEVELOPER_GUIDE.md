# Developer Guide: Secret Scanning with Betterleaks & GitHub Actions

Welcome to the **Secret Scanning Developer Guide**. This repository implements pre-commit secret detection and Continuous Integration (CI) secret scanning powered by [Betterleaks](https://github.com/betterleaks/betterleaks) — a high-performance, open-source secret scanner designed as the next-generation evolution of Gitleaks.

---

## Table of Contents
1. [Why Secret Scanning (Shift-Left Security)](#1-why-secret-scanning-shift-left-security)
2. [Prerequisites: Installing Betterleaks CLI](#2-prerequisites-installing-betterleaks-cli)
3. [Setting Up Local Pre-Commit Hooks](#3-setting-up-local-pre-commit-hooks)
   - [Method A: Native Git Hooks (Recommended - Zero Python dependencies)](#method-a-native-git-hooks-recommended---zero-python-dependencies)
   - [Method B: Python pre-commit Framework](#method-b-python-pre-commit-framework)
4. [How the Hook Runs During `git commit`](#4-how-the-hook-runs-during-git-commit)
5. [Testing the Setup (Safe Verification)](#5-testing-the-setup-safe-verification)
6. [Handling False Positives & Test Fixtures](#6-handling-false-positives--test-fixtures)
7. [GitHub Actions CI Pipeline](#7-github-actions-ci-pipeline)
8. [Future Roadmap: Adding CodeQL SAST Analysis](#8-future-roadmap-adding-codeql-sast-analysis)

---

## 1. Why Secret Scanning (Shift-Left Security)

Once an API key, private token, or database password is committed to a Git repository, it is **permanently embedded in the Git commit history**. Even if you commit an update removing the key in the very next commit, the credential remains accessible in historical commits, commit diffs, and cloned forks. Removing it requires rewriting Git history (`git filter-repo`), which is disruptive to entire teams and requires rotating the compromised credential.

**Shift-Left Security** means catching and blocking secrets locally on the developer's workstation *before* the commit object is created:

```
Developer Workspace
        │
        ▼
   `git add` (Files staged)
        │
        ▼
   `git commit` ──────► [Pre-Commit Hook: Betterleaks scans staged changes]
                              │
                    ┌─────────┴─────────┐
                    ▼                   ▼
             [Secret Found]       [No Secrets]
             Commit Aborted       Commit Allowed
             (Secret Never Enters         │
              Git History)                ▼
                                  `git push` to GitHub
                                          │
                                          ▼
                                  [GitHub Actions CI:
                                   Betterleaks + Code Scanning]
```

---

## 2. Prerequisites: Installing Betterleaks CLI

To run the local pre-commit hook, developers need the `betterleaks` binary in their system `PATH`.

### macOS (Homebrew)
```bash
brew install betterleaks
```

### Linux
```bash
BETTERLEAKS_VERSION="1.9.0"
curl -sSfL "https://github.com/betterleaks/betterleaks/releases/download/v${BETTERLEAKS_VERSION}/betterleaks_${BETTERLEAKS_VERSION}_linux_x64.tar.gz" | tar -xz
sudo mv betterleaks /usr/local/bin/
```

### Windows
You can install Betterleaks using **Scoop** or by downloading the binary release:

**Using Scoop:**
```powershell
scoop install betterleaks
```

**Using Direct Binary Download:**
1. Visit the [Betterleaks Releases page](https://github.com/betterleaks/betterleaks/releases).
2. Download the Windows `.zip` archive (e.g., `betterleaks_windows_x64.zip`).
3. Extract `betterleaks.exe` and place it in a folder included in your `PATH` (such as `C:\Program Files\betterleaks\` or your user binaries folder).

### Verify Installation
In your terminal or PowerShell, run:
```bash
betterleaks --version
```

---

## 3. Setting Up Local Pre-Commit Hooks

We provide two seamless ways to activate the pre-commit hook. Choose the one that best suits your workflow:

### Method A: Native Git Hooks (Recommended - Zero Python dependencies)

This repository includes a version-controlled `.githooks/` directory containing our pre-commit scanning script. You only need to run one command once to tell Git to use it:

#### One-Step Automated Setup:
* **macOS / Linux / Git Bash:**
  ```bash
  ./scripts/setup-hooks.sh
  ```
* **Windows (PowerShell):**
  ```powershell
  .\scripts\setup-hooks.ps1
  ```

#### Or Run the Git Command Manually:
```bash
git config core.hooksPath .githooks
```

*That's it!* Git will now automatically run `.githooks/pre-commit` before every commit.

---

### Method B: Python `pre-commit` Framework

If your team already uses the standard Python [pre-commit](https://pre-commit.com/) manager, this repository includes `.pre-commit-config.yaml`.

1. Install `pre-commit`:
   ```bash
   pip install pre-commit
   ```

2. Install the hook into your repository:
   ```bash
   pre-commit install
   ```

3. (Optional) Run against all files manually:
   ```bash
   pre-commit run --all-files
   ```

---

## 4. How the Hook Runs During `git commit`

When the hook is configured, it activates transparently whenever you execute `git commit`:

1. **Stage your files:**
   ```bash
   git add backend/services/auth.py
   ```

2. **Commit your changes:**
   ```bash
   git commit -m "feat: implement token validation"
   ```

3. **Automatic Scan Execution:**
   - The hook invokes `betterleaks git . --staged --config .betterleaks.toml`.
   - Only the changes in your staging area (`git diff --cached`) are scanned. Unstaged edits in your working directory are ignored.
   - Scanning typically completes in less than **100 milliseconds**.

### What happens when no secrets are detected:
```
🔍 [Betterleaks] Scanning staged changes for exposed secrets...
✅ [Betterleaks] No secrets detected. Proceeding with commit.
[feature/auth 2b4c10a] feat: implement token validation
 1 file changed, 14 insertions(+)
```

### What happens when a secret is detected:
```
🔍 [Betterleaks] Scanning staged changes for exposed secrets...

ERR leak detected: RuleID: aws-access-token, File: backend/services/auth.py, Line: 42
❌ [Betterleaks] Potential secret(s) detected in staged changes!
🛑 Commit has been aborted to prevent secrets from entering Git history.

💡 What to do next:
   1. Remove or redact the secret from your staged files.
   2. If it is a confirmed false positive, add '# betterleaks:allow' on that line
      or add the fingerprint to .betterleaksignore
   3. Restage your files ('git add <file>') and commit again.
```

Your commit is **aborted**, and no commit object is generated in your Git log.

---

## 5. Testing the Setup (Safe Verification)

You can easily verify that your local hook is actively protecting your repository:

1. Create a temporary test file with a mock secret:
   ```bash
   echo "MY_SECRET_KEY=ghp_ABC1234567890123456789012345678901234" > test_secret.txt # betterleaks:allow
   ```

2. Stage the file:
   ```bash
   git add test_secret.txt
   ```

3. Attempt to commit:
   ```bash
   git commit -m "test: test pre commit secret scanning"
   ```

4. **Verify the result:** The commit should immediately be blocked by Betterleaks.

5. **Clean up:**
   ```bash
   git rm -f test_secret.txt
   ```

---

## 6. Handling False Positives & Test Fixtures

Sometimes code contains test tokens, high-entropy hashes, or non-sensitive mock variables that resemble secrets. Betterleaks provides 3 ways to handle these:

### 1. Inline Code Comment (Recommended for isolated lines)
Add `# betterleaks:allow` (or `// betterleaks:allow` in JS/TS/Go) to the exact line:
```python
# Harmless dummy mock token for unit testing
TEST_AUTH_TOKEN = "ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"  # betterleaks:allow
```

### 2. Fingerprint Suppression (`.betterleaksignore`)
If Betterleaks flags a finding, it outputs a unique fingerprint. You can add this fingerprint to `.betterleaksignore` at the root of the repository:
```text
# .betterleaksignore
9e2a1b4c7f0d3e5a8b2c1d4e7f0a3b5c6d9e2a1b
```

### 3. Repository Configuration (`.betterleaks.toml`)
Global allowlists for files, directories (like `node_modules/`, lock files), and regex patterns are managed in `.betterleaks.toml`.

---

## 7. GitHub Actions CI Pipeline

Even with local pre-commit hooks, CI enforcement is critical as a second layer of defense (in case a developer used `--no-verify` or cloned into an unconfigured environment).

Our CI workflow is defined in `.github/workflows/secret-scanning.yml`:
* **Triggers:**
  - `push` to **all branches** (`branches: ['**']`)
  - `pull_request` to **all branches** (`branches: ['**']`)
  - `workflow_dispatch` (Manual on-demand trigger)
* **Runner:** `dortort/betterleaks-action@v0.1.0` (Official GitHub Marketplace Action)
* **Smart Scan Mode:**
  - On `push`: scans git commit history with `fetch-depth: 0`.
  - On `pull_request`: scans changes introduced by the pull request.
* **SARIF Integration:**
  - Outputs a native SARIF security report.
  - Automatically uploads findings to GitHub via `github/codeql-action/upload-sarif@v3`.
  - Leaks appear directly under your repository's **Security > Code scanning alerts** tab with detailed line-by-line remediation info.

---

## 8. Future Roadmap: Adding CodeQL SAST Analysis

### Secret Scanning vs CodeQL SAST
- **Secret Scanning (Betterleaks):** Detects hardcoded credentials, API keys, certificates, and private tokens.
- **CodeQL (SAST):** Performs semantic Static Application Security Testing to identify software vulnerabilities such as SQL injection, Cross-Site Scripting (XSS), path traversal, and unsafe deserialization.

### Activating CodeQL in the Future
The workflow file `.github/workflows/secret-scanning.yml` already contains a pre-configured, production-ready CodeQL template. When ready to enable CodeQL:

1. Open `.github/workflows/secret-scanning.yml`.
2. Uncomment the `codeql-analysis` job.
3. Configure the language matrix for your target stacks (e.g. `javascript-typescript`, `python`).
4. Commit and push the updated workflow file.

