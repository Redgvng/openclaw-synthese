# SPRINT 2 : DOCKER COMPOSE & AI WORKERS

Generate the docker-compose.yml file to run our local infrastructure.

REQUIREMENTS:
* Shared Services: Include PostgreSQL 16 and Redis 7.
* Tenant AI Workers: Define two sample OpenClaw containers (openclaw-tenant-a and openclaw-tenant-b).
* Security Constraints:
  * The OpenClaw containers must use the official Node 24 environment.
  * Apply deploy.resources.limits with 2GB of RAM minimum per OpenClaw container.
  * Set environment variables to bind to 127.0.0.1 and require an OPENCLAW_GATEWAY_TOKEN.
* Configuration: Generate a bash script or Node script to auto-generate the openclaw.json file for these tenants, ensuring compaction.memoryFlush is enabled.

Provide the docker-compose.yml and the configuration script.
