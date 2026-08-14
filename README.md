# Project Tracker — DevOps Junior Challenge

A simple full-stack app (frontend + API + database), containerized and
deployed on GCP with Terraform, with CI/CD automatically triggered by
tags.

The app itself — a "Project Tracker" for a software factory managing
projects for several clients — isn't what's being evaluated here: it's
just the vehicle for the infrastructure work.

**Deployed URLs:**
- Frontend: https://robin-frontend-5dxtaqilsq-uc.a.run.app
- Backend: https://robin-backend-5dxtaqilsq-uc.a.run.app

> These URLs are taken down (`terraform destroy`) once the evaluation is
> confirmed. See "Running it locally" to try it without depending on
> them staying up.

---

## Architecture

```mermaid
flowchart TB
    Internet((Internet))

    subgraph GCP["GCP — robin-project-tracker project"]
        subgraph VPC["Private VPC (robin-vpc)"]
            Backend["Cloud Run: backend<br/>(Direct VPC Egress)"]
            DB[("Cloud SQL Postgres<br/>Private IP")]
            Backend -->|"Private IP, no<br/>public access"| DB
        end
        Frontend["Cloud Run: frontend<br/>(public, no VPC access)"]
        SM["Secret Manager<br/>(DB password)"]
        AR["Artifact Registry<br/>(images)"]
        CB["Cloud Build<br/>(2 triggers, tag-based)"]

        SM -.->|injects password| Backend
        CB -->|build + push| AR
        AR -->|deploy| Backend
        AR -->|deploy| Frontend
    end

    GitHub["GitHub<br/>(push tag vX.Y.Z)"]

    Internet -->|HTTPS| Frontend
    Internet -->|HTTPS| Backend
    Frontend -->|fetch API| Backend
    GitHub -->|triggers| CB
```

**Data flow:** the browser talks directly to the frontend (React, served
by nginx) and directly to the backend (Node/Express) via its public URL
— the frontend does a client-side `fetch` to the backend. The backend is
the only component with access to the database, via **Direct VPC
Egress** (no separate connector), and the DB only has a private IP, with
no exposure to the internet.

**CI/CD flow:** a push of tag `vX.Y.Z` triggers the build, push to
Artifact Registry, and deploy to Cloud Run for both services.

---

## Stack

| Layer | Technology |
|---|---|
| Frontend | React + Vite, served in production with nginx |
| Backend | Node.js + Express, `pg` for Postgres |
| Database | Cloud SQL (Postgres 15), private IP |
| Infrastructure | Terraform Cloud (VCS-driven), GCP |
| Compute | Cloud Run (2 services: frontend, backend) |
| CI/CD | Cloud Build, 2 tag-triggered triggers |
| Secrets | Secret Manager (DB password) |

---

## Running it locally

Requires Docker and pnpm (or `corepack enable` to get it via Node 20+).

```bash
git clone https://github.com/willy9461/robin-devops-challenge.git
cd robin-devops-challenge
docker compose up --build
```

This spins up the backend and a local Postgres instance. The frontend
runs separately in dev mode (hot-reload):

```bash
cd frontend
pnpm install
pnpm dev
```

Open `http://localhost:5173`.

---

## Decisions and why

### A single repo, no modules published to an external Registry
The 5 Terraform modules (`networking`, `service-accounts`, `database`,
`cloud-run`, `cloudbuild-trigger`) live as folders inside
`terraform/modules/`, in the same repo as the app. Publishing them to a
module Registry only pays off when several different teams or projects
are going to consume them as an external dependency — here there's a
single consumer (this same repo), so adding that layer would be
complexity without real benefit.

### A single VCS-driven Terraform Cloud workspace
All 5 modules run in a single workspace connected via VCS to the repo.
References between modules (`module.networking.network_id`, etc.)
resolve automatically within the same `apply`, with no need to copy
outputs by hand between separate workspaces.

### A single deploy Service Account
The workspace runs with a single SA (`terraform-deployer`), with the
minimal union of roles each module needs. Since the whole `apply` runs
in a single authenticated session, splitting that identity into several
per-module SAs wouldn't add real isolation (they'd all end up being used
together in the same run) — it would just add more credentials to
manage with no real security gain.

There **are 2 separate runtime SAs** (`app-backend`, `app-frontend`) —
each Cloud Run service runs with its own identity in production, and the
frontend has no role granting access to the database or Secret Manager,
because it never needs them. There, separation does make sense: these
are identities running in production, exposed to real traffic.

### Direct VPC Egress instead of a Serverless VPC Access Connector
The backend reaches the VPC (and from there, Cloud SQL) using Direct VPC
Egress in the Cloud Run service configuration, with no separate
connector. It's the pattern currently recommended by GCP for this use
case: one less resource to provision and maintain, same result.

### Tag-triggered CI/CD
The pipeline is triggered by a tag push (`vX.Y.Z`) on a commit already
merged into `main`, rather than on every direct push. It separates
"integrated code" from "published version," giving an explicit checkpoint
before each release.

### Git flow: branch → PR → merge → tag
Every change (app code, each Terraform fix) was made on a separate
branch, with a Pull Request into `main`, and only once that commit was
merged was the tag created that triggers the actual deploy.

### DB password via Secret Manager
The Cloud SQL password is generated with `random_password`, stored in
Secret Manager, and injected into the backend on Cloud Run via
`secret_env_vars` — it's never in plain text in any environment variable
or in the code.

---

## What I'd improve with more time

- **`FRONTEND_ORIGIN` circular dependency resolved by hand:** the
  frontend URL doesn't exist yet when the backend is created on the
  first `apply` (Cloud Run generates the URL after creating the
  service), so the backend's CORS restriction is left without that
  specific origin until a second `apply`. With more time, I'd solve this
  with a fixed domain (via a Load Balancer) instead of depending on
  Cloud Run's autogenerated URL.
- **Workload Identity Federation instead of a JSON key:** the deploy SA
  uses a JSON key pasted as a sensitive variable in Terraform Cloud. WIF
  would avoid having any long-lived credential floating around.
- **A dedicated SA for Cloud Build, separate from the runtime SAs:**
  right now `app-backend` and `app-frontend` run both the build and the
  service's runtime — it works because the roles overlap only slightly,
  but separating "who builds" from "who runs in production" would be
  cleaner.
- **Auto-apply enabled:** for now every `apply` in Terraform Cloud
  requires manual confirmation, useful while iterating and debugging
  errors; in a mature flow I'd turn it on.
- **Automated tests** (none for now, given the 48h scope) and a test
  step in the CI pipeline before deploy.
- **Cloud SQL backups:** deliberately disabled for this challenge's
  scope; in a real environment I'd enable them.

---

## AI usage

I used Claude (Anthropic) throughout practically the whole build:
designing the backend and frontend, writing the Terraform modules,
debugging real `apply` errors against the GCP API, and organizing the
git flow. I document the most significant points here.

### What I asked it for, step by step
- Generate the backend skeleton and code (Express + Postgres) and the
  frontend (React + Vite) from scratch, including multi-stage
  Dockerfiles.
- Design and write the 5 Terraform modules (networking,
  service-accounts, database, cloud-run, cloudbuild-trigger) and the
  root module connecting them.
- Debug, in real time, every error from the first real `apply` against
  GCP (see cases below) — reading logs, forming hypotheses, verifying
  them against the GCP console before applying a fix.
- Walk me step by step through terminal commands (git, gh CLI, Terraform
  CLI) and through the GCP/Terraform Cloud web console, since I was
  executing everything myself on my machine.

### A decisive prompt
After the first failed `apply`, I shared the error exactly as Terraform
Cloud returned it:

> "Error: Error creating Trigger: googleapi: Error 400: Request contains
> an invalid argument.
> with module.cloudbuild_trigger.google_cloudbuild_trigger.backend
> on modules/cloudbuild-trigger/main.tf line 24, in resource
> "google_cloudbuild_trigger" "backend": [...]"

The API's message didn't carry any more detail about which field exactly
was failing. Sharing the full error, without summarizing or
interpreting it, made it possible to rule out a first hypothesis (a
`location` issue) and then diagnose the real cause by manually recreating
a trigger from the GCP console, which does validate field by field
before sending the request — the console flagged "Service account" as
required, something the API/Terraform never stated explicitly.

### What I did with what it gave me
I used most of the code as-is, after running `terraform validate` (and,
for the first draft, a Python HCL parser) before every real `apply`.
When something failed against the real GCP API, I asked for the
specific fix, validated it again, and applied it through the same
branch+PR+tag flow as the rest of the code — I never applied a fix
"blindly" without at least one verifiable hypothesis about the cause.

### Cases where the AI got something wrong or fell short, and how it was solved
These are the 4 real cases, in the order they happened:

**1. pnpm version incompatible with Node.** `packageManager:
pnpm@11.21.0` was pinned in the backend without checking compatibility
with the Dockerfile's base image (`node:20-alpine`). The build failed
inside the container: pnpm 11 requires Node ≥22.13. It was caught from
the Docker build log, and fixed by pinning `pnpm@10.5.2` (the version I
already had locally), compatible with Node 20.

**2. Missing explicit dependency in the `database` module.** The first
real `apply` failed with *"the network doesn't have at least 1 private
services connection"* while creating the Cloud SQL instance. The AI had
written the `database` module without an explicit `depends_on` toward
`networking`: Terraform only detects automatic dependencies when one
resource directly references another, and the Cloud SQL instance only
referenced the VPC (`network_id`), not the peering connection itself
(`google_service_networking_connection`), which is a separate resource
within the same module. This **passed every prior validation** (syntax,
`terraform validate`, even the `plan` showed "25 to add" with no
errors) — it only surfaced on the real `apply`. Fixed with
`depends_on = [module.networking]` at the module level.

**3. Invalid `location` on the Cloud Build triggers.** The `apply`
failed with a generic API error (*"Error 400: Request contains an
invalid argument"*, no specific detail). The AI had set
`location = var.region` on both triggers, copying the regional pattern
used for the rest of the resources — but triggers connected via the
classic GitHub App (1st gen) only live at `location = global`. Diagnosed
by manually recreating a test trigger from the GCP console (which does
validate field by field before sending the request), and fixed by
removing `location` from both triggers.

**4. Missing explicit `service_account` and `logging` on the triggers.**
After the previous fix, the `apply` kept failing with the same generic
error. Diagnosed again the same way (a manual test trigger in the
console), which revealed a new required field: the
organization/project requires an explicit Service Account to run each
build (Google changed Cloud Build's default behavior in mid-2024,
dropping the automatic legacy SA). After adding `service_account`, a
second related requirement showed up: with a custom SA, you also have to
explicitly specify where the build logs go
(`options { logging = "CLOUD_LOGGING_ONLY" }`). Neither requirement
showed up in syntax validation or in the `plan` — they only surfaced as
real failures on builds that had already been triggered.

The common pattern across all 4 cases: the AI generated code that was
syntactically valid and passed `terraform plan` with no errors, but with
incorrect assumptions about the real behavior of the GCP API — errors
that only surface on the real `apply`/build against live infrastructure,
not through static inspection of the code.

### A decision made without AI
When it came to creating resources in GCP (project, APIs, Service
Accounts), the AI suggested installing the `gcloud` CLI to speed up
several steps that were going to repeat. I decided not to install it and
to do everything through the GCP web console instead — I didn't want to
add a new tool to my environment just to save a few clicks, preferring a
slower step with no extra dependencies to manage after the challenge.

I also decided, without the AI suggesting it, to switch to pnpm as the
package manager across the whole project — it's the one I prefer to use
— and to keep the repo **private** throughout development, following the
branch+PR flow by discipline instead of with automatic protection, and
sharing access via collaborator only once it was time to submit.

---

## Cleanup after the evaluation

```bash
cd terraform
terraform destroy
```

Will notify once the project is taken down and the URLs stop being
available.
