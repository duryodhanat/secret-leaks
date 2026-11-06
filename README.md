# Secret Leaks Test Repository

A sandbox repository designed to test, validate, and verify **Betterleaks Secret Scanning** before rolling out to organization private repositories.

## ??? Security Architecture

1. **Shift-Left Pre-Commit Hook:** Intercepts `git commit` on local developer workstations and stops secrets from entering Git history.
2. **GitHub Actions CI Pipeline:** Automatically triggers on every `push` and `pull_request` across all branches (`**`). On this public repository, findings are automatically published to the **Security > Code scanning alerts** tab via SARIF.
3. **Branch Protection:** Protects `main` branch by enforcing status checks before PR merging.

## ?? Quick Setup for Developers

To activate the pre-commit hook in your local clone:

- **Windows PowerShell:**
  ```powershell
  .\scripts\setup-hooks.ps1
  ```
- **macOS / Linux / Git Bash:**
  ```bash
  ./scripts/setup-hooks.sh
  ```
- **Or native Git command:**
  ```bash
  git config core.hooksPath .githooks
  ```

## ?? Testing Secret Scanning

1. Try staging a fake secret:
   ```bash
   git add secret.txt
   git commit -m "test: committing fake secret"
   ```
2. Observe the hook blocking the commit with line number and file path.
3. Push to a feature branch to see GitHub Actions fail the check and block the PR.
