"! <p class="shorttext synchronized">MCP2 elicitation/create builder</p>
"! Builds the params for an elicitation/create input request.
"! Use set_form for schema-driven prompts, set_url for redirect-based prompts.
"! Feed the result into zcl_mcp2_server_base->input_required( ) or
"! zcl_mcp2_resp_input_req->add_request. Gate it with
"! zcl_mcp2_server_base->can_request_input( ); form mode requires elicitation
"! and URL mode requires elicitation.url.
CLASS zcl_mcp2_input_elicitation DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_mcp2_input_request.
    ALIASES get_method FOR zif_mcp2_input_request~get_method.
    ALIASES get_params FOR zif_mcp2_input_request~get_params.

    "! <p class="shorttext synchronized">Build a form-mode elicitation (schema-driven)</p>
    "! requestedSchema is required by the spec; when no schema is supplied an
    "! empty object schema is emitted (a plain confirmation prompt). The spec
    "! restricts elicitation schemas to a flat object of primitive properties -
    "! zcl_mcp2_elicit_schema makes non-flat schemas unrepresentable, so a
    "! tool input schema (nesting, x-mcp-header) can never leak in here.
    "! @parameter message          | Human-readable prompt shown to the user
    "! @parameter requested_schema | Flat form schema built with zcl_mcp2_elicit_schema
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    METHODS set_form
      IMPORTING !message         TYPE string
                requested_schema TYPE REF TO zcl_mcp2_elicit_schema OPTIONAL
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Build a URL-mode elicitation (browser redirect)</p>
    "! The client learns the outcome by retrying the original request (MRTR);
    "! encode any correlation id the server needs into requestState.
    "! @parameter message | Human-readable prompt
    "! @parameter url     | Redirect URL the client should open
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    METHODS set_url
      IMPORTING !message TYPE string
                !url     TYPE string
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Full elicitation request JSON</p>
    "! The complete {method, params} object for the elicitation/create request.
    "! @parameter result               | JSON-RPC request payload (method + params)
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    METHODS generate_json
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_ajson_error.

  PRIVATE SECTION.
    DATA params TYPE REF TO zif_mcp2_ajson.

ENDCLASS.


CLASS zcl_mcp2_input_elicitation IMPLEMENTATION.

  METHOD set_form.
    params = zcl_mcp2_ajson=>create_empty( ).
    params->set_string( iv_path = '/mode'
                        iv_val  = zif_mcp2_const=>elicit_modes-form ).
    params->set_string( iv_path = '/message'
                        iv_val  = message ).
    IF requested_schema IS BOUND.
      params->set( iv_path = '/requestedSchema'
                   iv_val  = requested_schema->to_json( ) ).
    ELSE.
      " requestedSchema is required by ElicitRequestFormParams - emit an
      " empty object schema for schema-less confirmation prompts.
      params->set( iv_path = '/requestedSchema'
                   iv_val  = zcl_mcp2_ajson=>parse( '{"type":"object","properties":{}}' ) ).
    ENDIF.
  ENDMETHOD.

  METHOD set_url.
    params = zcl_mcp2_ajson=>create_empty( ).
    params->set_string( iv_path = '/mode'
                        iv_val  = zif_mcp2_const=>elicit_modes-url ).
    params->set_string( iv_path = '/message'
                        iv_val  = message ).
    params->set_string( iv_path = '/url'
                        iv_val  = url ).
  ENDMETHOD.

  METHOD zif_mcp2_input_request~get_method.
    result = zif_mcp2_const=>methods-elicitation_create.
  ENDMETHOD.

  METHOD zif_mcp2_input_request~get_params.
    IF params IS BOUND.
      result = params.
    ELSE.
      result = zcl_mcp2_ajson=>create_empty( ).
    ENDIF.
  ENDMETHOD.

  METHOD generate_json.
    result = zcl_mcp2_ajson=>create_empty( ).
    result->set_string( iv_path = '/method'
                        iv_val  = get_method( ) ).
    result->set( iv_path = '/params'
                 iv_val  = get_params( ) ).
  ENDMETHOD.

ENDCLASS.
