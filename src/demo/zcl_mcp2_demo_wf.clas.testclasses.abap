CLASS ltcl_demo_wf DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.
  PUBLIC SECTION.
    METHODS test_identity                  FOR TESTING.
    METHODS test_first_call_input_required FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_report_sync_fallback      FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_legacy_approval_fallback  FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_retry_accept              FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_retry_decline             FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_retry_wrong_key           FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.

    "! Run one modern approval_required call and return the parsed result.
    "! @parameter params | tools/call params JSON
    METHODS modern_call
      IMPORTING params        TYPE string
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_error zcx_mcp2_ajson_error.
ENDCLASS.


CLASS ltcl_demo_wf IMPLEMENTATION.
  METHOD modern_call.
    DATA server TYPE REF TO zif_mcp2_server.
    server = NEW zcl_mcp2_demo_wf( ).

    DATA ctx TYPE zif_mcp2_server=>context.
    ctx-era         = zif_mcp2_const=>eras-modern.
    ctx-client_caps = zcl_mcp2_ajson=>parse( `{"elicitation":{}}` ).
    server->set_context( ctx ).

    DATA response TYPE REF TO zif_mcp2_result.
    response = server->tools_call(
        NEW zcl_mcp2_req_call_tool( zcl_mcp2_ajson=>parse( params ) ) ).
    result = zcl_mcp2_ajson=>parse( response->to_json( )->stringify( ) ).
  ENDMETHOD.

  METHOD test_identity.
    DATA server TYPE REF TO zif_mcp2_server.

    server = NEW zcl_mcp2_demo_wf( ).

    cl_abap_unit_assert=>assert_equals( exp = `mcp2-demo-wf`
                                        act = server->get_name( ) ).
    cl_abap_unit_assert=>assert_true( server->supports_tools( ) ).
    cl_abap_unit_assert=>assert_true( server->supports_tasks( ) ).
  ENDMETHOD.

  METHOD test_first_call_input_required.
    DATA server TYPE REF TO zif_mcp2_server.

    server = NEW zcl_mcp2_demo_wf( ).

    DATA ctx TYPE zif_mcp2_server=>context.
    ctx-era         = zif_mcp2_const=>eras-modern.
    ctx-client_caps = zcl_mcp2_ajson=>parse( `{"elicitation":{}}` ).
    server->set_context( ctx ).

    DATA params TYPE REF TO zif_mcp2_ajson.
    params = zcl_mcp2_ajson=>parse(
        `{"name":"approval_required","arguments":{"request_summary":"delete order 4711"}}` ) ##NO_TEXT.

    DATA response TYPE REF TO zif_mcp2_result.
    response = server->tools_call( NEW zcl_mcp2_req_call_tool( params ) ).

    DATA parsed TYPE REF TO zif_mcp2_ajson.
    parsed = zcl_mcp2_ajson=>parse( response->to_json( )->stringify( ) ).

    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>result_types-input_required
                                        act = response->result_type( ) ).
    " requestState carries the first call's summary forward - the server keeps
    " nothing between round-trips.
    cl_abap_unit_assert=>assert_equals( exp = `demo-approval:delete order 4711`
                                        act = parsed->get_string( '/requestState' ) ).
    " The elicited field must not collide with the tool's input argument.
    cl_abap_unit_assert=>assert_true( parsed->exists(
        '/inputRequests/approval/params/requestedSchema/properties/approval_reason' ) ).
  ENDMETHOD.

  METHOD test_retry_accept.
    " The retry leg: the client echoes requestState plus the elicited answer.
    DATA(json) = modern_call(
        `{"name":"approval_required","arguments":{"request_summary":"delete order 4711"},` &&
        `"requestState":"demo-approval:delete order 4711",` &&
        `"inputResponses":{"approval":{"action":"accept",` &&
        `"content":{"approval_reason":"checked with finance"}}}}` ).

    " Both halves survive the round-trip: the summary from requestState and the
    " reason from the elicited form.
    cl_abap_unit_assert=>assert_equals(
        exp = `Approved 'delete order 4711'. Reason given by the user: checked with finance.`
        act = json->get_string( '/content/1/text' ) ).
  ENDMETHOD.

  METHOD test_retry_decline.
    DATA(json) = modern_call(
        `{"name":"approval_required","arguments":{"request_summary":"delete order 4711"},` &&
        `"requestState":"demo-approval:delete order 4711",` &&
        `"inputResponses":{"approval":{"action":"decline"}}}` ).

    cl_abap_unit_assert=>assert_equals(
        exp = `Approval decline by the user for 'delete order 4711'.`
        act = json->get_string( '/content/1/text' ) ).
  ENDMETHOD.

  METHOD test_retry_wrong_key.
    " A retry answering some other key is a tool-level error the model can
    " react to, not a protocol error.
    DATA(json) = modern_call(
        `{"name":"approval_required","arguments":{"request_summary":"delete order 4711"},` &&
        `"requestState":"demo-approval:delete order 4711",` &&
        `"inputResponses":{"some_other_key":{"action":"accept"}}}` ).

    cl_abap_unit_assert=>assert_true( json->get_boolean( '/isError' ) ).
    cl_abap_unit_assert=>assert_true(
        xsdbool( json->get_string( '/content/1/text' ) CS `approval` ) ).
  ENDMETHOD.

  METHOD test_report_sync_fallback.
    DATA server TYPE REF TO zif_mcp2_server.
    server = NEW zcl_mcp2_demo_wf( ).

    DATA ctx TYPE zif_mcp2_server=>context.
    ctx-era = zif_mcp2_const=>eras-legacy.
    ctx-protocol_ver = zif_mcp2_const=>protocol-v2025_11_25.
    ctx-task_requested = abap_false.
    server->set_context( ctx ).

    DATA params TYPE REF TO zif_mcp2_ajson.
    params = zcl_mcp2_ajson=>parse( `{"name":"background_report","arguments":{}}` ).
    DATA response TYPE REF TO zif_mcp2_result.
    response = server->tools_call( NEW zcl_mcp2_req_call_tool( params ) ).
    DATA parsed TYPE REF TO zif_mcp2_ajson.
    parsed = zcl_mcp2_ajson=>parse( response->to_json( )->stringify( ) ).

    cl_abap_unit_assert=>assert_equals(
        exp = `Report finished synchronously: all demo rows processed.`
        act = parsed->get_string( '/content/1/text' ) ).
  ENDMETHOD.

  METHOD test_legacy_approval_fallback.
    DATA server TYPE REF TO zif_mcp2_server.
    server = NEW zcl_mcp2_demo_wf( ).

    DATA ctx TYPE zif_mcp2_server=>context.
    ctx-era = zif_mcp2_const=>eras-legacy.
    ctx-protocol_ver = zif_mcp2_const=>protocol-v2025_11_25.
    server->set_context( ctx ).

    DATA params TYPE REF TO zif_mcp2_ajson.
    params = zcl_mcp2_ajson=>parse(
        `{"name":"approval_required","arguments":{"request_summary":"trusted batch"}}` ).
    DATA response TYPE REF TO zif_mcp2_result.
    response = server->tools_call( NEW zcl_mcp2_req_call_tool( params ) ).
    DATA parsed TYPE REF TO zif_mcp2_ajson.
    parsed = zcl_mcp2_ajson=>parse( response->to_json( )->stringify( ) ).

    " The text describes what would happen; it must not claim a side effect
    " (a queue entry) that this demo never performs.
    cl_abap_unit_assert=>assert_equals(
        exp = `Legacy fallback: 'trusted batch' would require manual review. ` &&
              `No approval was requested and nothing was submitted.`
        act = parsed->get_string( '/content/1/text' ) ).
  ENDMETHOD.
ENDCLASS.
