# Class reference

A lookup index for the SDK's public surface. Each entry says what the class is for and which
guide explains it — the guides hold the usage patterns, this page just gets you to the right one.

Classes marked **internal** are part of the runtime and not meant to be called from a server
implementation; they are listed so the package contents are not a mystery.

## Start here

| Class | Purpose | Guide |
| --- | --- | --- |
| `zcl_mcp2_tool_server_base` | Preferred base for tool servers: declare `define_tools( )`, implement `call_tool( )` | [Tools](Tools.md) |
| `zcl_mcp2_server_base` | Base for servers needing resources, prompts, completions or custom `tools/list` | [Server context](ServerContext.md) |
| `zif_mcp2_server` | The server contract both bases implement — including `check_authorization`, the opt-in endpoint access check | [Architecture](Architecture.md), [Configuration and security](ConfigurationAndSecurity.md#endpoint-authorization--check_authorization) |

## Requests — what the client sent

All are constructed by the dispatcher and handed to your handler. Constructor takes the `params`
slice as `zif_mcp2_ajson`, so you can build one directly in a unit test
([Getting started §6](GettingStarted.md#6-test-it-without-http)).

| Class | Method | Guide |
| --- | --- | --- |
| `zcl_mcp2_req_call_tool` | `tools/call` — typed argument getters, `bind_arguments`, MRTR accessors | [Tools](Tools.md) |
| `zcl_mcp2_req_get_prompt` | `prompts/get` — string argument getters, MRTR accessors | [Prompts](Prompts.md) |
| `zcl_mcp2_req_read_resource` | `resources/read` — `get_uri`, MRTR accessors | [Resources](Resources.md) |
| `zcl_mcp2_req_complete` | `completion/complete` — ref type/name/uri, argument + context | [Completions](Completions.md) |
| `zcl_mcp2_req_list_tools`<br>`zcl_mcp2_req_list_resources`<br>`zcl_mcp2_req_list_res_tmpls`<br>`zcl_mcp2_req_list_prompts` | The `*/list` methods — pagination via `has_cursor` / `get_cursor` | [Tools](Tools.md) |
| `zcl_mcp2_req_get_task`<br>`zcl_mcp2_req_get_task_payload`<br>`zcl_mcp2_req_list_tasks`<br>`zcl_mcp2_req_cancel_task`<br>`zcl_mcp2_req_update_task` | The `tasks/*` methods — normally handled by the base class | [Tasks](Tasks.md) |

## Responses — what you return

| Class | Returned from | Guide |
| --- | --- | --- |
| `zcl_mcp2_resp_call_tool` | `tools/call`. Factories `text( )` / `error_text( )` / `structured_data( )`; builders `add_text`, `add_image`, `add_audio`, `add_resource`, `add_resource_link` | [Tools](Tools.md) |
| `zcl_mcp2_resp_get_prompt` | `prompts/get` — `add_user_text`, `add_assistant_text`, `add_message` | [Prompts](Prompts.md) |
| `zcl_mcp2_resp_read_resource` | `resources/read` — `add_text_content`, `add_blob_content` | [Resources](Resources.md) |
| `zcl_mcp2_resp_list_resources`<br>`zcl_mcp2_resp_list_res_tmpls`<br>`zcl_mcp2_resp_list_prompts`<br>`zcl_mcp2_resp_list_tools` | The `*/list` methods — `add_*`, `set_next_cursor`, `set_cache` | [Resources](Resources.md), [Prompts](Prompts.md) |
| `zcl_mcp2_resp_complete` | `completion/complete` — `add_value`, `set_total`, `set_has_more` | [Completions](Completions.md) |
| `zcl_mcp2_resp_input_req` | An MRTR `input_required` result. `input_required( )` on the base builds the common single-input case | [Input required](InputRequired.md) |
| `zcl_mcp2_resp_task_payload` | The terminal payload a background unit stores via `complete( )` | [Tasks](Tasks.md) |
| `zcl_mcp2_resp_empty` | Acknowledgement-only results | — |
| `zif_mcp2_result` | Implemented by every result class; carries `to_json` + the envelope hints the dispatcher stamps | [Conversion](Conversion.md) |

Task result shapes are built for you by `start_task( )` and the `tasks/*` handlers —
`zcl_mcp2_resp_task`, `zcl_mcp2_resp_task_get`, and the `*_lgcy` legacy variants
(`zcl_mcp2_resp_create_task_lgcy`, `zcl_mcp2_resp_get_task_lgcy`,
`zcl_mcp2_resp_list_tasks_lgcy`) are selected by era and rarely constructed by hand.

## Schemas and validation

| Class | Purpose | Guide |
| --- | --- | --- |
| `zcl_mcp2_schema_builder` | Fluent JSON Schema builder for tool input/output — nesting, arrays, `x-mcp-header` | [Schemas](Schemas.md) |
| `zcl_mcp2_schema_builder_ddic` | Derive a tool schema from a DDIC structure | [Schemas](Schemas.md) |
| `zcl_mcp2_elicit_schema` | Flat form schema for elicitation (`PrimitiveSchemaDefinition`) | [Schemas](Schemas.md) |
| `zcl_mcp2_schema_validator` | Validate an instance against the supported schema subset | [Schemas](Schemas.md#validator) |

## Input requests (MRTR)

| Class | Purpose | Guide |
| --- | --- | --- |
| `zif_mcp2_input_request` | Common contract (`get_method` / `get_params`) — accepted anywhere an input request is taken | [Input required](InputRequired.md) |
| `zcl_mcp2_input_elicitation` | Form- and URL-mode elicitation | [Input required](InputRequired.md) |
| `zcl_mcp2_input_sampling` | `sampling/createMessage` — ask the client's model | [Input required](InputRequired.md) |
| `zcl_mcp2_elicit_result` | Parse the client's elicitation answer (`is_accept`, `get_string`, …) | [Input required](InputRequired.md) |

## Tasks

| Class | Purpose | Guide |
| --- | --- | --- |
| `zcl_mcp2_tasks` | Task lifecycle. Instance methods for request-time use (via `get_tasks( )`); **class** methods `complete` / `fail` / `update_status` / `request_input` / `consume_update` for background units | [Tasks](Tasks.md) |
| `zif_mcp2_task_executor` | Optional shape for a background worker. **No SDK code calls it** — a convention, not a registration | [Tasks](Tasks.md) |
| `zcl_mcp2_task_util` | *Internal* — task id/status helpers | — |

## Shared types and errors

| Class | Purpose | Guide |
| --- | --- | --- |
| `zif_mcp2_const` | `sdk_version`, protocol versions, result types, cache scopes, task statuses, `task_support`, elicit formats, icon themes | — |
| `zif_mcp2_content` | Content-block structures: `annotations`, `icon`/`icons`, `resource_contents`, `resource_link` | [Conversion](Conversion.md) |
| `zcx_mcp2_error` | Protocol errors. Raise via `raise_invalid_params`, `raise_method_not_found`, `raise_resource_not_found`, … | [Configuration and security](ConfigurationAndSecurity.md#http-behavior-and-error-mapping) |
| `zcl_mcp2_icons` | *Internal* — the single icon-array emitter | [Conversion](Conversion.md#icons) |

## Runtime — you rarely touch these

| Class | Purpose | Guide |
| --- | --- | --- |
| `zcl_mcp2_http_handler` | The ICF entry point you register in SICF | [Getting started](GettingStarted.md#2-create-the-icf-service) |
| `zcl_mcp2_dispatch_legacy`<br>`zcl_mcp2_dispatch_modern` | Per-era routing. Useful directly in unit tests | [Getting started §6](GettingStarted.md#6-test-it-without-http) |
| `zcl_mcp2_jsonrpc` | JSON-RPC envelope parse/serialize | [Conversion](Conversion.md) |
| `zcl_mcp2_version` | Era detection and version negotiation | [Protocol support](ProtocolSupport.md) |
| `zcl_mcp2_server_factory` | Resolves the `zmcp2_servers` row to an instance | [Configuration](ConfigurationAndSecurity.md) |
| `zcl_mcp2_config` | Reads `zmcp2_config` / `zmcp2_origins` | [Configuration](ConfigurationAndSecurity.md) |
| `zif_mcp2_http_request`<br>`zif_mcp2_http_response`<br>`zcl_mcp2_http_factory`<br>`zcl_mcp2_http_req_icf`<br>`zcl_mcp2_http_resp_icf` | HTTP abstraction and its 7.5x ICF implementation | [Platform abstraction](PlatformAbstraction.md) |
| `zif_mcp2_ddic` / `zcl_mcp2_ddic_75` | DDIC metadata abstraction for the schema builder | [Platform abstraction](PlatformAbstraction.md) |
| `zcx_mcp2_ddic_error` | Raised by DDIC schema derivation | [Schemas](Schemas.md) |

## Tables and reports

| Object | Purpose | Guide |
| --- | --- | --- |
| `zmcp2_servers` | Server registry — `AREA` / `SERVER` → class | [Configuration](ConfigurationAndSecurity.md) |
| `zmcp2_origins` | Browser origin allow-list | [Configuration](ConfigurationAndSecurity.md) |
| `zmcp2_config` | Global switches (`CORS_MODE`), one row per SAP client | [Configuration](ConfigurationAndSecurity.md) |
| `zmcp2_tasks` | Task rows (runtime data, delivery class A) | [Tasks](Tasks.md) |
| `ZMCP2_CLEAR_TASKS` | Housekeeping report — schedule as a batch job | [Tasks](Tasks.md#housekeeping) |
| `ZMCP2_DEMO_TASK` | Background job used by the workflow demo | [Demo servers](DemoServers.md) |

## Demo servers

| Class | Shows | Guide |
| --- | --- | --- |
| `zcl_mcp2_demo_basic` | Tools, schemas, resources, templates, prompts, completions, request context | [Demo servers](DemoServers.md) |
| `zcl_mcp2_demo_wf` | Capability gating, MRTR elicitation, a real background task | [Demo servers](DemoServers.md) |
