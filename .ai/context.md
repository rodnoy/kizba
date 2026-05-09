# Files Retrieved
1. `.ai/plan.md` (current) - Overwritten with a micro-plan for wiring `discovery` into `AppEnvironment` + `UserDefaultsSettingsStore` in `live()`. 3 tasks only.
2. `.ai/plan.md` (at eaefd6b) - Original full MVP 1 plan with 9 phases (0–9), ~40 steps.
3. `.ai/step.md` - Current step: `8.3`.
4. `.ai/handoff.md` - Last completed: step 7.4 (Diagnostics), then 8.1 (UserDefaultsSettingsStore) was done out of order.
5. `.ai/decisions.md` - 29 durable design decisions (architecture, security, concurrency, etc.).

# Key Structures
- **Original plan phases:** P0 skeleton → P1 domain → P2 mock+UI → P3 shell → P4 PassCLI → P5 discovery → P6 scanner → P7 clipboard → P8 settings+diagnostics → P9 polish+security.
- **Current plan.md** is a tactical micro-plan (3 tasks) for wiring `discovery` into `AppEnvironment` and replacing `InMemorySettingsStore` with `UserDefaultsSettingsStore` in `live()`. This is Phase 8 scope work.
- **Step counter:** 8.3 (SettingsView/SettingsModel per original plan's 8.3).

# Architecture
The current micro-plan addresses Phase 8.3 scope: wiring settings and discovery into the app environment and KizbaApp. Phase 8.1 (UserDefaultsSettingsStore) and 8.4 (Diagnostics) are already done per handoff.md.

# Plan Comparison: eaefd6b (original) vs current

## Differences
1. **Current plan.md was completely replaced** with a narrow 3-task micro-plan focused on `AppEnvironment.discovery` wiring + `UserDefaultsSettingsStore` in `live()`. The original full 9-phase plan is gone from the file.
2. The original plan is the authoritative roadmap; the current file is a tactical execution plan for a sub-step.
3. No structural or goal changes — the micro-plan implements a subset of original Phase 8.

## Phase 8 Status
- 8.1 `UserDefaultsSettingsStore` — **DONE** (per handoff.md)
- 8.2 `UserDefaultsSettingsStoreTests` — **DONE** (committed with 8.1)
- 8.3 `SettingsView`/`SettingsModel` — **IN PROGRESS** (current step per step.md; micro-plan covers wiring)
- 8.4 `DiagnosticsView`/`DiagnosticsModel` + `InvocationLog` — **DONE** (per handoff.md, step 7.4)
- 8.5 Error-to-UI mapping — **NOT STARTED**

## Phase 9 Readiness
**Not ready for Phase 9.** Phase 8.3 is in progress and 8.5 (error-to-UI mapping) is not started.

## Phase 9 Top 3 Tasks (from original plan)
1. **9.1** Gate `MockPassManager` behind `#if DEBUG`; release binary contains no fixture passwords (`strings` grep test).
2. **9.2** `SecurityChecklistTests` — no `print` in `Kizba/`; no Codable on `PassSecret`; no CustomStringConvertible on `PassSecret`; SettingsStoring allow-list enforced.
3. **9.3** `Kizba.entitlements` — Hardened Runtime; document notarization commands in README.

# Recommended Starting Point
Complete the current micro-plan (Tasks 1–3 in current plan.md) to finish step 8.3, then proceed to 8.5 (error-to-UI mapping) before entering Phase 9.

# Risks / Unknowns
1. The original full plan was overwritten — only exists at commit eaefd6b. Consider restoring it or keeping a reference.
2. Step numbering mismatch: handoff.md mentions "7.5" as next but step.md says "8.3". The handoff note explains the discrepancy (Phase 8 numbering vs working counter).
3. Phase 8.5 (error-to-UI mapping) scope is significant and must be done before Phase 9.
