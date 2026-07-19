"! <p class="shorttext synchronized">MCP2 stateless server contract</p>
"! Implemented by every concrete MCP server.
"! The dispatcher sets the per-request context before calling any handler.
"! Handler methods reference Phase-3 data classes; those classes must be
"! activated before this interface is activated.
INTERFACE zif_mcp2_server PUBLIC.

  "Parsed client identity (name/version/title from clientInfo).
  TYPES: BEGIN OF client_identity,
           name    TYPE string,
           version TYPE string,
           title   TYPE string,
         END OF client_identity.

  "Per-request context extracted from _meta (modern) or initialize (legacy).
  "task_requested: legacy tools/call carried the per-request task opt-in
  "(params.task, 2025-11-25 tasks); always false in the modern era.
  TYPES: BEGIN OF context,
           protocol_ver   TYPE string,
           era            TYPE string,
           client         TYPE client_identity,
           client_info    TYPE REF TO zif_mcp2_ajson,
           client_caps    TYPE REF TO zif_mcp2_ajson,
           meta           TYPE REF TO zif_mcp2_ajson,
           task_requested TYPE abap_bool,
         END OF context.

  "Cache hints for a CacheableResult (ttlMs / cacheScope).
  TYPES: BEGIN OF cache_hints,
           ttl_ms      TYPE i,
           cache_scope TYPE string,
         END OF cache_hints.

  " -- Identity --------------------------------------------------------------

  "! <p class="shorttext synchronized">Server name advertised to clients</p>
  "! Returned in serverInfo at initialize / server/discover.
  "! @parameter result | Server name
  METHODS get_name
    RETURNING VALUE(result) TYPE string.

  "! <p class="shorttext synchronized">Server version advertised to clients</p>
  "! Returned in serverInfo at initialize / server/discover.
  "! @parameter result | Server version string
  METHODS get_version
    RETURNING VALUE(result) TYPE string.

  "! <p class="shorttext synchronized">Optional instructions / system-prompt hint</p>
  "! Advertised to the client; empty when the server offers none.
  "! @parameter result | Instructions text, or empty
  METHODS get_instructions
    RETURNING VALUE(result) TYPE string.

  "! <p class="shorttext synchronized">Optional human-readable display name</p>
  "! serverInfo.title - shown in client UIs instead of the technical name.
  "! @parameter result | Display title, or empty to omit
  METHODS get_title
    RETURNING VALUE(result) TYPE string.

  "! <p class="shorttext synchronized">Optional server description</p>
  "! serverInfo.description - what this server does, for humans and clients.
  "! @parameter result | Description text, or empty to omit
  METHODS get_description
    RETURNING VALUE(result) TYPE string.

  "! <p class="shorttext synchronized">Optional website URL</p>
  "! serverInfo.websiteUrl - where to learn more about this server.
  "! @parameter result | URL, or empty to omit
  METHODS get_website_url
    RETURNING VALUE(result) TYPE string.

  "! <p class="shorttext synchronized">Optional server icons</p>
  "! serverInfo.icons - UI icons for this server (HTTP/HTTPS or data: URIs).
  "! @parameter result | Icon entries, or empty to omit
  METHODS get_icons
    RETURNING VALUE(result) TYPE zif_mcp2_content=>icons.

  "! <p class="shorttext synchronized">Cache hints for server/discover</p>
  "! The discover result is the most cacheable response in the protocol; when
  "! the capability set only changes with transports, advertise a generous TTL.
  "! Default: ttl_ms 0 / private (never cached beyond the immediate use).
  "! @parameter result | ttlMs + cacheScope for the DiscoverResult
  METHODS get_discover_cache
    RETURNING VALUE(result) TYPE cache_hints.

  " -- Per-request context ---------------------------------------------------

  "! <p class="shorttext synchronized">Set the per-request context</p>
  "! Called by the dispatcher once per request before any handler.
  "! @parameter ctx | Context from _meta (modern) or initialize (legacy)
  METHODS set_context
    IMPORTING ctx TYPE context.

  "! <p class="shorttext synchronized">Get the current per-request context</p>
  "! @parameter result | Context set for the request in flight
  METHODS get_context
    RETURNING VALUE(result) TYPE context.

  " -- Authorization ---------------------------------------------------------

  "! <p class="shorttext synchronized">Authorize the caller for this endpoint</p>
  "! Called once per request after the server class is resolved and before the
  "! body is parsed, so a denied caller cannot reach any handler - not even
  "! initialize or server/discover. Runs under the authenticated ICF user.
  "!
  "! ICF logon and S_ICF service authorization already gate the node itself;
  "! this refines that per registered server, for a node hosting servers with
  "! different audiences. The SDK ships no authorization object of its own, so
  "! the default grants access. Redefine to apply your own check, for example
  "!   AUTHORITY-CHECK OBJECT 'Z_MY_MCP' ID 'ZAREA' FIELD area.
  "!   result = xsdbool( sy-subrc = 0 ).
  "! Denial answers HTTP 403 with a generic message - no detail is echoed back.
  "! An exception escaping this method aborts the request, so it fails closed.
  "!
  "! This is endpoint-level. Keep per-tool or per-record checks in the handler
  "! that knows what is being touched.
  "! @parameter area   | AREA path segment the request was routed to
  "! @parameter server | SERVER path segment the request was routed to
  "! @parameter result | abap_true when the caller may use this server
  METHODS check_authorization
    IMPORTING !area         TYPE string
              !server       TYPE string
    RETURNING VALUE(result) TYPE abap_bool.

  " -- Capability flags ------------------------------------------------------

  "! <p class="shorttext synchronized">Whether the server offers tools</p>
  "! @parameter result | abap_true if tools/list and tools/call are served
  METHODS supports_tools
    RETURNING VALUE(result) TYPE abap_bool.

  "! <p class="shorttext synchronized">Whether the server offers resources</p>
  "! @parameter result | abap_true if the resources/* methods are served
  METHODS supports_resources
    RETURNING VALUE(result) TYPE abap_bool.

  "! <p class="shorttext synchronized">Whether the server offers prompts</p>
  "! @parameter result | abap_true if the prompts/* methods are served
  METHODS supports_prompts
    RETURNING VALUE(result) TYPE abap_bool.

  "! <p class="shorttext synchronized">Whether the server offers completions</p>
  "! @parameter result | abap_true if completion/complete is served
  METHODS supports_completions
    RETURNING VALUE(result) TYPE abap_bool.

  " -- Handlers --------------------------------------------------------------
  " All handlers receive a typed request object built from the parsed params.
  " Returning zif_mcp2_result so the dispatcher can stamp resultType/cache
  " hints centrally without each handler touching the envelope.

  "! <p class="shorttext synchronized">Handle tools/list</p>
  "! @parameter request | Parsed tools/list request (optional cursor)
  "! @parameter result  | List-tools result
  "! @raising   zcx_mcp2_error       | Protocol error returned to the client
  "! @raising   zcx_mcp2_ajson_error | JSON build/parse failure
  METHODS tools_list
    IMPORTING request       TYPE REF TO zcl_mcp2_req_list_tools
    RETURNING VALUE(result) TYPE REF TO zif_mcp2_result
    RAISING   zcx_mcp2_error
              zcx_mcp2_ajson_error.

  "! <p class="shorttext synchronized">Handle tools/call</p>
  "! May return an inputRequired (MRTR) result in the modern era.
  "! @parameter request | Parsed tools/call request (name, arguments, MRTR state)
  "! @parameter result  | Call-tool or inputRequired result
  "! @raising   zcx_mcp2_error       | Protocol error returned to the client
  "! @raising   zcx_mcp2_ajson_error | JSON build/parse failure
  METHODS tools_call
    IMPORTING request       TYPE REF TO zcl_mcp2_req_call_tool
    RETURNING VALUE(result) TYPE REF TO zif_mcp2_result
    RAISING   zcx_mcp2_error
              zcx_mcp2_ajson_error.

  "! <p class="shorttext synchronized">Handle resources/list</p>
  "! @parameter request | Parsed resources/list request (optional cursor)
  "! @parameter result  | List-resources result
  "! @raising   zcx_mcp2_error       | Protocol error returned to the client
  "! @raising   zcx_mcp2_ajson_error | JSON build/parse failure
  METHODS resources_list
    IMPORTING request       TYPE REF TO zcl_mcp2_req_list_resources
    RETURNING VALUE(result) TYPE REF TO zif_mcp2_result
    RAISING   zcx_mcp2_error
              zcx_mcp2_ajson_error.

  "! <p class="shorttext synchronized">Handle resources/read</p>
  "! @parameter request | Parsed resources/read request (uri)
  "! @parameter result  | Read-resource result
  "! @raising   zcx_mcp2_error       | Protocol error returned to the client
  "! @raising   zcx_mcp2_ajson_error | JSON build/parse failure
  METHODS resources_read
    IMPORTING request       TYPE REF TO zcl_mcp2_req_read_resource
    RETURNING VALUE(result) TYPE REF TO zif_mcp2_result
    RAISING   zcx_mcp2_error
              zcx_mcp2_ajson_error.

  "! <p class="shorttext synchronized">Handle resources/templates/list</p>
  "! @parameter request | Parsed templates/list request (optional cursor)
  "! @parameter result  | Resource-templates result
  "! @raising   zcx_mcp2_error       | Protocol error returned to the client
  "! @raising   zcx_mcp2_ajson_error | JSON build/parse failure
  METHODS resources_tmpls_list
    IMPORTING request       TYPE REF TO zcl_mcp2_req_list_res_tmpls
    RETURNING VALUE(result) TYPE REF TO zif_mcp2_result
    RAISING   zcx_mcp2_error
              zcx_mcp2_ajson_error.

  "! <p class="shorttext synchronized">Handle prompts/list</p>
  "! @parameter request | Parsed prompts/list request (optional cursor)
  "! @parameter result  | List-prompts result
  "! @raising   zcx_mcp2_error       | Protocol error returned to the client
  "! @raising   zcx_mcp2_ajson_error | JSON build/parse failure
  METHODS prompts_list
    IMPORTING request       TYPE REF TO zcl_mcp2_req_list_prompts
    RETURNING VALUE(result) TYPE REF TO zif_mcp2_result
    RAISING   zcx_mcp2_error
              zcx_mcp2_ajson_error.

  "! <p class="shorttext synchronized">Handle prompts/get</p>
  "! May return an inputRequired (MRTR) result in the modern era.
  "! @parameter request | Parsed prompts/get request (name, arguments, MRTR state)
  "! @parameter result  | Get-prompt or inputRequired result
  "! @raising   zcx_mcp2_error       | Protocol error returned to the client
  "! @raising   zcx_mcp2_ajson_error | JSON build/parse failure
  METHODS prompts_get
    IMPORTING request       TYPE REF TO zcl_mcp2_req_get_prompt
    RETURNING VALUE(result) TYPE REF TO zif_mcp2_result
    RAISING   zcx_mcp2_error
              zcx_mcp2_ajson_error.

  "! <p class="shorttext synchronized">Handle completion/complete</p>
  "! @parameter request | Parsed completion request (ref + argument)
  "! @parameter result  | Completion result
  "! @raising   zcx_mcp2_error       | Protocol error returned to the client
  "! @raising   zcx_mcp2_ajson_error | JSON build/parse failure
  METHODS completions_complete
    IMPORTING request       TYPE REF TO zcl_mcp2_req_complete
    RETURNING VALUE(result) TYPE REF TO zif_mcp2_result
    RAISING   zcx_mcp2_error
              zcx_mcp2_ajson_error.

  "! <p class="shorttext synchronized">Input schema for a named tool</p>
  "! Used for header-mirroring validation and, when validate_tool_input is
  "! enabled, argument validation.
  "! Default: return initial (no schema, skip both validations).
  "! @parameter tool_name            | Tool name
  "! @parameter result               | Input schema, or unbound when none
  "! @raising   zcx_mcp2_ajson_error | JSON build/parse failure
  METHODS get_tool_schema
    IMPORTING tool_name     TYPE string
    RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson
    RAISING   zcx_mcp2_ajson_error.

  "! <p class="shorttext synchronized">Whether tools/call arguments are validated</p>
  "! When abap_true the dispatcher validates the call arguments against
  "! get_tool_schema before invoking tools_call. Schema violations become an
  "! isError tool result in both eras; malformed calls remain -32602.
  "! Tools without a schema are not validated.
  "! Default: abap_false (handlers validate themselves via typed getters).
  "! @parameter result | abap_true to enable framework input validation
  METHODS validate_tool_input
    RETURNING VALUE(result) TYPE abap_bool.

  "! <p class="shorttext synchronized">Whether the server supports the Tasks extension</p>
  "! When abap_true the tasks/* methods are routed and resultType=task is allowed.
  "! @parameter result | abap_true if the Tasks extension is supported
  METHODS supports_tasks
    RETURNING VALUE(result) TYPE abap_bool.

  "! <p class="shorttext synchronized">Handle tasks/get (modern + legacy)</p>
  "! @parameter request | Parsed tasks/get request
  "! @parameter result  | Task status result
  "! @raising   zcx_mcp2_error       | Protocol error
  "! @raising   zcx_mcp2_ajson_error | JSON failure
  METHODS tasks_get
    IMPORTING request       TYPE REF TO zcl_mcp2_req_get_task
    RETURNING VALUE(result) TYPE REF TO zif_mcp2_result
    RAISING   zcx_mcp2_error
              zcx_mcp2_ajson_error.

  "! <p class="shorttext synchronized">Handle tasks/update (modern only - MRTR continuation)</p>
  "! @parameter request | Parsed tasks/update request
  "! @parameter result  | Acknowledgement result
  "! @raising   zcx_mcp2_error       | Protocol error
  "! @raising   zcx_mcp2_ajson_error | JSON failure
  METHODS tasks_update
    IMPORTING request       TYPE REF TO zcl_mcp2_req_update_task
    RETURNING VALUE(result) TYPE REF TO zif_mcp2_result
    RAISING   zcx_mcp2_error
              zcx_mcp2_ajson_error.

  "! <p class="shorttext synchronized">Handle tasks/cancel (modern + legacy)</p>
  "! @parameter request | Parsed tasks/cancel request
  "! @parameter result  | Cancellation result
  "! @raising   zcx_mcp2_error       | Protocol error
  "! @raising   zcx_mcp2_ajson_error | JSON failure
  METHODS tasks_cancel
    IMPORTING request       TYPE REF TO zcl_mcp2_req_cancel_task
    RETURNING VALUE(result) TYPE REF TO zif_mcp2_result
    RAISING   zcx_mcp2_error
              zcx_mcp2_ajson_error.

  "! <p class="shorttext synchronized">Handle tasks/list (legacy era)</p>
  "! @parameter request | Parsed tasks/list request
  "! @parameter result  | Task list result
  "! @raising   zcx_mcp2_error       | Protocol error
  "! @raising   zcx_mcp2_ajson_error | JSON failure
  METHODS tasks_list
    IMPORTING request       TYPE REF TO zcl_mcp2_req_list_tasks
    RETURNING VALUE(result) TYPE REF TO zif_mcp2_result
    RAISING   zcx_mcp2_error
              zcx_mcp2_ajson_error.

  "! <p class="shorttext synchronized">Handle tasks/result (legacy era - get terminal payload)</p>
  "! @parameter request | Parsed tasks/result request
  "! @parameter result  | Payload result
  "! @raising   zcx_mcp2_error       | Protocol error
  "! @raising   zcx_mcp2_ajson_error | JSON failure
  METHODS tasks_result
    IMPORTING request       TYPE REF TO zcl_mcp2_req_get_task_payload
    RETURNING VALUE(result) TYPE REF TO zif_mcp2_result
    RAISING   zcx_mcp2_error
              zcx_mcp2_ajson_error.

ENDINTERFACE.
