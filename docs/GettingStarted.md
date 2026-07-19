# Getting Started

This guide walks you from installation to a working MCP server responding to real clients.

## Prerequisites

- ABAP 7.5x system (7.52 language level or higher)
- [abapGit](https://abapgit.org/) installed
- Authorization to create ICF services (transaction SICF)

## 1. Install

Pull this repository into your system with abapGit (online or offline). Everything ships in
one package with the `zmcp2` object prefix — classes, interfaces, four DDIC tables
(`zmcp2_servers`, `zmcp2_origins`, `zmcp2_config`, `zmcp2_tasks`) and the vendored ajson
JSON library. Activate everything; the DDIC tables need no manual conversion.

## 2. Create the ICF service

In **SICF**, create a service node (for example `/zmcp2`) and assign
`ZCL_MCP2_HTTP_HANDLER` as its handler class. Activate the node.

The path below the service node selects the server:

```
POST /zmcp2/{AREA}/{SERVER}
```

`AREA` and `SERVER` are resolved against the `zmcp2_servers` table (case-sensitive). An
optional `mcp` path prefix (`/zmcp2/mcp/{AREA}/{SERVER}`) is also accepted.

Authentication is plain ICF: whatever logon procedure the service node is configured with
(basic auth, SSO, certificates) applies before the SDK ever runs.

## 3. Write a server class

For a tool server, inherit from `zcl_mcp2_tool_server_base`, provide a name/version, declare
your tool catalog once, and implement the tool behavior:

```abap
CLASS zcl_my_server DEFINITION PUBLIC
  INHERITING FROM zcl_mcp2_tool_server_base CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS zif_mcp2_server~get_name    REDEFINITION.
    METHODS zif_mcp2_server~get_version REDEFINITION.

  PROTECTED SECTION.
    METHODS define_tools REDEFINITION.
    METHODS call_tool    REDEFINITION.
ENDCLASS.

CLASS zcl_my_server IMPLEMENTATION.
  METHOD zif_mcp2_server~get_name.
    result = `my-server`.
  ENDMETHOD.

  METHOD zif_mcp2_server~get_version.
    result = `1.0.0`.
  ENDMETHOD.

  METHOD define_tools.
    result = VALUE #( ( name         = `greet`
                        title        = `Greet`
                        description  = `Greets a person by name.`
                        input_schema = NEW zcl_mcp2_schema_builder(
                          )->add_string( name = `name` required = abap_true
                          )->to_json( ) ) ).
  ENDMETHOD.

  METHOD call_tool.
    result = zcl_mcp2_resp_call_tool=>text(
      |Hello, { request->require_arg_string( `name` ) }!| ).
  ENDMETHOD.
ENDCLASS.
```

`zcl_mcp2_tool_server_base` derives `supports_tools`, `tools_list`, `get_tool_schema`, and
input validation from `define_tools`. Calls for names not declared in the catalog are rejected
before `call_tool` runs. For non-tool features, inherit from `zcl_mcp2_server_base` or combine
the tool base with the extra handlers you need.

The base also exposes the current client, protocol era, capabilities, log-level hint and trace
context without raw `_meta` parsing. See [Server identity and request context](ServerContext.md).

## 4. Register the server

Add a row to `zmcp2_servers` (SM30/SE16, or via abapGit table content — see
[Configuration](ConfigurationAndSecurity.md)):

| AREA | SERVER | CLASS |
| --- | --- | --- |
| `DEMO` | `GREETER` | `ZCL_MY_SERVER` |

The server is now live at `POST /zmcp2/DEMO/GREETER`.

If browsers will call the endpoint, also add allowed origins to `zmcp2_origins` — with no
rows for your area/server, every request carrying an `Origin` header is rejected with 403.
Requests without an `Origin` header (curl, server-to-server, most desktop clients) are
always allowed.

## 5. Test it

With a client that supports the stateless MCP draft transport — for example the TypeScript SDK:

```ts
const client = new Client({ name: "test", version: "1.0" });
await client.connect(new StreamableHTTPClientTransport(
    new URL("https://your-host:port/zmcp2/DEMO/GREETER")));
const result = await client.callTool({ name: "greet", arguments: { name: "Basti" } });
```

Or raw legacy JSON-RPC with curl:

```bash
curl -X POST https://your-host:port/zmcp2/DEMO/GREETER \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{
        "protocolVersion":"2025-11-25",
        "clientInfo":{"name":"curl","version":"1.0"},"capabilities":{}}}'
```

Both protocol eras are served automatically from the same class: legacy clients
(`2025-03-26` … `2025-11-25`) negotiate via `initialize`, modern clients (`2026-07-28`)
send per-request `_meta` and can use `server/discover`. See
[Protocol support](ProtocolSupport.md) for what each era gets.

A modern discovery request needs the draft Streamable HTTP headers plus request `_meta`:

```bash
curl -X POST https://your-host:port/zmcp2/DEMO/GREETER \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -H "MCP-Protocol-Version: 2026-07-28" \
  -H "Mcp-Method: server/discover" \
  -d '{"jsonrpc":"2.0","id":1,"method":"server/discover","params":{"_meta":{
        "io.modelcontextprotocol/protocolVersion":"2026-07-28",
        "io.modelcontextprotocol/clientInfo":{"name":"curl","version":"1.0"},
        "io.modelcontextprotocol/clientCapabilities":{}}}}'
```

## 6. Test it without HTTP

Your server is plain ABAP — no ICF service is needed to exercise it. In an ABAP Unit
test (or a console snippet), construct the typed request from JSON and call the handler
directly:

```abap
DATA(server)  = NEW zcl_my_server( ).
DATA(request) = NEW zcl_mcp2_req_call_tool( zcl_mcp2_ajson=>parse(
  `{"name":"greet","arguments":{"name":"Basti"}}` ) ).

DATA(result) = server->zif_mcp2_server~tools_call( request ).
DATA(json)   = result->to_json( ).
cl_abap_unit_assert=>assert_equals(
  exp = `Hello, Basti!`
  act = json->get_string( '/content/1/text' ) ).
```

Or drive a full JSON-RPC round-trip through a dispatcher — every request is
self-contained, so a single `tools/call` works without a prior `initialize`:

```abap
DATA(dispatcher) = NEW zcl_mcp2_dispatch_legacy( NEW zcl_my_server( ) ).
DATA(response)   = dispatcher->dispatch( zcl_mcp2_jsonrpc=>parse_request(
  `{"jsonrpc":"2.0","id":1,"method":"tools/call",` &&
  `"params":{"name":"greet","arguments":{"name":"Basti"}}}` ) ).
DATA(body) = zcl_mcp2_jsonrpc=>serialize_response( response ).
```

`zcl_mcp2_dispatch_modern` works the same way for the modern era; its `dispatch`
additionally accepts the `MCP-Protocol-Version` header value and an optional wrapped HTTP
request for header mirroring. The SDK's own testclasses use exactly these patterns.

## Demo servers

Two ready-to-register demo implementations ship with the SDK:

- `ZCL_MCP2_DEMO_BASIC` — a `request_info` tool that makes compatibility context visible,
  an echo tool with header mirroring, a `text_stats` tool showing
  `bind_arguments` and structured output, a `ddic_schema` tool showing the
  [DDIC schema builder](Schemas.md), a static resource, a readable resource template, a prompt,
  and completions.
- `ZCL_MCP2_DEMO_WF` — an approval workflow that uses modern MRTR elicitation and explains the
  manual-review path to legacy clients ([Input required](InputRequired.md)), plus a task that runs
  in the real `ZMCP2_DEMO_TASK` background report and advances its status for about 15 seconds,
  observable by polling `tasks/get` ([Tasks](Tasks.md)). The scheduling user must be allowed to
  create immediate background jobs.

See [Demo servers](DemoServers.md) for a feature map, a suggested walkthrough, and a concrete
legacy-versus-modern compatibility exercise.

## Where to go next

- [Learning path](LearningPath.md) — follow the guides and demos as staged, testable exercises
- [Tools](Tools.md) — arguments, content blocks, structured output, validation
- [Server identity and request context](ServerContext.md) — metadata, capabilities, tracing, caching
- [Resources](Resources.md) and [Prompts](Prompts.md)
- [Completions](Completions.md) — argument autocompletion
- [Schemas](Schemas.md) — the three schema builders and the validator
- [Input required (MRTR)](InputRequired.md) — elicitation and sampling round-trips
- [Tasks](Tasks.md) — long-running background work
- [Configuration and security](ConfigurationAndSecurity.md) — tables, CORS, error mapping
- [Troubleshooting](Troubleshooting.md) — when a request fails and it is not obvious why
- [Class reference](Reference.md) — the public class index
