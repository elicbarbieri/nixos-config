# Global Engineering Principles

**Precedence.** The two sections immediately below — *Comments* and *Type
declarations* — are HARD RULES and outrank everything else in this file, every
project-level `CLAUDE.md`, and any default style habit. They apply in every
session, every language, every file, with no exceptions beyond the ones written
here. Do not relax them because a file's existing comments already violate them,
because the change is small, or because a longer comment "seems helpful". If a
conflict arises with any other instruction, these win.

## Comments: notes, not prose (hard rule)

**NO FULL SENTENCES IN COMMENTS. EVER.** A comment is a note jotted in a
margin, not writing. Bullet fragments, symbols, parentheticals, code refs.
The reader is mid-code and must absorb it without parsing grammar. This is
the rule most often violated — check every comment against it before writing.

Banned outright: full sentences, filler words, narration. If a comment reads
like something you would say out loud, it is wrong.

### Shape

```
//! Driver→controller live event stream.
//!
//! - Controller stateless between commands (driver-pod log = only channel to live term)
//! - One EVENT_PREFIX-tagged line per event, lifted from otherwise-verbatim stream
//! - Data only, no formatting (renderers controller-side, so layout floats)
```

not

```
//! The controller is stateless between commands, so the driver pod's log is
//! the only channel to a watching terminal: one EVENT_PREFIX-tagged line per
//! event, lifted out of a stream otherwise passed through verbatim.
```

### Form — all mandatory

1. **No finite verb where a fragment works.** Kill "is/are/was/has/does" as the
   main verb. `Held across await` not "This lock is held across the await".
   `Callers must drop before poll()` is fine — a real constraint keeps its
   modal.
2. **No leading article.** Never open with "A", "An", "The", "This", "One".
   `Bytes remaining` not "The number of bytes remaining".
3. **Parenthesise the why.** Rationale goes in `(...)` after the fact, never in
   a subordinate clause. `rate ships pre-computed (resumed stream drops events)`
   not "rate is published rather than differenced controller-side, because a
   resumed stream replays and drops events".
4. **Symbols over words.** `=`, `→`, `[]`, `!=`, `>=`, `&`, `/`.
   `driver → controller` not "from the driver to the controller".
   `x = only channel` not "x is the only channel that exists".
5. **Name the code, don't describe it.** Refer to the real identifier —
   `poll()`, `EVENT_PREFIX`, `Config.retries` — never "the polling function".
6. **Multiple facts = multiple bullets.** Never chain with em-dash, semicolon,
   "because", "so that", "which means", "rather than". One fact per line, `- `
   prefixed.
7. **No filler.** "deliberately", "genuinely", "merely", "actually", "simply",
   "basically", "essentially", "note that", "of course", "in order to",
   "makes sure that". Zero information — cut every one.
8. **No trailing period on a fragment.** It is not a sentence.

### Content — what earns a comment at all

A comment earns its place only by explaining *why* something non-obvious is
done. Delete these on sight, never write them:

1. **Restating the code.** `// increment i`, `// return the client`,
   `// Storage stack, profile-dependent` above an obviously
   profile-dependent branch.
2. **Justifying an API's own spec.** A comment explaining that the field is
   `fstype` not `fsType`, or that an enum value is one of the documented set.
   The code is correct; the rejected alternative does not need narrating.
   Just write `fstype: xfs`.
3. **Docstrings that echo the item name.** A test named
   `render_is_valid_yaml_with_all_paths` needs no
   `/// The render must be valid YAML with all paths`. Same for functions
   whose name and signature already say it.
4. **Provenance trivia.** "verified against a live cluster", "reached state
   Ready", "the historical behaviour" — belongs in the commit message.

Keep a comment only when removing it would make a senior reader ask "why is it
done *this* way?" and the answer is not in the code: a genuine gotcha, a
non-local invariant, a workaround for an external bug (link it), an ordering
constraint invisible at the call site. Prefer a well-named function or constant
over a comment that labels a block.

### Budget

**One line. Two if the invariant needs it.** Three-plus bullets means it
belongs in a docs file, in a better name, or nowhere. A 30-word comment evicts
two lines of code from the screen and costs more attention than the code it
sits on. Length tracks *surprise*, not importance: hairy invariant → two
lines, well-named function → zero, nothing earns twelve.

**Run to the project's full formatter width** (100 columns where allowed).
Never wrap at 80 out of habit. Two 80-column lines that would fit on one
full-width line are a bug — merge them. Most formatters do not reflow
comments; the width is yours to hold.

## Type declarations stay dense (hard rule)

A type declaration is read as a *shape*. A reader scans it to learn what the
thing is made of, and every line that isn't a field costs them that. A 5-field
struct is 7 lines: the declaration line, five fields, the closing brace.

**Fields and enum variants get no doc comment by default.** Do not write one,
and delete one you find. The field's name and type are the documentation; if
they aren't, that is a naming or typing bug and the fix is a better name or a
type that constrains the value (`Duration` over `u64`, a newtype over `String`,
an enum over `bool`), never a doc comment that apologises for the weak one.

The narrow exception is a field carrying an invariant the type genuinely cannot
express — a unit the type erases, a cross-field constraint, a range the compiler
won't enforce. Then prefer one line at the *top* of the declaration naming the
field, and only inline the comment when it would be lost up there. "This field
is the X" is never such an invariant.

**Type-level docs: 0-2 lines normally, 5 at the absolute ceiling.** Say what the
type is for and how it fits its neighbours — the thing a reader cannot recover
by reading the fields. Then stop. Reaching for the fourth line means it belongs
in a docs file. Specifically, never write:

- Design history. "used to carry", "was previously", "stopped doing X because" —
  dead alternatives and the path to the current shape belong in the commit
  message. The code is the current shape.
- A field-by-field walkthrough in prose. That is field docs relocated.
- Restated names. `/// A validator component.` above `struct Validator` is zero
  information.

If a type is subtle enough to need more than five lines, that is a signal to
write it up in a docs file and link it in one line, not to grow the header.

**Exception — user-facing doc strings.** Doc comments that are compiled into
output the user reads (clap `#[derive(Parser)]` / `Args` / `Subcommand` fields
and variants, any type whose docs feed a generated schema, NixOS module option
`description`s) are user-facing strings that happen to use doc-comment syntax.
These are code, not commentary — write them well and never strip them.

## Build it right, not fast (hard rule)

Optimize for correctness, clarity, and long-term maintainability — never for
speed or smallest diff. When multiple approaches could solve a problem
(feature, bugfix, test, refactor), rank them only by: (1) correctness incl.
edge/failure paths, (2) clarity for the next reader, (3) scalability &
maintainability. Effort/time/LOC is **not** a ranking factor and must be
completely ignored when choosing between approaches. Never let cost estimates —
"this is ~2 weeks of work," "much bigger change," "simpler for now" — steer the
decision or even enter the comparison. Pick the cleaner abstraction even when it
costs far more upfront work. Fix the real problem at the
right layer; don't force it into the existing worse shape because a proper fix
feels "out of scope."

Never do these without express confirmation: special-casing over a general bug;
duplication where an abstraction belongs; hardcoding what should be derived;
suppressing errors/warnings/tests to "pass"; bypassing an abstraction instead
of extending it; "temporary" stubs on a real code path.

Escalate, don't silently compromise: if the clean fix is large-scope, or
options differ *only* in effort, state the trade-off in a sentence and ask.
Otherwise proceed with the correct implementation by default.

## Research before designing (hard rule)

Before designing any solution, look for an existing, battle-tested answer first:
established open-source projects, the Linux kernel's own facilities, and the
core system libraries/dependencies already in play. Read their docs and verify
actual capabilities — do not reinvent, and do not assume an API's behavior.
Prefer composing a mature, well-maintained primitive over hand-rolling one.

## Tests: few, dense, readable (hard rule)

A test suite is read far more often than it is written, and it is read under
pressure — something just broke and the failing test is the first clue.
Optimize every test for correctness and for a human reading it cold. Nothing
else ranks: not test count, not one-assert-per-test dogma, not coverage
percentages.

Each test asserts a **group of related behaviours**, not a single fact. A test
walks one coherent scenario end to end and checks every consequence that
belongs to it — the return value, the resulting state, the emitted events, the
error path for the same class of input. Prefer a small number of tests that
each pin down a large surface over thousands of one-assert tests pinning down
the same surface with far more noise. A failing assertion already names itself
and the test it sits in, which is enough to locate the broken behaviour, so
density costs nothing diagnostically.

This matters most for integration tests with expensive setup/teardown
harnessing. There, the cost of a test is dominated by the fixture, so bringing
a real environment up to assert one thing is close to pure waste. Design the
scenario so that one bring-up exercises and asserts a large, logically
coherent slice of the system, in the order a real caller would hit it.

Rules:

1. **Group by scenario, not by assertion.** The test name states the scenario
   and the guarantee; the body proves it from several angles.
2. **Keep each test one coherent story.** Everything asserted belongs to the
   same scenario. Behaviour from an unrelated story does not get bolted on
   just to reuse a fixture — that is a second test.
3. **Assertions must say what broke.** Prefer comparing whole structures over
   a stack of field-by-field checks, and give the assertion enough context
   that the failure output alone identifies the bug.
4. **No setup helpers. Anti-DRY is correct in tests.** A reader must never
   go-to-definition to learn what a test actually verifies. Inline the fixture
   data, the arrangement and the expectations, even when that repeats the
   neighbouring test verbatim. Shared builders, `setUp` inheritance chains and
   helper layers that hide the arrangement are worse than repetition. Factor
   out only genuine infrastructure the test does not assert on — spinning up a
   container, a temp dir — never the values under test.
5. **Parametrised matrices are welcome where they clarify.** A table of
   input → expected, read top to bottom next to the single body that consumes
   it, is often the clearest possible form. Use it when the cases really are
   the same scenario with different data; do not use it to merge scenarios
   that read differently.
6. **Arrange / act / assert stays visible.** A reader should see the setup,
   the one thing being exercised, and what it must produce, without scrolling
   elsewhere.
7. **Delete redundant tests.** A test that cannot fail independently of
   another is upkeep with no return.

Correctness of the test itself outranks all of the above: a dense, elegant
test that asserts the wrong thing, or passes for the wrong reason, is a bug in
the suite.

## Use native tools over imperative scripts (guideline)

Whenever possible, use the read/write tools that are included, over modifying code
with python scripts, reading code with grep, etc... If doing bulk operations over
a large set of files, you can use a bash/python script, but the native tools should
always be the first choice.
