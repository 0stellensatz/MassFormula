# Codex integration

Run `python3 .codex/__sync__.py` after changing `.mcp.json` or `.claude/settings.json`; `--check` detects stale generated configuration. The generated files are owned by this script. Keep personal Codex settings in your user configuration.

Open Codex in this project's working copy and trust the project to load the Lean MCP server. Restart the client after adding the configuration, then verify the connection with `/mcp`. The server uses the same `uvx lean-lsp-mcp` command as the Claude configuration.

Review and trust the generated completion hook through `/hooks`. It runs the shared structural checker at every Stop, including after shell or patch edits, without relying on Claude's edit markers. A failure asks the agent to continue and repair it; the existing `stop_hook_active` escape permits a subsequent stop. This is a completion aid; CI remains independent enforcement.

See the official [MCP configuration](https://learn.chatgpt.com/docs/extend/mcp?surface=cli) and [hook documentation](https://learn.chatgpt.com/docs/hooks) for client setup and trust behavior.
