# SPRINT 1 : NEXT.JS SETUP & PRISMA SCHEMA

We are starting from an empty directory. Your tasks:
* Initialize a Next.js 15 project with TypeScript, Tailwind, and App Router.
* Initialize Prisma ORM.
* Write the complete schema.prisma for our legal SaaS.

SCHEMA REQUIREMENTS:
* Tenant (Law firm).
* User (Lawyer, linked to Tenant).
* Case (Legal matter, linked to Tenant).
* Document (Files uploaded to a Case).
* Message & AuditLog (For AI chat and tracking actions).
* AI_Job (For tracking BullMQ background tasks).

CONSTRAINT: Every table (except Tenant) MUST have a tenantId for strict data isolation. Provide the terminal commands and the full schema.prisma code. Do not write UI code yet.
