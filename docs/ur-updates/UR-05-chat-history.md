# UR-05: Talk to any agent (updated — chat history persistence added)

**Description:** Switch between agents from the chat interface — pick Albert, Steve, Steinar, or Siri and have a direct conversation with that specific agent. Chat history persists across page reloads and devices.

**Rationale:** Different questions go to different agents. Financial questions go to Steinar, health questions go to Siri. Thomas shouldn't have to ask Albert to relay — he should talk directly. Chat history is agent knowledge — it belongs with the agent on campus, synced across the mesh.

**Fit criteria:**
1. An agent picker shows all available agents. Selecting one connects within 10 seconds.
2. If the agent is unreachable, the picker shows an error within 15 seconds.
3. Messages go to that agent and responses come back from that agent.
4. Switching agents preserves chat history in the current browser session.
5. Chat history persists to `thul-agents/agents/{role}/chats/{date}.md` — one file per day, markdown with metadata (timestamp, from, message).
6. Reloading the page or switching devices shows the last 50 messages.
7. History older than 30 days is pruned automatically.
8. Campus is synced across machines (git pull) before agent spawn.

**Origin:** Thomas Ulleberg, March 2026. Chat history persistence decided during Volere Agentic Framework discovery — chat is agent knowledge, belongs on campus.

**Depends on:** Campus sync mechanism (roster.yaml already requires this).
