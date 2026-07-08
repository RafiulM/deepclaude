# deepclaude Guide

This guide explains what `deepclaude` is, the components it relies on (Claude Code and DeepSeek), and how to install and use it, step by step.

## 1. What is Claude Code

Claude Code is a CLI (also available as a desktop app) built by Anthropic that runs Claude as a *coding agent* directly in your terminal or editor. The difference from a regular chat interface: Claude Code has access to real tools on your machine — reading/writing files, running shell commands, running tests, reading git output, and so on — so it can execute engineering tasks end to end, not just suggest snippets of code.

A few things about Claude Code that matter for deepclaude:

- Claude Code picks up its credentials and API target through environment variables, not only through a `claude.ai` login. The two key variables are `ANTHROPIC_BASE_URL` (the API endpoint it talks to) and `ANTHROPIC_AUTH_TOKEN` (the API key/auth token).
- Claude Code has a "model tier" concept — a default model for heavy tasks (typically mapped to Opus), mid-tier tasks (Sonnet), and light/fast tasks (Haiku) — each of which can be overridden via environment variables (`ANTHROPIC_DEFAULT_OPUS_MODEL`, and so on).
- Because its architecture is built on env vars plus an Anthropic-compatible endpoint, Claude Code can be "redirected" to talk to a different provider as long as that provider exposes an API compatible with the Anthropic format (the Messages API). This is the same principle other harnesses like OpenCode use — everything is built around "base URL + auth token + model name," not locked to a single backend.

## 2. What is DeepSeek and its models

DeepSeek is an AI lab that releases large language models (LLMs), both open-weight and via a commercial API, known for reasoning and coding quality that's competitive with frontier models at a much lower cost. DeepSeek runs its own API at `api.deepseek.com`.

What makes DeepSeek usable directly by Claude Code without an extra proxy: DeepSeek exposes an **Anthropic-compatible endpoint** at `https://api.deepseek.com/anthropic`. This endpoint accepts requests in the Anthropic Messages API format, so any tool that already knows how to talk to Claude (including Claude Code) can be pointed at it just by swapping `ANTHROPIC_BASE_URL` and `ANTHROPIC_AUTH_TOKEN` — no SDK or custom adapter required.

The models `deepclaude` uses by default (per the current configuration in `deepclaude`):

| Claude Code env var | DeepSeek model | Role |
|---|---|---|
| `ANTHROPIC_MODEL` | `deepseek-v4-pro[1m]` | Primary model when `claude` runs |
| `ANTHROPIC_DEFAULT_OPUS_MODEL` | `deepseek-v4-pro[1m]` | Replacement for the "Opus" tier (heavy tasks) |
| `ANTHROPIC_DEFAULT_SONNET_MODEL` | `deepseek-v4-pro[1m]` | Replacement for the "Sonnet" tier (standard tasks) |
| `ANTHROPIC_DEFAULT_HAIKU_MODEL` | `deepseek-v4-flash` | Replacement for the "Haiku" tier (light/fast tasks) |
| `CLAUDE_CODE_SUBAGENT_MODEL` | `deepseek-v4-flash` | Model used by subagents (e.g., results from the `Task`/`Agent` tool) |

`[1m]` denotes the large-context-window variant (1 million tokens) of that pro model. With this mapping, every Claude Code model tier is automatically routed to the DeepSeek model that matches its role (heavy vs. light), without changing how you use Claude Code day to day.

## 3. What is deepclaude

`deepclaude` is a thin shell-script wrapper around the `claude` CLI. It doesn't modify Claude Code itself — it only:

1. Stores and manages your DeepSeek API key locally.
2. *Exports* the required environment variables (base URL, auth token, model mappings) before invoking `claude`.
3. Runs `claude --dangerously-skip-permissions "$@"`, forwarding every argument you passed to `deepclaude`.

Because this is "just" env vars plus an exec, you're still running the genuine `claude` binary already installed on your machine — deepclaude is not a fork or a separate distribution of Claude Code.

> **Note on `--dangerously-skip-permissions`:** this flag makes Claude Code run tools (editing files, running commands, etc.) without asking for per-action confirmation. That's convenient for speed, but it means shell commands and file changes execute immediately without manual approval. Only use `deepclaude` in a directory/project you trust.

## 4. Prerequisites

- Operating system: macOS, Linux, or Windows (native PowerShell, or via Git Bash/WSL).
- `curl` or `wget` installed (for the shell installer).
- **The Claude Code CLI (`claude`) must already be installed** on your PATH. This is a hard prerequisite — deepclaude does not install Claude Code, it only sets env vars and invokes it. Install it first from [docs.claude.com/en/docs/claude-code](https://docs.claude.com/en/docs/claude-code) if you don't have it yet.
- A DeepSeek API key. Create one at [platform.deepseek.com/api_keys](https://platform.deepseek.com/api_keys).

## 5. Step-by-step installation

### macOS / Linux

1. Run the installer:

   ```bash
   curl -fsSL --retry 3 --retry-delay 2 --retry-all-errors https://raw.githubusercontent.com/RafiulM/deepclaude/main/install.sh | bash
   ```

   If GitHub's raw content CDN is rate-limited (`curl: (56) ... 429`), use the jsDelivr mirror instead:

   ```bash
   curl -fsSL https://cdn.jsdelivr.net/gh/RafiulM/deepclaude@main/install.sh | bash
   ```

   This installer script downloads a single `deepclaude` executable to `~/.local/bin/deepclaude` (overridable via the `DEEPCLAUDE_BIN_DIR` env var), then `chmod +x`s it. It also automatically retries and falls back to the mirror if the initial download fails.

2. If `~/.local/bin` isn't on your `PATH` yet, the installer will print the line you need to add to your shell profile (`~/.bashrc` or `~/.zshrc`):

   ```bash
   export PATH="$HOME/.local/bin:$PATH"
   ```

   Add that line, then open a new terminal (or re-`source` your profile).

3. Verify the installation:

   ```bash
   deepclaude --help
   ```

### Windows (PowerShell)

1. Run:

   ```powershell
   irm https://raw.githubusercontent.com/RafiulM/deepclaude/main/install.ps1 | iex
   ```

   This installs `deepclaude` to `%LOCALAPPDATA%\Programs\deepclaude` and adds it to your user `PATH`.

2. **You must open a new terminal** after installation so the `PATH` change takes effect.

3. Alternative: from **Git Bash** or **WSL** on Windows, you can also use the macOS/Linux command above.

## 6. API key configuration

The first time `deepclaude` runs without a stored key, it will prompt for your API key interactively (hidden input, not echoed to the terminal) and save it.

Key resolution order (highest to lowest priority):

1. `deepclaude config <KEY>` — set it directly via argument, no prompt.
2. The stored config file — set on a previous run.
3. The `DEEPSEEK_API_KEY` environment variable — used once, then automatically saved for next time.
4. Interactive prompt — appears automatically if none of the above are available.

Key storage locations:

| Platform | Path | Notes |
|---|---|---|
| macOS/Linux | `~/.config/deepclaude/config` | permissions `600` (owner only) |
| Windows | `%APPDATA%\deepclaude\config` | ACL: your user only |

The key is stored in **plaintext**. Anyone with access to your user account can read it — treat it like any other local credential (don't commit it, don't share your screen with the file open).

## 7. How to use it

Run it directly; all arguments are forwarded as-is to `claude`:

```bash
deepclaude                          # open Claude Code interactively, as usual
deepclaude "refactor this module"   # send a prompt directly
deepclaude --help                   # see the underlying `claude` options
```

What happens behind the scenes every time you run `deepclaude` (assuming the key is already available):

```sh
export ANTHROPIC_BASE_URL="https://api.deepseek.com/anthropic"
export ANTHROPIC_AUTH_TOKEN="<your DeepSeek key>"
export ANTHROPIC_MODEL="deepseek-v4-pro[1m]"
export ANTHROPIC_DEFAULT_OPUS_MODEL="deepseek-v4-pro[1m]"
export ANTHROPIC_DEFAULT_SONNET_MODEL="deepseek-v4-pro[1m]"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="deepseek-v4-flash"
export CLAUDE_CODE_SUBAGENT_MODEL="deepseek-v4-flash"
export CLAUDE_CODE_EFFORT_LEVEL="max"

exec claude --dangerously-skip-permissions "$@"
```

Because this uses `exec`, the `deepclaude` process is replaced directly by the `claude` process — it isn't run as a separate child process.

## 8. Managing your key

```bash
deepclaude change-key            # change the stored key (interactive prompt)
deepclaude change-key <KEY>      # change the key without a prompt
deepclaude reset                 # delete the stored key
```

`config`, `set-key`, and `change` are aliases equivalent to `change-key`.

## 9. Updating deepclaude

```bash
deepclaude update
```

This command re-runs the installer (`install.sh`) to pull the latest version from GitHub, with retry logic and a fallback to the jsDelivr mirror if `raw.githubusercontent.com` is rate-limited.

## 10. Uninstall

**macOS / Linux**

```bash
rm ~/.local/bin/deepclaude
rm -rf ~/.config/deepclaude
```

**Windows (PowerShell)**

```powershell
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\Programs\deepclaude"
Remove-Item -Recurse -Force "$env:APPDATA\deepclaude"
```

## 11. Quick troubleshooting

| Symptom | Common cause | Fix |
|---|---|---|
| `curl: (56) ... 429` during install/update | Rate limiting on `raw.githubusercontent.com` (intermittent, IP-dependent) | The installer now retries automatically and falls back to the jsDelivr mirror — just re-run the same command. If it still fails, use the jsDelivr mirror explicitly (see section 5), or wait a few minutes |
| `claude CLI not found on PATH` | Claude Code isn't installed, or isn't on `PATH` | Install Claude Code from the official docs, and confirm `claude --version` works before using `deepclaude` |
| `No API key available` | No key has ever been stored, and none is set in the environment | Run `deepclaude config <KEY>`, or let the interactive prompt appear on first run |
| `PATH` change not picked up after install | Shell profile hasn't been reloaded | Open a new terminal, or `source ~/.zshrc` / `source ~/.bashrc` |

### On 429 error handling

The current version of `install.sh` has a `fetch()` mechanism that: (1) tries `raw.githubusercontent.com` with `curl --retry 3 --retry-delay 2 --retry-all-errors`, and (2) if that still fails, automatically switches to the `cdn.jsdelivr.net` mirror. The same mechanism is used by `deepclaude update` and the installation one-liner in the README — the bootstrap curl that downloads `install.sh` itself has been given the same retry + jsDelivr fallback, not just the `deepclaude` binary download inside it.

This has been verified directly: by simulating failures against `raw.githubusercontent.com` (including a real case where GitHub genuinely returned `429` during testing), the installation still **succeeded** because it fell back to the jsDelivr mirror automatically. Rate limiting on `raw.githubusercontent.com` is intermittent (it doesn't always happen), so installs sometimes succeed on the very first attempt — this fallback mechanism keeps the install working when the rate limit does show up.

## 12. Conceptual summary

- **Claude Code** = a harness/agent CLI that talks to an Anthropic-style API via `ANTHROPIC_BASE_URL` + `ANTHROPIC_AUTH_TOKEN`.
- **DeepSeek** = an LLM provider with an Anthropic-compatible endpoint at `api.deepseek.com/anthropic`, letting it "pose" as a Claude backend with no extra proxy required.
- **deepclaude** = a thin wrapper that manages your DeepSeek key and points `claude` at that DeepSeek endpoint via env vars, then `exec`s `claude` — there's no additional AI logic inside it, purely routing configuration.
