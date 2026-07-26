# Pattern: integrity for money and other conserved quantities

Applies to anything that moves between accounts and must be conserved: currency, credits,
points, inventory items, tickets. Two rules, both cheap now and close to impossible to
retrofit.

## Rule 1 — money is an integer type, never a float

Represent money as a value type wrapping an INTEGER count of the smallest unit — cents,
minor units, whatever the domain's atom is. Forbid floating-point arithmetic on it.

**Why.** Binary floating point cannot represent most decimal fractions. Every operation
rounds a little, the errors accumulate in different directions on different code paths, and
the totals stop agreeing. In a shared or persistent system that is not a rounding
annoyance: it is an exploit surface and an imbalance nobody can attribute, because no single
transaction is wrong.

**How to enforce it.** A grep in the gate that fails on `float`/`double` inside the modules
that handle money, with an explicit marker for the genuinely non-monetary number that has to
live there.

**Two things learned the hard way about that gate.** It is COARSE — an escape marker exempts
a whole line, and exotic forms slip through it entirely: exponent-only literals, values
inferred from library constants, indirect bit conversions, dynamic typing, type aliases. So
the gate is the first pass and the reviewer is the fine one; a review of those modules reads
every marked line, including the ones that look obviously fine. And rates and fees go
through one scaling function whose rounding rule is stated in exactly one place. A call site
that re-implements the rounding, or multiplies by a fractional factor, is a reject —
otherwise you have two rounding rules and they will disagree.

Note that the money TYPE may permit negative values; arithmetic needs them. The constraint
belongs on the stored movement, not on the type.

## Rule 2 — movement is an append-only ledger; balance is derived

A balance is not a field you update. Every movement is a row: `from`, `to`, `amount`,
`reason`, `correlation id`, `timestamp`. Rows are never updated or deleted; a mistake is
corrected by a compensating row. A balance is computed from the rows — cache it if you must,
but the cache must be verifiable against the ledger, and when they disagree the ledger wins.

Every transaction writes ALL of its rows inside ONE database transaction. Partial movement
must be impossible, including across a hand-off between services.

**Why.** Duplication is the top risk in any persistent economy. With a mutable balance a
duplicate is invisible AND unattributable: the total inflates, and there is nothing to
inspect — no record of what happened, only the wrong number that resulted. With a ledger,
the same bug is auditable, traceable and reversible.

### Three details that turn out to matter

- **`amount` is always POSITIVE; direction lives in `from` and `to`.** One movement is ONE
  row carrying both sides. Enforce it in the schema: `amount > 0`, both endpoints NOT NULL
  and never equal. Signed amounts are invalid, and so is splitting one movement across two
  rows — an unbalanced movement should be *inexpressible*, not merely detectable.
- **Creation and destruction go through reserved system accounts.** A `SOURCE_*` account
  mints, a `SINK_*` account burns. Then the total supply is
  `SUM(SOURCE_*) - SUM(SINK_*)` and it must equal the sum of all balances — an invariant a
  test can assert every night. Without this, "money is only created in allowed places" is a
  sentence in a document rather than a query.
- **Only one component owns the ledger and its transaction boundary.** Everything else
  computes amounts and produces movement requests. A module that holds an authoritative
  balance is a second source of truth.

## The long-run test

Unit tests will not catch the real failure mode, which is "every test passes and the
hundred-hour emergent behaviour degenerates". Add a simulation: fixed seed, deterministic,
N simulated days, M actors, asserting the invariants — total supply within declared bounds,
no value going negative or unbounded or NaN, no single strategy permanently dominant. It is
slower than a unit test, so run it nightly or on demand, not in the commit gate.

A non-deterministic simulation cannot detect a regression, only produce anecdotes. The seed
is the whole point.
