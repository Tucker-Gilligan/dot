---
name: edtech-integrations
description: Background knowledge for building and reviewing common ed-tech integrations — LTI 1.3 (LMS tools), SSO/rostering (SAML, OAuth, Clever, ClassLink, Google Classroom), and rostering data standards (OneRoster, Ed-Fi). Load automatically when a change involves an LMS, SSO/login, rostering/SIS sync, or grade passback so the work respects these protocols' constraints and privacy expectations.
user-invocable: false
---

# Ed-tech integrations — background knowledge

> This is reference knowledge that loads when relevant. Replace the `<!-- repo: ... -->` notes
> with how *this* codebase actually does each integration so agents follow your real patterns.

## LTI 1.3 / LTI Advantage (launching tools inside an LMS)
- Auth is **OIDC third-party-initiated login + signed JWT** launch; validate the `iss`, `aud`, `nonce`, and signature against the platform's JWKS. Never trust launch claims without verifying the signature.
- **Advantage services**: Names & Role Provisioning Services (NRPS) for rosters; Assignment & Grade Services (AGS) for grade passback; Deep Linking for content selection.
- Store platform/client registrations securely; rotate keys. Treat `sub` as the stable user id per platform; don't leak ids across tenants.
- <!-- repo: where launches are handled, where registrations live -->

## SSO / authentication
- **SAML 2.0** (common with districts): validate signatures, `Audience`, `NotBefore/NotOnOrAfter`, and replay; map assertions to roles carefully.
- **OAuth/OIDC** (Google, Microsoft): validate `aud`/`iss`/expiry; request least-scope; handle Google Classroom domain restrictions.
- **Clever / ClassLink**: SSO + rostering; tokens are district-scoped — enforce tenant isolation so one district can't see another's data.
- <!-- repo: auth entry points, session/role mapping -->

## Rostering / SIS sync
- **OneRoster (1.1 / 1.2)**: CSV bulk and REST; core entities orgs → academicSessions → classes → enrollments → users. Handle incremental sync (`dateLastModified`), soft-deletes (`status: tobedeleted`), and idempotency.
- **Ed-Fi**: data standard + API some states/districts use; richer model than OneRoster.
- Sync is **eventually consistent and partial** — never assume a full, clean dataset. Plan for missing fields, duplicate ids across sources, and mid-sync states.
- <!-- repo: how/when rostering sync runs, source of truth, conflict resolution -->

## Grade passback
- Via LTI AGS (line items + scores) or LMS-specific APIs. Scores must map to the right line item and respect the platform's scale; passback is async and can fail silently — log and reconcile.

## Cross-cutting rules
- **Tenant isolation is non-negotiable**: every integration is multi-tenant (district/school). Always scope queries by tenant; never let an id from one tenant resolve in another.
- **Privacy**: integration data is student PII/education records — pair changes here with the Security Reviewer (FERPA/COPPA). Minimize what you pull and store; honor deletion.
- **Resilience**: external systems are flaky and rate-limited. Use retries with backoff, idempotency keys, and graceful degradation; never block a student login on a slow downstream sync.
- **Seasonality**: rostering and logins spike hard at term start — design sync and auth paths for peak, not average.

## When using this knowledge
Verify against the actual spec version the integration targets and the repo's existing
implementation before writing code. Flag anywhere a change could cross tenant boundaries or
broaden what student data is shared.
