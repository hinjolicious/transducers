# Red Transducer Library

A high-performance, composable, single-pass data transformation pipeline for the [Red Programming Language](https://www.red-lang.org/).

Transducers decouple data transformations from the underlying source or destination. By leveraging custom lexical environment capturing via `closure.red`, this library enables zero-allocation array processing pipelines, early loop short-circuiting, and thread-safe batching channels for co-routines.

---

## Key Features

* **Zero Intermediate Allocations:** Chain multiple operations (`map`, `filter`, `take`, `partition`) into a single pass without creating temporary intermediate blocks.


* **Source-Agnostic Execution:** Write transformation logic once and apply it over standard Red series, infinite streams, or concurrent channel queues.


* **Early Termination Support:** Stop evaluation immediately (via `reduced` sentinels) the moment pipeline demands are satisfied (e.g., `t-take`).


* **Lexical Closure Engine:** Built-in environment capturing (`closure.red`) to maintain stateful variables across transformation steps safely.


* **Concurrent Channel Integration:** Includes a co-routine channel adapter (`make-transducer-channel`) to filter and batch payloads before hitting inter-thread queues.



---

## Core Components

### 1. Transducer Families

| Family | Function | Short Alias | Description | State |
| --- | --- | --- | --- | --- |
| **Transformers** | `t-map`<br> | `tm.`<br> | Applies a 1-to-1 function transformation. | None |
| **Filters** | `t-filter`<br> | `tf.`<br> | Retains items matching a predicate function.| None |
| **Stateful** | `t-take`<br> | `tt.`<br> | Retains first `N` items and signals early loop exit. | Counter |
| **Stateful** | `t-drop`<br> | `td.`<br> | Skips the first `N` items before passing through. | Counter |
| **Stateful** | `t-dedupe`<br> | `tdd.`<br> | Removes consecutive duplicate values. | Last Value |
| **Stateful** | `t-distinct`<br> | `tdt.`<br> | Removes global duplicates across the dataset. | Hash Set |
| **Structural** | `t-partition`<br> | `tp.`<br> | Batches items into blocks of fixed size `N`. | Array Buffer |

### 2. Infrastructure & Runners

* **`transduce` / `tx.`:** The primary transduction runner. Takes a transducer pipeline, a target step reducer, an initial accumulator, and source data.


* **`push-reducer` / `pr.`:** Base collection reducer (`[acc input] -> append/only acc input`).


* **`make-transducer-channel` / `mtc.`:** Constructs a thread-safe co-routine queue pre-wrapped with a transducer pipeline.


* **`comp-funcs`:** Variadic function composition utility used to combine array-declared transducers into a single left-to-right execution pipe.



---

## Quick Start & Usage

### 1. Simple Pipeline Execution

```red
#include %transducers.red
#include %comp-funcs.red

data: [1 2 2 3 2 4 2 5 6 7 8 9 10 11 12 13 14 15]

; Pipeline: Distinct -> Keep Evens -> Drop 1 -> Triple -> Take 5
pipeline: comp-funcs reduce [
    tdt.        ; 1. Deduplicate globally
    tf. :even?  ; 2. Retain even numbers
    td. 1       ; 3. Skip first even result
    tm. :triple ; 4. Multiply by 3
    tt. 5       ; 5. Halt after 5 items
]

result: tx. :pipeline :pr. copy [] data
probe result
; Output: [12 18 24 30 36]

```

### 2. Single-Pass Early Termination

```red
; Loop halts execution immediately at index 4 once 2 items are collected:
result: tx. comp-funcs reduce [
    tf. :even?
    tm. func [x] [x * 3]
    tt. 2
] :pr. copy [] [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15]

probe result
; Output: [6 12]

```

### 3. Co-routine Channel Batching

```red
; Embed a transducer inside a thread channel to batch inputs:
chan-pipeline: comp-funcs reduce [
    tf. :even?
    tm. func [x] [x * 2]
    tp. 3  ; Batch into groups of 3
]

work-channel: mtc./pipeline :chan-pipeline

; Producer pushes raw values:
foreach i [1 2 3 4 5 6 7 8 9 10 11 12] [
    work-channel/send i
]

; Consumer receives batched vector payloads:
print mold work-channel/receive ; Output: [4 8 12]
print mold work-channel/receive ; Output: [16 20 24]

```

---

## Project Structure

```text
├── transducers.red   # Core transducer functions, runners, and channel adapter
├── closure.red       # Lexical scoping macro for environment capturing
├── comp-funcs.red    # Variadic functional composition helper
├── range.red         # Numerical sequence generator
└── error.red         # Custom error formatting helper

```

---

## License & Credits

* **Author:** hinjolicious


* **Credits:** Gemini AI, early concepts inspired by Red/Sensei