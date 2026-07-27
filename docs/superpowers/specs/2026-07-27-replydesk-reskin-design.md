# ReplyDesk — Product Reskin (for Meta App Review + demo)

**Date:** 2026-07-27
**Scope:** UI/UX reskin only. No routes/controllers/models/jobs/`MetaGraphClient` behavior changes, except one new **read-only** Automations page (route + thin controller + view).
**Goal:** Make the app read as a real product ("ReplyDesk"), not a Facebook API debug console, so a Meta reviewer / boss understands what it does and what to do next.

## Problem
Every screen leads with "Flow N", exposes webhook endpoints, raw JSON, PSIDs, permission-name badges, and "Screencast Testing" token inputs. Users can't tell what the product is or what to do.

## Product framing
ReplyDesk — "Connect your Facebook & Instagram pages, auto-answer common questions, and hand off tricky ones to a human."

## Navigation (maps onto existing pages)
| Nav | Purpose | Backed by |
|---|---|---|
| Home | Setup status + next steps | `dashboard` (rewritten) |
| Inbox | Conversations + "Needs a human" tickets (2 tabs) | `profiles/inbox` + `orders/tickets` |
| Automations | Auto-reply rules (FAQ + IG DM) — read-only | NEW `automations#index` over `FaqEntry` |
| Connections | Connect/manage pages + Instagram | `onboarding/connect` + `instagram/accounts` |
| Activity | Event log | `webhook_logs` |

## Per-screen changes
- **Home:** friendly welcome; if no connected page → prominent "Connect your first page" CTA; else cards to Inbox/Automations + a compact stats row. Remove "5 flows / reviewer" copy.
- **Connections:** "Connect a Facebook Page" with real OAuth button as primary path. Connected-pages table stays (Instagram link action folded in here).
- **Inbox:** two tabs — *Conversations* (profile roster) and *Needs a human* (tickets + reply form). "PSID" → "Customer"; raw JSON history → collapsible "View history".
- **Automations:** list FAQ rules (Q → A) and the IG brand/creator auto-replies as configured rules.
- **Activity:** human-readable event names; keep clear-log action.
- **Sign-in:** keep "Continue with Facebook"; drop reviewer copy from primary view.

## Debug-gating (keeps local testing, cleans the review build)
Anything a real user wouldn't see is wrapped in `<% if Rails.env.development? %>`:
manual token inputs (sessions, onboarding), raw JSON dumps (inbox), webhook endpoint paths, permission-name badges, PSIDs shown raw.
Result: production/review build is clean; `bin/dev` locally still shows the token/JSON shortcuts.

## Non-goals
Accounts/multi-tenant, editable automations, billing, merged single-inbox controller, any backend/API change.

## Files touched
`app/views/layouts/application.html.erb` (nav + a few utility styles), `dashboard/index`, `onboarding/connect/index`, `profiles/inbox/index`, `orders/tickets/index`, `instagram/accounts/index`, `webhook_logs/index`, `sessions/new`; NEW `automations_controller.rb` + `automations/index.html.erb` + one route.
