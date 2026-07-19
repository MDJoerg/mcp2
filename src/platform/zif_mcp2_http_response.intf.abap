"! <p class="shorttext synchronized">MCP2 HTTP response abstraction</p>
"! Transport-neutral view of an outbound HTTP response. Only ZCL_MCP2_HTTP_FACTORY
"! creates instances; the protocol core never imports ICF types directly.
INTERFACE zif_mcp2_http_response
  PUBLIC.

  "! <p class="shorttext synchronized">Set HTTP status code</p>
  "! @parameter code | HTTP status code
  METHODS set_status
    IMPORTING !code TYPE i.

  "! <p class="shorttext synchronized">Set response header</p>
  "! @parameter name  | Header name
  "! @parameter value | Header value
  METHODS set_header
    IMPORTING !name  TYPE string
              !value TYPE string.

  "! <p class="shorttext synchronized">Set content-type header</p>
  "! @parameter content_type | Content-type value
  METHODS set_content_type
    IMPORTING content_type TYPE string.

  "! <p class="shorttext synchronized">Set response body (string, UTF-8)</p>
  "! @parameter body | Response body
  METHODS set_body
    IMPORTING body TYPE string.

ENDINTERFACE.
