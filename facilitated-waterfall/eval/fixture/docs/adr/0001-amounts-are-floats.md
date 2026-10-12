---
id: adr-0001
title: "Amounts Are Floats"
created: 2026-09-01
relates:
  - task-001
superseded-by:
  - adr-0002
---

# ADR 0001: Amounts Are Floats

## Context

Amounts arrive as decimal strings such as `12.30`.

## Decision

Store each amount as a Python `float`.

## Consequences

Simple to parse; sums may drift by a fraction of a cent.

## Alternatives

Integer cents; `Decimal`.
