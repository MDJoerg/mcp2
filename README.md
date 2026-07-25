# ABAP Model Context Protocol Server SDK v2 (`mcp2`)

A stateless, rewrite of the ABAP [Model Context Protocol](https://modelcontextprotocol.io/)
server SDK, targeting the upcoming **`2026-07-28`** protocol generation while staying downward
compatible with the legacy era (`2025-03-26` … `2025-11-25`).

> MCP `2026-07-28` draft synchronous request/response profile. SSE, subscriptions,
> streaming responses, sessions, and server-pushed notifications are unsupported.
> Legacy revisions are served statelessly with the latest legacy data shapes.

This is a **server** implementation only. It is **stateless** — no protocol sessions, no SSE —
so notification- and subscription-based features are out of scope by design (see
[docs/ProtocolSupport.md](docs/ProtocolSupport.md)).

> **Status:** `0.1.0` — first beta ([changelog](CHANGELOG.md)). Pre-release: the ABAP API surface
> is not frozen and breaking changes may land in any release before `1.0.0`.
> Active v2 implementation for the stateless `2026-07-28` protocol generation.
> Protocol core, data classes, HTTP runtime, config/factory, DDIC tables, demo servers and
> the request/response Tasks extension are implemented and covered by abaplint plus the
> external Jest integration suite in the sibling `mcp2_tests` repository. The original
> session-based SDK lives separately and is unaffected; this package uses the distinct `mcp2`
> object prefix so both can coexist in one ABAP system.

## Main Differences from V1 MCP SDK

- Currently no 7.x downport - planned to be added with release, like within 1 month of spec release
- No sessions, etc. 
- No default auth object and check delivered --> you **must** implement your own auth checks if required, see [Configuration and security](docs/ConfigurationAndSecurity.md)
- No table maintenance due to frequent install issues

## Intentionally not supported

- ABAP Cloud - with SAP pushing towards using their MCP strategy and features in BTP I see no reason to put in the required effort

## Documentation

**User guide** — building servers with the SDK:

- [Getting started](docs/GettingStarted.md) — install, ICF setup, first server
- [Learning path](docs/LearningPath.md) — staged exercises from first tool to MRTR and tasks
- [Demo servers](docs/DemoServers.md) — feature map and legacy/modern walkthrough
- [Server identity and request context](docs/ServerContext.md) — metadata, capabilities, tracing, caching
- [Tools](docs/Tools.md) — arguments, content blocks, structured output, validation
- [Resources](docs/Resources.md) — resources, reads, templates
- [Prompts](docs/Prompts.md) — prompt templates and arguments
- [Completions](docs/Completions.md) — argument autocompletion
- [Schemas](docs/Schemas.md) — schema builders (general / DDIC / elicitation) + validator
- [Input required (MRTR)](docs/InputRequired.md) — elicitation, sampling, URL mode
- [Tasks](docs/Tasks.md) — long-running background work
- [Configuration and security](docs/ConfigurationAndSecurity.md) — tables, CORS, auth, error mapping
- [Troubleshooting](docs/Troubleshooting.md) — symptom-first index of common failures
- [Migrating from v1](docs/MigrationV1.md) — what changes, what is dropped, suggested order

**Reference** — design and internals:

- [Class reference](docs/Reference.md) — every public class, what it is for, where it is explained
- [Architecture](docs/Architecture.md) — design, packages, eras, request flow
- [Protocol support](docs/ProtocolSupport.md) — versions, methods, what is excluded and why
- [Conversion](docs/Conversion.md) — per-field data-class conversion conventions
- [Platform abstraction](docs/PlatformAbstraction.md) — HTTP/DDIC wrapping and the ABAP Cloud roadmap

## Design at a glance

- **Stateless only** — every request is self-contained; no `Mcp-Session-Id`, no session tables.
- **One server contract, two protocol eras** — legacy `initialize` and modern per-request
  `_meta` negotiation served by the same `zif_mcp2_server`.
- **Typed authoring surface** — common server-authoring paths need no hand-written JSON: typed
  request getters (`require_arg_string`,
  `get_arg_string_or`, `bind_arguments`),
  typed response factories (`zcl_mcp2_resp_call_tool=>text`,
  `=>error_text`, `=>structured_data`) and full-control builders (`add_resource`,
  `add_resource_link`, `set_structured_data`) with typed content annotations
  (`zif_mcp2_content`), fluent schema builders (`zcl_mcp2_schema_builder` for tool schemas,
  `zcl_mcp2_elicit_schema` for flat elicitation forms), and typed input-request builders
  (`zcl_mcp2_input_elicitation`,
  `zcl_mcp2_input_sampling`) unified by `zif_mcp2_input_request`. UI icons are typed
  everywhere the spec allows them: serverInfo (`get_icons`), tools, prompts, resources,
  resource templates and resource links (`zif_mcp2_content=>icons`). Pre-built ajson remains an
  escape hatch for rich prompt content and custom extensions.
- **Tool catalog base** — inherit from `zcl_mcp2_tool_server_base`, declare `define_tools( )`
  once, and implement `call_tool( )`. The base derives `supports_tools`, `tools/list`,
  `get_tool_schema`, unknown-tool rejection, and default schema validation from the catalog.
  Advertised-schema violations are returned as `isError` tool results in both eras;
  structurally malformed calls and unknown tools remain `-32602`.
- **Era-aware capability checks** on the base class — `client_supports_elicitation`,
  `client_supports_elicit_url`, `client_supports_sampling`, `client_supports_tasks`
  (modern: declared extension; legacy: per-request `params.task` opt-in), `era_is_modern`,
  `get_protocol_version`, plus `can_request_input` / `input_required` for MRTR, let authors
  safely gate era- and client-dependent features instead of hitting a framework
  `-32021`/`-32600`. Of the features SEP-2577 deprecates in
  `2026-07-28`, Roots and Logging are not implemented; Sampling is kept (as an MRTR input
  builder) because it is the only key-less LLM access path from ABAP.
- **Request context without `_meta` parsing** — client identity, negotiated protocol,
  log-level hints and W3C trace context are available through typed base-class getters.
- **`serverInfo` lives in `_meta` in the modern era.** The `2026-07-28` draft moved `serverInfo`
  out of the top-level result and into `_meta["io.modelcontextprotocol/serverInfo"]` (the
  `ResultMetaObject` shape) on 2026-07-16, so the SDK emits it there on **every** modern result,
  `server/discover` included, and nowhere else
  ([details](docs/ProtocolSupport.md#caching--discovery)). Legacy `initialize` is unaffected:
  `serverInfo` stays a plain top-level field there.
- **Conversion in the data class** — explicit per-field JSON↔ABAP; central code only for the
  JSON-RPC envelope and the modern result stamp.

## Target / tooling

- ABAP **7.5x** classic (first iteration). abaplint `v752`.
- ABAP 7.4x donwport planned to be added after beta phase, cloud-ready not planned.
- Distributed via [abapGit](https://github.com/abapGit/abapGit).

## Used ABAP open-source projects

- [ajson](https://github.com/sbcgua/ajson) — JSON library, vendored as `zmcp2_ajson` (MIT).
- [abaplint](https://github.com/abaplint/abaplint) — linting and transpiler-based unit tests.
- [abapGit](https://github.com/abapGit/abapGit) — source control.

More awesome ABAP projects at [dotabap.org](https://dotabap.org/).

## Development checks

- Static check: `npm install` once, then `npm run lint` (abaplint, config in
  [abaplint.json](abaplint.json)).
- Behavior: the Jest integration suite in the sibling `mcp2_tests` repository, run against an
  ABAP system serving the SDK and its test servers. It covers both protocol eras against the
  reference TypeScript SDK plus raw-HTTP wire checks.
- ABAP unit tests run in the ABAP system (SE80/ADT); the transpiler-based local run only
  covers a subset (no database, vendored-ajson unicode test excluded).

## License

MIT. Vendored dependencies retain their original licenses; see
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
