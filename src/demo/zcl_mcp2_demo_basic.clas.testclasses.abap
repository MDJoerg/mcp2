CLASS ltcl_demo_basic DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.
  PUBLIC SECTION.
    METHODS test_identity   FOR TESTING.
    METHODS test_tools_list FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_request_info_legacy FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_request_info_modern FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_template_read FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_prompt_and_completion FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_completion_prefix FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_completion_no_match FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_completion_unrelated_ref FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_text_stats FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_text_stats_upper FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_price_quote FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_price_quote_default FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_price_quote_bad_array FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_price_quote_schema FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_ddic_schema_ok FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_ddic_schema_error FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_unknown_resource FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_prompt_required FOR TESTING RAISING zcx_mcp2_ajson_error.

    "! Run one completion request and return the parsed result.
    METHODS complete
      IMPORTING params        TYPE string
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_error zcx_mcp2_ajson_error.

    "! Call one tool with the given JSON params and return the parsed result.
    METHODS call_tool
      IMPORTING params        TYPE string
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_error zcx_mcp2_ajson_error.
ENDCLASS.


CLASS ltcl_demo_basic IMPLEMENTATION.
  METHOD complete.
    DATA server TYPE REF TO zif_mcp2_server.
    server = NEW zcl_mcp2_demo_basic( ).
    DATA response TYPE REF TO zif_mcp2_result.
    response = server->completions_complete(
        NEW zcl_mcp2_req_complete( zcl_mcp2_ajson=>parse( params ) ) ).
    result = zcl_mcp2_ajson=>parse( response->to_json( )->stringify( ) ).
  ENDMETHOD.

  METHOD call_tool.
    DATA server TYPE REF TO zif_mcp2_server.
    server = NEW zcl_mcp2_demo_basic( ).
    DATA response TYPE REF TO zif_mcp2_result.
    response = server->tools_call(
        NEW zcl_mcp2_req_call_tool( zcl_mcp2_ajson=>parse( params ) ) ).
    result = zcl_mcp2_ajson=>parse( response->to_json( )->stringify( ) ).
  ENDMETHOD.

  METHOD test_unknown_resource.
    DATA server TYPE REF TO zif_mcp2_server.
    server = NEW zcl_mcp2_demo_basic( ).
    TRY.
        server->resources_read( NEW zcl_mcp2_req_read_resource(
          zcl_mcp2_ajson=>parse( `{"uri":"mcp2://other/missing"}` ) ) ).
        cl_abap_unit_assert=>fail( `Expected resource-not-found signal` ).
      CATCH zcx_mcp2_error INTO DATA(err).
        cl_abap_unit_assert=>assert_equals(
          exp = zif_mcp2_const=>error_codes-resource_not_found act = err->code ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_prompt_required.
    DATA server TYPE REF TO zif_mcp2_server.
    server = NEW zcl_mcp2_demo_basic( ).
    TRY.
        server->prompts_get( NEW zcl_mcp2_req_get_prompt(
          zcl_mcp2_ajson=>parse( `{"name":"summarize","arguments":{}}` ) ) ).
        cl_abap_unit_assert=>fail( `Expected required prompt argument error` ).
      CATCH zcx_mcp2_error INTO DATA(err).
        cl_abap_unit_assert=>assert_equals(
          exp = zif_mcp2_const=>error_codes-invalid_params act = err->code ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_identity.
    DATA server TYPE REF TO zif_mcp2_server.

    server = NEW zcl_mcp2_demo_basic( ).

    cl_abap_unit_assert=>assert_equals( exp = `mcp2-demo-basic`
                                        act = server->get_name( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `MCP2 Basic Demo`
                                        act = server->get_title( ) ).
    cl_abap_unit_assert=>assert_not_initial( server->get_description( ) ).
    cl_abap_unit_assert=>assert_true( server->supports_tools( ) ).
    cl_abap_unit_assert=>assert_true( server->supports_resources( ) ).
    cl_abap_unit_assert=>assert_true( server->supports_prompts( ) ).
    cl_abap_unit_assert=>assert_true( server->supports_completions( ) ).
    " This server deliberately does not advertise tasks - see ZCL_MCP2_DEMO_WF.
    cl_abap_unit_assert=>assert_false( server->supports_tasks( ) ).

    " Discovery is shape, not user data: long TTL, shareable.
    DATA(cache) = server->get_discover_cache( ).
    cl_abap_unit_assert=>assert_equals( exp = 3600000
                                        act = cache-ttl_ms ).
    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>cache_scopes-public
                                        act = cache-cache_scope ).
  ENDMETHOD.

  METHOD test_tools_list.
    DATA server TYPE REF TO zif_mcp2_server.

    server = NEW zcl_mcp2_demo_basic( ).

    DATA response TYPE REF TO zif_mcp2_result.
    response = server->tools_list( NEW zcl_mcp2_req_list_tools( zcl_mcp2_ajson=>create_empty( ) ) ).

    DATA parsed TYPE REF TO zif_mcp2_ajson.
    parsed = zcl_mcp2_ajson=>parse( response->to_json( )->stringify( ) ).

    cl_abap_unit_assert=>assert_equals( exp = `echo`
                                        act = parsed->get_string( '/tools/1/name' ) ).
    cl_abap_unit_assert=>assert_equals(
        exp = `Message`
        act = parsed->get_string( '/tools/1/inputSchema/properties/message/x-mcp-header' ) ).
    " The catalog order is the order of the define_tools entries and is part
    " of what clients cache, so it is pinned here.
    cl_abap_unit_assert=>assert_equals( exp = `price_quote`
                                        act = parsed->get_string( '/tools/3/name' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `request_info`
                                        act = parsed->get_string( '/tools/5/name' ) ).
  ENDMETHOD.

  METHOD test_request_info_legacy.
    DATA server TYPE REF TO zif_mcp2_server.
    server = NEW zcl_mcp2_demo_basic( ).

    DATA ctx TYPE zif_mcp2_server=>context.
    ctx-era = zif_mcp2_const=>eras-legacy.
    ctx-protocol_ver = zif_mcp2_const=>protocol-v2025_11_25.
    ctx-client-name = `Legacy Unit`.
    ctx-task_requested = abap_true.
    server->set_context( ctx ).

    DATA params TYPE REF TO zif_mcp2_ajson.
    params = zcl_mcp2_ajson=>parse( `{"name":"request_info","arguments":{}}` ).
    DATA response TYPE REF TO zif_mcp2_result.
    response = server->tools_call( NEW zcl_mcp2_req_call_tool( params ) ).
    DATA parsed TYPE REF TO zif_mcp2_ajson.
    parsed = zcl_mcp2_ajson=>parse( response->to_json( )->stringify( ) ).

    cl_abap_unit_assert=>assert_equals( exp = `legacy`
                                        act = parsed->get_string( '/structuredContent/era' ) ).
    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>protocol-v2025_11_25
                                        act = parsed->get_string( '/structuredContent/protocol_version' ) ).
    " The legacy client opted in per call, so it would accept a task result...
    cl_abap_unit_assert=>assert_true(
        parsed->get_boolean( '/structuredContent/client_accepts_task_results' ) ).
    " ...but this server does not advertise tasks, so none can be created here.
    " Reporting only the client flag would claim tasks are available.
    cl_abap_unit_assert=>assert_false(
        parsed->get_boolean( '/structuredContent/server_offers_tasks' ) ).
  ENDMETHOD.

  METHOD test_request_info_modern.
    DATA server TYPE REF TO zif_mcp2_server.
    server = NEW zcl_mcp2_demo_basic( ).

    DATA ctx TYPE zif_mcp2_server=>context.
    ctx-era = zif_mcp2_const=>eras-modern.
    ctx-protocol_ver = zif_mcp2_const=>protocol-v2026_07_28.
    ctx-client-name = `Modern Unit`.
    " Modern clients declare the tasks extension in clientCapabilities.
    ctx-client_caps = zcl_mcp2_ajson=>parse(
        `{"extensions":{"io.modelcontextprotocol/tasks":{}}}` ).
    server->set_context( ctx ).

    DATA response TYPE REF TO zif_mcp2_result.
    response = server->tools_call( NEW zcl_mcp2_req_call_tool(
        zcl_mcp2_ajson=>parse( `{"name":"request_info","arguments":{}}` ) ) ).
    DATA parsed TYPE REF TO zif_mcp2_ajson.
    parsed = zcl_mcp2_ajson=>parse( response->to_json( )->stringify( ) ).

    cl_abap_unit_assert=>assert_equals( exp = `modern`
                                        act = parsed->get_string( '/structuredContent/era' ) ).
    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>protocol-v2026_07_28
                                        act = parsed->get_string( '/structuredContent/protocol_version' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `Modern Unit`
                                        act = parsed->get_string( '/structuredContent/client_name' ) ).
    cl_abap_unit_assert=>assert_true(
        parsed->get_boolean( '/structuredContent/client_accepts_task_results' ) ).
    cl_abap_unit_assert=>assert_false(
        parsed->get_boolean( '/structuredContent/server_offers_tasks' ) ).
  ENDMETHOD.

  METHOD test_template_read.
    DATA server TYPE REF TO zif_mcp2_server.
    server = NEW zcl_mcp2_demo_basic( ).
    DATA params TYPE REF TO zif_mcp2_ajson.
    params = zcl_mcp2_ajson=>parse( `{"uri":"mcp2://demo/greeting/Ada"}` ).
    DATA response TYPE REF TO zif_mcp2_result.
    response = server->resources_read( NEW zcl_mcp2_req_read_resource( params ) ).
    DATA parsed TYPE REF TO zif_mcp2_ajson.
    parsed = zcl_mcp2_ajson=>parse( response->to_json( )->stringify( ) ).

    cl_abap_unit_assert=>assert_equals(
        exp = `Hello Ada from an expanded resource template.`
        act = parsed->get_string( '/contents/1/text' ) ).
  ENDMETHOD.

  METHOD test_prompt_and_completion.
    DATA server TYPE REF TO zif_mcp2_server.
    server = NEW zcl_mcp2_demo_basic( ).

    DATA prompt_params TYPE REF TO zif_mcp2_ajson.
    prompt_params = zcl_mcp2_ajson=>parse(
        `{"name":"summarize","arguments":{"topic":"ABAP"}}` ).
    DATA prompt_result TYPE REF TO zif_mcp2_result.
    prompt_result = server->prompts_get( NEW zcl_mcp2_req_get_prompt( prompt_params ) ).
    DATA prompt_json TYPE REF TO zif_mcp2_ajson.
    prompt_json = zcl_mcp2_ajson=>parse( prompt_result->to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals(
        exp = `Summarize ABAP in three bullets.`
        act = prompt_json->get_string( '/messages/1/content/text' ) ).

    " An empty argument value offers every candidate, unmodified.
    DATA(completion_json) = complete(
        `{"ref":{"type":"ref/prompt","name":"summarize"},` &&
        `"argument":{"name":"topic","value":""}}` ).
    cl_abap_unit_assert=>assert_equals(
        exp = `ABAP`
        act = completion_json->get_string( '/completion/values/1' ) ).
    cl_abap_unit_assert=>assert_equals(
        exp = `MCP`
        act = completion_json->get_string( '/completion/values/2' ) ).
    cl_abap_unit_assert=>assert_equals(
        exp = 2
        act = completion_json->get_integer( '/completion/total' ) ).
  ENDMETHOD.

  METHOD test_completion_prefix.
    " A completion returns WHOLE candidate values that start with the typed
    " prefix - never the prefix with a suffix appended. Typing "A" must yield
    " "Ada", not "AAda".
    DATA(json) = complete(
        `{"ref":{"type":"ref/resource","uri":"mcp2://demo/greeting/{name}"},` &&
        `"argument":{"name":"name","value":"A"}}` ).

    cl_abap_unit_assert=>assert_equals( exp = `Ada`
                                        act = json->get_string( '/completion/values/1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `Alan`
                                        act = json->get_string( '/completion/values/2' ) ).
    " Basti does not start with A and must be filtered out.
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = json->get_integer( '/completion/total' ) ).
    cl_abap_unit_assert=>assert_false( json->exists( '/completion/values/3' ) ).
  ENDMETHOD.

  METHOD test_completion_no_match.
    " No candidate starts with Z: return an empty list, not a fabricated value.
    DATA(json) = complete(
        `{"ref":{"type":"ref/resource","uri":"mcp2://demo/greeting/{name}"},` &&
        `"argument":{"name":"name","value":"Z"}}` ).

    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = json->get_integer( '/completion/total' ) ).
    cl_abap_unit_assert=>assert_false( json->exists( '/completion/values/1' ) ).
  ENDMETHOD.

  METHOD test_completion_unrelated_ref.
    " Completions are scoped to a known reference and argument.
    DATA(json) = complete(
        `{"ref":{"type":"ref/prompt","name":"does_not_exist"},` &&
        `"argument":{"name":"topic","value":"A"}}` ).

    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = json->get_integer( '/completion/total' ) ).
    cl_abap_unit_assert=>assert_false( json->exists( '/completion/values/1' ) ).
  ENDMETHOD.

  METHOD test_price_quote.
    " 19.99 x 10 units = 199.90 exactly - the point of decfloat34 over a
    " binary float, which would land on 199.89999...
    DATA(json) = call_tool(
        `{"name":"price_quote","arguments":{"unit_price":19.99,` &&
        `"quantities":[2,3,5],"discount_pct":10,"tags":["rush","eu"]}}` ).

    cl_abap_unit_assert=>assert_equals( exp = 3
                                        act = json->get_integer( '/structuredContent/line_count' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 10
                                        act = json->get_integer( '/structuredContent/units' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = json->get_integer( '/structuredContent/tag_count' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `199.9`
                                        act = json->get( '/structuredContent/gross' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `179.91`
                                        act = json->get( '/structuredContent/net' ) ).
  ENDMETHOD.

  METHOD test_price_quote_default.
    " discount_pct omitted - the handler supplies the fallback, so net = gross.
    DATA(json) = call_tool(
        `{"name":"price_quote","arguments":{"unit_price":5,"quantities":[4]}}` ).

    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = json->get_integer( '/structuredContent/tag_count' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `20`
                                        act = json->get( '/structuredContent/gross' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `20`
                                        act = json->get( '/structuredContent/net' ) ).
  ENDMETHOD.

  METHOD test_price_quote_bad_array.
    " Input validation runs in the dispatcher, not in the server class, so
    " this drives a full JSON-RPC round trip rather than using the call_tool
    " helper. A wrongly typed array element fails the declared integer item
    " type and comes back as an isError tool result, not a JSON-RPC error.
    DATA(dispatcher) = NEW zcl_mcp2_dispatch_legacy( NEW zcl_mcp2_demo_basic( ) ).
    DATA(response) = dispatcher->dispatch( zcl_mcp2_jsonrpc=>parse_request(
        `{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{` &&
        `"name":"price_quote","arguments":{"unit_price":5,"quantities":["two"]}}}` ) ).

    DATA(json) = zcl_mcp2_ajson=>parse( zcl_mcp2_jsonrpc=>serialize_response( response ) ).
    cl_abap_unit_assert=>assert_true( json->get_boolean( '/result/isError' ) ).
  ENDMETHOD.

  METHOD test_price_quote_schema.
    " The catalog advertises titles, the integer item type and the default.
    DATA server TYPE REF TO zif_mcp2_server.
    server = NEW zcl_mcp2_demo_basic( ).
    DATA(parsed) = zcl_mcp2_ajson=>parse( server->tools_list(
        NEW zcl_mcp2_req_list_tools( zcl_mcp2_ajson=>create_empty( ) ) )->to_json( )->stringify( ) ).

    DATA(schema_path) = `/tools/3/inputSchema`.
    cl_abap_unit_assert=>assert_equals( exp = `price_quote`
                                        act = parsed->get_string( '/tools/3/name' ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = `Unit price`
      act = parsed->get_string( |{ schema_path }/properties/unit_price/title| ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = `integer`
      act = parsed->get_string( |{ schema_path }/properties/quantities/items/type| ) ).
    cl_abap_unit_assert=>assert_true(
      parsed->exists( |{ schema_path }/properties/discount_pct/default| ) ).
  ENDMETHOD.

  METHOD test_text_stats.
    " bind_arguments fills the typed structure by field name and
    " structured_data serializes the result back into structuredContent.
    DATA(json) = call_tool(
        `{"name":"text_stats","arguments":{"text":"hello brave new world"}}` ).

    cl_abap_unit_assert=>assert_equals( exp = 21
                                        act = json->get_integer( '/structuredContent/chars' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 4
                                        act = json->get_integer( '/structuredContent/words' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `hello brave new world`
                                        act = json->get_string( '/structuredContent/preview' ) ).
  ENDMETHOD.

  METHOD test_text_stats_upper.
    DATA(json) = call_tool(
        `{"name":"text_stats","arguments":{"text":"abap","uppercase_preview":true}}` ).

    cl_abap_unit_assert=>assert_equals( exp = `ABAP`
                                        act = json->get_string( '/structuredContent/preview' ) ).
  ENDMETHOD.

  METHOD test_ddic_schema_ok.
    DATA(json) = call_tool(
        `{"name":"ddic_schema","arguments":{"structure_name":"ZMCP2_SERVERS"}}` ).

    cl_abap_unit_assert=>assert_false( json->get_boolean( '/isError' ) ).
    cl_abap_unit_assert=>assert_equals(
        exp = `object`
        act = json->get_string( '/structuredContent/type' ) ).
    cl_abap_unit_assert=>assert_true(
        json->exists( '/structuredContent/properties' ) ).
  ENDMETHOD.

  METHOD test_ddic_schema_error.
    " A bad structure name is a tool-level failure the model can react to,
    " not a protocol error: isError, no exception.
    DATA(json) = call_tool(
        `{"name":"ddic_schema","arguments":{"structure_name":"ZZ_DOES_NOT_EXIST"}}` ).

    cl_abap_unit_assert=>assert_true( json->get_boolean( '/isError' ) ).
    cl_abap_unit_assert=>assert_true(
        xsdbool( json->get_string( '/content/1/text' ) CS `ZZ_DOES_NOT_EXIST` ) ).
  ENDMETHOD.

ENDCLASS.
