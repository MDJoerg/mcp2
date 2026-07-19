# Input required — elicitation and sampling (MRTR)

A stateless server cannot open a request to the client. The modern era (`2026-07-28`)
solves this with **multi-round-trip requests (MRTR)**: instead of a final result, the
server answers an MRTR-capable method — `tools/call`, `prompts/get` or `resources/read` —
with `resultType = input_required`,
embedding what it needs (an elicitation form, a URL visit, or a sampling request). The
client fulfils the embedded requests locally and **retries the original call**, attaching
the responses. Your handler sees the retry and completes. All three request classes carry
the same MRTR accessors (`is_retry`, `get_request_state`, `has_input_responses`,
`get_input_response`, `try_get_input_response`).

Everything is correlated through an opaque `requestState` string you choose — the server
keeps no session.

> **Security — `requestState` is attacker-controlled input.** The token round-trips
> through the client, so the spec requires: if it influences authorization, resource
> access, or business logic, you **must** integrity-protect it (HMAC or AEAD) and reject
> state that fails verification. To bound replay, include the authenticated principal
> (reject other users), a short expiry, and an identifier of the originating request
> inside the protected payload. Plain tokens like `approval-4711` below are only
> acceptable when tampering can cause nothing worse than a failed request.

## Gating: who can do MRTR

MRTR is modern-only, and each input kind needs a client capability. Always gate before
returning an inputRequired result. The base class can inspect a typed input builder and apply
the right era/capability check for that specific input kind:

```abap
DATA(elicitation) = NEW zcl_mcp2_input_elicitation( ).
elicitation->set_form( `Approve this request?` ).

IF can_request_input( elicitation ) = abap_false.
  result = zcl_mcp2_resp_call_tool=>text(
    `This workflow needs a modern client with elicitation support.` ).
  RETURN.
ENDIF.

result = input_required( request_key   = `approval`
                         input         = elicitation
                         request_state = `approval-4711` ).
```

Available checks: `client_supports_elicitation`, `client_supports_elicit_url`,
`client_supports_sampling`, `client_supports_tasks`, plus generic `has_client_cap` and
`era_is_modern` / `get_protocol_version`. `can_request_input( )` wraps the MRTR-specific
ones: form elicitation requires `elicitation`, URL elicitation requires `elicitation.url`,
and sampling requires `sampling`.

If you return an inputRequired result ungated, the framework still protects the wire:
legacy clients get `-32600`, modern clients without the required capability get `-32021`.
URL-mode elicitation is checked against the explicit `elicitation.url` sub-capability.

## Round 1 — requesting input

```abap
" 1. A flat form schema (never reuse the tool input schema here)
DATA(form) = NEW zcl_mcp2_elicit_schema(
    )->add_string( name = `reason` title = `Reason`
                   description = `Why should this be approved?` required = abap_true ).

" 2. The elicitation request
DATA(elicitation) = NEW zcl_mcp2_input_elicitation( ).
elicitation->set_form( message          = `Approve this request?`
                       requested_schema = form ).

" 3. The inputRequired result: state token + keyed request
result = input_required( request_key   = `approval`
                         input         = elicitation
                         request_state = `approval-4711` ).
```

- `set_request_state` takes any string that lets the retry leg resume — an id, a
  serialized token, whatever you can decode statelessly.
- `input_required` builds the common single-input response. For multi-input responses,
  instantiate `zcl_mcp2_resp_input_req` directly; `add_request` accepts any
  `zif_mcp2_input_request` implementor and can be called multiple times.
- **URL mode**: `elicitation->set_url( message = `Sign in first` url = `https://...` )` —
  gate with `can_request_input( )` or `client_supports_elicit_url( )`.
- **Sampling**: `zcl_mcp2_input_sampling` asks the client's model for a completion —
  fluent `add_user_text` / `add_assistant_text` / `set_system_prompt` /
  `set_max_tokens`; gate with `can_request_input( )` or `client_supports_sampling( )`.

## Round 2 — the retry

The client retries the same method with `inputResponses` and — only if you sent one —
`requestState`. `is_retry( )` is true when either field is present, so it also covers
servers that send `inputRequests` without a state token:

```abap
IF request->is_retry( ) = abap_true AND request->has_input_responses( ) = abap_true.
  DATA(state) = request->get_request_state( ).      " your `approval-4711`

  DATA(elicit) = request->try_get_input_response( `approval` ).  " zcl_mcp2_elicit_result
  IF elicit IS NOT BOUND.
    " ... the retry answered some other key - report a tool error
  ELSEIF elicit->is_accept( ) = abap_true.
    DATA(reason) = elicit->get_string( `reason` ).
    " ... complete the business action, return the final result
  ELSE.                                             " is_decline( ) / is_cancel( )
    " ... aborted by the user
  ENDIF.
  RETURN.
ENDIF.
```

`try_get_input_response` returns unbound when your key was not answered;
`get_input_response` is the raising variant (`-32602` when the key is absent). Both raise
when a present answer is malformed. `zcl_mcp2_elicit_result` parses the elicitation
answer: `get_action` / `is_accept|decline|cancel`, `has_content`, and typed field access
(`get_string`, `get_integer`, `get_boolean`). For sampling responses use
`request->get_input_responses( )` and read the `CreateMessageResult` JSON under your key.

The reference TypeScript SDK fulfils this loop automatically (its inputRequired driver
dispatches embedded requests to registered handlers and retries) — the integration suite
proves interop against it.

## <a name="tasks"></a>Tasks: input mid-background-job

A running [task](Tasks.md) can park on user input without an open HTTP request:

```abap
" In the background unit: ask and park (status -> input_required)
zcl_mcp2_tasks=>request_input( task_id     = task_id
                               request_key = `confirm`
                               input       = elicitation ).
```

The client sees `input_required` plus `inputRequests` on `tasks/get`, answers via
`tasks/update` (`taskId` + `inputResponses`, keyed by the `inputRequests` keys), and the
framework stores only responses for outstanding keys (`consume_update`, which also verifies
the creating user). Unknown and already-satisfied keys are successful no-ops. A partial answer
retains the unanswered requests and leaves the task in `input_required`; only a complete answer
set moves it back to `working`. The typed consume result exposes `accepted_keys`,
`remaining_keys`, and `ready`. Your background unit picks the answers up from the task row and
finishes with `complete` / `fail`.

Request keys are lifetime-unique within a task. Reusing a key after it has already been answered
is rejected, preventing a later input round from being confused with an earlier response.

Unlike the original-request MRTR flow, task input carries **no `requestState`**: the spec
keys task input by the `inputRequests` keys, so there is nothing to correlate across a
retry. If a background unit needs its own continuation context, encode it in the
`request_key` or in your own storage.

## Legacy clients

The legacy era has no MRTR vocabulary. The framework converts any inputRequired result
into `-32600` with a pointing message; design legacy paths to either work without input
or return an explanatory text result (gate as shown above).

`ZCL_MCP2_DEMO_WF.approval_required` shows a safe differentiated path: a capable modern client
receives form elicitation, a modern client that omitted the capability is told that approval was
not attempted, and a legacy client is told the request would need manual review. The legacy path
deliberately does not treat a tool argument as proof of user approval — and it says plainly that
nothing was submitted rather than implying a queue or workflow it does not actually feed. When a
fallback cannot complete the operation, describe the situation; do not claim a side effect.

The demo also keeps the two questions distinct: `request_summary` (a tool argument: *what* needs
approving) and the elicited `approval_reason` (*why* the user approved it). Reusing one name for
both makes the round trip much harder to follow. See the annotated exchange in
[Demo servers](DemoServers.md#multi-round-trip-approval_required).
