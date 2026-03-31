# SPRINT 4 : VERCEL AI SDK INTEGRATION

Build the Case Workspace Chat interface.

TASKS:
* Install @ai-sdk/react.
* Build the <WorkspaceChat /> component using the useChat hook to handle streaming, auto-scroll, and markdown rendering.
* Build the Next.js API Route (app/api/chat/route.ts).

BACKEND LOGIC:
* The API route must extract the tenantId from the user session.
* Look up the correct OpenClaw container URL for this tenant (e.g., http://openclaw-tenant-a:18789).
* Proxy the chat request to the OpenClaw Gateway using the Gateway WebSocket API or its OpenAI-compatible HTTP endpoints.
* Ensure the prompt asks OpenClaw to analyze the context of the specific caseId.
