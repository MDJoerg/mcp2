"! Minimal dispatcher tests that don't require Phase-3 data classes.
"! Full routing tests with mock servers live in Phase 4.
CLASS ltcl_dispatch_legacy DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.

  PUBLIC SECTION.
    METHODS test_unknown_method     FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_ping               FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_logging_removed    FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_init_caps_obj      FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_init_requires_info FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_context_stamped    FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_init_tasks_ext     FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_task_needs_opt_in  FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_task_opt_in_ok     FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_init_identity      FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_input_invalid      FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_input_valid_ok     FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_resource_ir_bad    FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_tasks_list_dispatch  FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_tasks_get_dispatch   FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_tasks_result_dispatch FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_tools_call_ir_reject FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_prompts_get_ir_reject FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_caps_all_flags      FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_init_clientinfo_type FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_init_caps_type      FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.

  PRIVATE SECTION.
    DATA server     TYPE REF TO zif_mcp2_server.
    DATA dispatcher TYPE REF TO zcl_mcp2_dispatch_legacy.

    METHODS setup.

ENDCLASS.

"! Minimal concrete server just for dispatcher tests.
CLASS ltcl_test_server DEFINITION FINAL CREATE PUBLIC
  INHERITING FROM zcl_mcp2_server_base.

  PUBLIC SECTION.
    METHODS zif_mcp2_server~get_name       REDEFINITION.
    METHODS zif_mcp2_server~get_version    REDEFINITION.
    METHODS zif_mcp2_server~supports_tools REDEFINITION.
ENDCLASS.

CLASS ltcl_test_server IMPLEMENTATION.
  METHOD zif_mcp2_server~get_name.
    result = `TestServer`.
  ENDMETHOD.

  METHOD zif_mcp2_server~get_version.
    result = `1.0`.
  ENDMETHOD.

  METHOD zif_mcp2_server~supports_tools.
    result = abap_true.
  ENDMETHOD.
ENDCLASS.

"! Server with identity overrides for the initialize serverInfo shape.
CLASS ltcl_ident_server DEFINITION FINAL CREATE PUBLIC
  INHERITING FROM zcl_mcp2_server_base.

  PUBLIC SECTION.
    METHODS zif_mcp2_server~get_name        REDEFINITION.
    METHODS zif_mcp2_server~get_version     REDEFINITION.
    METHODS zif_mcp2_server~get_title       REDEFINITION.
    METHODS zif_mcp2_server~get_website_url REDEFINITION.
    METHODS zif_mcp2_server~get_icons       REDEFINITION.
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

  METHOD zif_mcp2_server~get_website_url.
    result = `https://example.com/ident`.
  ENDMETHOD.

  METHOD zif_mcp2_server~get_icons.
    result = VALUE #( ( src = `https://example.com/ident.png` ) ).
  ENDMETHOD.
ENDCLASS.

"! Server advertising the tasks extension for capability tests. Its tools/call
"! always answers with a create-task result (no DB) so the dispatcher's
"! params.task opt-in gate can be exercised.
CLASS ltcl_task_server DEFINITION FINAL CREATE PUBLIC
  INHERITING FROM zcl_mcp2_server_base.

  PUBLIC SECTION.
    METHODS zif_mcp2_server~get_name       REDEFINITION.
    METHODS zif_mcp2_server~get_version    REDEFINITION.
    METHODS zif_mcp2_server~supports_tasks REDEFINITION.
    METHODS zif_mcp2_server~supports_tools REDEFINITION.
    METHODS zif_mcp2_server~tools_call     REDEFINITION.
    " Stub the tasks_* interface methods directly so dispatch-level routing
    " can be tested without going through zcl_mcp2_server_base's DB-backed
    " defaults (there is no DB test double in this codebase - see
    " zcl_mcp2_ddic_75's test file for the same constraint on FM calls).
    METHODS zif_mcp2_server~tasks_list     REDEFINITION.
    METHODS zif_mcp2_server~tasks_get      REDEFINITION.
    METHODS zif_mcp2_server~tasks_result   REDEFINITION.
    METHODS zif_mcp2_server~tasks_cancel   REDEFINITION.
ENDCLASS.

CLASS ltcl_task_server IMPLEMENTATION.
  METHOD zif_mcp2_server~get_name.
    result = `TaskServer`.
  ENDMETHOD.

  METHOD zif_mcp2_server~get_version.
    result = `1.0`.
  ENDMETHOD.

  METHOD zif_mcp2_server~supports_tasks.
    result = abap_true.
  ENDMETHOD.

  METHOD zif_mcp2_server~supports_tools.
    result = abap_true.
  ENDMETHOD.

  METHOD zif_mcp2_server~tools_call.
    DATA(task) = NEW zcl_mcp2_resp_create_task_lgcy( ).
    task->set_task( task_id = `AAAABBBBCCCCDDDDEEEEFFFF00001111`
                    status  = `working`
                    poll_ms = 500 ).
    result = task.
  ENDMETHOD.

  METHOD zif_mcp2_server~tasks_list.
    result = zcl_mcp2_resp_call_tool=>text( `stub-list` ).
  ENDMETHOD.

  METHOD zif_mcp2_server~tasks_get.
    result = zcl_mcp2_resp_call_tool=>text( `stub-get` ).
  ENDMETHOD.

  METHOD zif_mcp2_server~tasks_result.
    result = zcl_mcp2_resp_call_tool=>text( `stub-result` ).
  ENDMETHOD.

  METHOD zif_mcp2_server~tasks_cancel.
    result = zcl_mcp2_resp_call_tool=>text( `stub-cancel` ).
  ENDMETHOD.
ENDCLASS.


"! Server with opt-in tools/call input validation.
CLASS ltcl_vld_input_server DEFINITION FINAL CREATE PUBLIC
  INHERITING FROM zcl_mcp2_server_base.

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


"! Server returning input_required from resources/read for legacy guard tests.
CLASS ltcl_ir_resource_server DEFINITION FINAL CREATE PUBLIC
  INHERITING FROM zcl_mcp2_server_base.

  PUBLIC SECTION.
    METHODS zif_mcp2_server~get_name           REDEFINITION.
    METHODS zif_mcp2_server~get_version        REDEFINITION.
    METHODS zif_mcp2_server~supports_resources REDEFINITION.
    METHODS zif_mcp2_server~resources_read     REDEFINITION.
ENDCLASS.

CLASS ltcl_ir_resource_server IMPLEMENTATION.
  METHOD zif_mcp2_server~get_name.
    result = `IRResourceServer`.
  ENDMETHOD.

  METHOD zif_mcp2_server~get_version.
    result = `1.0`.
  ENDMETHOD.

  METHOD zif_mcp2_server~supports_resources.
    result = abap_true.
  ENDMETHOD.

  METHOD zif_mcp2_server~resources_read.
    DATA ir TYPE REF TO zcl_mcp2_resp_input_req.
    ir = NEW zcl_mcp2_resp_input_req( ).
    ir->set_request_state( `resource-state` ).
    result = ir.
  ENDMETHOD.
ENDCLASS.


"! Server returning input_required from tools/call for legacy guard tests.
CLASS ltcl_ir_tools_server DEFINITION FINAL CREATE PUBLIC
  INHERITING FROM zcl_mcp2_server_base.

  PUBLIC SECTION.
    METHODS zif_mcp2_server~get_name       REDEFINITION.
    METHODS zif_mcp2_server~get_version    REDEFINITION.
    METHODS zif_mcp2_server~supports_tools REDEFINITION.
    METHODS zif_mcp2_server~tools_call     REDEFINITION.
ENDCLASS.

CLASS ltcl_ir_tools_server IMPLEMENTATION.
  METHOD zif_mcp2_server~get_name.
    result = `IRToolsServer`.
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
    ir->set_request_state( `tool-state` ).
    result = ir.
  ENDMETHOD.
ENDCLASS.


"! Server returning input_required from prompts/get for legacy guard tests.
CLASS ltcl_ir_prompts_server DEFINITION FINAL CREATE PUBLIC
  INHERITING FROM zcl_mcp2_server_base.

  PUBLIC SECTION.
    METHODS zif_mcp2_server~get_name         REDEFINITION.
    METHODS zif_mcp2_server~get_version      REDEFINITION.
    METHODS zif_mcp2_server~supports_prompts REDEFINITION.
    METHODS zif_mcp2_server~prompts_get      REDEFINITION.
ENDCLASS.

CLASS ltcl_ir_prompts_server IMPLEMENTATION.
  METHOD zif_mcp2_server~get_name.
    result = `IRPromptsServer`.
  ENDMETHOD.

  METHOD zif_mcp2_server~get_version.
    result = `1.0`.
  ENDMETHOD.

  METHOD zif_mcp2_server~supports_prompts.
    result = abap_true.
  ENDMETHOD.

  METHOD zif_mcp2_server~prompts_get.
    DATA ir TYPE REF TO zcl_mcp2_resp_input_req.
    ir = NEW zcl_mcp2_resp_input_req( ).
    ir->set_request_state( `prompt-state` ).
    result = ir.
  ENDMETHOD.
ENDCLASS.


"! Server advertising resources/prompts/completions for build_capabilities tests.
CLASS ltcl_full_caps_server DEFINITION FINAL CREATE PUBLIC
  INHERITING FROM zcl_mcp2_server_base.

  PUBLIC SECTION.
    METHODS zif_mcp2_server~get_name             REDEFINITION.
    METHODS zif_mcp2_server~get_version          REDEFINITION.
    METHODS zif_mcp2_server~supports_resources   REDEFINITION.
    METHODS zif_mcp2_server~supports_prompts     REDEFINITION.
    METHODS zif_mcp2_server~supports_completions REDEFINITION.
ENDCLASS.

CLASS ltcl_full_caps_server IMPLEMENTATION.
  METHOD zif_mcp2_server~get_name.
    result = `FullCapsServer`.
  ENDMETHOD.

  METHOD zif_mcp2_server~get_version.
    result = `1.0`.
  ENDMETHOD.

  METHOD zif_mcp2_server~supports_resources.
    result = abap_true.
  ENDMETHOD.

  METHOD zif_mcp2_server~supports_prompts.
    result = abap_true.
  ENDMETHOD.

  METHOD zif_mcp2_server~supports_completions.
    result = abap_true.
  ENDMETHOD.
ENDCLASS.


CLASS ltcl_dispatch_legacy IMPLEMENTATION.
  METHOD setup.
    server     = NEW ltcl_test_server( ).
    dispatcher = NEW zcl_mcp2_dispatch_legacy( server ).
  ENDMETHOD.

  METHOD test_ping.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.

    req-jsonrpc    = `2.0`.
    req-method     = zif_mcp2_const=>methods-ping.
    req-id         = `1`.
    req-id_present = abap_true.
    req-params     = zcl_mcp2_ajson=>create_empty( ).

    DATA(resp) = dispatcher->dispatch( req ).

    cl_abap_unit_assert=>assert_initial( resp-error-code ).
    cl_abap_unit_assert=>assert_equals( exp = `1`
                                        act = resp-id ).
  ENDMETHOD.

  METHOD test_unknown_method.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.

    req-jsonrpc    = `2.0`.
    req-method     = `no/such/method`.
    req-id         = `1`.
    req-id_present = abap_true.
    req-params     = zcl_mcp2_ajson=>create_empty( ).

    DATA(resp) = dispatcher->dispatch( req ).

    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-method_not_found
                                        act = resp-error-code ).
  ENDMETHOD.

  METHOD test_logging_removed.
    " The Logging feature is deprecated (SEP-2577) and the stateless runtime
    " can never deliver notifications/message - setLevel is not served.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.

    req-jsonrpc    = `2.0`.
    req-method     = zif_mcp2_const=>methods-logging_set_level.
    req-id         = `1`.
    req-id_present = abap_true.
    req-params     = zcl_mcp2_ajson=>parse( `{"level":"info"}` ).

    DATA(resp) = dispatcher->dispatch( req ).

    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-method_not_found
                                        act = resp-error-code ).
  ENDMETHOD.

  METHOD test_context_stamped.
    " Every legacy request - not just initialize - must run with era and
    " baseline protocol version populated in the server context.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.

    req-jsonrpc    = `2.0`.
    req-method     = zif_mcp2_const=>methods-ping.
    req-id         = `1`.
    req-id_present = abap_true.
    req-params     = zcl_mcp2_ajson=>create_empty( ).

    dispatcher->dispatch( req ).

    DATA(ctx) = server->get_context( ).
    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>eras-legacy
                                        act = ctx-era ).
    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>protocol-latest_legacy
                                        act = ctx-protocol_ver ).
  ENDMETHOD.

  METHOD test_init_tasks_ext.
    " A server with supports_tasks must advertise the 2025-11-25 tasks
    " capability shape (tasks.{list,cancel,requests.tools.call}) in the legacy
    " initialize capabilities - never the draft's capabilities.extensions key.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.

    req-jsonrpc    = `2.0`.
    req-method     = zif_mcp2_const=>methods-initialize.
    req-id         = `1`.
    req-id_present = abap_true.
    req-params     = zcl_mcp2_ajson=>parse(
                         `{"protocolVersion":"2025-11-25","clientInfo":{"name":"Unit","version":"1"},"capabilities":{}}` ).

    DATA(task_dispatcher) = NEW zcl_mcp2_dispatch_legacy( NEW ltcl_task_server( ) ).
    DATA(resp) = task_dispatcher->dispatch( req ).
    DATA(result_json) = zcl_mcp2_ajson=>parse( zcl_mcp2_jsonrpc=>serialize_response( resp ) ).

    cl_abap_unit_assert=>assert_initial( resp-error-code ).
    cl_abap_unit_assert=>assert_equals(
        exp = zif_mcp2_ajson_types=>node_type-object
        act = result_json->get_node_type( '/result/capabilities/tasks/list' ) ).
    cl_abap_unit_assert=>assert_equals(
        exp = zif_mcp2_ajson_types=>node_type-object
        act = result_json->get_node_type( '/result/capabilities/tasks/cancel' ) ).
    cl_abap_unit_assert=>assert_equals(
        exp = zif_mcp2_ajson_types=>node_type-object
        act = result_json->get_node_type( '/result/capabilities/tasks/requests/tools/call' ) ).
    cl_abap_unit_assert=>assert_false(
        result_json->exists( '/result/capabilities/extensions' ) ).
  ENDMETHOD.

  METHOD test_task_needs_opt_in.
    " 2025-11-25: a CreateTaskResult may only answer a task-augmented request.
    " Without params.task the dispatcher must reject with -32600.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.

    req-jsonrpc    = `2.0`.
    req-method     = zif_mcp2_const=>methods-tools_call.
    req-id         = `1`.
    req-id_present = abap_true.
    req-params     = zcl_mcp2_ajson=>parse( `{"name":"long_running"}` ).

    DATA(task_dispatcher) = NEW zcl_mcp2_dispatch_legacy( NEW ltcl_task_server( ) ).
    DATA(resp) = task_dispatcher->dispatch( req ).

    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-invalid_request
                                        act = resp-error-code ).
  ENDMETHOD.

  METHOD test_task_opt_in_ok.
    " With params.task the create-task result passes through, and the
    " opt-in is visible to handlers via client_supports_tasks( ).
    DATA req TYPE zcl_mcp2_jsonrpc=>request.

    req-jsonrpc    = `2.0`.
    req-method     = zif_mcp2_const=>methods-tools_call.
    req-id         = `1`.
    req-id_present = abap_true.
    req-params     = zcl_mcp2_ajson=>parse( `{"name":"long_running","task":{"ttl":60000}}` ).

    DATA(task_server)     = NEW ltcl_task_server( ).
    DATA(task_dispatcher) = NEW zcl_mcp2_dispatch_legacy( task_server ).
    DATA(resp) = task_dispatcher->dispatch( req ).

    cl_abap_unit_assert=>assert_initial( resp-error-code ).
    DATA(result_json) = zcl_mcp2_ajson=>parse( zcl_mcp2_jsonrpc=>serialize_response( resp ) ).
    cl_abap_unit_assert=>assert_equals( exp = `AAAABBBBCCCCDDDDEEEEFFFF00001111`
                                        act = result_json->get_string( '/result/task/taskId' ) ).
    cl_abap_unit_assert=>assert_true( task_server->client_supports_tasks( ) ).
  ENDMETHOD.

  METHOD test_init_identity.
    " Optional serverInfo fields (title / websiteUrl / icons) surface in initialize.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.

    req-jsonrpc    = `2.0`.
    req-method     = zif_mcp2_const=>methods-initialize.
    req-id         = `1`.
    req-id_present = abap_true.
    req-params     = zcl_mcp2_ajson=>parse(
                         `{"protocolVersion":"2025-11-25","clientInfo":{"name":"Unit","version":"1"},"capabilities":{}}` ).

    DATA(ident_dispatcher) = NEW zcl_mcp2_dispatch_legacy( NEW ltcl_ident_server( ) ).
    DATA(resp) = ident_dispatcher->dispatch( req ).
    DATA(result_json) = zcl_mcp2_ajson=>parse( zcl_mcp2_jsonrpc=>serialize_response( resp ) ).

    cl_abap_unit_assert=>assert_initial( resp-error-code ).
    cl_abap_unit_assert=>assert_equals( exp = `Ident Server`
                                        act = result_json->get_string( '/result/serverInfo/title' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `https://example.com/ident`
                                        act = result_json->get_string( '/result/serverInfo/websiteUrl' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `https://example.com/ident.png`
                                        act = result_json->get_string( '/result/serverInfo/icons/1/src' ) ).
    cl_abap_unit_assert=>assert_false( result_json->exists( '/result/serverInfo/description' ) ).
  ENDMETHOD.

  METHOD test_input_invalid.
    " Advertised-schema violations are tool execution errors, not JSON-RPC
    " request errors, in every supported protocol era.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.

    req-jsonrpc    = `2.0`.
    req-method     = zif_mcp2_const=>methods-tools_call.
    req-id         = `1`.
    req-id_present = abap_true.
    req-params     = zcl_mcp2_ajson=>parse( `{"name":"tool","arguments":{}}` ).

    DATA(vld_dispatcher) = NEW zcl_mcp2_dispatch_legacy( NEW ltcl_vld_input_server( ) ).
    DATA(resp) = vld_dispatcher->dispatch( req ).

    cl_abap_unit_assert=>assert_initial( resp-error-code ).
    DATA(result_json) = zcl_mcp2_ajson=>parse(
      zcl_mcp2_jsonrpc=>serialize_response( resp ) ).
    cl_abap_unit_assert=>assert_true(
      result_json->get_boolean( '/result/isError' ) ).
    cl_abap_unit_assert=>assert_char_cp(
      act = result_json->get_string( '/result/content/1/text' )
      exp = `*Invalid tool input*` ).
  ENDMETHOD.

  METHOD test_input_valid_ok.
    " validate_tool_input on + schema-conformant arguments --> handler runs.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.

    req-jsonrpc    = `2.0`.
    req-method     = zif_mcp2_const=>methods-tools_call.
    req-id         = `1`.
    req-id_present = abap_true.
    req-params     = zcl_mcp2_ajson=>parse( `{"name":"tool","arguments":{"msg":"hello"}}` ).

    DATA(vld_dispatcher) = NEW zcl_mcp2_dispatch_legacy( NEW ltcl_vld_input_server( ) ).
    DATA(resp) = vld_dispatcher->dispatch( req ).

    cl_abap_unit_assert=>assert_initial( resp-error-code ).
  ENDMETHOD.

  METHOD test_resource_ir_bad.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.

    req-jsonrpc    = `2.0`.
    req-method     = zif_mcp2_const=>methods-resources_read.
    req-id         = `1`.
    req-id_present = abap_true.
    req-params     = zcl_mcp2_ajson=>parse( `{"uri":"mcp2://test/input"}` ).

    DATA(ir_dispatcher) = NEW zcl_mcp2_dispatch_legacy( NEW ltcl_ir_resource_server( ) ).
    DATA(resp) = ir_dispatcher->dispatch( req ).

    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-invalid_request
                                        act = resp-error-code ).
  ENDMETHOD.

  METHOD test_init_caps_obj.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.

    req-jsonrpc    = `2.0`.
    req-method     = zif_mcp2_const=>methods-initialize.
    req-id         = `1`.
    req-id_present = abap_true.
    req-params     = zcl_mcp2_ajson=>parse(
                         `{"protocolVersion":"2025-11-25","clientInfo":{"name":"Unit","version":"1"},"capabilities":{}}` ).

    DATA(resp) = dispatcher->dispatch( req ).
    DATA(result_json) = zcl_mcp2_ajson=>parse( zcl_mcp2_jsonrpc=>serialize_response( resp ) ).

    cl_abap_unit_assert=>assert_initial( resp-error-code ).
    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_ajson_types=>node_type-object
                                        act = result_json->get_node_type( '/result/capabilities/tools' ) ).
  ENDMETHOD.

  METHOD test_init_requires_info.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.

    req-jsonrpc    = `2.0`.
    req-method     = zif_mcp2_const=>methods-initialize.
    req-id         = `1`.
    req-id_present = abap_true.
    req-params     = zcl_mcp2_ajson=>parse( `{"protocolVersion":"2025-11-25","capabilities":{}}` ).

    DATA(resp) = dispatcher->dispatch( req ).

    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-invalid_params
                                        act = resp-error-code ).
  ENDMETHOD.

  METHOD test_tasks_list_dispatch.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.
    req-jsonrpc    = `2.0`.
    req-method     = zif_mcp2_const=>methods-tasks_list.
    req-id         = `1`.
    req-id_present = abap_true.
    req-params     = zcl_mcp2_ajson=>parse( `{}` ).

    DATA(task_dispatcher) = NEW zcl_mcp2_dispatch_legacy( NEW ltcl_task_server( ) ).
    DATA(resp) = task_dispatcher->dispatch( req ).

    cl_abap_unit_assert=>assert_initial( resp-error-code ).
    DATA(result_json) = zcl_mcp2_ajson=>parse( zcl_mcp2_jsonrpc=>serialize_response( resp ) ).
    cl_abap_unit_assert=>assert_equals( exp = `stub-list`
                                        act = result_json->get_string( '/result/content/1/text' ) ).
  ENDMETHOD.

  METHOD test_tasks_get_dispatch.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.
    req-jsonrpc    = `2.0`.
    req-method     = zif_mcp2_const=>methods-tasks_get.
    req-id         = `1`.
    req-id_present = abap_true.
    req-params     = zcl_mcp2_ajson=>parse( `{"taskId":"AABBCCDDEEFF00112233445566778899"}` ).

    DATA(task_dispatcher) = NEW zcl_mcp2_dispatch_legacy( NEW ltcl_task_server( ) ).
    DATA(resp) = task_dispatcher->dispatch( req ).

    cl_abap_unit_assert=>assert_initial( resp-error-code ).
    DATA(result_json) = zcl_mcp2_ajson=>parse( zcl_mcp2_jsonrpc=>serialize_response( resp ) ).
    cl_abap_unit_assert=>assert_equals( exp = `stub-get`
                                        act = result_json->get_string( '/result/content/1/text' ) ).
  ENDMETHOD.

  METHOD test_tasks_result_dispatch.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.
    req-jsonrpc    = `2.0`.
    req-method     = zif_mcp2_const=>methods-tasks_result.
    req-id         = `1`.
    req-id_present = abap_true.
    req-params     = zcl_mcp2_ajson=>parse( `{"taskId":"AABBCCDDEEFF00112233445566778899"}` ).

    DATA(task_dispatcher) = NEW zcl_mcp2_dispatch_legacy( NEW ltcl_task_server( ) ).
    DATA(resp) = task_dispatcher->dispatch( req ).

    cl_abap_unit_assert=>assert_initial( resp-error-code ).
    DATA(result_json) = zcl_mcp2_ajson=>parse( zcl_mcp2_jsonrpc=>serialize_response( resp ) ).
    cl_abap_unit_assert=>assert_equals( exp = `stub-result`
                                        act = result_json->get_string( '/result/content/1/text' ) ).
  ENDMETHOD.

  METHOD test_tools_call_ir_reject.
    " Same guard as resources/read: input_required is unanswerable on the
    " stateless legacy transport.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.
    req-jsonrpc    = `2.0`.
    req-method     = zif_mcp2_const=>methods-tools_call.
    req-id         = `1`.
    req-id_present = abap_true.
    req-params     = zcl_mcp2_ajson=>parse( `{"name":"tool"}` ).

    DATA(ir_dispatcher) = NEW zcl_mcp2_dispatch_legacy( NEW ltcl_ir_tools_server( ) ).
    DATA(resp) = ir_dispatcher->dispatch( req ).

    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-invalid_request
                                        act = resp-error-code ).
  ENDMETHOD.

  METHOD test_prompts_get_ir_reject.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.
    req-jsonrpc    = `2.0`.
    req-method     = zif_mcp2_const=>methods-prompts_get.
    req-id         = `1`.
    req-id_present = abap_true.
    req-params     = zcl_mcp2_ajson=>parse( `{"name":"prompt"}` ).

    DATA(ir_dispatcher) = NEW zcl_mcp2_dispatch_legacy( NEW ltcl_ir_prompts_server( ) ).
    DATA(resp) = ir_dispatcher->dispatch( req ).

    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-invalid_request
                                        act = resp-error-code ).
  ENDMETHOD.

  METHOD test_caps_all_flags.
    " Only tools/tasks are exercised elsewhere - resources/prompts/completions
    " must each add their own capability key too.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.
    req-jsonrpc    = `2.0`.
    req-method     = zif_mcp2_const=>methods-initialize.
    req-id         = `1`.
    req-id_present = abap_true.
    req-params     = zcl_mcp2_ajson=>parse(
                         `{"protocolVersion":"2025-11-25","clientInfo":{"name":"Unit","version":"1"},"capabilities":{}}` ).

    DATA(caps_dispatcher) = NEW zcl_mcp2_dispatch_legacy( NEW ltcl_full_caps_server( ) ).
    DATA(resp) = caps_dispatcher->dispatch( req ).
    DATA(result_json) = zcl_mcp2_ajson=>parse( zcl_mcp2_jsonrpc=>serialize_response( resp ) ).

    cl_abap_unit_assert=>assert_initial( resp-error-code ).
    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_ajson_types=>node_type-object
                                        act = result_json->get_node_type( '/result/capabilities/resources' ) ).
    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_ajson_types=>node_type-object
                                        act = result_json->get_node_type( '/result/capabilities/prompts' ) ).
    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_ajson_types=>node_type-object
                                        act = result_json->get_node_type( '/result/capabilities/completions' ) ).
  ENDMETHOD.

  METHOD test_init_clientinfo_type.
    " clientInfo present but the wrong node type is a distinct branch from
    " clientInfo being absent entirely.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.
    req-jsonrpc    = `2.0`.
    req-method     = zif_mcp2_const=>methods-initialize.
    req-id         = `1`.
    req-id_present = abap_true.
    req-params     = zcl_mcp2_ajson=>parse(
                         `{"protocolVersion":"2025-11-25","clientInfo":"not-an-object","capabilities":{}}` ).

    DATA(resp) = dispatcher->dispatch( req ).

    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-invalid_params
                                        act = resp-error-code ).
  ENDMETHOD.

  METHOD test_init_caps_type.
    " capabilities present but the wrong node type is a distinct branch from
    " capabilities being absent entirely.
    DATA req TYPE zcl_mcp2_jsonrpc=>request.
    req-jsonrpc    = `2.0`.
    req-method     = zif_mcp2_const=>methods-initialize.
    req-id         = `1`.
    req-id_present = abap_true.
    req-params     = zcl_mcp2_ajson=>parse(
                         `{"protocolVersion":"2025-11-25","clientInfo":{"name":"Unit","version":"1"},"capabilities":[]}` ).

    DATA(resp) = dispatcher->dispatch( req ).

    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-invalid_params
                                        act = resp-error-code ).
  ENDMETHOD.
ENDCLASS.
