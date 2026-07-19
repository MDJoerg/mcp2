# Tasks — long-running work

The Tasks extension (`io.modelcontextprotocol/tasks` in the modern era, the experimental
core `tasks` feature in `2025-11-25`) lets a tool return immediately with
a task handle while the real work runs in the background; the client polls for status and
fetches the result later. Tasks are the stateful complement to the stateless core:
persisted in `zmcp2_tasks`. `tasks/list` is scoped to **user + area + server**;
direct task operations use the unguessable task UUID and verify the creating user.

Enable with `supports_tasks` returning `abap_true`. The dispatchers then route the supported
`tasks/*` methods, and the capability is advertised era-appropriately: modern
`server/discover` carries `capabilities.extensions["io.modelcontextprotocol/tasks"]`,
legacy `initialize` carries the 2025-11-25 shape
`capabilities.tasks = { list, cancel, requests.tools.call }`. The base class implements the
standard polling/update/cancel behavior; override only when a server needs custom
task-update semantics.

## Who may receive a task result — era-aware gating

A client must be able to parse a create-task result before you return one:

- **Modern (`2026-07-28`)**: the client declares the tasks extension in its per-request
  `clientCapabilities.extensions`.
- **Legacy (`2025-11-25`)**: the client opts in **per request** by sending `params.task`
  (optionally with a requested `ttl` in ms) on `tools/call`; capabilities from `initialize`
  are unknowable statelessly, so the opt-in is the only reliable signal.

`client_supports_tasks( )` on the base class answers "can this client take a task **right
now**" for **both** eras — use it to fall back to a synchronous result. If you return a
task result ungated, the framework protects the wire: modern clients without the extension
get `-32021`, legacy clients without `params.task` get `-32600`.

On `tools/list`, advertise task capability per tool with `task_support`
(`zif_mcp2_const=>task_support-optional` / `required` / `forbidden`), emitted as the
2025-11-25 `execution.taskSupport` field. Omitted means `forbidden` to legacy clients, so
set it on every tool that may return a task. The legacy request also exposes
`has_task_request( )` and `get_task_ttl_ms( )` directly when you need the requested TTL.

## Starting a task from a tool

`start_task` on the base class does everything in one call: it persists a `working` row
in the server's scoped task store and builds the era-appropriate create-task result:

```abap
METHOD call_tool.
  IF request->get_name( ) = `run_report`.
    IF client_supports_tasks( ) = abap_false.
      " Era-aware: modern extension declaration or legacy params.task opt-in.
      result = zcl_mcp2_resp_call_tool=>text( run_report_synchronously( ) ).
      RETURN.
    ENDIF.

    DATA(task) = start_task( poll_ms        = 2000       " client poll hint
                             ttl_s          = 3600       " row TTL, 0 = keep
                             status_message = `report queued` ).
    result = task-result.

    " Hand task-task_id to your background unit (job, bgRFC, ...).
    submit_report_job( task-task_id ).
    RETURN.
  ENDIF.
ENDMETHOD.
```

## Finishing from the background unit

All lifecycle mutators are **class methods** on `zcl_mcp2_tasks` — safe to call from
batch jobs and background RFCs without any request context:

```abap
" Success: store the terminal payload atomically
DATA(payload) = NEW zcl_mcp2_resp_task_payload( ).
payload->add_text( `Report finished: 1200 rows.` ).
zcl_mcp2_tasks=>complete( task_id = task_id  result = payload ).

" Failure: message + JSON-RPC error code (surfaced by tasks/get)
zcl_mcp2_tasks=>fail( task_id = task_id
                      message = `Report source unavailable`
                      code    = -32011 ).

" Progress without a status change
zcl_mcp2_tasks=>update_status( task_id = task_id  status = `working`
                               message = `500 of 1200 rows` ).
```

`zcl_mcp2_resp_task_payload` offers the same content-block and structured-data builders as
a tool result (`add_text`, `set_structured_data`, …).

**How the work gets started is yours to choose.** The SDK persists and serves task state; it
never launches anything. `start_task` gives you a task id, and you hand it to a background job
(as the demo does), bgRFC, or any other worker. The optional `zif_mcp2_task_executor` interface
(`execute` / `cancel`) exists only as a suggested shape for such a worker — **no SDK code calls
it**, so implementing it is a convention, not a registration.

### Complete runnable example

`ZCL_MCP2_DEMO_WF.background_report` is the concrete version of the pattern above. It calls
`start_task`, opens an immediate SAP background job, submits `ZMCP2_DEMO_TASK` with the task ID,
and closes the job for immediate execution. The report then:

1. waits five seconds between three work steps,
2. checks whether the task was cancelled,
3. updates the `working` status message after each step,
4. completes the task with a content payload, or marks it failed when worker processing raises.

The client only polls `tasks/get`; polling does not drive execution. The authenticated scheduling
user must be authorized to create and immediately start background jobs. Scheduling failures are
also recorded as task failures, so the row is not left indefinitely in `working`.

The deliberate waits make progress observable and are appropriate only for this demo. Real jobs
should update status after meaningful units of work rather than sleeping to manufacture progress.

## What the client sees

| Method | Era | Behavior |
| --- | --- | --- |
| `tasks/get` | both | status, statusMessage, timestamps, ttl/poll hints; terminal result for completed tasks; `error.code`/`message` for failed ones; pending `inputRequests` for `input_required` tasks. **Modern is flat** (`taskId`/`status`/`createdAt`/`lastUpdatedAt`/`ttlMs`/`result`/`error`/`inputRequests` all at the result root — `GetTaskResult = Result & DetailedTask`); legacy returns the task under `task`. Task input is keyed by `inputRequests`; there is no `requestState` on `tasks/get`/`tasks/update` (that field belongs to MRTR retries of the original request) |
| `tasks/result` | legacy | terminal payloads are returned as the CallToolResult the call would have produced, stamped with the `io.modelcontextprotocol/related-task` `_meta` annotation; a task failed via `fail( )` re-raises the **stored JSON-RPC error** (code + message); a cancelled task is `-32602`; non-terminal tasks answer `-32600` — the stateless runtime cannot block, keep polling `tasks/get` (a documented deviation from the legacy blocking behavior). Modern clients get the payload through `tasks/get` |
| `tasks/list` | legacy | cursor-paginated list — only the calling user's tasks for this area/server |
| `tasks/cancel` | both | cooperative. Modern returns an empty `complete` acknowledgement, is idempotent for already-cancelled tasks, and **acks (does not error) a task already in any terminal state** — the work may have finished before the cancel arrived; only an unknown taskId errors. Legacy returns the task snapshot and rejects **any** terminal-state cancel (including repeat cancels) with `-32602` per the 2025-11-25 spec |
| `tasks/update` | modern | accepts only responses keyed to outstanding `inputRequests`; unknown/already-satisfied keys are no-ops. Partial responses retain unanswered requests and keep `input_required`; the task returns to `working` only when every outstanding request is answered. Request keys cannot be reused during a task's lifetime. Returns an empty `complete` acknowledgement ([see MRTR](InputRequired.md#tasks)) |

The modern create-task result (`tools/call` → `resultType: "task"`) is likewise **flat**
(`CreateTaskResult = Result & Task`): `taskId`, `status`, `createdAt`, `lastUpdatedAt` and
`ttlMs` sit at the result root, not under a `task` wrapper. `ttlMs` is always present —
the millisecond value, or `null` for an unlimited task. On the modern transport the client
also mirrors `params.taskId` into the `Mcp-Name` header on every `tasks/*` request (the
dispatcher validates it, mismatch → `-32020`).

Status lifecycle: `working` → `completed` / `failed` / `cancelled`, plus
`input_required` ↔ `working` for interactive tasks. Illegal transitions are rejected, and
concurrent transitions are guarded at the database level.

The task's protocol era is persisted when it is created, so background completion keeps the
correct semantics after the request context is gone. An `isError: true` tool payload marks a
legacy task `failed` (and remains retrievable through `tasks/result`); the same payload is a
modern task's completed `result`. The `failed` + `error` shape in modern Tasks is reserved for
JSON-RPC failures recorded through `fail( )`. Rows created before era persistence are treated
as legacy.

## Asking the user mid-task

A background unit can park the task on user input and resume when the answer arrives —
see [Input required → Tasks](InputRequired.md#tasks).

## Housekeeping

Task rows outlive requests, so purge them periodically: schedule report
**`ZMCP2_CLEAR_TASKS`** as a batch job. It deletes:

- terminal rows past their explicit TTL,
- terminal rows without a TTL (`ttl_s = 0`) after a 7-day default retention,
- **non-terminal rows (`working` / `input_required`) older than 24 hours** — these are
  treated as stuck. If your tasks may legitimately run or wait for input longer than
  24 hours, do not schedule the report as-is; adjust the cutoff before using it.

## Security model

- `tasks/list` filters by the requesting user, area, and server.
- `tasks/get` / `tasks/result` / `tasks/cancel` / `tasks/update` address a task by its
  unguessable UUID and verify the creating user (so one user cannot read, cancel, or inject
  input responses into another user's task).
- Task IDs are UUIDs. `get_task_area` / `get_task_server` scope listing and creation, while
  direct operations rely on UUID + creating-user checks.
