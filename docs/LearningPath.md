# Learning path

This path turns the reference guides and demo servers into a sequence of small exercises. Follow
the core path in order; take the compatibility and advanced branches when they become relevant to
your server. Each stage should leave you with working ABAP, not just protocol vocabulary.

## Core path

### 1. Run one tool

Read [Getting started](GettingStarted.md) through “Test it without HTTP”. Copy the `greet` server,
call it directly from ABAP Unit, and then register it behind ICF.

**Checkpoint:** you can explain the roles of the server class, dispatcher, HTTP handler, and
`zmcp2_servers` registration row.

### 2. Define a reliable tool contract

Read [Tools](Tools.md) and the general-builder section of [Schemas](Schemas.md). In
`ZCL_MCP2_DEMO_BASIC`, inspect `define_tools`, `build_stats_schema`, and `handle_text_stats`. Call
`text_stats` once with valid arguments and once without its required `text` argument.

Then add one typed argument and one structured result field to your own tool.

**Checkpoint:** you know when to use `require_arg_*`, `get_arg_*_or`, `bind_arguments`, plain text,
structured output, `error_text`, and a raised protocol error.

### 3. Add discoverable context

Read [Server identity and request context](ServerContext.md). Give your server a title,
description, and useful instructions, and decide a `get_discover_cache` policy —
`ZCL_MCP2_DEMO_BASIC` overrides all four. Call `ZCL_MCP2_DEMO_BASIC.request_info` and inspect how
the handler uses typed context helpers without parsing `_meta`, and how it reports client and
server task capability as two separate facts rather than one flag.

**Checkpoint:** your server is recognizable in a client UI, and application code does not depend
on raw protocol metadata paths.

### 4. Expose information as a resource

Read [Resources](Resources.md). List and read the demo README resource, then expand and read
`mcp2://demo/greeting/{name}`. Add one concrete resource to your server; add a template only if
clients can meaningfully choose its variables.

**Checkpoint:** every listed concrete URI and every expanded template has a working read path and
unknown URIs use the resource-not-found helper so the dispatcher can emit the era-specific code.

### 5. Guide users with prompts and completions

Read [Prompts](Prompts.md) and [Completions](Completions.md). Get the demo `summarize` prompt and
request completions for its `topic` argument and for the greeting template's `name` variable.

**Checkpoint:** completion code checks the reference and argument it is completing, and an
unrelated reference receives an empty completion list.

Resources, templates, prompts, and completions normally use the same application handlers in both
protocol eras. Compatibility conversion belongs to the dispatcher and response data classes. Add
an era branch only when the protocol actually changes what the client can consume, such as a
modern-only input request.

### 6. Make it production-ready

Read [Configuration and security](ConfigurationAndSecurity.md). Configure authentication and CORS
for the intended caller, verify error-to-HTTP mapping, and add ABAP Unit tests around your server
handlers. Review cache hints in [Server identity and request context](ServerContext.md) if discovery
or catalogs are stable.

**Checkpoint:** authorization is based on the authenticated ABAP user, client-supplied metadata is
treated as untrusted, and both success and failure paths have tests.

## Compatibility branch

Take this branch after stage 2 if legacy clients matter.

1. Read the era overview and exclusions in [Protocol support](ProtocolSupport.md).
2. Follow the [demo compatibility walkthrough](DemoServers.md#backward-compatibility-walkthrough).
3. Call `request_info` from a legacy client and a modern client.
4. Send invalid `text_stats` arguments in both eras and confirm both return an actionable
   `isError` tool result rather than a JSON-RPC request error.
5. Add a legacy and a modern context test for any behavior in your server that depends on client
   capabilities.

**Checkpoint:** one application handler serves both eras; it asks semantic capability helpers
instead of branching on version strings or maintaining a legacy implementation.

## Advanced workflow branch

Take this branch only when an operation genuinely needs another round trip or background work.

### 7. Request client input

Read [Input required](InputRequired.md), then trace `ZCL_MCP2_DEMO_WF.approval_required`: initial
call, legacy explanatory fallback, modern capability fallback, `inputRequired`, echoed
`requestState`, and retry response. The
[annotated exchange](DemoServers.md#multi-round-trip-approval_required) shows all four messages
if the code path is easier to follow with the wire format beside it.

**Checkpoint:** the server retains no continuation state, validates the returned input key, and
has an explicit path for clients that cannot satisfy the request.

### 8. Run long work as a task

Read [Tasks](Tasks.md), then call `background_report` without task support, with legacy per-call
task opt-in, and with the modern tasks extension. Observe `working` in the create result and poll
`tasks/get` while `ZMCP2_DEMO_TASK` advances its stored status through three five-second steps and
completes independently of the client — nothing is pushed, and a slow poller may never see the
intermediate steps ([annotated exchange](DemoServers.md#tasks-background_report)). Inspect the
report to see cancellation checks, progress updates, completion, and failure handling. In an
application, extend this job pattern or replace it with bgRFC or your own worker.

**Checkpoint:** the tool offers a useful synchronous fallback, task creation is capability-gated,
and background code completes or fails the persisted task explicitly.

## Reference path for SDK contributors

Application authors can stop after the relevant branches above. Contributors changing protocol
or conversion behavior should additionally read [Architecture](Architecture.md),
[Conversion](Conversion.md), [Platform abstraction](PlatformAbstraction.md), and the complete
[Protocol support matrix](ProtocolSupport.md), then extend dispatcher and data-class tests in both
eras.
