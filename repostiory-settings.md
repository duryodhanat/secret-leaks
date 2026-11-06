# GitHub Repository Configuration & Branch Protection Guide

This guide details the required GitHub repository settings to enforce automated secret scanning via **Betterleaks**, enable SARIF security alerts, and configure branch protection rules so that pull requests containing secrets **cannot be merged into `main`**.

---

## 📋 Table of Contents
1. [GitHub Actions Permissions](#1-github-actions-permissions)
2. [Code Security & Analysis (GHAS / SARIF Upload)](#2-code-security--analysis-ghas--sarif-upload)
3. [Branch Protection Rules (Merge Gate Enforcement)](#3-branch-protection-rules-merge-gate-enforcement)
4. [How Merge Blocking Works in Practice](#4-how-merge-blocking-works-in-practice)
5. [Administrative Checklist](#5-administrative-checklist)

---

## 1. GitHub Actions Permissions

Ensure GitHub Actions has the necessary execution and token privileges:

1. In your GitHub repository, navigate to:  
   **Settings** → **Actions** → **General**
2. **Actions permissions:**  
   Select **"Allow all actions and reusable workflows"** (default on most repositories).
3. **Workflow permissions:**  
   - Select **"Read repository contents and package permissions"** (or "Read and write permissions").
   - *Note:* The workflow explicitly defines its own granular permissions (`contents: read`, `security-events: write`), so the default setting will work correctly.
4. Click **Save**.

---

## 2. Code Security & Analysis (GHAS / SARIF Upload)

The workflow generates SARIF reports (`betterleaks.sarif`) and uploads them directly to your repository's **Security** tab using `github/codeql-action/upload-sarif`.

1. In your GitHub repository, navigate to:  
   **Settings** → **Code security and analysis**
2. **Public Repositories:**  
   Code scanning and SARIF uploads are **100% free** and enabled by default.
3. **Private Repositories:**  
   - SARIF upload to the Security tab requires **GitHub Advanced Security (GHAS)** to be enabled.
   - Under *GitHub Advanced Security*, click **Enable**.
   > 💡 **Note:** If your organization does not have GHAS on a private repo, the workflow will still run and fail the CI check (blocking the PR), but the optional SARIF upload step can be removed or skipped.

---

## 3. Branch Protection Rules (Merge Gate Enforcement)

> [!IMPORTANT]
> This is the crucial setting that **physically locks the Merge button** whenever Betterleaks detects a secret. Without this rule, PR merges can still be manually executed even if the CI check fails.

### Step-by-Step Setup:

1. In your GitHub repository, navigate to:  
   **Settings** → **Branches**
2. Under **Branch protection rules**, click **Add rule** (or edit the existing rule for `main`).
3. In **Branch name pattern**, enter:
   ```text
   main
   ```
4. Configure the following protection checkboxes:

| Setting | Recommended Value | Purpose |
|---|---|---|
| **Require a pull request before merging** | ✅ **Enabled** | Prevents direct pushes to `main`; all code must go through a PR and peer review. |
| **Require approvals** | ✅ **Enabled** (1 approval) | Ensures at least one team member or lead approves the PR. |
| **Require status checks to pass before merging** | ✅ **Enabled** | Enforces that CI checks must pass green before the PR can be merged. |
| **Require branches to be up to date before merging** | ✅ **Enabled** | Guarantees the PR code has been tested against the latest `main` commit. |
| **Status checks search bar** | Search: **`Betterleaks secret scan`** | Select the exact job name from the workflow. *(Note: This check name appears in the search dropdown only after the workflow has run at least once).* |
| **Do not allow bypassing the above settings** | ✅ **Enabled** | Enforces rules strictly for **everyone** — even repository Admins and Team Leads cannot accidentally force-merge a failing PR. |

5. Click **Save changes** (or **Create**).

---

## 4. How Merge Blocking Works in Practice

When developers raise pull requests against `main`, GitHub evaluates the checks automatically:

```
Developer raises Pull Request
               │
               ▼
   [Betterleaks Secret Scan Runs]
               │
      ┌────────┴────────┐
      ▼                 ▼
[✅ No Secrets]   [❌ Secret Detected]
      │                 │
CI Status: GREEN   CI Status: RED
Merge Button:      Merge Button:
🟢 ENABLED         🔒 DISABLED / LOCKED
```

### Scenario 1: Clean Pull Request (Pass)
* Betterleaks finds 0 leaks.
* Check status: `✅ Betterleaks secret scan — Successful in 45s`.
* Reviewer approves → Green **"Merge pull request"** button is active.

### Scenario 2: Compromised Pull Request (Fail)
* Developer accidentally commits a token, password, or key.
* Betterleaks detects the credential and exits with code `1`.
* Check status: `❌ Betterleaks secret scan — Failed`.
* GitHub disables the **"Merge pull request"** button:
  > *"Required status check 'Betterleaks secret scan' was not successful. Merging can be performed automatically once the required conditions are met."*
* The PR author must remove the credential before the PR can be merged.

---

## 5. Administrative Checklist

Use this quick checklist to confirm repository configuration:

- [ ] GitHub Actions enabled (`Settings` → `Actions` → `General`).
- [ ] Workflow file present (`.github/workflows/secret-scanning.yml`).
- [ ] Workflow has run at least once on any branch (to register the check name).
- [ ] Branch protection rule created for `main`.
- [ ] **"Require status checks to pass before merging"** is active.
- [ ] **`Betterleaks secret scan`** is selected as a required check.
- [ ] **"Do not allow bypassing the above settings"** is active (blocks admin force-merge).
