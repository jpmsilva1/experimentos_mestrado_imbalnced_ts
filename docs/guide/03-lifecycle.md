## 3. The Experiment Lifecycle: From Pending to Done

Every experiment goes through exactly these stages. The status badge in each experiment's `README.md` must always reflect the current stage.

```
                  ┌──────────────────────────────────────────────────────┐
                  │                                                      │
    ⚪ Pending ──→ 🔵 Setup ──→ 🟡 In Progress ──→ 🟢 Done              │
                                      │                                  │
                                      └──────────────────→ 🔴 Blocked   │
                                                                         │
                  └──────────────────────────────────────────────────────┘
```

### Stage Definitions

| Badge | Stage | What it means | When to set it |
|-------|-------|---------------|----------------|
| ⚪ | **Pending** | Folder exists, no work started | Default state for all 17 experiments |
| 🔵 | **Setup** | Environment is working | After: code is in `src/original/`, dependencies are installed, and the code runs without import errors |
| 🟡 | **In Progress** | Actively producing results | After: first successful end-to-end run, target results identified |
| 🟢 | **Done** | Replication complete | After: key results match the paper (within tolerance), README comparison table is filled, REPLICATION_LOG is complete |
| 🔴 | **Blocked** | Cannot proceed | When: broken deps, missing data, or unresolvable errors — **always document the blocker** |

> **How to change the status:** Open the experiment's `README.md` and change the line that says:
> ```
> ## Replication Status: ⚪ Pending
> ```
> to the appropriate badge. Then run `python3 scripts/update_readme.py` to propagate the change to the main dashboard.

---
