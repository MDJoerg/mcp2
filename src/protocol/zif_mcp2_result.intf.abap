"! <p class="shorttext synchronized">MCP2 result contract</p>
"! Implemented by every response data class. The dispatcher reads these
"! values once and stamps the JSON-RPC envelope centrally - callers never
"! touch the envelope boilerplate themselves.
INTERFACE zif_mcp2_result PUBLIC.

  "! <p class="shorttext synchronized">Serialize this result to a JSON object</p>
  "! Placed under the JSON-RPC result field.
  "! @parameter result               | The serialized result object
  "! @raising   zcx_mcp2_ajson_error | JSON build failure
  METHODS to_json
    RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson
    RAISING   zcx_mcp2_ajson_error.

  "! <p class="shorttext synchronized">Result type (complete / input_required)</p>
  "! See zif_mcp2_const=>result_types. Emitted only for the modern era (2026-07-28+).
  "! @parameter result | Result type token
  METHODS result_type
    RETURNING VALUE(result) TYPE string.

  "! <p class="shorttext synchronized">Cache freshness lifetime in milliseconds</p>
  "! For modern cacheable results, 0 is emitted as "immediately stale".
  "! @parameter result | Freshness lifetime in milliseconds
  METHODS ttl_ms
    RETURNING VALUE(result) TYPE i.

  "! <p class="shorttext synchronized">Cache scope (public / private)</p>
  "! For modern cacheable results, empty defaults to private.
  "! @parameter result | Cache scope token
  METHODS cache_scope
    RETURNING VALUE(result) TYPE string.

  "! <p class="shorttext synchronized">Whether this is a spec CacheableResult</p>
  "! Covers tools/list, prompts/list, resources/list, resources/read and
  "! resources/templates/list. The modern dispatcher stamps ttlMs/cacheScope
  "! only when this returns abap_true - no sniffing of the serialized JSON.
  "! @parameter result | abap_true for a CacheableResult
  METHODS is_cacheable
    RETURNING VALUE(result) TYPE abap_bool.

ENDINTERFACE.
