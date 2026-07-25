CLASS ltcl_mock_request DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES zif_mcp2_http_request.

    DATA headers  TYPE string_table.
    DATA hdr_vals TYPE string_table.
ENDCLASS.

CLASS ltcl_mock_request IMPLEMENTATION.
  METHOD zif_mcp2_http_request~get_method.
  ENDMETHOD.

  METHOD zif_mcp2_http_request~get_path.
  ENDMETHOD.

  METHOD zif_mcp2_http_request~get_body.
  ENDMETHOD.

  METHOD zif_mcp2_http_request~get_origin.
  ENDMETHOD.

  METHOD zif_mcp2_http_request~get_header.
    DATA idx TYPE i.

    LOOP AT headers INTO DATA(h) WHERE table_line = name.
      idx = sy-tabix.
      READ TABLE hdr_vals INDEX idx INTO result. "#EC CI_SUBRC
      RETURN.
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_mcp2_http_request~get_header_names.
    result = headers.
  ENDMETHOD.
ENDCLASS.


"! Minimal dispatcher tests that don't require Phase-3 data classes.
CLASS ltcl_dispatch_modern DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.

  PUBLIC SECTION.
    METHODS test_unknown_method  FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_ping_removed    FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_discover        FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_discover_identity FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_discover_no_client_info FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_bad_client_info FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_server_info_non_discover FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_header_mismatch FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_missing_meta    FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_log_level_ok    FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_log_level_bad   FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_method_header   FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_logging_removed FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_input_valid_ok  FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_input_invalid   FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_input_no_args_ok FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_name_base64     FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_name_pct_literal  FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_name_pct_no_decode FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_nested_header   FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    " Fix 1 - MRTR/input_required enforcement
    METHODS test_mrtr_wrong_method FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_mrtr_empty_bad    FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_mrtr_no_cap       FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_mrtr_url_no_cap   FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_mrtr_form_no_cap  FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_mrtr_form_ok      FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_mrtr_ok           FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    " Fix 2 - x-mcp-header must be a non-empty string
    METHODS test_xmcp_bool_rejected  FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_xmcp_empty_rejected FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_xmcp_oneof_rejected FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_xmcp_defs_rejected  FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    " Fix 3 - plain header value character set
    METHODS test_hdr_htab_mid_ok     FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_hdr_nonascii_reject FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_hdr_leading_ws      FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    " Tasks extension - dispatcher routing/capability-gate/header-mirror
    METHODS test_tasks_no_cap_gate   FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_tasks_missing_ext_cap FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_tasks_cap_ok        FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_tasks_name_hdr_mismatch FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_tasks_no_name_hdr_ok  FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_tools_call_no_name_hdr FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_tasks_cap_false_bad  FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_top_cap_false_bad    FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_tasks_lowercase_name FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_empty_param_header   FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_retry_cache_private  FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_resource_not_found   FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.

  PRIVATE SECTION.
    DATA server     TYPE REF TO zif_mcp2_server.
    DATA dispatcher TYPE REF TO zcl_mcp2_dispatch_modern.

    METHODS setup.

    METHODS modern_params
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_ajson_error.

    METHODS modern_params_with_sampling
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_ajson_error.

    METHODS modern_params_with_elicit
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_ajson_error.

    METHODS modern_params_elicit_url_only
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_ajson_error.

    METHODS modern_params_with_tasks_cap
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_ajson_error.

    METHODS make_tools_call_request
      IMPORTING tool_name     TYPE string
                with_sampling TYPE abap_bool DEFAULT abap_false
      RETURNING VALUE(result) TYPE zcl_mcp2_jsonrpc=>request
      RAISING   zcx_mcp2_ajson_error.

    METHODS make_tools_call_http
      IMPORTING tool_name     TYPE string
      RETURNING VALUE(result) TYPE REF TO ltcl_mock_request.

ENDCLASS.

CLASS ltcl_resource_server DEFINITION FINAL
  INHERITING FROM zcl_mcp2_server_base CREATE PUBLIC.
  PUBLIC SECTION.
    METHODS zif_mcp2_server~get_name REDEFINITION.
    METHODS zif_mcp2_server~get_version REDEFINITION.
    METHODS zif_mcp2_server~supports_resources REDEFINITION.
    METHODS zif_mcp2_server~resources_read REDEFINITION.
ENDCLASS.
CLASS ltcl_resource_server IMPLEMENTATION.
  METHOD zif_mcp2_server~get_name.
    result = `ResourceServer`.
  ENDMETHOD.
  METHOD zif_mcp2_server~get_version.
    result = `1.0`.
  ENDMETHOD.
  METHOD zif_mcp2_server~supports_resources.
    result = abap_true.
  ENDMETHOD.
  METHOD zif_mcp2_server~resources_read.
    IF request->get_uri( ) = `mcp2://missing`.
      zcx_mcp2_error=>raise_resource_not_found( request->get_uri( ) ).
    ENDIF.
    DATA(resp) = NEW zcl_mcp2_resp_read_resource( ).
    resp->add_text_content( uri = request->get_uri( ) text = `dependent` ).
    resp->set_cache( ttl_ms = 60000 cache_scope = zif_mcp2_const=>cache_scopes-public ).
    result = resp.
  ENDMETHOD.
ENDCLASS.


CLASS ltcl_test_server DEFINITION
  INHERITING FROM zcl_mcp2_server_base FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS zif_mcp2_server~get_name    REDEFINITION.
    METHODS zif_mcp2_server~get_version REDEFINITION.
ENDCLASS.

CLASS ltcl_test_server IMPLEMENTATION.
  METHOD zif_mcp2_server~get_name.
    result = `ModernServer`.
  ENDMETHOD.


  METHOD zif_mcp2_server~get_version.
    result = `2.0`.
  ENDMETHOD.
ENDCLASS.


"! Server with full identity + discover cache overrides.
CLASS ltcl_ident_server DEFINITION
  INHERITING FROM zcl_mcp2_server_base FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS zif_mcp2_server~get_name           REDEFINITION.
    METHODS zif_mcp2_server~get_version        REDEFINITION.
    METHODS zif_mcp2_server~get_title          REDEFINITION.
    METHODS zif_mcp2_server~get_description    REDEFINITION.
    METHODS zif_mcp2_server~get_website_url    REDEFINITION.
    METHODS zif_mcp2_server~get_icons          REDEFINITION.
    METHODS zif_mcp2_server~get_discover_cache REDEFINITION.
ENDCLASS.

CLASS ltcl_ident_server IMPLEMENTATION.
  METHOD zif_mcp2_server~get_name.
    result = `ident-server`.
  ENDMETHOD.

  METHOD zif_mcp2_server~get_version.
    result = `3.1`.
  ENDMETHOD.

  METHOD zif_mcp2_server~get_title.
    result = `Ident Server`.
  ENDMETHOD.

  METHOD zif_mcp2_server~get_description.
    result = `Serves identity fields for tests.`.
  ENDMETHOD.

  METHOD zif_mcp2_server~get_website_url.
    result = `https://example.com/ident`.
  ENDMETHOD.

  METHOD zif_mcp2_server~get_icons.
    result = VALUE #( ( src       = `https://example.com/ident.png`
                        mime_type = `image/png`
                        sizes     = VALUE #( ( `48x48` ) )
                        theme     = zif_mcp2_const=>icon_themes-light ) ).
  ENDMETHOD.

  METHOD zif_mcp2_server~get_discover_cache.
    result-ttl_ms      = 3600000.
    result-cache_scope = zif_mcp2_const=>cache_scopes-public.
  ENDMETHOD.
ENDCLASS.


CLASS ltcl_tool_server DEFINITION
  INHERITING FROM zcl_mcp2_server_base FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS zif_mcp2_server~get_name        REDEFINITION.
    METHODS zif_mcp2_server~get_version     REDEFINITION.
    METHODS zif_mcp2_server~supports_tools  REDEFINITION.
    METHODS zif_mcp2_server~tools_call      REDEFINITION.
    METHODS zif_mcp2_server~get_tool_schema REDEFINITION.
ENDCLASS.

CLASS ltcl_tool_server IMPLEMENTATION.
  METHOD zif_mcp2_server~get_name.
    result = `ToolServer`.
  ENDMETHOD.

  METHOD zif_mcp2_server~get_version.
    result = `2.0`.
  ENDMETHOD.

  METHOD zif_mcp2_server~supports_tools.
    result = abap_true.
  ENDMETHOD.

  METHOD zif_mcp2_server~tools_call.
    DATA(resp) = NEW zcl_mcp2_resp_call_tool( ).
    resp->add_text( `ok` ).
    result = resp.
  ENDMETHOD.

  METHOD zif_mcp2_server~get_tool_schema.
    result = zcl_mcp2_ajson=>parse(
      `{"type":"object","properties":{"outer":{"type":"object","properties":{"inner":{"type":"string","x-mcp-header":"Inner"}}}}}` ).
  ENDMETHOD.
ENDCLASS.


"Mock server: returns zcl_mcp2_resp_input_req from tools/list (wrong method) ----------
CLASS ltcl_ir_list_server DEFINITION
  INHERITING FROM zcl_mcp2_server_base FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    METHODS zif_mcp2_server~get_name     REDEFINITION.
    METHODS zif_mcp2_server~get_version  REDEFINITION.
    METHODS zif_mcp2_server~supports_tools REDEFINITION.
    METHODS zif_mcp2_server~tools_list   REDEFINITION.
ENDCLASS.
CLASS ltcl_ir_list_server IMPLEMENTATION.
  METHOD zif_mcp2_server~get_name.
    result = `IRListServer`.
  ENDMETHOD.

  METHOD zif_mcp2_server~get_version.
    result = `1.0`.
  ENDMETHOD.

  METHOD zif_mcp2_server~supports_tools.
    result = abap_true.
  ENDMETHOD.

  METHOD zif_mcp2_server~tools_list.
    DATA ir TYPE REF TO zcl_mcp2_resp_input_req.

    ir = NEW zcl_mcp2_resp_input_req( ).
    ir->set_request_state( `s1` ).
    ir->add_input_request( request_key = `k`
                           method      = `sampling/createMessage` ).
    result = ir.
  ENDMETHOD.
ENDCLASS.

" -- Mock server: returns zcl_mcp2_resp_input_req from tools/call (MRTR call server) ------
CLASS ltcl_ir_call_server DEFINITION
  INHERITING FROM zcl_mcp2_server_base FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    METHODS zif_mcp2_server~get_name     REDEFINITION.
    METHODS zif_mcp2_server~get_version  REDEFINITION.
    METHODS zif_mcp2_server~supports_tools REDEFINITION.
    METHODS zif_mcp2_server~tools_call   REDEFINITION.
    METHODS zif_mcp2_server~get_tool_schema REDEFINITION.
ENDCLASS.
CLASS ltcl_ir_call_server IMPLEMENTATION.
  METHOD zif_mcp2_server~get_name.
    result = `IRCallServer`.
  ENDMETHOD.

  METHOD zif_mcp2_server~get_version.
    result = `1.0`.
  ENDMETHOD.

  METHOD zif_mcp2_server~supports_tools.
    result = abap_true.
  ENDMETHOD.

  METHOD zif_mcp2_server~tools_call.
    DATA ir TYPE REF TO zcl_mcp2_resp_input_req.

    ir = NEW zcl_mcp2_resp_input_req( ).
    ir->set_request_state( `state-1` ).
    ir->add_input_request( request_key = `sample`
                           method      = `sampling/createMessage` ).
    result = ir.
  ENDMETHOD.

  METHOD zif_mcp2_server~get_tool_schema.
    result = zcl_mcp2_ajson=>parse( `{"type":"object","properties":{}}` ).
  ENDMETHOD.
ENDCLASS.

" -- Mock server: returns URL-mode elicitation without handler-side gating ----------------
CLASS ltcl_ir_url_server DEFINITION
  INHERITING FROM zcl_mcp2_server_base FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    METHODS zif_mcp2_server~get_name       REDEFINITION.
    METHODS zif_mcp2_server~get_version    REDEFINITION.
    METHODS zif_mcp2_server~supports_tools REDEFINITION.
    METHODS zif_mcp2_server~tools_call     REDEFINITION.
ENDCLASS.
CLASS ltcl_ir_url_server IMPLEMENTATION.
  METHOD zif_mcp2_server~get_name.
    result = `IRUrlServer`.
  ENDMETHOD.

  METHOD zif_mcp2_server~get_version.
    result = `1.0`.
  ENDMETHOD.

  METHOD zif_mcp2_server~supports_tools.
    result = abap_true.
  ENDMETHOD.

  METHOD zif_mcp2_server~tools_call.
    DATA input TYPE REF TO zcl_mcp2_input_elicitation.
    DATA ir    TYPE REF TO zcl_mcp2_resp_input_req.

    input = NEW zcl_mcp2_input_elicitation( ).
    input->set_url( message = `Authorize`
                    url     = `https://example.com/authorize` ).
    ir = NEW zcl_mcp2_resp_input_req( ).
    ir->set_request_state( `url-state` ).
    ir->add_request( request_key = `auth`
                     input       = input ).
    result = ir.
  ENDMETHOD.
ENDCLASS.

" -- Mock server: returns form-mode elicitation without handler-side gating --------------
CLASS ltcl_ir_form_server DEFINITION
  INHERITING FROM zcl_mcp2_server_base FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS zif_mcp2_server~get_name       REDEFINITION.
    METHODS zif_mcp2_server~get_version    REDEFINITION.
    METHODS zif_mcp2_server~supports_tools REDEFINITION.
    METHODS zif_mcp2_server~tools_call     REDEFINITION.
ENDCLASS.
CLASS ltcl_ir_form_server IMPLEMENTATION.
  METHOD zif_mcp2_server~get_name.
    result = `IRFormServer`.
  ENDMETHOD.

  METHOD zif_mcp2_server~get_version.
    result = `1.0`.
  ENDMETHOD.

  METHOD zif_mcp2_server~supports_tools.
    result = abap_true.
  ENDMETHOD.
  METHOD zif_mcp2_server~tools_call.
    DATA input TYPE REF TO zcl_mcp2_input_elicitation.
    DATA ir    TYPE REF TO zcl_mcp2_resp_input_req.

    input = NEW zcl_mcp2_input_elicitation( ).
    input->set_form( `Confirm?` ).
    ir = NEW zcl_mcp2_resp_input_req( ).
    ir->add_request( request_key = `confirm`
                     input       = input ).
    result = ir.
  ENDMETHOD.
ENDCLASS.

" -- Mock server: returns an empty input_required result (invalid MRTR) -------------------
CLASS ltcl_ir_empty_server DEFINITION
  INHERITING FROM zcl_mcp2_server_base FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    METHODS zif_mcp2_server~get_name     REDEFINITION.
    METHODS zif_mcp2_server~get_version  REDEFINITION.
    METHODS zif_mcp2_server~supports_tools REDEFINITION.
    METHODS zif_mcp2_server~tools_call   REDEFINITION.
ENDCLASS.
CLASS ltcl_ir_empty_server IMPLEMENTATION.
  METHOD zif_mcp2_server~get_name.
    result = `IREmptyServer`.
  ENDMETHOD.

  METHOD zif_mcp2_server~get_version.
    result = `1.0`.
  ENDMETHOD.

  METHOD zif_mcp2_server~supports_tools.
    result = abap_true.
  ENDMETHOD.

  METHOD zif_mcp2_server~tools_call.
    result = NEW zcl_mcp2_resp_input_req( ).
  ENDMETHOD.
ENDCLASS.

" -- Mock server: opt-in tools/call input validation (validate_tool_input) ----------------
CLASS ltcl_vld_input_server DEFINITION
  INHERITING FROM zcl_mcp2_server_base FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    METHODS zif_mcp2_server~get_name            REDEFINITION.
    METHODS zif_mcp2_server~get_version         REDEFINITION.
    METHODS zif_mcp2_server~supports_tools      REDEFINITION.
    METHODS zif_mcp2_server~tools_call          REDEFINITION.
    METHODS zif_mcp2_server~get_tool_schema     REDEFINITION.
    METHODS zif_mcp2_server~validate_tool_input REDEFINITION.
ENDCLASS.
CLASS ltcl_vld_input_server IMPLEMENTATION.
  METHOD zif_mcp2_server~get_name.
    result = `VldServer`.
  ENDMETHOD.

  METHOD zif_mcp2_server~get_version.
    result = `1.0`.
  ENDMETHOD.

  METHOD zif_mcp2_server~supports_tools.
    result = abap_true.
  ENDMETHOD.

  METHOD zif_mcp2_server~validate_tool_input.
    result = abap_true.
  ENDMETHOD.

  METHOD zif_mcp2_server~tools_call.
    DATA resp TYPE REF TO zcl_mcp2_resp_call_tool.

    resp = NEW zcl_mcp2_resp_call_tool( ).
    resp->add_text( `ok` ).
    result = resp.
  ENDMETHOD.
  METHOD zif_mcp2_server~get_tool_schema.
    result = zcl_mcp2_ajson=>parse(
      `{"type":"object","properties":{"msg":{"type":"string"}},"required":["msg"]}` ).
  ENDMETHOD.
ENDCLASS.

" -- Mock server: opt-in validation, tool schema with no required fields ------------------
CLASS ltcl_vld_optional_server DEFINITION
  INHERITING FROM zcl_mcp2_server_base FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    METHODS zif_mcp2_server~get_name            REDEFINITION.
    METHODS zif_mcp2_server~get_version         REDEFINITION.
    METHODS zif_mcp2_server~supports_tools      REDEFINITION.
    METHODS zif_mcp2_server~tools_call          REDEFINITION.
    METHODS zif_mcp2_server~get_tool_schema     REDEFINITION.
    METHODS zif_mcp2_server~validate_tool_input REDEFINITION.
ENDCLASS.
CLASS ltcl_vld_optional_server IMPLEMENTATION.
  METHOD zif_mcp2_server~get_name.
    result = `VldOptServer`.
  ENDMETHOD.

  METHOD zif_mcp2_server~get_version.
    result = `1.0`.
  ENDMETHOD.

  METHOD zif_mcp2_server~supports_tools.
    result = abap_true.
  ENDMETHOD.

  METHOD zif_mcp2_server~validate_tool_input.
    result = abap_true.
  ENDMETHOD.

  METHOD zif_mcp2_server~tools_call.
    DATA resp TYPE REF TO zcl_mcp2_resp_call_tool.

    resp = NEW zcl_mcp2_resp_call_tool( ).
    resp->add_text( `ok` ).
    result = resp.
  ENDMETHOD.

  METHOD zif_mcp2_server~get_tool_schema.
    " No "required" list - a call with no arguments at all must still pass.
    result = zcl_mcp2_ajson=>parse(
      `{"type":"object","properties":{"msg":{"type":"string"}}}` ).
  ENDMETHOD.
ENDCLASS.

" -- Mock servers for bad x-mcp-header schemas --------------------------------------------
CLASS ltcl_schema_server DEFINITION ABSTRACT
  INHERITING FROM zcl_mcp2_server_base CREATE PUBLIC.
  PUBLIC SECTION.
    METHODS zif_mcp2_server~get_name       REDEFINITION.
    METHODS zif_mcp2_server~get_version    REDEFINITION.
    METHODS zif_mcp2_server~supports_tools REDEFINITION.
    METHODS zif_mcp2_server~tools_call     REDEFINITION.
ENDCLASS.
CLASS ltcl_schema_server IMPLEMENTATION.
  METHOD zif_mcp2_server~get_name.
    result = `SchemaServer`.
  ENDMETHOD.

  METHOD zif_mcp2_server~get_version.
    result = `1.0`.
  ENDMETHOD.

  METHOD zif_mcp2_server~supports_tools.
    result = abap_true.
  ENDMETHOD.

  METHOD zif_mcp2_server~tools_call.
    DATA resp TYPE REF TO zcl_mcp2_resp_call_tool.

    resp = NEW zcl_mcp2_resp_call_tool( ).
    resp->add_text( `ok` ).
    result = resp.
  ENDMETHOD.
ENDCLASS.

CLASS ltcl_schema_bool_srv DEFINITION FINAL
  INHERITING FROM ltcl_schema_server CREATE PUBLIC.
  PUBLIC SECTION.
    METHODS zif_mcp2_server~get_tool_schema REDEFINITION.
ENDCLASS.
CLASS ltcl_schema_bool_srv IMPLEMENTATION.
  METHOD zif_mcp2_server~get_tool_schema.
    " x-mcp-header: true (boolean) - must be rejected per spec
    result = zcl_mcp2_ajson=>parse(
      `{"type":"object","properties":{"p":{"type":"string","x-mcp-header":true}}}` ).
  ENDMETHOD.
ENDCLASS.

CLASS ltcl_schema_empty_srv DEFINITION FINAL
  INHERITING FROM ltcl_schema_server CREATE PUBLIC.
  PUBLIC SECTION.
    METHODS zif_mcp2_server~get_tool_schema REDEFINITION.
ENDCLASS.
CLASS ltcl_schema_empty_srv IMPLEMENTATION.
  METHOD zif_mcp2_server~get_tool_schema.
    " x-mcp-header: "" (empty string) - must be rejected per spec
    result = zcl_mcp2_ajson=>parse(
      `{"type":"object","properties":{"p":{"type":"string","x-mcp-header":""}}}` ).
  ENDMETHOD.
ENDCLASS.

CLASS ltcl_schema_oneof_srv DEFINITION FINAL
  INHERITING FROM ltcl_schema_server CREATE PUBLIC.
  PUBLIC SECTION.
    METHODS zif_mcp2_server~get_tool_schema REDEFINITION.
ENDCLASS.
CLASS ltcl_schema_oneof_srv IMPLEMENTATION.
  METHOD zif_mcp2_server~get_tool_schema.
    " x-mcp-header nested inside oneOf - must be rejected per spec
    result = zcl_mcp2_ajson=>parse(
      `{"type":"object","properties":{"p":{"oneOf":[{"type":"string","x-mcp-header":"Bad"}]}}}` ).
  ENDMETHOD.
ENDCLASS.

CLASS ltcl_schema_defs_srv DEFINITION FINAL
  INHERITING FROM ltcl_schema_server CREATE PUBLIC.
  PUBLIC SECTION.
    METHODS zif_mcp2_server~get_tool_schema REDEFINITION.
ENDCLASS.
CLASS ltcl_schema_defs_srv IMPLEMENTATION.
  METHOD zif_mcp2_server~get_tool_schema.
    " x-mcp-header hidden in a $defs subschema (only reachable via $ref) -
    " makes the tool definition invalid per spec; must be rejected, not ignored
    result = zcl_mcp2_ajson=>parse(
      `{"type":"object",` &&
      `"properties":{"p":{"$ref":"#/$defs/hdr"}},` &&
      `"$defs":{"hdr":{"type":"string","x-mcp-header":"Bad"}}}` ).
  ENDMETHOD.
ENDCLASS.

" -- Mock server: plain header test (string param with x-mcp-header annotation) -----------
CLASS ltcl_hdr_test_server DEFINITION FINAL
  INHERITING FROM zcl_mcp2_server_base CREATE PUBLIC.
  PUBLIC SECTION.
    METHODS zif_mcp2_server~get_name       REDEFINITION.
    METHODS zif_mcp2_server~get_version    REDEFINITION.
    METHODS zif_mcp2_server~supports_tools REDEFINITION.
    METHODS zif_mcp2_server~tools_call     REDEFINITION.
    METHODS zif_mcp2_server~get_tool_schema REDEFINITION.
ENDCLASS.
CLASS ltcl_hdr_test_server IMPLEMENTATION.
  METHOD zif_mcp2_server~get_name.
    result = `HdrServer`.
  ENDMETHOD.

  METHOD zif_mcp2_server~get_version.
    result = `1.0`.
  ENDMETHOD.

  METHOD zif_mcp2_server~supports_tools.
    result = abap_true.
  ENDMETHOD.

  METHOD zif_mcp2_server~tools_call.
    DATA resp TYPE REF TO zcl_mcp2_resp_call_tool.

    resp = NEW zcl_mcp2_resp_call_tool( ).
    resp->add_text( `ok` ).
    result = resp.
  ENDMETHOD.

  METHOD zif_mcp2_server~get_tool_schema.
    result = zcl_mcp2_ajson=>parse( `{"type":"object","properties":{"p":{"type":"string","x-mcp-header":"P"}}}` ).
  ENDMETHOD.
ENDCLASS.

" -- Mock server: tasks/* routing, capability gate, and header mirroring ------------------
" Redefines tasks_get/tasks_update/tasks_cancel directly (bypassing
" zcl_mcp2_server_base's DB-backed defaults) so the dispatcher's own
" routing/gating/header-mirroring logic can be tested without a live task store.
CLASS ltcl_task_cap_server DEFINITION FINAL
  INHERITING FROM zcl_mcp2_server_base CREATE PUBLIC.
  PUBLIC SECTION.
    DATA received_task_id TYPE string.
    METHODS zif_mcp2_server~get_name       REDEFINITION.
    METHODS zif_mcp2_server~get_version    REDEFINITION.
    METHODS zif_mcp2_server~supports_tasks REDEFINITION.
    METHODS zif_mcp2_server~tasks_get      REDEFINITION.
    METHODS zif_mcp2_server~tasks_update   REDEFINITION.
    METHODS zif_mcp2_server~tasks_cancel   REDEFINITION.
ENDCLASS.
CLASS ltcl_task_cap_server IMPLEMENTATION.
  METHOD zif_mcp2_server~get_name.
    result = `TaskCapServer`.
  ENDMETHOD.

  METHOD zif_mcp2_server~get_version.
    result = `1.0`.
  ENDMETHOD.

  METHOD zif_mcp2_server~supports_tasks.
    result = abap_true.
  ENDMETHOD.

  METHOD zif_mcp2_server~tasks_get.
    received_task_id = request->get_task_id( ).
    result = zcl_mcp2_resp_call_tool=>text( `stub-get` ).
  ENDMETHOD.

  METHOD zif_mcp2_server~tasks_update.
    received_task_id = request->get_task_id( ).
    result = zcl_mcp2_resp_call_tool=>text( `stub-update` ).
  ENDMETHOD.

  METHOD zif_mcp2_server~tasks_cancel.
    received_task_id = request->get_task_id( ).
    result = zcl_mcp2_resp_call_tool=>text( `stub-cancel` ).
  ENDMETHOD.
ENDCLASS.


CLASS ltcl_dispatch_modern IMPLEMENTATION.
  METHOD test_top_cap_false_bad.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.
    req-jsonrpc = `2.0`.
    req-method = zif_mcp2_const=>methods-server_discover.
    req-id = `1`.
    req-id_present = abap_true.
    req-params = zcl_mcp2_ajson=>parse(
      `{"_meta":{"io.modelcontextprotocol/protocolVersion":"2026-07-28",` &&
      `"io.modelcontextprotocol/clientInfo":{"name":"Unit","version":"1"},` &&
      `"io.modelcontextprotocol/clientCapabilities":{"sampling":false}}}` ).
    DATA(d) = NEW zcl_mcp2_dispatch_modern( NEW ltcl_test_server( ) ).
    DATA(resp) = d->dispatch( request = req
                              header_ver = zif_mcp2_const=>protocol-v2026_07_28 ).
    cl_abap_unit_assert=>assert_equals(
      exp = zif_mcp2_const=>error_codes-invalid_params act = resp-error-code ).
  ENDMETHOD.

  METHOD test_retry_cache_private.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.
    req-jsonrpc = `2.0`.
    req-method = zif_mcp2_const=>methods-resources_read.
    req-id = `1`.
    req-id_present = abap_true.
    req-params = modern_params( ).
    req-params->set_string( iv_path = '/uri' iv_val = `mcp2://cache` ).
    req-params->set_string( iv_path = '/requestState' iv_val = `retry` ).
    DATA(d) = NEW zcl_mcp2_dispatch_modern( NEW ltcl_resource_server( ) ).
    DATA(resp) = d->dispatch( request = req
                              header_ver = zif_mcp2_const=>protocol-v2026_07_28 ).
    cl_abap_unit_assert=>assert_initial( resp-error-code ).
    cl_abap_unit_assert=>assert_equals( exp = 0 act = resp-result->get_integer( '/ttlMs' ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = zif_mcp2_const=>cache_scopes-private
      act = resp-result->get_string( '/cacheScope' ) ).
  ENDMETHOD.

  METHOD test_resource_not_found.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.
    req-jsonrpc = `2.0`.
    req-method = zif_mcp2_const=>methods-resources_read.
    req-id = `1`.
    req-id_present = abap_true.
    req-params = modern_params( ).
    req-params->set_string( iv_path = '/uri' iv_val = `mcp2://missing` ).
    DATA(d) = NEW zcl_mcp2_dispatch_modern( NEW ltcl_resource_server( ) ).
    DATA(resp) = d->dispatch( request = req
                              header_ver = zif_mcp2_const=>protocol-v2026_07_28 ).
    cl_abap_unit_assert=>assert_equals(
      exp = zif_mcp2_const=>error_codes-invalid_params act = resp-error-code ).
    cl_abap_unit_assert=>assert_equals(
      exp = `mcp2://missing` act = resp-error-data->get_string( '/uri' ) ).
  ENDMETHOD.

  METHOD test_tasks_cap_false_bad.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.
    req-jsonrpc = `2.0`.
    req-method = zif_mcp2_const=>methods-tasks_get.
    req-id = `1`.
    req-id_present = abap_true.
    req-params = zcl_mcp2_ajson=>parse(
      `{"taskId":"AABBCCDDEEFF00112233445566778899","_meta":{` &&
      `"io.modelcontextprotocol/protocolVersion":"2026-07-28",` &&
      `"io.modelcontextprotocol/clientInfo":{"name":"Unit","version":"1"},` &&
      `"io.modelcontextprotocol/clientCapabilities":{"extensions":{` &&
      `"io.modelcontextprotocol/tasks":false}}}}` ).
    DATA(d) = NEW zcl_mcp2_dispatch_modern( NEW ltcl_task_cap_server( ) ).
    DATA(resp) = d->dispatch( request = req
                              header_ver = zif_mcp2_const=>protocol-v2026_07_28 ).
    cl_abap_unit_assert=>assert_equals(
      exp = zif_mcp2_const=>error_codes-invalid_params act = resp-error-code ).
  ENDMETHOD.

  METHOD test_tasks_lowercase_name.
    DATA(lower_id) = `aabbccddeeff00112233445566778899`.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.
    req-jsonrpc = `2.0`.
    req-method = zif_mcp2_const=>methods-tasks_get.
    req-id = `1`.
    req-id_present = abap_true.
    req-params = modern_params_with_tasks_cap( ).
    req-params->set_string( iv_path = '/taskId' iv_val = lower_id ).
    DATA(http) = NEW ltcl_mock_request( ).
    APPEND zif_mcp2_const=>headers-method TO http->headers.
    APPEND zif_mcp2_const=>methods-tasks_get TO http->hdr_vals.
    APPEND zif_mcp2_const=>headers-name TO http->headers.
    APPEND lower_id TO http->hdr_vals.
    DATA(server) = NEW ltcl_task_cap_server( ).
    DATA(d) = NEW zcl_mcp2_dispatch_modern( server ).
    DATA(resp) = d->dispatch( request = req
                              header_ver = zif_mcp2_const=>protocol-v2026_07_28
                              http_request = http ).
    cl_abap_unit_assert=>assert_initial( resp-error-code ).
    cl_abap_unit_assert=>assert_equals(
      exp = to_upper( lower_id ) act = server->received_task_id ).
  ENDMETHOD.

  METHOD test_empty_param_header.
    DATA(req) = make_tools_call_request( tool_name = `tool` ).
    req-params->set_string( iv_path = '/arguments/p' iv_val = `` ).
    DATA(http) = make_tools_call_http( tool_name = `tool` ).
    APPEND `Mcp-Param-P` TO http->headers.
    APPEND `` TO http->hdr_vals.
    DATA(d) = NEW zcl_mcp2_dispatch_modern( NEW ltcl_hdr_test_server( ) ).
    DATA(resp) = d->dispatch( request = req
                              header_ver = zif_mcp2_const=>protocol-v2026_07_28
                              http_request = http ).
    cl_abap_unit_assert=>assert_initial( resp-error-code ).
  ENDMETHOD.

  METHOD setup.
    server     = NEW ltcl_test_server( ).
    dispatcher = NEW zcl_mcp2_dispatch_modern( server ).
  ENDMETHOD.

  METHOD modern_params.
    result = zcl_mcp2_ajson=>parse(
        `{"_meta":{"io.modelcontextprotocol/protocolVersion":"2026-07-28","io.modelcontextprotocol/clientInfo":{"name":"Unit","version":"1"},"io.modelcontextprotocol/clientCapabilities":{}}}` ).
  ENDMETHOD.

  METHOD modern_params_with_sampling.
    result = zcl_mcp2_ajson=>parse(
        `{"_meta":{"io.modelcontextprotocol/protocolVersion":"2026-07-28","io.modelcontextprotocol/clientInfo":{"name":"Unit","version":"1"},"io.modelcontextprotocol/clientCapabilities":{"sampling":{}}}}` ).
  ENDMETHOD.

  METHOD modern_params_with_elicit.
    result = zcl_mcp2_ajson=>parse(
        `{"_meta":{"io.modelcontextprotocol/protocolVersion":"2026-07-28","io.modelcontextprotocol/clientInfo":{"name":"Unit","version":"1"},"io.modelcontextprotocol/clientCapabilities":{"elicitation":{}}}}` ).
  ENDMETHOD.

  METHOD modern_params_elicit_url_only.
    " elicitation with url mode only - form mode is NOT supported.
    result = zcl_mcp2_ajson=>parse(
        `{"_meta":{"io.modelcontextprotocol/protocolVersion":"2026-07-28","io.modelcontextprotocol/clientInfo":{"name":"Unit","version":"1"},"io.modelcontextprotocol/clientCapabilities":{"elicitation":{"url":{}}}}}` ).
  ENDMETHOD.

  METHOD modern_params_with_tasks_cap.
    result = zcl_mcp2_ajson=>parse(
        `{"_meta":{"io.modelcontextprotocol/protocolVersion":"2026-07-28",` &&
        `"io.modelcontextprotocol/clientInfo":{"name":"Unit","version":"1"},` &&
        `"io.modelcontextprotocol/clientCapabilities":` &&
        `{"extensions":{"io.modelcontextprotocol/tasks":{}}}}}` ).
  ENDMETHOD.

  METHOD make_tools_call_request.
    result-jsonrpc    = `2.0`.
    result-method     = zif_mcp2_const=>methods-tools_call.
    result-id         = `1`.
    result-id_present = abap_true.

    DATA meta TYPE REF TO zif_mcp2_ajson.
    IF with_sampling = abap_true.
      meta = modern_params_with_sampling( ).
    ELSE.
      meta = modern_params( ).
    ENDIF.
    meta->set_string( iv_path = '/name'       iv_val = tool_name ).
    meta->set( iv_path = '/arguments'
               iv_val  = zcl_mcp2_ajson=>parse( '{}' ) ).
    result-params = meta.
  ENDMETHOD.

  METHOD make_tools_call_http.
    result = NEW ltcl_mock_request( ).
    APPEND zif_mcp2_const=>headers-method TO result->headers.
    APPEND zif_mcp2_const=>methods-tools_call TO result->hdr_vals.
    APPEND zif_mcp2_const=>headers-name TO result->headers.
    APPEND tool_name TO result->hdr_vals.
  ENDMETHOD.

  METHOD test_ping_removed.
    " ping was removed from the 2026-07-28 vocabulary - the modern
    " dispatcher must not route it.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.

    req-jsonrpc    = `2.0`.
    req-method     = zif_mcp2_const=>methods-ping.
    req-id         = `1`.
    req-id_present = abap_true.
    req-params     = modern_params( ).

    DATA(resp) = dispatcher->dispatch( request    = req
                                       header_ver = zif_mcp2_const=>protocol-v2026_07_28 ).

    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-method_not_found
                                        act = resp-error-code ).
    cl_abap_unit_assert=>assert_equals( exp = `1`
                                        act = resp-id ).
  ENDMETHOD.

  METHOD test_unknown_method.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.

    req-jsonrpc    = `2.0`.
    req-method     = `no/such/method`.
    req-id         = `1`.
    req-id_present = abap_true.
    req-params     = modern_params( ).

    DATA(resp) = dispatcher->dispatch( request    = req
                                       header_ver = zif_mcp2_const=>protocol-v2026_07_28 ).

    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-method_not_found
                                        act = resp-error-code ).
  ENDMETHOD.

  METHOD test_discover.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.

    req-jsonrpc    = `2.0`.
    req-method     = zif_mcp2_const=>methods-server_discover.
    req-id         = `1`.
    req-id_present = abap_true.
    req-params     = modern_params( ).

    DATA(resp) = dispatcher->dispatch( request    = req
                                       header_ver = zif_mcp2_const=>protocol-v2026_07_28 ).

    cl_abap_unit_assert=>assert_initial( resp-error-code ).
    DATA(result_json) = zcl_mcp2_ajson=>parse( zcl_mcp2_jsonrpc=>serialize_response( resp ) ).
    DATA(tab) = cl_abap_char_utilities=>horizontal_tab.
    DATA(server_info_path) = '/result/_meta/io.modelcontextprotocol' && tab && 'serverInfo'.
    " serverInfo lives in _meta (ResultMetaObject) only; the discover body
    " carries no top-level serverInfo since the 2026-07-16 schema change.
    cl_abap_unit_assert=>assert_equals( exp = `ModernServer`
                                        act = result_json->get_string( |{ server_info_path }/name| ) ).
    cl_abap_unit_assert=>assert_false( result_json->exists( '/result/serverInfo' ) ).
    cl_abap_unit_assert=>assert_true( result_json->exists( '/result/supportedVersions' ) ).
    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>result_types-complete
                                        act = result_json->get_string( '/result/resultType' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = result_json->get_integer( '/result/ttlMs' ) ).
    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>cache_scopes-private
                                        act = result_json->get_string( '/result/cacheScope' ) ).
    " Optional identity fields are omitted when the server provides none.
    cl_abap_unit_assert=>assert_false( result_json->exists( |{ server_info_path }/title| ) ).
  ENDMETHOD.

  METHOD test_discover_identity.
    " Identity fields and configurable discover cache hints.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.

    req-jsonrpc    = `2.0`.
    req-method     = zif_mcp2_const=>methods-server_discover.
    req-id         = `1`.
    req-id_present = abap_true.
    req-params     = modern_params( ).

    DATA(ident_dispatcher) = NEW zcl_mcp2_dispatch_modern( NEW ltcl_ident_server( ) ).
    DATA(resp) = ident_dispatcher->dispatch( request    = req
                                             header_ver = zif_mcp2_const=>protocol-v2026_07_28 ).

    cl_abap_unit_assert=>assert_initial( resp-error-code ).
    DATA(result_json) = zcl_mcp2_ajson=>parse( zcl_mcp2_jsonrpc=>serialize_response( resp ) ).
    DATA(tab) = cl_abap_char_utilities=>horizontal_tab.
    DATA(server_info_path) = '/result/_meta/io.modelcontextprotocol' && tab && 'serverInfo'.
    " _meta is the only identity location in the modern era.
    cl_abap_unit_assert=>assert_false( result_json->exists( '/result/serverInfo' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `Ident Server`
                                        act = result_json->get_string( |{ server_info_path }/title| ) ).
    cl_abap_unit_assert=>assert_equals( exp = `Serves identity fields for tests.`
                                        act = result_json->get_string( |{ server_info_path }/description| ) ).
    cl_abap_unit_assert=>assert_equals( exp = `https://example.com/ident`
                                        act = result_json->get_string( |{ server_info_path }/websiteUrl| ) ).
    cl_abap_unit_assert=>assert_equals( exp = `https://example.com/ident.png`
                                        act = result_json->get_string( |{ server_info_path }/icons/1/src| ) ).
    cl_abap_unit_assert=>assert_equals( exp = `light`
                                        act = result_json->get_string( |{ server_info_path }/icons/1/theme| ) ).
    cl_abap_unit_assert=>assert_equals( exp = 3600000
                                        act = result_json->get_integer( '/result/ttlMs' ) ).
    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>cache_scopes-public
                                        act = result_json->get_string( '/result/cacheScope' ) ).
  ENDMETHOD.

  METHOD test_discover_no_client_info.
    " io.modelcontextprotocol/clientInfo is optional per the 2026-07-28 draft
    " (2026-07-16 schema change) - a request omitting it entirely must still
    " succeed, not be rejected as malformed params.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.

    req-jsonrpc    = `2.0`.
    req-method     = zif_mcp2_const=>methods-server_discover.
    req-id         = `1`.
    req-id_present = abap_true.
    req-params     = zcl_mcp2_ajson=>parse(
        `{"_meta":{"io.modelcontextprotocol/protocolVersion":"2026-07-28",` &&
        `"io.modelcontextprotocol/clientCapabilities":{}}}` ).

    DATA(resp) = dispatcher->dispatch( request    = req
                                       header_ver = zif_mcp2_const=>protocol-v2026_07_28 ).

    cl_abap_unit_assert=>assert_initial( resp-error-code ).
    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>result_types-complete
                                        act = resp-result->get_string( '/resultType' ) ).
  ENDMETHOD.

  METHOD test_bad_client_info.
    " clientInfo is optional, but when the key IS present it must still be a
    " well-formed Implementation (non-empty name and version).
    DATA req TYPE zcl_mcp2_jsonrpc=>request.

    req-jsonrpc    = `2.0`.
    req-method     = zif_mcp2_const=>methods-server_discover.
    req-id         = `1`.
    req-id_present = abap_true.
    req-params     = zcl_mcp2_ajson=>parse(
        `{"_meta":{"io.modelcontextprotocol/protocolVersion":"2026-07-28",` &&
        `"io.modelcontextprotocol/clientInfo":{"name":"Unit"},` &&
        `"io.modelcontextprotocol/clientCapabilities":{}}}` ).

    DATA(resp) = dispatcher->dispatch( request    = req
                                       header_ver = zif_mcp2_const=>protocol-v2026_07_28 ).

    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-invalid_params
                                        act = resp-error-code ).
  ENDMETHOD.

  METHOD test_server_info_non_discover.
    " _meta.serverInfo is not discover-only: the 2026-07-28 ResultMetaObject
    " applies to every modern result.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.
    req-jsonrpc    = `2.0`.
    req-method     = zif_mcp2_const=>methods-resources_read.
    req-id         = `1`.
    req-id_present = abap_true.
    req-params     = modern_params( ).
    req-params->set_string( iv_path = '/uri' iv_val = `mcp2://cache` ).

    DATA(d) = NEW zcl_mcp2_dispatch_modern( NEW ltcl_resource_server( ) ).
    DATA(resp) = d->dispatch( request    = req
                             header_ver = zif_mcp2_const=>protocol-v2026_07_28 ).

    cl_abap_unit_assert=>assert_initial( resp-error-code ).
    DATA(tab) = cl_abap_char_utilities=>horizontal_tab.
    DATA(server_info_path) = '/_meta/io.modelcontextprotocol' && tab && 'serverInfo'.
    cl_abap_unit_assert=>assert_equals( exp = `ResourceServer`
                                        act = resp-result->get_string( |{ server_info_path }/name| ) ).
  ENDMETHOD.

  METHOD test_header_mismatch.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.

    req-jsonrpc    = `2.0`.
    req-method     = zif_mcp2_const=>methods-tools_list.
    req-id         = `1`.
    req-id_present = abap_true.
    req-params     = modern_params( ).

    " Header says legacy, _meta says modern -> mismatch
    DATA(resp) = dispatcher->dispatch( request    = req
                                       header_ver = `2025-11-25` ).

    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-header_mismatch
                                        act = resp-error-code ).
  ENDMETHOD.

  METHOD test_missing_meta.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.

    req-jsonrpc    = `2.0`.
    req-method     = zif_mcp2_const=>methods-tools_list.
    req-id         = `1`.
    req-id_present = abap_true.
    req-params     = zcl_mcp2_ajson=>create_empty( ).

    DATA(resp) = dispatcher->dispatch( request    = req
                                       header_ver = zif_mcp2_const=>protocol-v2026_07_28 ).

    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-invalid_params
                                        act = resp-error-code ).
  ENDMETHOD.

  METHOD test_log_level_ok.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.
    req-jsonrpc    = `2.0`.
    " Use discovery for the positive metadata case: the minimal test server
    " does not advertise tools, so tools/list would correctly return -32601
    " after logLevel validation succeeds.
    req-method     = zif_mcp2_const=>methods-server_discover.
    req-id         = `1`.
    req-id_present = abap_true.
    req-params     = modern_params( ).
    DATA(tab) = cl_abap_char_utilities=>horizontal_tab.
    req-params->set_string(
      iv_path = '/_meta/io.modelcontextprotocol' && tab && 'logLevel'
      iv_val  = `warning` ).

    DATA(resp) = dispatcher->dispatch(
      request    = req
      header_ver = zif_mcp2_const=>protocol-v2026_07_28 ).
    cl_abap_unit_assert=>assert_initial( resp-error-code ).
  ENDMETHOD.

  METHOD test_log_level_bad.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.
    req-jsonrpc    = `2.0`.
    req-method     = zif_mcp2_const=>methods-tools_list.
    req-id         = `1`.
    req-id_present = abap_true.
    req-params     = modern_params( ).
    DATA(tab) = cl_abap_char_utilities=>horizontal_tab.
    req-params->set_string(
      iv_path = '/_meta/io.modelcontextprotocol' && tab && 'logLevel'
      iv_val  = `verbose` ).

    DATA(resp) = dispatcher->dispatch(
      request    = req
      header_ver = zif_mcp2_const=>protocol-v2026_07_28 ).
    cl_abap_unit_assert=>assert_equals(
      exp = zif_mcp2_const=>error_codes-invalid_params
      act = resp-error-code ).
  ENDMETHOD.

  METHOD test_logging_removed.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.

    req-jsonrpc    = `2.0`.
    req-method     = zif_mcp2_const=>methods-logging_set_level.
    req-id         = `1`.
    req-id_present = abap_true.
    req-params     = modern_params( ).

    " logging/setLevel was removed in 2026-07-28 (replaced by _meta logLevel)
    " and the Logging feature is deprecated - never routed in the modern era.
    DATA(resp) = dispatcher->dispatch( request    = req
                                       header_ver = zif_mcp2_const=>protocol-v2026_07_28 ).

    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-method_not_found
                                        act = resp-error-code ).
  ENDMETHOD.

  METHOD test_method_header.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.

    req-jsonrpc    = `2.0`.
    req-method     = zif_mcp2_const=>methods-tools_list.
    req-id         = `1`.
    req-id_present = abap_true.
    req-params     = modern_params( ).

    DATA http TYPE REF TO ltcl_mock_request.
    http = NEW #( ).
    APPEND zif_mcp2_const=>headers-method TO http->headers.
    APPEND zif_mcp2_const=>methods-prompts_list TO http->hdr_vals.

    DATA(resp) = dispatcher->dispatch( request      = req
                                       header_ver   = zif_mcp2_const=>protocol-v2026_07_28
                                       http_request = http ).

    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-header_mismatch
                                        act = resp-error-code ).
  ENDMETHOD.

  METHOD test_name_base64.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.

    req-jsonrpc    = `2.0`.
    req-method     = zif_mcp2_const=>methods-tools_call.
    req-id         = `1`.
    req-id_present = abap_true.
    req-params     = zcl_mcp2_ajson=>parse(
      `{"name":"nested","arguments":{},"_meta":{"io.modelcontextprotocol/protocolVersion":"2026-07-28","io.modelcontextprotocol/clientInfo":{"name":"Unit","version":"1"},"io.modelcontextprotocol/clientCapabilities":{}}}` ).

    DATA http TYPE REF TO ltcl_mock_request.
    http = NEW #( ).
    APPEND zif_mcp2_const=>headers-method TO http->headers.
    APPEND zif_mcp2_const=>methods-tools_call TO http->hdr_vals.
    APPEND zif_mcp2_const=>headers-name TO http->headers.
    APPEND `=?base64?bmVzdGVk?=` TO http->hdr_vals.

    DATA(tool_dispatcher) = NEW zcl_mcp2_dispatch_modern( NEW ltcl_tool_server( ) ).
    DATA(resp) = tool_dispatcher->dispatch( request      = req
                                            header_ver   = zif_mcp2_const=>protocol-v2026_07_28
                                            http_request = http ).

    cl_abap_unit_assert=>assert_initial( resp-error-code ).
  ENDMETHOD.

  METHOD test_name_pct_literal.
    " A name containing literal percent-escapes must compare byte-for-byte:
    " body 'a%20b' + header 'a%20b' -> match (no percent-decoding exists).
    DATA req TYPE zcl_mcp2_jsonrpc=>request.

    req-jsonrpc    = `2.0`.
    req-method     = zif_mcp2_const=>methods-tools_call.
    req-id         = `1`.
    req-id_present = abap_true.
    req-params     = zcl_mcp2_ajson=>parse(
      `{"name":"a%20b","arguments":{},"_meta":{"io.modelcontextprotocol/protocolVersion":"2026-07-28","io.modelcontextprotocol/clientInfo":{"name":"Unit","version":"1"},"io.modelcontextprotocol/clientCapabilities":{}}}` ).

    DATA http TYPE REF TO ltcl_mock_request.
    http = NEW #( ).
    APPEND zif_mcp2_const=>headers-method TO http->headers.
    APPEND zif_mcp2_const=>methods-tools_call TO http->hdr_vals.
    APPEND zif_mcp2_const=>headers-name TO http->headers.
    APPEND `a%20b` TO http->hdr_vals.

    DATA(tool_dispatcher) = NEW zcl_mcp2_dispatch_modern( NEW ltcl_tool_server( ) ).
    DATA(resp) = tool_dispatcher->dispatch( request      = req
                                            header_ver   = zif_mcp2_const=>protocol-v2026_07_28
                                            http_request = http ).

    cl_abap_unit_assert=>assert_initial( resp-error-code ).
  ENDMETHOD.

  METHOD test_name_pct_no_decode.
    " A percent-encoded header against a plain body value must NOT match:
    " SEP-2243 defines no percent-encoding, only the base64 sentinel.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.

    req-jsonrpc    = `2.0`.
    req-method     = zif_mcp2_const=>methods-tools_call.
    req-id         = `1`.
    req-id_present = abap_true.
    req-params     = zcl_mcp2_ajson=>parse(
      `{"name":"a b","arguments":{},"_meta":{"io.modelcontextprotocol/protocolVersion":"2026-07-28","io.modelcontextprotocol/clientInfo":{"name":"Unit","version":"1"},"io.modelcontextprotocol/clientCapabilities":{}}}` ).

    DATA http TYPE REF TO ltcl_mock_request.
    http = NEW #( ).
    APPEND zif_mcp2_const=>headers-method TO http->headers.
    APPEND zif_mcp2_const=>methods-tools_call TO http->hdr_vals.
    APPEND zif_mcp2_const=>headers-name TO http->headers.
    APPEND `a%20b` TO http->hdr_vals.

    DATA(tool_dispatcher) = NEW zcl_mcp2_dispatch_modern( NEW ltcl_tool_server( ) ).
    DATA(resp) = tool_dispatcher->dispatch( request      = req
                                            header_ver   = zif_mcp2_const=>protocol-v2026_07_28
                                            http_request = http ).

    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-header_mismatch
                                        act = resp-error-code ).
  ENDMETHOD.

  METHOD test_nested_header.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.

    req-jsonrpc    = `2.0`.
    req-method     = zif_mcp2_const=>methods-tools_call.
    req-id         = `1`.
    req-id_present = abap_true.
    req-params     = zcl_mcp2_ajson=>parse(
      `{"name":"nested","arguments":{"outer":{"inner":"line\nvalue"}},"_meta":{"io.modelcontextprotocol/protocolVersion":"2026-07-28","io.modelcontextprotocol/clientInfo":{"name":"Unit","version":"1"},"io.modelcontextprotocol/clientCapabilities":{}}}` ).

    DATA http TYPE REF TO ltcl_mock_request.
    http = NEW #( ).
    APPEND zif_mcp2_const=>headers-method TO http->headers.
    APPEND zif_mcp2_const=>methods-tools_call TO http->hdr_vals.
    APPEND zif_mcp2_const=>headers-name TO http->headers.
    APPEND `nested` TO http->hdr_vals.
    APPEND `Mcp-Param-Inner` TO http->headers.
    APPEND `=?base64?bGluZQp2YWx1ZQ==?=` TO http->hdr_vals.

    DATA(tool_dispatcher) = NEW zcl_mcp2_dispatch_modern( NEW ltcl_tool_server( ) ).
    DATA(resp) = tool_dispatcher->dispatch( request      = req
                                            header_ver   = zif_mcp2_const=>protocol-v2026_07_28
                                            http_request = http ).

    cl_abap_unit_assert=>assert_initial( resp-error-code ).
  ENDMETHOD.

  " --- Fix 1: MRTR/input_required enforcement ---------------------------------------------

  METHOD test_mrtr_wrong_method.
    " tools/list returning input_required --> internal_error (not an MRTR method)
    DATA req TYPE zcl_mcp2_jsonrpc=>request.
    req-jsonrpc    = `2.0`.
    req-method     = zif_mcp2_const=>methods-tools_list.
    req-id         = `1`.
    req-id_present = abap_true.
    req-params     = modern_params( ).

    DATA d TYPE REF TO zcl_mcp2_dispatch_modern.
    d = NEW zcl_mcp2_dispatch_modern( NEW ltcl_ir_list_server( ) ).
    DATA(resp) = d->dispatch( request    = req
                              header_ver = zif_mcp2_const=>protocol-v2026_07_28 ).

    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-internal_error
                                        act = resp-error-code ).
  ENDMETHOD.

  METHOD test_mrtr_no_cap.
    " tools/call returning input_required with sampling/createMessage,
    " client declares no sampling capability --> missing_client_cap (-32021)
    DATA req TYPE zcl_mcp2_jsonrpc=>request.
    req = make_tools_call_request( tool_name = `tool` with_sampling = abap_false ).

    DATA d TYPE REF TO zcl_mcp2_dispatch_modern.
    d = NEW zcl_mcp2_dispatch_modern( NEW ltcl_ir_call_server( ) ).
    DATA(resp) = d->dispatch( request    = req
                              header_ver = zif_mcp2_const=>protocol-v2026_07_28 ).

    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-missing_client_cap
                                        act = resp-error-code ).
  ENDMETHOD.

  METHOD test_mrtr_empty_bad.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.
    req = make_tools_call_request( tool_name = `tool` with_sampling = abap_true ).

    DATA d TYPE REF TO zcl_mcp2_dispatch_modern.
    d = NEW zcl_mcp2_dispatch_modern( NEW ltcl_ir_empty_server( ) ).
    DATA(resp) = d->dispatch( request    = req
                              header_ver = zif_mcp2_const=>protocol-v2026_07_28 ).

    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-internal_error
                                        act = resp-error-code ).
  ENDMETHOD.

  METHOD test_mrtr_url_no_cap.
    " {elicitation:{}} means form-only; URL mode requires elicitation.url.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.
    req = make_tools_call_request( tool_name = `tool` ).
    req-params = modern_params_with_elicit( ).
    req-params->set_string( iv_path = '/name'
                            iv_val  = `tool` ).
    req-params->set( iv_path = '/arguments'
                     iv_val  = zcl_mcp2_ajson=>parse( '{}' ) ).

    DATA d TYPE REF TO zcl_mcp2_dispatch_modern.
    d = NEW zcl_mcp2_dispatch_modern( NEW ltcl_ir_url_server( ) ).
    DATA(resp) = d->dispatch( request    = req
                              header_ver = zif_mcp2_const=>protocol-v2026_07_28 ).

    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-missing_client_cap
                                        act = resp-error-code ).
  ENDMETHOD.

  METHOD test_mrtr_form_no_cap.
    " Client declares elicitation:{url:{}} (no form); a form-mode inputRequest
    " must be rejected with missing_client_cap (-32021), not slip through.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.
    req = make_tools_call_request( tool_name = `tool` ).
    req-params = modern_params_elicit_url_only( ).
    req-params->set_string( iv_path = '/name'
                            iv_val  = `tool` ).
    req-params->set( iv_path = '/arguments'
                     iv_val  = zcl_mcp2_ajson=>parse( '{}' ) ).

    DATA d TYPE REF TO zcl_mcp2_dispatch_modern.
    d = NEW zcl_mcp2_dispatch_modern( NEW ltcl_ir_form_server( ) ).
    DATA(resp) = d->dispatch( request    = req
                              header_ver = zif_mcp2_const=>protocol-v2026_07_28 ).

    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-missing_client_cap
                                        act = resp-error-code ).
  ENDMETHOD.

  METHOD test_mrtr_form_ok.
    " A bare elicitation:{} object means form-only support - a form-mode
    " inputRequest is accepted and surfaces as an input_required result.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.
    req = make_tools_call_request( tool_name = `tool` ).
    req-params = modern_params_with_elicit( ).
    req-params->set_string( iv_path = '/name'
                            iv_val  = `tool` ).
    req-params->set( iv_path = '/arguments'
                     iv_val  = zcl_mcp2_ajson=>parse( '{}' ) ).

    DATA d TYPE REF TO zcl_mcp2_dispatch_modern.
    d = NEW zcl_mcp2_dispatch_modern( NEW ltcl_ir_form_server( ) ).
    DATA(resp) = d->dispatch( request    = req
                              header_ver = zif_mcp2_const=>protocol-v2026_07_28 ).

    cl_abap_unit_assert=>assert_initial( resp-error-code ).
    cl_abap_unit_assert=>assert_equals(
      exp = zif_mcp2_const=>result_types-input_required
      act = resp-result->get_string( '/resultType' ) ).
  ENDMETHOD.

  METHOD test_mrtr_ok.
    " tools/call returning input_required with sampling/createMessage,
    " client declares sampling --> success (resultType=input_required)
    DATA req TYPE zcl_mcp2_jsonrpc=>request.
    req = make_tools_call_request( tool_name = `tool` with_sampling = abap_true ).

    DATA d TYPE REF TO zcl_mcp2_dispatch_modern.
    d = NEW zcl_mcp2_dispatch_modern( NEW ltcl_ir_call_server( ) ).
    DATA(resp) = d->dispatch( request    = req
                              header_ver = zif_mcp2_const=>protocol-v2026_07_28 ).

    cl_abap_unit_assert=>assert_initial( resp-error-code ).
    DATA(result_json) = zcl_mcp2_ajson=>parse( zcl_mcp2_jsonrpc=>serialize_response( resp ) ).
    cl_abap_unit_assert=>assert_equals(
        exp = zif_mcp2_const=>result_types-input_required
        act = result_json->get_string( '/result/resultType' ) ).
  ENDMETHOD.

  METHOD test_input_valid_ok.
    " validate_tool_input on + schema-conformant arguments --> handler runs.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.
    req = make_tools_call_request( tool_name = `tool` ).
    req-params->set( iv_path = '/arguments'
                     iv_val  = zcl_mcp2_ajson=>parse( '{"msg":"hello"}' ) ).

    DATA d TYPE REF TO zcl_mcp2_dispatch_modern.
    d = NEW zcl_mcp2_dispatch_modern( NEW ltcl_vld_input_server( ) ).
    DATA(resp) = d->dispatch( request    = req
                              header_ver = zif_mcp2_const=>protocol-v2026_07_28 ).

    cl_abap_unit_assert=>assert_initial( resp-error-code ).
  ENDMETHOD.

  METHOD test_input_invalid.
    " validate_tool_input on + missing required argument --> isError tool result.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.
    req = make_tools_call_request( tool_name = `tool` ).

    DATA d TYPE REF TO zcl_mcp2_dispatch_modern.
    d = NEW zcl_mcp2_dispatch_modern( NEW ltcl_vld_input_server( ) ).
    DATA(resp) = d->dispatch( request    = req
                              header_ver = zif_mcp2_const=>protocol-v2026_07_28 ).

    cl_abap_unit_assert=>assert_initial( resp-error-code ).
    DATA(result_json) = zcl_mcp2_ajson=>parse( zcl_mcp2_jsonrpc=>serialize_response( resp ) ).
    cl_abap_unit_assert=>assert_equals( exp = abap_true
                                        act = result_json->get_boolean( '/result/isError' ) ).
  ENDMETHOD.

  METHOD test_input_no_args_ok.
    " validate_tool_input on + no arguments at all + schema with no required
    " fields --> must still pass. The no-arguments fallback used to graft an
    " ajson create_empty() instance, whose root has no node type, so
    " validate() rejected every argument-less call regardless of schema.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.
    req = make_tools_call_request( tool_name = `tool` ).

    DATA d TYPE REF TO zcl_mcp2_dispatch_modern.
    d = NEW zcl_mcp2_dispatch_modern( NEW ltcl_vld_optional_server( ) ).
    DATA(resp) = d->dispatch( request    = req
                              header_ver = zif_mcp2_const=>protocol-v2026_07_28 ).

    cl_abap_unit_assert=>assert_initial( resp-error-code ).
    DATA(result_json) = zcl_mcp2_ajson=>parse( zcl_mcp2_jsonrpc=>serialize_response( resp ) ).
    cl_abap_unit_assert=>assert_false( result_json->get_boolean( '/result/isError' ) ).
  ENDMETHOD.

  " --- Fix 2: x-mcp-header must be a non-empty string -------------------------------------

  METHOD test_xmcp_bool_rejected.
    " Schema has x-mcp-header: true (boolean) --> invalid_params
    DATA req TYPE zcl_mcp2_jsonrpc=>request.
    req = make_tools_call_request( tool_name = `tool` ).
    DATA http TYPE REF TO ltcl_mock_request.
    http = make_tools_call_http( tool_name = `tool` ).

    DATA d TYPE REF TO zcl_mcp2_dispatch_modern.
    d = NEW zcl_mcp2_dispatch_modern( NEW ltcl_schema_bool_srv( ) ).
    DATA(resp) = d->dispatch( request      = req
                              header_ver   = zif_mcp2_const=>protocol-v2026_07_28
                              http_request = http ).

    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-invalid_params
                                        act = resp-error-code ).
  ENDMETHOD.

  METHOD test_xmcp_empty_rejected.
    " Schema has x-mcp-header: "" (empty string) --> invalid_params
    DATA req TYPE zcl_mcp2_jsonrpc=>request.
    req = make_tools_call_request( tool_name = `tool` ).
    DATA http TYPE REF TO ltcl_mock_request.
    http = make_tools_call_http( tool_name = `tool` ).

    DATA d TYPE REF TO zcl_mcp2_dispatch_modern.
    d = NEW zcl_mcp2_dispatch_modern( NEW ltcl_schema_empty_srv( ) ).
    DATA(resp) = d->dispatch( request      = req
                              header_ver   = zif_mcp2_const=>protocol-v2026_07_28
                              http_request = http ).

    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-invalid_params
                                        act = resp-error-code ).
  ENDMETHOD.

  METHOD test_xmcp_oneof_rejected.
    " Schema has x-mcp-header inside oneOf --> invalid_params
    DATA req TYPE zcl_mcp2_jsonrpc=>request.
    req = make_tools_call_request( tool_name = `tool` ).
    DATA http TYPE REF TO ltcl_mock_request.
    http = make_tools_call_http( tool_name = `tool` ).

    DATA d TYPE REF TO zcl_mcp2_dispatch_modern.
    d = NEW zcl_mcp2_dispatch_modern( NEW ltcl_schema_oneof_srv( ) ).
    DATA(resp) = d->dispatch( request      = req
                              header_ver   = zif_mcp2_const=>protocol-v2026_07_28
                              http_request = http ).

    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-invalid_params
                                        act = resp-error-code ).
  ENDMETHOD.

  METHOD test_xmcp_defs_rejected.
    " Schema has x-mcp-header inside $defs (behind a $ref) --> invalid_params
    DATA req TYPE zcl_mcp2_jsonrpc=>request.
    req = make_tools_call_request( tool_name = `tool` ).
    DATA http TYPE REF TO ltcl_mock_request.
    http = make_tools_call_http( tool_name = `tool` ).

    DATA d TYPE REF TO zcl_mcp2_dispatch_modern.
    d = NEW zcl_mcp2_dispatch_modern( NEW ltcl_schema_defs_srv( ) ).
    DATA(resp) = d->dispatch( request      = req
                              header_ver   = zif_mcp2_const=>protocol-v2026_07_28
                              http_request = http ).

    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-invalid_params
                                        act = resp-error-code ).
  ENDMETHOD.

  " --- Fix 3: plain header value character set ---------------------------------------------

  METHOD test_hdr_htab_mid_ok.
    " Plain Mcp-Param-P header containing HTAB in the middle --> allowed (RFC 9110)
    DATA req TYPE zcl_mcp2_jsonrpc=>request.
    req = make_tools_call_request( tool_name = `tool` ).
    DATA meta_with_arg TYPE REF TO zif_mcp2_ajson.
    meta_with_arg = modern_params( ).
    meta_with_arg->set_string( iv_path = '/name' iv_val = `tool` ).
    DATA(htab) = cl_abap_char_utilities=>horizontal_tab.
    meta_with_arg->set_string( iv_path = '/arguments/p'
                               iv_val  = |val{ htab }here| ).
    req-params = meta_with_arg.

    DATA http TYPE REF TO ltcl_mock_request.
    http = make_tools_call_http( tool_name = `tool` ).
    APPEND `Mcp-Param-P` TO http->headers.
    APPEND |val{ htab }here| TO http->hdr_vals.

    DATA d TYPE REF TO zcl_mcp2_dispatch_modern.
    d = NEW zcl_mcp2_dispatch_modern( NEW ltcl_hdr_test_server( ) ).
    DATA(resp) = d->dispatch( request      = req
                              header_ver   = zif_mcp2_const=>protocol-v2026_07_28
                              http_request = http ).

    cl_abap_unit_assert=>assert_initial( resp-error-code ).
  ENDMETHOD.

  METHOD test_hdr_nonascii_reject.
    " Plain Mcp-Param-P header containing non-ASCII --> header_mismatch
    DATA req TYPE zcl_mcp2_jsonrpc=>request.
    req = make_tools_call_request( tool_name = `tool` ).

    DATA http TYPE REF TO ltcl_mock_request.
    http = make_tools_call_http( tool_name = `tool` ).
    APPEND `Mcp-Param-P` TO http->headers.
    APPEND `café` TO http->hdr_vals.  " 'café' - contains non-ASCII é

    DATA d TYPE REF TO zcl_mcp2_dispatch_modern.
    d = NEW zcl_mcp2_dispatch_modern( NEW ltcl_hdr_test_server( ) ).
    DATA(resp) = d->dispatch( request      = req
                              header_ver   = zif_mcp2_const=>protocol-v2026_07_28
                              http_request = http ).

    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-header_mismatch
                                        act = resp-error-code ).
  ENDMETHOD.

  METHOD test_hdr_leading_ws.
    " Plain Mcp-Param-P header with leading space --> header_mismatch
    DATA req TYPE zcl_mcp2_jsonrpc=>request.
    req = make_tools_call_request( tool_name = `tool` ).

    DATA http TYPE REF TO ltcl_mock_request.
    http = make_tools_call_http( tool_name = `tool` ).
    APPEND `Mcp-Param-P` TO http->headers.
    APPEND ` leading space` TO http->hdr_vals.

    DATA d TYPE REF TO zcl_mcp2_dispatch_modern.
    d = NEW zcl_mcp2_dispatch_modern( NEW ltcl_hdr_test_server( ) ).
    DATA(resp) = d->dispatch( request      = req
                              header_ver   = zif_mcp2_const=>protocol-v2026_07_28
                              http_request = http ).

    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-header_mismatch
                                        act = resp-error-code ).
  ENDMETHOD.

  METHOD test_tasks_no_cap_gate.
    " supports_tasks() = false gates tasks/get before any capability check.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.
    req-jsonrpc    = `2.0`.
    req-method     = zif_mcp2_const=>methods-tasks_get.
    req-id         = `1`.
    req-id_present = abap_true.
    DATA(meta) = modern_params( ).
    meta->set_string( iv_path = '/taskId' iv_val = `AABBCCDDEEFF00112233445566778899` ).
    req-params = meta.

    DATA(resp) = dispatcher->dispatch( request    = req
                                       header_ver = zif_mcp2_const=>protocol-v2026_07_28 ).

    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-method_not_found
                                        act = resp-error-code ).
  ENDMETHOD.

  METHOD test_tasks_missing_ext_cap.
    " supports_tasks() = true, but the client never declared the
    " extensions/io.modelcontextprotocol/tasks capability --> -32021.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.
    req-jsonrpc    = `2.0`.
    req-method     = zif_mcp2_const=>methods-tasks_get.
    req-id         = `1`.
    req-id_present = abap_true.
    DATA(meta) = modern_params( ).
    meta->set_string( iv_path = '/taskId' iv_val = `AABBCCDDEEFF00112233445566778899` ).
    req-params = meta.

    DATA d TYPE REF TO zcl_mcp2_dispatch_modern.
    d = NEW zcl_mcp2_dispatch_modern( NEW ltcl_task_cap_server( ) ).
    DATA(resp) = d->dispatch( request    = req
                              header_ver = zif_mcp2_const=>protocol-v2026_07_28 ).

    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-missing_client_cap
                                        act = resp-error-code ).
  ENDMETHOD.

  METHOD test_tasks_cap_ok.
    " Capability declared + Mcp-Name mirrors the normalized taskId -->
    " the dispatcher routes through to the server's tasks_get.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.
    req-jsonrpc    = `2.0`.
    req-method     = zif_mcp2_const=>methods-tasks_get.
    req-id         = `1`.
    req-id_present = abap_true.
    DATA(meta) = modern_params_with_tasks_cap( ).
    meta->set_string( iv_path = '/taskId' iv_val = `AABBCCDDEEFF00112233445566778899` ).
    req-params = meta.

    DATA http TYPE REF TO ltcl_mock_request.
    http = NEW #( ).
    APPEND zif_mcp2_const=>headers-method TO http->headers.
    APPEND zif_mcp2_const=>methods-tasks_get TO http->hdr_vals.
    APPEND zif_mcp2_const=>headers-name TO http->headers.
    APPEND `AABBCCDDEEFF00112233445566778899` TO http->hdr_vals.

    DATA(server) = NEW ltcl_task_cap_server( ).
    DATA d TYPE REF TO zcl_mcp2_dispatch_modern.
    d = NEW zcl_mcp2_dispatch_modern( server ).
    DATA(resp) = d->dispatch( request      = req
                              header_ver   = zif_mcp2_const=>protocol-v2026_07_28
                              http_request = http ).

    cl_abap_unit_assert=>assert_initial( resp-error-code ).
    cl_abap_unit_assert=>assert_equals( exp = `AABBCCDDEEFF00112233445566778899`
                                        act = server->received_task_id ).
  ENDMETHOD.

  METHOD test_tasks_name_hdr_mismatch.
    " Mcp-Name must mirror params.taskId (normalized) for the tasks/*
    " extension, same as /name and /uri do for other methods.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.
    req-jsonrpc    = `2.0`.
    req-method     = zif_mcp2_const=>methods-tasks_get.
    req-id         = `1`.
    req-id_present = abap_true.
    DATA(meta) = modern_params_with_tasks_cap( ).
    meta->set_string( iv_path = '/taskId' iv_val = `AABBCCDDEEFF00112233445566778899` ).
    req-params = meta.

    DATA http TYPE REF TO ltcl_mock_request.
    http = NEW #( ).
    APPEND zif_mcp2_const=>headers-method TO http->headers.
    APPEND zif_mcp2_const=>methods-tasks_get TO http->hdr_vals.
    APPEND zif_mcp2_const=>headers-name TO http->headers.
    APPEND `00000000000000000000000000000000` TO http->hdr_vals.

    DATA d TYPE REF TO zcl_mcp2_dispatch_modern.
    d = NEW zcl_mcp2_dispatch_modern( NEW ltcl_task_cap_server( ) ).
    DATA(resp) = d->dispatch( request      = req
                              header_ver   = zif_mcp2_const=>protocol-v2026_07_28
                              http_request = http ).

    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-header_mismatch
                                        act = resp-error-code ).
  ENDMETHOD.

  METHOD test_tasks_no_name_hdr_ok.
    " The counterpart of test_tasks_name_hdr_mismatch: an omitted Mcp-Name on
    " tasks/* is accepted. The Tasks extension obliges the CLIENT to send it
    " for routing affinity, but no spec text obliges a server to reject its
    " absence, and this SDK reads every task from ZMCP2_TASKS - there is no
    " instance affinity to protect. tools/call and friends still require it
    " (test_tools_call_no_name_hdr).
    DATA req TYPE zcl_mcp2_jsonrpc=>request.
    req-jsonrpc    = `2.0`.
    req-method     = zif_mcp2_const=>methods-tasks_get.
    req-id         = `1`.
    req-id_present = abap_true.
    DATA(meta) = modern_params_with_tasks_cap( ).
    meta->set_string( iv_path = '/taskId' iv_val = `AABBCCDDEEFF00112233445566778899` ).
    req-params = meta.

    DATA http TYPE REF TO ltcl_mock_request.
    http = NEW #( ).
    APPEND zif_mcp2_const=>headers-method TO http->headers.
    APPEND zif_mcp2_const=>methods-tasks_get TO http->hdr_vals.

    DATA d TYPE REF TO zcl_mcp2_dispatch_modern.
    d = NEW zcl_mcp2_dispatch_modern( NEW ltcl_task_cap_server( ) ).
    DATA(resp) = d->dispatch( request      = req
                              header_ver   = zif_mcp2_const=>protocol-v2026_07_28
                              http_request = http ).

    cl_abap_unit_assert=>assert_initial( resp-error-code ).
  ENDMETHOD.

  METHOD test_tools_call_no_name_hdr.
    " Core transport: Mcp-Name is a required standard header for tools/call,
    " so a missing one stays -32020 - the leniency above is tasks/* only.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.
    req-jsonrpc    = `2.0`.
    req-method     = zif_mcp2_const=>methods-tools_call.
    req-id         = `1`.
    req-id_present = abap_true.
    DATA(params) = modern_params( ).
    params->set_string( iv_path = '/name' iv_val = `echo` ).
    req-params = params.

    DATA http TYPE REF TO ltcl_mock_request.
    http = NEW #( ).
    APPEND zif_mcp2_const=>headers-method TO http->headers.
    APPEND zif_mcp2_const=>methods-tools_call TO http->hdr_vals.

    DATA(resp) = dispatcher->dispatch( request      = req
                                       header_ver   = zif_mcp2_const=>protocol-v2026_07_28
                                       http_request = http ).

    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-header_mismatch
                                        act = resp-error-code ).
  ENDMETHOD.
ENDCLASS.
