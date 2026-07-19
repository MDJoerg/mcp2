"! <p class="shorttext synchronized">MCP2 server-initiated input request (MRTR)</p>
"! Implemented by the input builders (elicitation, sampling) so that
"! zcl_mcp2_resp_input_req and the tasks store can accept any input kind
"! uniformly - a new kind only needs to implement this interface.
INTERFACE zif_mcp2_input_request PUBLIC.

  "! <p class="shorttext synchronized">JSON-RPC method the client must invoke</p>
  "! The method the client calls to satisfy the request
  "! (e.g. elicitation/create, sampling/createMessage).
  "! @parameter result | JSON-RPC method name
  METHODS get_method
    RETURNING VALUE(result) TYPE string.

  "! <p class="shorttext synchronized">Method-specific params object</p>
  "! The params object sent to the client for this request.
  "! @parameter result               | Method-specific params
  "! @raising   zcx_mcp2_ajson_error | JSON build failure
  METHODS get_params
    RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson
    RAISING   zcx_mcp2_ajson_error.

ENDINTERFACE.
