"! Tests for the abstract server base: identity defaults, capability
"! defaults, the method_not_found handler fallbacks, context round-trip
"! and the has_client_cap helper.
CLASS ltcl_server_base DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.

  PUBLIC SECTION.
    METHODS test_default_identity    FOR TESTING.
    METHODS test_default_caps_false  FOR TESTING.
    METHODS test_instructions_empty  FOR TESTING.
    METHODS test_tool_schema_initial FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_handler_not_found   FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_context_roundtrip   FOR TESTING.
    METHODS test_cap_no_context      FOR TESTING.
    METHODS test_cap_present         FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_cap_absent          FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_sampling_modern     FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_sampling_legacy     FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_elicit_form_implicit FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_elicit_url_declared FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_elicit_both_modes   FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_can_req_form_input   FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_can_req_url_input    FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_can_req_sampling     FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_input_required_build FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_protocol_version    FOR TESTING.

    METHODS test_task_result_modern  FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_task_result_legacy  FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_tasks_cap_modern    FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_tasks_cap_legacy    FOR TESTING.
    METHODS test_ttl_clamp           FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_meta_helpers        FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_meta_unbound        FOR TESTING.
    METHODS test_discover_cache_dflt FOR TESTING.
    METHODS test_start_task_neg_poll FOR TESTING.
    METHODS test_task_area_default   FOR TESTING.
    METHODS test_tasks_cap_no_context FOR TESTING.
    METHODS test_meta_multi_slash    FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_auth_default_allows FOR TESTING.
    METHODS test_auth_can_deny       FOR TESTING.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_mcp2_server_base.

    METHODS setup.

    METHODS sample_task_row
      RETURNING VALUE(result) TYPE zcl_mcp2_tasks=>task_row.
ENDCLASS.

"! Subclass that denies one area/server pair, to prove check_authorization
"! is redefinable and receives the routed area and server.
CLASS ltcl_guarded_server DEFINITION FINAL CREATE PUBLIC
  INHERITING FROM zcl_mcp2_server_base.

  PUBLIC SECTION.
    METHODS zif_mcp2_server~get_name            REDEFINITION.
    METHODS zif_mcp2_server~get_version         REDEFINITION.
    METHODS zif_mcp2_server~check_authorization REDEFINITION.
ENDCLASS.

CLASS ltcl_guarded_server IMPLEMENTATION.
  METHOD zif_mcp2_server~get_name.
    result = `guarded`.
  ENDMETHOD.
  METHOD zif_mcp2_server~get_version.
    result = `1.0.0`.
  ENDMETHOD.
  METHOD zif_mcp2_server~check_authorization.
    " Stands in for an AUTHORITY-CHECK in a real server.
    result = xsdbool( area = `OPEN` ).
  ENDMETHOD.
ENDCLASS.

"! Minimal concrete subclass that overrides nothing beyond what CREATE needs,
"! so the base-class defaults are what the tests observe. Exposes the
"! protected build_task_result for shape tests (no DB involved).
CLASS ltcl_base_server DEFINITION FINAL CREATE PUBLIC
  INHERITING FROM zcl_mcp2_server_base.

  PUBLIC SECTION.
    METHODS zif_mcp2_server~get_name    REDEFINITION.
    METHODS zif_mcp2_server~get_version REDEFINITION.

    METHODS probe_task_result
      IMPORTING !row          TYPE zcl_mcp2_tasks=>task_row
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_result
      RAISING   zcx_mcp2_error.

    METHODS probe_can_request_input
      IMPORTING input         TYPE REF TO zif_mcp2_input_request
      RETURNING VALUE(result) TYPE abap_bool
      RAISING   zcx_mcp2_ajson_error.

    METHODS probe_input_required
      IMPORTING request_key          TYPE string
                input                TYPE REF TO zif_mcp2_input_request
                request_state        TYPE string OPTIONAL
      RETURNING VALUE(result)        TYPE REF TO zcl_mcp2_resp_input_req
      RAISING   zcx_mcp2_error
                zcx_mcp2_ajson_error.

    METHODS probe_start_task
      IMPORTING poll_ms       TYPE i DEFAULT 5000
      RAISING   zcx_mcp2_error.
ENDCLASS.

CLASS ltcl_base_server IMPLEMENTATION.
  METHOD zif_mcp2_server~get_name.
    result = `base-test-server`.
  ENDMETHOD.

  METHOD zif_mcp2_server~get_version.
    result = `1.0`.
  ENDMETHOD.

  METHOD probe_task_result.
    result = build_task_result( row ).
  ENDMETHOD.

  METHOD probe_can_request_input.
    result = can_request_input( input ).
  ENDMETHOD.

  METHOD probe_input_required.
    result = input_required( request_key   = request_key
                             input         = input
                             request_state = request_state ).
  ENDMETHOD.

  METHOD probe_start_task.
    " poll_ms is validated before get_tasks() ever touches the DB, so this
    " is reachable without a live task store as long as poll_ms is negative.
    start_task( poll_ms = poll_ms ).
  ENDMETHOD.
ENDCLASS.


CLASS ltcl_server_base IMPLEMENTATION.
  METHOD setup.
    cut = NEW ltcl_base_server( ).
  ENDMETHOD.

  METHOD test_default_identity.
    " get_name / get_version are abstract - the subclass values must surface.
    cl_abap_unit_assert=>assert_equals( exp = `base-test-server`
                                        act = cut->zif_mcp2_server~get_name( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `1.0`
                                        act = cut->zif_mcp2_server~get_version( ) ).
  ENDMETHOD.

  METHOD test_default_caps_false.
    cl_abap_unit_assert=>assert_false( cut->zif_mcp2_server~supports_tools( ) ).
    cl_abap_unit_assert=>assert_false( cut->zif_mcp2_server~supports_resources( ) ).
    cl_abap_unit_assert=>assert_false( cut->zif_mcp2_server~supports_prompts( ) ).
    cl_abap_unit_assert=>assert_false( cut->zif_mcp2_server~supports_completions( ) ).
  ENDMETHOD.

  METHOD test_instructions_empty.
    cl_abap_unit_assert=>assert_initial( cut->zif_mcp2_server~get_instructions( ) ).
    cl_abap_unit_assert=>assert_initial( cut->zif_mcp2_server~get_icons( ) ).
  ENDMETHOD.

  METHOD test_tool_schema_initial.
    cl_abap_unit_assert=>assert_not_bound( cut->zif_mcp2_server~get_tool_schema( `any` ) ).
  ENDMETHOD.

  METHOD test_handler_not_found.
    " A handler that is not overridden must raise method_not_found.
    DATA request TYPE REF TO zcl_mcp2_req_list_tools.

    request = NEW #( zcl_mcp2_ajson=>create_empty( ) ).

    TRY.
        cut->zif_mcp2_server~tools_list( request ).
        cl_abap_unit_assert=>fail( 'Expected method_not_found' ).
      CATCH zcx_mcp2_error INTO DATA(error).
        cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-method_not_found
                                            act = error->code ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_context_roundtrip.
    DATA ctx TYPE zif_mcp2_server=>context.

    ctx-protocol_ver = zif_mcp2_const=>protocol-v2026_07_28.

    cut->zif_mcp2_server~set_context( ctx ).

    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>protocol-v2026_07_28
                                        act = cut->zif_mcp2_server~get_context( )-protocol_ver ).
  ENDMETHOD.

  METHOD test_cap_no_context.
    " No context set -> client_caps unbound -> capability reported absent.
    cl_abap_unit_assert=>assert_false( cut->has_client_cap( `sampling` ) ).
  ENDMETHOD.

  METHOD test_cap_present.
    DATA ctx TYPE zif_mcp2_server=>context.

    ctx-client_caps = zcl_mcp2_ajson=>parse( `{"sampling":{}}` ).
    cut->zif_mcp2_server~set_context( ctx ).

    cl_abap_unit_assert=>assert_true( cut->has_client_cap( `sampling` ) ).
  ENDMETHOD.

  METHOD test_cap_absent.
    DATA ctx TYPE zif_mcp2_server=>context.

    ctx-client_caps = zcl_mcp2_ajson=>parse( `{"sampling":{}}` ).
    cut->zif_mcp2_server~set_context( ctx ).

    cl_abap_unit_assert=>assert_false( cut->has_client_cap( `elicitation` ) ).
  ENDMETHOD.

  METHOD test_sampling_modern.
    DATA ctx TYPE zif_mcp2_server=>context.

    ctx-era         = zif_mcp2_const=>eras-modern.
    ctx-client_caps = zcl_mcp2_ajson=>parse( `{"sampling":{}}` ).
    cut->zif_mcp2_server~set_context( ctx ).

    cl_abap_unit_assert=>assert_true( cut->client_supports_sampling( ) ).
  ENDMETHOD.

  METHOD test_sampling_legacy.
    " sampling MRTR is modern-only - a legacy client never supports it even if declared.
    DATA ctx TYPE zif_mcp2_server=>context.

    ctx-era         = zif_mcp2_const=>eras-legacy.
    ctx-client_caps = zcl_mcp2_ajson=>parse( `{"sampling":{}}` ).
    cut->zif_mcp2_server~set_context( ctx ).

    cl_abap_unit_assert=>assert_false( cut->client_supports_sampling( ) ).
  ENDMETHOD.

  METHOD test_elicit_form_implicit.
    " A bare elicitation object means form-mode support; URL mode is never implicit.
    DATA ctx TYPE zif_mcp2_server=>context.

    ctx-era         = zif_mcp2_const=>eras-modern.
    ctx-client_caps = zcl_mcp2_ajson=>parse( `{"elicitation":{}}` ).
    cut->zif_mcp2_server~set_context( ctx ).

    cl_abap_unit_assert=>assert_true( cut->client_supports_elicitation( ) ).
    cl_abap_unit_assert=>assert_false( cut->client_supports_elicit_url( ) ).
  ENDMETHOD.

  METHOD test_elicit_url_declared.
    " Declaring only the url mode does not imply form-mode support.
    DATA ctx TYPE zif_mcp2_server=>context.

    ctx-era         = zif_mcp2_const=>eras-modern.
    ctx-client_caps = zcl_mcp2_ajson=>parse( `{"elicitation":{"url":{}}}` ).
    cut->zif_mcp2_server~set_context( ctx ).

    cl_abap_unit_assert=>assert_false( cut->client_supports_elicitation( ) ).
    cl_abap_unit_assert=>assert_true( cut->client_supports_elicit_url( ) ).
  ENDMETHOD.

  METHOD test_elicit_both_modes.
    DATA ctx TYPE zif_mcp2_server=>context.

    ctx-era         = zif_mcp2_const=>eras-modern.
    ctx-client_caps = zcl_mcp2_ajson=>parse( `{"elicitation":{"form":{},"url":{}}}` ).
    cut->zif_mcp2_server~set_context( ctx ).

    cl_abap_unit_assert=>assert_true( cut->client_supports_elicitation( ) ).
    cl_abap_unit_assert=>assert_true( cut->client_supports_elicit_url( ) ).
  ENDMETHOD.

  METHOD test_can_req_form_input.
    DATA ctx TYPE zif_mcp2_server=>context.
    DATA server TYPE REF TO ltcl_base_server.
    DATA input TYPE REF TO zcl_mcp2_input_elicitation.

    server ?= cut.
    ctx-era         = zif_mcp2_const=>eras-modern.
    ctx-client_caps = zcl_mcp2_ajson=>parse( `{"elicitation":{}}` ).
    cut->zif_mcp2_server~set_context( ctx ).
    input = NEW #( ).
    input->set_form( `Confirm?` ).

    cl_abap_unit_assert=>assert_true( server->probe_can_request_input( input ) ).
  ENDMETHOD.

  METHOD test_can_req_url_input.
    DATA ctx TYPE zif_mcp2_server=>context.
    DATA server TYPE REF TO ltcl_base_server.
    DATA input TYPE REF TO zcl_mcp2_input_elicitation.

    server ?= cut.
    ctx-era         = zif_mcp2_const=>eras-modern.
    ctx-client_caps = zcl_mcp2_ajson=>parse( `{"elicitation":{}}` ).
    cut->zif_mcp2_server~set_context( ctx ).
    input = NEW #( ).
    input->set_url( message = `Sign in`
                    url     = `https://example.com` ).

    cl_abap_unit_assert=>assert_false( server->probe_can_request_input( input ) ).

    ctx-client_caps = zcl_mcp2_ajson=>parse( `{"elicitation":{"url":{}}}` ).
    cut->zif_mcp2_server~set_context( ctx ).

    cl_abap_unit_assert=>assert_true( server->probe_can_request_input( input ) ).
  ENDMETHOD.

  METHOD test_can_req_sampling.
    DATA ctx TYPE zif_mcp2_server=>context.
    DATA server TYPE REF TO ltcl_base_server.
    DATA input TYPE REF TO zcl_mcp2_input_sampling.

    server ?= cut.
    ctx-era         = zif_mcp2_const=>eras-modern.
    ctx-client_caps = zcl_mcp2_ajson=>parse( `{"sampling":{}}` ).
    cut->zif_mcp2_server~set_context( ctx ).
    input = NEW #( ).
    input->set_max_tokens( 20 )->add_user_text( `Summarize.` ).

    cl_abap_unit_assert=>assert_true( server->probe_can_request_input( input ) ).

    ctx-era = zif_mcp2_const=>eras-legacy.
    cut->zif_mcp2_server~set_context( ctx ).

    cl_abap_unit_assert=>assert_false( server->probe_can_request_input( input ) ).
  ENDMETHOD.

  METHOD test_input_required_build.
    DATA server TYPE REF TO ltcl_base_server.
    DATA input TYPE REF TO zcl_mcp2_input_elicitation.

    server ?= cut.
    input = NEW #( ).
    input->set_form( `Confirm?` ).

    DATA(response) = server->probe_input_required( request_key   = `confirm`
                                                   input         = input
                                                   request_state = `state-1` ).
    DATA(json) = response->zif_mcp2_result~to_json( ).

    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>result_types-input_required
                                        act = response->zif_mcp2_result~result_type( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `state-1`
                                        act = json->get_string( '/requestState' ) ).
    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>methods-elicitation_create
                                        act = json->get_string( '/inputRequests/confirm/method' ) ).
    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>elicit_modes-form
                                        act = json->get_string( '/inputRequests/confirm/params/mode' ) ).
  ENDMETHOD.

  METHOD test_protocol_version.
    DATA ctx TYPE zif_mcp2_server=>context.

    ctx-protocol_ver = zif_mcp2_const=>protocol-v2026_07_28.
    cut->zif_mcp2_server~set_context( ctx ).

    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>protocol-v2026_07_28
                                        act = cut->get_protocol_version( ) ).
  ENDMETHOD.

  METHOD test_meta_helpers.
    " Keys containing '/' must work without the caller knowing the ajson
    " TAB-escaping convention.
    DATA ctx TYPE zif_mcp2_server=>context.
    ctx-meta = zcl_mcp2_ajson=>parse(
      `{"io.modelcontextprotocol/logLevel":"debug",` &&
      `"traceparent":"00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01",` &&
      `"tracestate":"vendor=x"}` ).
    cut->zif_mcp2_server~set_context( ctx ).

    cl_abap_unit_assert=>assert_equals( exp = `debug`
                                        act = cut->get_log_level( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01`
                                        act = cut->get_traceparent( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `vendor=x`
                                        act = cut->get_tracestate( ) ).
    cl_abap_unit_assert=>assert_initial( cut->get_meta_string( `no/such/key` ) ).
  ENDMETHOD.

  METHOD test_meta_unbound.
    " No context / no _meta -> all helpers return empty, no dump.
    cl_abap_unit_assert=>assert_initial( cut->get_log_level( ) ).
    cl_abap_unit_assert=>assert_initial( cut->get_traceparent( ) ).
    cl_abap_unit_assert=>assert_initial( cut->get_meta_string( `traceparent` ) ).
  ENDMETHOD.

  METHOD test_discover_cache_dflt.
    DATA(hints) = cut->zif_mcp2_server~get_discover_cache( ).
    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = hints-ttl_ms ).
    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>cache_scopes-private
                                        act = hints-cache_scope ).
  ENDMETHOD.

  METHOD sample_task_row.
    result-task_id        = 'AAAABBBBCCCCDDDDEEEEFFFF00001111'.
    result-status         = zif_mcp2_const=>task_statuses-working.
    result-status_message = `queued`.
    result-created_at     = '20260101120000'.
    result-last_updated   = '20260101120000'.
    result-ttl_s          = 60.
    result-poll_ms        = 500.
  ENDMETHOD.

  METHOD test_task_result_modern.
    " Modern era: resultType=task shape with millisecond fields.
    DATA ctx TYPE zif_mcp2_server=>context.
    ctx-era = zif_mcp2_const=>eras-modern.
    cut->zif_mcp2_server~set_context( ctx ).

    DATA(res) = CAST ltcl_base_server( cut )->probe_task_result( sample_task_row( ) ).

    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>result_types-task
                                        act = res->result_type( ) ).
    DATA(json) = res->to_json( ).
    cl_abap_unit_assert=>assert_equals( exp = `AAAABBBBCCCCDDDDEEEEFFFF00001111`
                                        act = json->get_string( '/taskId' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `working`
                                        act = json->get_string( '/status' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `queued`
                                        act = json->get_string( '/statusMessage' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `2026-01-01T12:00:00Z`
                                        act = json->get_string( '/createdAt' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `2026-01-01T12:00:00Z`
                                        act = json->get_string( '/lastUpdatedAt' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 60000
                                        act = json->get_integer( '/ttlMs' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 500
                                        act = json->get_integer( '/pollIntervalMs' ) ).
  ENDMETHOD.

  METHOD test_tasks_cap_modern.
    " Modern era: the tasks extension must be declared in clientCapabilities.
    DATA ctx TYPE zif_mcp2_server=>context.
    ctx-era         = zif_mcp2_const=>eras-modern.
    ctx-client_caps = zcl_mcp2_ajson=>parse(
      `{"extensions":{"io.modelcontextprotocol/tasks":{}}}` ).
    cut->zif_mcp2_server~set_context( ctx ).
    cl_abap_unit_assert=>assert_true( cut->client_supports_tasks( ) ).

    ctx-client_caps = zcl_mcp2_ajson=>parse( `{}` ).
    " The legacy opt-in flag must not leak into the modern check.
    ctx-task_requested = abap_true.
    cut->zif_mcp2_server~set_context( ctx ).
    cl_abap_unit_assert=>assert_false( cut->client_supports_tasks( ) ).
  ENDMETHOD.

  METHOD test_tasks_cap_legacy.
    " Legacy era: the per-request params.task opt-in is the signal.
    DATA ctx TYPE zif_mcp2_server=>context.
    ctx-era            = zif_mcp2_const=>eras-legacy.
    ctx-task_requested = abap_true.
    cut->zif_mcp2_server~set_context( ctx ).
    cl_abap_unit_assert=>assert_true( cut->client_supports_tasks( ) ).

    ctx-task_requested = abap_false.
    cut->zif_mcp2_server~set_context( ctx ).
    cl_abap_unit_assert=>assert_false( cut->client_supports_tasks( ) ).
  ENDMETHOD.

  METHOD test_ttl_clamp.
    " ttl_s beyond ~24.8 days cannot be represented as int4 milliseconds.
    DATA ctx TYPE zif_mcp2_server=>context.
    ctx-era = zif_mcp2_const=>eras-modern.
    cut->zif_mcp2_server~set_context( ctx ).

    DATA(row) = sample_task_row( ).
    row-ttl_s = 3000000.  " > 2147483 s
    TRY.
        CAST ltcl_base_server( cut )->probe_task_result( row ).
        cl_abap_unit_assert=>fail( `Expected an unrepresentable TTL to be rejected` ).
      CATCH zcx_mcp2_error INTO DATA(error).
        cl_abap_unit_assert=>assert_equals(
          exp = zif_mcp2_const=>error_codes-invalid_params
          act = error->code ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_task_result_legacy.
    " Legacy era: nested CreateTaskResult with timestamps, no modern fields.
    DATA ctx TYPE zif_mcp2_server=>context.
    ctx-era = zif_mcp2_const=>eras-legacy.
    cut->zif_mcp2_server~set_context( ctx ).

    DATA(res) = CAST ltcl_base_server( cut )->probe_task_result( sample_task_row( ) ).

    DATA(json) = res->to_json( ).
    cl_abap_unit_assert=>assert_equals( exp = `AAAABBBBCCCCDDDDEEEEFFFF00001111`
                                        act = json->get_string( '/task/taskId' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `working`
                                        act = json->get_string( '/task/status' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `2026-01-01T12:00:00Z`
                                        act = json->get_string( '/task/createdAt' ) ).
    cl_abap_unit_assert=>assert_true( json->exists( '/task/pollInterval' ) ).
    cl_abap_unit_assert=>assert_false( json->exists( '/task/pollIntervalMs' ) ).
  ENDMETHOD.

  METHOD test_start_task_neg_poll.
    " poll_ms is validated before get_tasks() ever touches the DB.
    TRY.
        CAST ltcl_base_server( cut )->probe_start_task( poll_ms = -1 ).
        cl_abap_unit_assert=>fail( `Expected error for negative poll_ms` ) ##NO_TEXT.
      CATCH zcx_mcp2_error INTO DATA(err).
        cl_abap_unit_assert=>assert_equals(
          exp = zif_mcp2_const=>error_codes-invalid_params
          act = err->code ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_task_area_default.
    " get_task_area/get_task_server default to get_name() when not overridden.
    cl_abap_unit_assert=>assert_equals( exp = `base-test-server`
                                        act = cut->get_task_area( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `base-test-server`
                                        act = cut->get_task_server( ) ).
  ENDMETHOD.

  METHOD test_tasks_cap_no_context.
    " Legacy era default (era_is_modern() = false when context was never
    " set), so client_supports_tasks() falls back to the never-set
    " task_requested flag rather than dumping.
    cl_abap_unit_assert=>assert_false( cut->client_supports_tasks( ) ).
  ENDMETHOD.

  METHOD test_meta_multi_slash.
    " A meta key with more than one literal slash must round-trip through
    " the TAB-escaping convention, not just the single-slash happy path.
    DATA ctx TYPE zif_mcp2_server=>context.
    ctx-meta = zcl_mcp2_ajson=>parse(
      `{"io.modelcontextprotocol/foo/bar":"nested-value"}` ).
    cut->zif_mcp2_server~set_context( ctx ).

    cl_abap_unit_assert=>assert_equals(
      exp = `nested-value`
      act = cut->get_meta_string( `io.modelcontextprotocol/foo/bar` ) ).
  ENDMETHOD.

  METHOD test_auth_default_allows.
    " The SDK ships no authorization object: an untouched server grants
    " access and leaves the gate to the ICF node.
    cl_abap_unit_assert=>assert_true( cut->zif_mcp2_server~check_authorization(
        area = `ANY` server = `ANY` ) ).
  ENDMETHOD.

  METHOD test_auth_can_deny.
    DATA guarded TYPE REF TO zif_mcp2_server.
    guarded = NEW ltcl_guarded_server( ).

    cl_abap_unit_assert=>assert_true( guarded->check_authorization(
        area = `OPEN` server = `DEMO` ) ).
    cl_abap_unit_assert=>assert_false( guarded->check_authorization(
        area = `CLOSED` server = `DEMO` ) ).
  ENDMETHOD.

ENDCLASS.
