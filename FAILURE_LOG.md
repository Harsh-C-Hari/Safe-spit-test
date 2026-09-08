# FAILURE_LOG.md — SAFE//SPIT

> **Status:** PLANNED (new). Template for documenting every meaningful failure discovered during the reference build. The first real entry is created when the first real failure happens.
> **Cross-references:** `update.ai/CURRENT_STATUS.md` "What is broken" section, `update.ai/DECISIONS.md` for any decision that results from a failure, `BUILD-MANIFEST.md` for the build that experienced the failure.

## Format

Each failure is recorded in this format:

```
### F-NN: <title>
- Date: YYYY-MM-DD
- Device: <model + Android version>
- Build: <commit hash or build label>
- Feature: <which feature>
- Expected: <what should have happened>
- Actual: <what happened>
- Cause: <root cause>
- Fix: <how it was fixed, or "not fixed">
- Regression test: <test that now covers this>
- Status: <open | fixed | wontfix>
```

## Entries

(none yet — the reference build has not started)
