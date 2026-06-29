# GitHub Copilot CLI - Skills & Agents Inventory

**Generated:** 2026-06-29  
**CLI Version:** 1.0.65  
**Repository:** Tucker-Gilligan/dot  
**Model:** claude-haiku-4.5

> Project skills live in `.github/skills/`. Builtin skills/agents ship with the
> Copilot CLI and are not stored in this repo. Keep this list in sync with
> `.github/skills/` when you add or remove a skill.

---

## 📋 Table of Contents

1. [Skills](#skills)
2. [How to Use Skills](#how-to-use-skills)
3. [Agent Types](#agent-types)
4. [Core Tools Available](#core-tools-available)
5. [Commands & Workflows](#commands--workflows)
6. [Stack Evaluation](#stack-evaluation)

---

## 🎯 Skills

Skills enhance your capabilities for specific workflows.

### Project Skills (maintained in this repo)

These live in `.github/skills/` and are symlinked into every workspace via `install.sh`.

#### 1. **commit-pr-writer**
- **Description:** Generate conventional-commit messages for staged changes or structured PR descriptions
- **Use Case:** When asked to write a commit message, draft a PR description, or summarize changes for review
- **Location:** project
- **Features:**
  - Reads repo's PR standards (PULL_REQUEST_TEMPLATE.md, CONTRIBUTING.md)
  - Fills real template matching repo's commit style
  - Prompts for missing information

#### 2. **commit-prep**
- **Description:** Pre-commit self-check for the work you're about to commit on the current branch
- **Use Case:** Right before `git commit` — validate that staged changes are coherent, atomic, and risk-free
- **Location:** project
- **Features:**
  - Runs a diff digest on the staged changes
  - Scans for risk and produces a numbered in-code walkthrough
  - Confirms the change is atomic (not bundling unrelated work)
  - Drafts the commit message via `commit-pr-writer`
  - Commit-scoped sibling of `/pr-prep` (one commit, not a whole branch)

#### 3. **diff-digest**
- **Description:** Produce token-efficient digest of pending git changes with automated risk-pattern scanning
- **Use Case:** Before code review, preparing a PR, or when analyzing "what's risky in my diff"
- **Location:** project
- **Features:**
  - Shows stat, changed files, full diff
  - Automated risk scan: debug leftovers, secrets, removed auth, raw SQL, destructive migrations, oversized changes
  - Pairs with `/pr-prep` skill

#### 4. **pr-prep**
- **Description:** Pre-review your own branch before requesting code review
- **Use Case:** Self-review workflow before submitting changes
- **Location:** project
- **Features:**
  - Runs diff digest
  - Automated risk scan
  - Produces walkthrough with numbered comments
  - Runs Socratic understanding check
  - Drafts PR description from repo template

#### 5. **pr-review**
- **Description:** Review someone else's PR with structured, severity-ranked comments
- **Use Case:** Code review on peer branches
- **Location:** project
- **Features:**
  - Same risk scan as `/pr-prep`
  - File-by-file comments
  - Surfaces auth/PII/migration concerns

#### 6. **scout**
- **Description:** Research across large or multi-repo surface (read-only)
- **Use Case:** Large-scale codebase exploration and research
- **Location:** project
- **Features:**
  - Searches first, reads on budget
  - Returns findings with file/line references

### Builtin Skills (ship with the Copilot CLI)

Not stored in this repo and not managed by `install.sh` — they come bundled with the
Copilot CLI and are available automatically.

#### **customize-cloud-agent**
- **Description:** Customize Copilot cloud agent environment
- **Use Case:** Configuration of copilot-setup-steps.yml, preinstalling tools, runners, and settings
- **Location:** builtin
- **Features:**
  - Manage cloud agent environment
  - Configure dependencies and tools
  - Mentioned when user says "copilot-setup-steps" or wants to configure the cloud agent

---

## 🚀 How to Use Skills

You don't have to memorize anything. There are **three ways** to use a skill — pick whichever feels natural.

### 1. Just ask (easiest — skills auto-activate)
Describe what you want in plain English. The model reads each skill's description and pulls in the right one automatically.

> "Can you check my changes before I push?" → runs **pr-prep**
> "What's risky in my diff?" → runs **diff-digest**
> "Write me a commit message" → runs **commit-pr-writer**

### 2. Slash command (explicit — when you know what you want)
Type `/` followed by the skill name. This forces that specific skill to run.

```
/pr-prep
/pr-review https://github.com/owner/repo/pull/123
/scout where is the auth middleware defined
/commit-pr-writer main
/diff-digest
```

Many skills take an optional argument (a base branch, a PR URL, a question). If you omit it, the skill asks or uses a sensible default — you're never stuck.

### 3. Name it directly
If you'd rather be explicit in a sentence, just say the skill's name:

> "Use the **scout** skill to find every error handler."
> "Run **diff-digest** on my staged changes."

### Quick reference — what to say → what runs

| When you want to… | Say something like… | Skill |
| --- | --- | --- |
| Self-check what you're about to commit | "check what I'm committing" / `/commit-prep` | **commit-prep** |
| Self-review your branch before a PR | "prep my PR" / `/pr-prep` | **pr-prep** |
| Review someone else's PR | "review this PR" / `/pr-review <url>` | **pr-review** |
| See what changed & what's risky | "what's risky in my diff" / `/diff-digest` | **diff-digest** |
| Write a commit message or PR description | "write a commit message" / `/commit-pr-writer` | **commit-pr-writer** |
| Research across the codebase | "where is X" / `/scout <question>` | **scout** |
| Configure the cloud agent | "set up copilot-setup-steps" | **customize-cloud-agent** |

### Good to know
- **No setup per request.** Skills are always available in every workspace (symlinked via `install.sh`) — nothing to import or enable.
- **Optional arguments are optional.** Leave them off and the skill prompts you or picks a default.
- **Skills can chain.** For example, `/pr-prep` automatically uses **diff-digest** and **commit-pr-writer** under the hood — you only call the top-level one.
- **Not sure which to use?** Just describe the goal; the model routes to the right skill (or tells you none fits).

---

## 🤖 Agent Types

These specialized agents autonomously handle complex tasks with dedicated tools and context windows:

### Built-in Agents

#### 1. **explore**
- **Model:** Haiku
- **Purpose:** Fast codebase exploration and research
- **Use When:**
  - Tasks decompose into many independent research threads
  - Analyzing multiple services/modules in parallel
  - Complex cross-cutting investigations across many modules
- **Tools:** grep, glob, view, bash, powershell
- **Performance:** Best for parallel research threads

#### 2. **task**
- **Model:** Haiku
- **Purpose:** Execute commands with verbose output
- **Use When:**
  - Running tests, builds, lints, dependency installs
  - Need success/failure status, not verbose output
- **Tools:** All CLI tools
- **Output:** Brief summary on success, full output on failure

#### 3. **general-purpose**
- **Model:** Sonnet (Claude 3.5 Sonnet)
- **Purpose:** Full-capability agent for complex multi-step tasks
- **Use When:**
  - Complex multi-step tasks requiring complete toolset
  - High-quality reasoning needed
  - Want to keep main context clean
- **Tools:** All CLI tools
- **Context:** Separate context window

#### 4. **rubber-duck**
- **Model:** Default
- **Purpose:** High-signal feedback on plans and implementations
- **Use When:**
  - Need feedback on architectural decisions
  - Want to catch bugs and logic errors
- **Features:**
  - Catches bugs, logic errors, design flaws
  - Won't comment on style/formatting
  - Expects complete context

#### 5. **code-review**
- **Model:** Default
- **Purpose:** Review code changes (high signal-to-noise)
- **Use When:**
  - Reviewing your own staged changes
  - Analyzing branch diffs
- **Features:**
  - Analyzes staged/unstaged changes
  - Only surfaces genuine issues (bugs, security, logic)
  - Won't modify code
  - Same risk scan as pr-review skill
- **Note:** Won't comment on style/formatting

#### 6. **security-review**
- **Model:** Default
- **Purpose:** Security-focused code review
- **Use When:**
  - Need to identify security vulnerabilities
  - Scanning for injection, auth, crypto issues, etc.
- **Features:**
  - Analyzes 11 security categories
  - Minimizes false positives (>80% confidence threshold)
  - Reports with severity (CRITICAL/HIGH/MEDIUM/LOW) and confidence
  - Won't modify code
- **Tools:** All CLI tools for investigation

#### 7. **research**
- **Model:** Default
- **Purpose:** Thorough searches across GitHub repos
- **Use When:**
  - Need deep research and verification
- **Features:**
  - Searches GitHub repos
  - Fetches files
  - Verifies claims
  - Reports with citations

### Custom Agents

#### **main**
- **Description:** Unified Copilot agent with intelligent routing to skills and inline code execution
- **Capabilities:** Full integration with skills and inline execution

---

## 🛠 Core Tools Available

### File & Search Tools
- **grep** - Fast code search using ripgrep (supports multiline, context, case-insensitive)
- **glob** - File pattern matching with wildcards
- **view** - View files/directories (parallel safe, truncated at 20KB)
- **edit** - String replacement in files (batch-safe, supports multiple edits)
- **create** - Create new files

### Execution Tools
- **bash** - Run shell commands (sync/async modes, background processes, detach support)
- **read_bash** - Read output from background bash sessions
- **stop_bash** - Stop running bash commands
- **list_bash** - List all active bash sessions

### Git & GitHub Tools
- **gh** CLI - Native GitHub operations (recommended over MCP tools)
- **git** - Version control commands

### Code Intelligence
- **sql** - SQLite queries (session database, todos/todo_deps tables available)
- **session_store_sql** - Read-only queries across session history (DuckDB)

### Specialized Tools
- **web_fetch** - Fetch URLs and convert to markdown/HTML
- **ask_user** - Interactive user questions with choices/freeform
- **skill** - Invoke available skills by name
