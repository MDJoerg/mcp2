# Demo servers

The demos are deliberately split by learning level. `ZCL_MCP2_DEMO_BASIC` is the server to copy
when starting an application. `ZCL_MCP2_DEMO_WF` isolates the state-machine-like parts of MCP so
that task and multi-round-trip code do not obscure the basic handler patterns.

Both classes serve legacy (`2025-03-26` through `2025-11-25`) and modern (`2026-07-28`) clients.
Do not make a legacy subclass: the dispatcher selects the wire shape and installs an era-aware
request context before calling the same handler.

For a guided sequence rather than a feature lookup, follow the [learning path](LearningPath.md).
It introduces the basic demo one concept at a time, then branches into compatibility and advanced
workflows.

## Registering the demos

The demos ship as classes only — like any server they need a `zmcp2_servers` row before they
answer. Add these two (SM30/SE16, or via abapGit table content — see
[Configuration](ConfigurationAndSecurity.md)):

| AREA | SERVER | CLASS |
| --- | --- | --- |
| `DEMO` | `BASIC` | `ZCL_MCP2_DEMO_BASIC` |
| `DEMO` | `WF` | `ZCL_MCP2_DEMO_WF` |

They are then live at `POST /zmcp2/DEMO/BASIC` and `POST /zmcp2/DEMO/WF`. Every example below
uses those two paths. Browser callers additionally need `zmcp2_origins` rows; curl and
server-to-server calls send no `Origin` header and are always allowed.

## What each example teaches

| Example | Main SDK concepts | Try this first |
| --- | --- | --- |
| `ZCL_MCP2_DEMO_BASIC` | tool catalog, schemas, typed argument binding, decimal and array arguments, structured output, tool errors, DDIC schema generation, header annotations, resources, readable URI templates, prompts, completions, request context | Call `request_info`, then `text_stats` and `price_quote`; expand and read `mcp2://demo/greeting/{name}` |
| `ZCL_MCP2_DEMO_WF` | capability gating, synchronous fallback, a real background job whose status advances, form elicitation, MRTR retries and correlation through request state | Compare legacy and modern `approval_required`; start `background_report` and poll its status for about 15 seconds |

## Feature and compatibility coverage

| Feature | Demo behavior | Compatibility lesson |
| --- | --- | --- |
| Tools | `echo`, `echo_sep2243_mirror`, typed `text_stats`, `price_quote`, DDIC schema generation, and `request_info` | One catalog and handler set serves both eras; advertised-schema failures become `isError` tool results in both |
| Decimal and array arguments | `price_quote` takes a `decfloat34` unit price, an integer array of quantities and a string array of tags, and returns exact money amounts | `get_arg_number` converts from the raw JSON literal, so 19.99 × 10 is 199.90 rather than a binary-float approximation. Arrays of primitives have typed readers too (`get_arg_string_table`, `get_arg_integer_table`), so no handler here touches raw JSON. Property `title` and `default` are advertised so clients can label and prefill the form |
| Resources | Lists and reads `mcp2://demo/readme` | The handler uses the era-neutral resource-not-found helper; the dispatcher emits legacy `-32002` or modern `-32602` |
| Resource templates | Lists `mcp2://demo/greeting/{name}` and reads expanded greeting URIs | A template is not merely metadata: every valid expansion reaches `resources_read` in both eras |
| Prompts | Lists and gets the required-argument `summarize` prompt | The same prompt handler serves both eras; required arguments are enforced in application code |
| Completions | Completes `summarize.topic` and `greeting.name` by returning whole candidate values that start with what the user typed, and no values for unrelated references | Code scopes suggestions by reference type, reference identity, and argument, then filters by prefix — a completion replaces the argument, so it must never append to the typed text; legacy completion context remains available through typed request accessors |
| Request context | `request_info` returns era, negotiated version, client name, and **two** task flags: whether the client would accept a task result and whether this server offers tasks at all | Client labels are observable but not trusted; behavior branches on semantic capability helpers. Client and server capability are different facts — the basic demo does not advertise tasks, so a capable client still cannot get one here |
| Input validation | `text_stats` declares a required input and structured output schema | Invalid advertised-schema input becomes `isError` in both eras without changing the handler; malformed calls remain JSON-RPC `-32602` |
| Tasks | `background_report` schedules `ZMCP2_DEMO_TASK`, which updates its stored task status through three steps and completes after about 15 seconds | Work proceeds independently of polling; modern clients declare an extension, legacy clients opt in per call, and incapable clients receive a useful fallback. The server never pushes: a client sees progress only by calling `tasks/get`, and a slow poller may skip intermediate states |
| Input required | `approval_required` takes a `request_summary`, performs a form-elicitation retry for capable modern clients asking for an `approval_reason`, and for legacy clients explains that the request would need manual review | MRTR is modern-only and capability-gated. The legacy path states the outcome honestly rather than treating client-supplied text as user approval — and rather than claiming a side effect the demo does not perform |

The demos react differently only where the protocol or a declared capability changes what the
client can consume. They do not vary business results merely because a client has a particular
name or version. That is intentional: prefer `client_supports_tasks`, `can_request_input`, and
other semantic helpers over client-name checks or scattered version comparisons.

The examples are small on purpose. They do not duplicate every response-content variant or every
identity field. Those are straightforward builder calls and are easier to scan in the focused
[Tools](Tools.md), [Resources](Resources.md), and [Server context](ServerContext.md) guides. URL
elicitation and sampling are also kept in [Input required](InputRequired.md): unlike the form demo,
they need a real callback URL or model interaction to be meaningful.

## Backward-compatibility walkthrough

Use the same `/zmcp2/DEMO/BASIC` endpoint from both clients and call `request_info`.
The structured result makes the otherwise transparent compatibility layer visible:

| Client request | `era` | `protocol_version` | `client_accepts_task_results` | `server_offers_tasks` |
| --- | --- | --- | --- | --- |
| Legacy request negotiated as `2025-03-26`, `2025-06-18`, or `2025-11-25` | `legacy` | negotiated version | true only when this `tools/call` contains `params.task` | always false on this server |
| Modern request with `2026-07-28` metadata | `modern` | `2026-07-28` | true only when `clientCapabilities.extensions` declares `io.modelcontextprotocol/tasks` | always false on this server |

The second flag is the point: `ZCL_MCP2_DEMO_BASIC` never overrides `supports_tasks`, and every
dispatcher gates `tasks/*` on that **server** flag. A tool that reported only the client side would
happily announce that tasks are available on an endpoint that cannot create one. Report both, or
report the conjunction — never the client flag alone. `ZCL_MCP2_DEMO_WF` is the server that does
offer tasks.

Next, repeat `text_stats` with an invalid argument. The application handler and schema are
unchanged, but the compatibility policy is observable: clients receive a tool result with
`isError` in both eras; structurally malformed calls still receive JSON-RPC `-32602`.

Finally, use `ZCL_MCP2_DEMO_WF.background_report`:

1. With no task capability, it returns the finished report synchronously in either era.
2. A legacy `2025-11-25` call opts in with `params.task`; the response uses the legacy task shape.
3. A modern call declares the tasks extension in request metadata; the response uses the modern
   flat task shape.
4. Poll the task with `tasks/get` and watch the stored status message advance through three steps.
   The executable report `ZMCP2_DEMO_TASK` runs as an immediate background job and completes after
   about 15 seconds, independently of whether anyone polls.

Scheduling requires the authenticated ABAP user to be allowed to create and immediately start a
background job. The demo turns job-open, step-submission, or job-start failures into a failed task
and a protocol error instead of leaving an orphaned `working` row. A production application may
use the same pattern or replace the report with bgRFC or another worker mechanism.
The artificial five-second waits exist only to make three status changes easy to observe; real
workers should update the status after actual units of work.

This is the recommended compatibility pattern for application servers: ask the semantic helper
(`client_supports_tasks`, `can_request_input`, or `era_is_modern`) and provide a useful fallback.
Avoid parsing protocol versions or `_meta` inside business handlers.

## Calling the demos directly

The shortest legacy call — `initialize` first, then the tool:

```bash
curl -X POST https://your-host:port/zmcp2/DEMO/BASIC \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{
        "protocolVersion":"2025-11-25",
        "clientInfo":{"name":"curl","version":"1.0"},"capabilities":{}}}'

curl -X POST https://your-host:port/zmcp2/DEMO/BASIC \
  -H "Content-Type: application/json" \
  -H "MCP-Protocol-Version: 2025-11-25" \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{
        "name":"text_stats","arguments":{"text":"hello brave new world"}}}'
```

The modern era has no handshake, but every request carries `_meta` and mirrors the routing
fields into headers. `Mcp-Method` is always required; `Mcp-Name` is required for `tools/call`,
`prompts/get` and `resources/read`, and is validated when sent on `tasks/*`:

```bash
curl -X POST https://your-host:port/zmcp2/DEMO/BASIC \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -H "MCP-Protocol-Version: 2026-07-28" \
  -H "Mcp-Method: tools/call" \
  -H "Mcp-Name: request_info" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{
        "name":"request_info","arguments":{},"_meta":{
        "io.modelcontextprotocol/protocolVersion":"2026-07-28",
        "io.modelcontextprotocol/clientInfo":{"name":"curl","version":"1.0"},
        "io.modelcontextprotocol/clientCapabilities":{}}}}'
```

`echo_sep2243_mirror` is `echo` with its `message` property annotated `x-mcp-header`, so
SEP-2243 obliges the client to send the value as `Mcp-Param-Message` too. The body stays the
source of truth; a missing or mismatched header is rejected with `-32020`. Plain `echo` carries
no annotation on purpose — clients that have not implemented mirroring yet (several v2 alphas
have not) must still be able to call the first tool in the catalog:

```bash
curl -X POST https://your-host:port/zmcp2/DEMO/BASIC \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -H "MCP-Protocol-Version: 2026-07-28" \
  -H "Mcp-Method: tools/call" -H "Mcp-Name: echo_sep2243_mirror" \
  -H "Mcp-Param-Message: hi" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{
        "name":"echo_sep2243_mirror","arguments":{"message":"hi"},"_meta":{
        "io.modelcontextprotocol/protocolVersion":"2026-07-28",
        "io.modelcontextprotocol/clientCapabilities":{}}}}'
```

## Expected conversations

Both state-machine flows are easier to implement against a concrete exchange than a description.
`_meta`, headers and envelope fields are abbreviated for readability.

### Multi-round-trip: `approval_required`

The server keeps nothing between the two calls. Everything it needs to resume travels out in
`requestState` and comes back untouched.

**1. Client calls the tool.** The client declared `elicitation` in `clientCapabilities`.

```jsonc
{"method":"tools/call","params":{"name":"approval_required",
 "arguments":{"request_summary":"delete order 4711"}}}
```

**2. Server answers `input_required`** — not an error, and not the final result:

```jsonc
{"result":{"resultType":"input_required",
  "inputRequests":{"approval":{"method":"elicitation/create","params":{
      "mode":"form","message":"Approve 'delete order 4711'?",
      "requestedSchema":{"type":"object",
        "properties":{"approval_reason":{"type":"string","title":"Approval reason"}},
        "required":["approval_reason"]}}}},
  "requestState":"demo-approval:delete order 4711"}}
```

**3. Client asks the user, then repeats the original call** with `requestState` echoed back
verbatim and the answer keyed by the same `approval` key:

```jsonc
{"method":"tools/call","params":{"name":"approval_required",
 "arguments":{"request_summary":"delete order 4711"},
 "requestState":"demo-approval:delete order 4711",
 "inputResponses":{"approval":{"action":"accept",
   "content":{"approval_reason":"checked with finance"}}}}}
```

**4. Server completes**, recovering the summary from `requestState` and the reason from the form:

```jsonc
{"result":{"resultType":"complete","content":[{"type":"text",
  "text":"Approved 'delete order 4711'. Reason given by the user: checked with finance."}]}}
```

If the user declines or cancels, step 3 carries `{"action":"decline"}` with no `content` and the
tool completes normally with a declined message — a refusal is a valid outcome, not an error. A
retry answering some *other* key returns `isError` so the model can correct itself.

### Tasks: `background_report`

**1. Client calls the tool** having declared the tasks extension
(`clientCapabilities.extensions["io.modelcontextprotocol/tasks"]`, or legacy `params.task`):

```jsonc
{"method":"tools/call","params":{"name":"background_report"}}
```

**2. Server returns a task handle immediately** — the work is not done yet:

```jsonc
{"result":{"resultType":"task","taskId":"35C4DBDA…","status":"working",
  "pollIntervalMs":1000,"createdAt":"…","lastUpdatedAt":"…","ttlMs":null}}
```

**3. Client polls** at roughly `pollIntervalMs`, quoting the id in the body and, ideally, in
`Mcp-Name` too:

```jsonc
{"method":"tasks/get","params":{"taskId":"35C4DBDA…"}}
```

```jsonc
{"result":{"resultType":"complete","taskId":"35C4DBDA…","status":"working",
  "statusMessage":"Demo report progress: 2 of 3 steps"}}
```

**4. After about 15 seconds** the job finishes and the same poll returns the payload:

```jsonc
{"result":{"resultType":"complete","taskId":"35C4DBDA…","status":"completed",
  "result":{"content":[{"type":"text","text":"Demo report finished…"}]}}}
```

`statusMessage` is a stored value the job overwrites, not a notification stream: this SDK cannot
push to a client. A client that polls slowly may go straight from `working` step 1 to `completed`
without ever observing steps 2 and 3, and that is legitimate — never make progress messages
load-bearing.

## Design checklist for copying a demo

- Keep tool names in one constants structure shared by `define_tools` and `call_tool`.
- Declare an input schema for every tool and let `zcl_mcp2_tool_server_base` validate it — including
  an explicit *empty* schema for tools that take no arguments, so clients read "takes nothing"
  rather than "schema unknown".
- Annotate tools that only read with `read_only_hint` (and `idempotent_hint` where it holds), so
  clients need not prompt for confirmation. Remember `destructive_hint` and `open_world_hint`
  default to true: an explicit false needs the paired `*_set` flag.
- Set `get_title` and `get_description`, and widen `get_discover_cache` when the catalog does not
  vary per user. The defaults are deliberately conservative, not recommended.
- Pair every advertised resource template with a working `resources_read` path.
- Scope completion results to the referenced prompt or resource and argument name, and return whole
  candidate values filtered by the typed prefix — the client replaces the argument with what you
  return, so appending to the input produces values like `AAda`.
- Report client and server capability separately (or as a conjunction). A client that would accept
  a task result still cannot get one from a server that does not advertise tasks.
- Never describe a side effect a handler does not perform. A fallback that says "queued for review"
  without a queue teaches the model, and the reader, something false.
- Return tool-level failures with `error_text`; reserve raised `zcx_mcp2_error` exceptions for
  protocol errors.
- Gate tasks and input requests with the base-class capability helpers and keep a synchronous or
  explanatory fallback where the operation permits one.
- Test at least one legacy and one modern context for behavior that depends on the era.
