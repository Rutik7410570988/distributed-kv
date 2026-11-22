# AGENTS.md — Distributed KV Store (C++20)

## Project mission
Build a **distributed, fault-tolerant key-value database** from first principles in **C++20**. This is a learning-first systems engineering project, not a code-generation race. The developer studies concepts in ChatGPT and MIT 6.5840 / a modern C++ course, then uses Codex to implement, test, debug, and review one milestone at a time.

The target system supports `PUT`, `GET`, and `DELETE`; a three-node Raft-replicated cluster; durable state; snapshots/log compaction; failure testing; and, in later milestones, sharding, benchmarks, Docker, and observability.

**Status:** This file describes the intended roadmap, **not features already implemented**. Inspect the repository before claiming anything exists or works.

## Technology choices
- Language: C++20; standard library first, explicit dependencies only when justified.
- Editor: VS Code; preferred runtime: Linux or WSL2 Ubuntu.
- Build: CMake, out-of-source builds (`build/`).
- Tests: GoogleTest when introduced; CTest integration.
- Networking: raw TCP sockets for node-to-node traffic; start with POSIX sockets on Linux. Define framing and request IDs explicitly. A client-facing HTTP/REST gateway is optional and comes later.
- Storage: in-memory `std::unordered_map` initially; append-only WAL and crash recovery, then snapshots/compaction; integrate Raft's durable log carefully rather than duplicating conflicting sources of truth.
- Consensus: Raft (leader election, log replication, commit/application, persistence, snapshot installation).
- Packaging/operations: Git, Docker Compose, structured logs; metrics and dashboards only in later milestones.
- Do **not** add RocksDB, gRPC, Kubernetes, complex frameworks, or dynamic membership by default.

## Architecture target (conceptual)
```text
Client / CLI (optional HTTP gateway later)
             |
        KV service API
             |
       Raft replicated state machine
        /       |       \
     Node 1   Node 2   Node 3
       |        |        |
   durable Raft logs + snapshots
```
A Raft group replicates a state machine; **each node owns its own durable storage**. Sharding later means multiple independent Raft groups, not merely hashing client requests among individual Raft replicas.

## Collaboration contract
1. **Stay inside the active milestone.** If the user has not identified it, inspect `docs/progress.md` or ask. Never silently jump to Raft or sharding.
2. **Teach as you implement.** Before substantial edits, briefly explain the concept, planned files, and why the approach fits. After edits, explain non-obvious C++ and distributed-systems decisions in plain language.
3. **Inspect before changing.** Read the existing structure, `CMakeLists.txt`, tests, and progress notes. Preserve established interfaces and user work.
4. **Small, reviewable changes.** Prefer one feature and its tests per iteration. Avoid wholesale rewrites and unrelated refactors.
5. **Never fabricate results.** Run available builds/tests; report exact commands and outcomes. If unable to run, say why. Do not invent benchmarks, fault tolerance, or production-readiness.
6. **No hidden shortcuts.** Do not replace requested custom TCP/Raft implementations with third-party libraries unless the user approves. Do not copy MIT Go solutions mechanically.
7. **Ask before major tradeoffs.** Seek approval for new dependencies, wire-format changes, persistence-format changes, architectural shifts, or scope expansion.
8. **Keep code understandable.** Prefer explicit ownership, RAII, bounded resource usage, clear error handling, and straightforward interfaces over cleverness.
9. **Respect learning checkpoints.** After each stage, ask the developer to explain key concepts or walk through important functions before moving forward.
10. **Do not assume prior chat context is available to Codex.** This file, repository documentation, and code are the shared source of truth.

## Correctness and safety requirements
- Use RAII for file descriptors, sockets, locks, and other resources; avoid leaks and undefined behavior.
- Handle partial TCP reads/writes, disconnects, invalid input, message size limits, and timeouts; TCP is a byte stream, not a message protocol.
- Ensure thread safety and avoid data races; document lock ownership/order. Prefer simple synchronization before optimization.
- Define durability guarantees precisely (append, flush/fsync, acknowledgment timing, crash recovery). Do not equate buffered writes with durable commits.
- Test truncated/corrupt log tails and interrupted snapshot writes before claiming crash safety.
- For Raft, preserve its safety invariants: at most one leader per term, term/vote persistence, log matching, leader completeness, majority-based commitment, and ordered exactly-once **application of each committed log index**. Client retry deduplication is a separate feature and must be designed explicitly.
- Acknowledge successful writes only according to the documented consistency/durability contract. Reads advertised as linearizable require a valid Raft read protocol; a follower's local read is not automatically linearizable.
- With three voting nodes, a majority is two; losing the majority must prevent new commits. Never claim the cluster remains writable with only one node alive.
- Partition tests must guard against split-brain and stale reads, not merely verify eventual recovery.
- Treat network messages and on-disk files as untrusted inputs. Validate lengths, checksums (when defined), versions, and bounds.

## Milestone roadmap
Use **one Project chat per milestone**. The following IDs are the canonical sequence for this repository:

| ID | Learn | Build / acceptance target |
|---|---|---|
| M0 | KV concepts, distributed-system goals, tradeoffs | Architecture notes, scope, environment decisions |
| M1 | Modern C++20, STL, RAII, ownership, CMake | Small exercises, CMake starter, optional HashMap exercise |
| M2 | Hash tables, APIs, complexity | In-memory KV with PUT/GET/DELETE and tests |
| M3 | Threads, mutexes, shared_mutex, condition variables | Thread-safe KV and concurrency tests |
| M4 | TCP/IP, sockets, client/server lifecycle | TCP echo server, then networked KV client/server |
| M5 | Serialization, framing, protocol versioning | Robust request/response protocol and malformed-input tests |
| M6 | Disk I/O, WAL, durability, recovery | Single-node persistent KV with restart tests |
| M7 | Snapshots, compaction, atomic replacement | Single-node snapshot + replay recovery tests |
| M8 | Failure models, CAP, linearizability, quorum | Design notes and small distributed-systems simulations |
| M9 | Leader/follower replication and limitations | Educational replication prototype, explicitly **not Raft** |
| M10 | Raft terms, elections, RPCs, logs, commits | Raft module with deterministic protocol tests |
| M11 | Replicated state machines, client semantics | Three-node Raft-backed KV; document read/write guarantees |
| M12 | Durable Raft state, snapshot installation | Restart-safe Raft log and snapshot/compaction integration |
| M13 | Leader crashes, partitions, retries, recovery | Automated fault-injection and recovery tests |
| M14 | Sharding, hash distribution, multiple Raft groups | Static sharding first; reconfiguration only if explicitly scoped |
| M15 | Latency, throughput, p50/p95/p99 | Reproducible load benchmarks and bottleneck analysis |
| M16 | Unit/integration/stress testing | CI-ready test suite and reliability checks |
| M17 | Containers and multi-process deployment | Reproducible Docker Compose cluster |
| M18 | Logs, health, metrics | Structured logs, metrics, optional Prometheus/Grafana |
| M19 | Documentation, demo, review | End-to-end demo, architecture, limitations, reproducible results |

**Sequencing note:** M6–M7 are educational single-node storage exercises; M12 integrates persistence with Raft's replicated log. Do not assume single-node WAL design can be reused unchanged as the Raft log. Optional TTL, caching, HTTP gateway, and dynamic membership require explicit scope decisions and are not prerequisites to M19.

## Suggested repository layout
Create folders only when needed; do not scaffold every future component on day one.
```text
distributed-kv/
├── AGENTS.md
├── README.md
├── CMakeLists.txt
├── include/
├── src/
├── tests/
├── docs/
│   ├── architecture.md
│   ├── roadmap.md
│   ├── progress.md
│   └── milestones/
├── config/
└── scripts/
```

## Coding conventions
- Prefer `namespace dkv` (or the repository's existing namespace), meaningful names, and `.hpp`/`.cpp` separation where useful.
- Keep headers minimal; use `const` correctness, `std::optional`/typed results where appropriate, and explicit error paths.
- No raw owning pointers; prefer stack ownership, `std::unique_ptr`, and RAII wrappers.
- No detached background threads without a documented lifecycle and shutdown path.
- Keep networking, Raft, storage, and KV state-machine layers separable for deterministic testing.
- Avoid sleeps as the primary synchronization mechanism in tests; inject clocks/transports or use bounded waits when practical.
- Prefer reproducible tests over nondeterministic manual-only demonstrations.

## Standard development loop
1. Read the active milestone and current repository state.
2. State the objective and acceptance criteria in 3–6 concise sentences.
3. Implement the smallest working increment.
4. Add focused unit tests and at least one failure/edge case where relevant.
5. Configure and build using CMake, run CTest, and fix regressions.
6. Summarize changed files, commands run, observed outcomes, remaining limitations, and next learning checkpoint.
7. Update `docs/progress.md` and `docs/milestones/MXX.md` when the milestone is completed.

Typical commands (adapt to the actual repository):
```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build -j
ctest --test-dir build --output-on-failure
```

## Milestone completion template
Record in `docs/milestones/MXX.md`:
```markdown
# MXX — Title
Status: Complete / In progress / Blocked

## Concepts learned
## Implemented files and behavior
## Design decisions and tradeoffs
## Build and test commands + actual results
## Known bugs / limitations
## Questions I can now explain
## Next milestone prerequisites
```
Update `docs/progress.md` with the active milestone, verified completion status, and immediate next task. **Never mark a milestone complete just because code was generated.**

## Starting instructions for Codex
When asked to begin a milestone, respond with:
- What the developer will learn.
- What code will be written **in this milestone only**.
- Acceptance tests and expected behavior.
- The first small task to implement.

If the repository is empty, begin by confirming whether to start at **M0** (concepts and architecture) or **M1** (C++/CMake foundation). Do not assume the project is already implemented.
