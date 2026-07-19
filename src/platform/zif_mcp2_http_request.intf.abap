"! <p class="shorttext synchronized">MCP2 HTTP request abstraction</p>
"! Transport-neutral view of an inbound HTTP request. The only component that
"! creates instances of this interface is ZCL_MCP2_HTTP_FACTORY; everything in
"! the protocol core consumes this interface so it never depends on ICF directly.
INTERFACE zif_mcp2_http_request
  PUBLIC.

  "! <p class="shorttext synchronized">HTTP method (GET, POST, OPTIONS, ...)</p>
  "! @parameter result | HTTP method
  METHODS get_method
    RETURNING VALUE(result) TYPE string.

  "! <p class="shorttext synchronized">Request header value (empty string if absent)</p>
  "! @parameter name   | Header name (case-insensitive)
  "! @parameter result | Header value, empty when absent
  METHODS get_header
    IMPORTING !name         TYPE string
    RETURNING VALUE(result) TYPE string.

  "! <p class="shorttext synchronized">All header names present on the request</p>
  "! @parameter result | Header names
  METHODS get_header_names
    RETURNING VALUE(result) TYPE string_table.

  "! <p class="shorttext synchronized">URL path (without query string)</p>
  "! @parameter result | URL path
  METHODS get_path
    RETURNING VALUE(result) TYPE string.

  "! <p class="shorttext synchronized">Raw request body as string (UTF-8)</p>
  "! @parameter result | Request body
  METHODS get_body
    RETURNING VALUE(result) TYPE string.

  "! <p class="shorttext synchronized">Origin header value (empty if absent)</p>
  "! @parameter result | Origin header, empty when absent
  METHODS get_origin
    RETURNING VALUE(result) TYPE string.

ENDINTERFACE.
