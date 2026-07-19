# Platform abstraction — cloud-readiness without cloud cost (yet)

> Status: **implemented** for 7.5x classic (`zcl_mcp2_http_req_icf` / `zcl_mcp2_http_resp_icf` /
> `zcl_mcp2_ddic_75` behind the interfaces below). The ABAP Cloud implementations remain
> deliberately deferred — building them is new implementations plus a factory change, no core
> change. Also still open: whether to trim the vendored ajson `libs` to the mapping code
> actually used.

## Goal

The first iteration runs on **ABAP 7.5x classic** only. But we want a later **ABAP Cloud** port
(ABAP for Cloud / Steampunk-style restricted runtime) to be a *small, localized* change rather
than a rewrite. The way to get there cheaply is to route every **environment-sensitive call**
through a thin interface now, with a single 7.5x implementation behind it. When cloud support is
built, only the implementations (and a factory) change; the protocol core, dispatchers, and data
classes never see ICF or other release-specific APIs.

We are **not** building the cloud implementation now. We are only paying the small cost of an
interface boundary so the future change is one place.

## What counts as "environment-sensitive"

Calls whose API is unavailable or different under the ABAP Cloud restricted runtime, or that we
expect to swap for dynamic/environment-dependent coding later:

1. **HTTP request/response handling.** `if_http_extension`, `if_http_request`, `if_http_response`
   are classic-ICF. The cloud HTTP handler model differs. This is the primary abstraction.
2. **DDIC metadata reads** used by the schema builder (reading a structure's fields/types to
   generate a JSON Schema). RTTI (`cl_abap_typedescr` & friends) is largely available on cloud,
   but the field-name handling and any DDIC-specific reads are wrapped so the schema builder
   never depends directly on a release-specific call.

If a future need surfaces another such call, it gets a wrapper here — **not** inline in business
logic.

## HTTP abstraction

```
zif_mcp2_http_request    method, path, query, headers, body (string/xstring), content type
zif_mcp2_http_response   set status, set header, set body, set content type
zcl_mcp2_http_factory    create_request( if_http_request ) / create_response( if_http_response )
```

- `zcl_mcp2_http_handler` (`if_http_extension`, classic ICF) is the **only** class that imports
  `if_http_*`. It calls the factory once and hands the wrapped objects to the core.
- The 7.5x factory returns ICF-backed implementations (`zcl_mcp2_http_req_icf` /
  `zcl_mcp2_http_resp_icf`, names ≤30 chars).
- The core (dispatch, server base, data classes) sees only `zif_mcp2_http_*`.

### Later (cloud) — not now

When cloud support is added, the factory decides — by environment detection or build variant —
whether to return ICF-backed or cloud-backed implementations. The decision lives in
`zcl_mcp2_http_factory` alone. Candidate mechanisms (to be chosen then, not now): a compile-time
package split, or a runtime check guarded so the classic code path is only *referenced*
dynamically on cloud. The point of the interface is that this choice is deferred and contained.

## DDIC schema-reference abstraction

```
zif_mcp2_ddic    read a structure's fields and types for schema generation; field-name mapping
zcl_mcp2_ddic_75 7.5x implementation (RTTI + DDIC reads)
```

The schema builder depends on `zif_mcp2_ddic`, never on `cl_abap_*descr` or DDIC reads directly.
The old SDK's field-name conversion (`zcl_mcp_schema_builder_ddic`, crude lowercase + char
replace) is re-homed here and can be improved without touching the builder.

## Testability bonus

The abstraction is not only for cloud — it makes the SDK testable. Because the core consumes
`zif_mcp2_http_request` / `zif_mcp2_http_response`, unit tests feed a **mock request** and assert
on a **mock response**, exercising the full parse → dispatch → serialize path with no ICF and no
running server. The old SDK could not do this; its handler talked to `if_http_*` directly.

## Rules of thumb

- Business/protocol code imports `zif_mcp2_*`, never `if_http_*` or DDIC/RTTI APIs directly.
- New environment-sensitive call → add a method to the relevant `zif_mcp2_*` interface and its
  7.5x impl; do not inline it.
- Keep the interfaces minimal — only what the SDK actually uses — so the future cloud impl is
  small.
