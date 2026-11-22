# Distributed KV architecture

## Scope

A key-value store maps a key to a value. PUT creates or replaces that mapping, GET returns the current value or reports a missing key, and DELETE removes the mapping if it exists.

The first working store (M2) is an in-memory map in one process. The distributed target (M11) runs one Raft group across three fixed voting nodes. M12 adds restart-safe Raft storage and snapshots. Sharding would add multiple Raft groups in M14. Dynamic membership, TTL, and an HTTP gateway are outside the initial scope.

## Components

```text
Client → KV service on the leader → Raft log replication → follower logs
                    ↓                                            ↓
              leader KV map                               follower KV maps
```

The KV service handles requests and returns results. Raft agrees on which commands are committed and in what order. Each node applies committed commands in log order to its own map. In the durable target, each node owns its own Raft state, log, and snapshots.

## Walkthrough

1. A client sends `PUT color blue` to the leader. The leader appends the command to its log and sends it to followers.
2. For this current-term entry, replication on two of the three voting nodes lets the leader commit it. For the durable target, the replicas count toward that majority only after the entry is persisted.
3. The leader applies the committed command to its map before replying successfully. Other nodes apply it in order once they learn it is committed.
4. A subsequent linearizable `GET color` returns `blue` unless a later write or delete takes effect first. Such a read requires a Raft read protocol that confirms leadership and waits for the required committed entries to be applied. A follower can lag.

If one node fails, the other two can still form a majority and make progress once a leader is available. With only one reachable voter, new writes cannot commit. A client timeout leaves the outcome uncertain because a command may have committed before the reply was lost.

## Development environment

Use C++20 and the standard library first, with out-of-source CMake builds on Linux or WSL2 Ubuntu. The current Linux workspace has GCC 14.2.0. CMake is unavailable on PATH and needs to be available before verifying the M1 build. M0 has no build or runtime tests.
