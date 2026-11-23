# Ballerina A2A agents on WSO2 Agent Manager

Two [A2A](https://a2a-protocol.org/) 1.0 agents built with [`ballerina/a2a`](https://central.ballerina.io/ballerina/a2a)
0.8.0, laid out the way WSO2 Agent Manager hosts an **A2A Agent**: one port (9090), the agent card at
`/.well-known/agent-card.json`, and HTTP+JSON under `/rest` (where `a2a:RestListener` serves it by default).
The Agent Manager gateway does the authentication, so the listeners have none.

| Agent | Path | What it does |
|---|---|---|
| Weather Agent | `weather/` | Scripted forecasts for a few cities; asks which city when none is named. No model. |
| Trip Planner Agent | `trip-planner/` | Claude-backed day-trip planner; asks which city when none is named. Needs `ANTHROPIC_API_KEY`. |

Both build with their `Dockerfile` (Ballerina 2201.14; the platform's Ballerina buildpack supports 2201.13 only).

```bash
amctl agent create weather --subtype a2a-agent --port 9090 \
  --repo-url https://github.com/Anuja-jayasinghe/ballerina-a2a-agents-on-agent-manager \
  --repo-branch main --repo-path weather --build-type docker --dockerfile Dockerfile
```

Call them with any A2A 1.0 client through the gateway, for example Ballerina's `ai:A2aToolKit`:

```ballerina
final ai:A2aToolKit weather = check new ("<invoke-url>", headers = {"X-API-Key": apiKey});
```

Not supported here: JSON-RPC under `/rpc` (`ballerina/a2a` 0.8.0 has no JSON-RPC listener).
