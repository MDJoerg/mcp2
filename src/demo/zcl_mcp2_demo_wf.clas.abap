"! <p class="shorttext synchronized">MCP2 MRTR workflow demo server</p>
CLASS zcl_mcp2_demo_wf DEFINITION
  PUBLIC
  INHERITING FROM zcl_mcp2_tool_server_base
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS zif_mcp2_server~get_name        REDEFINITION.
    METHODS zif_mcp2_server~get_version     REDEFINITION.
    METHODS zif_mcp2_server~get_instructions REDEFINITION.
    METHODS zif_mcp2_server~supports_tasks  REDEFINITION.

  PROTECTED SECTION.
    METHODS define_tools REDEFINITION.
    METHODS call_tool REDEFINITION.

  PRIVATE SECTION.
    " Shared by define_tools and call_tool so the catalog and the dispatch
    " cannot drift apart.
    CONSTANTS: BEGIN OF tool_names,
                 approval_required TYPE string VALUE `approval_required`,
                 background_report TYPE string VALUE `background_report`,
               END OF tool_names.

    " The input-request key the client answers under; shared by the
    " input_required response and the retry handler.
    CONSTANTS approval_key TYPE string VALUE `approval`.

    " Marks this demo's own requestState payload so the retry can recognize and
    " decode it. Real applications should prefer an opaque correlation id.
    CONSTANTS state_prefix TYPE string VALUE `demo-approval:`.

    "! <p class="shorttext synchronized">Build the input schema for the approval tool</p>
    "! @parameter result               | JSON Schema for the approval tool arguments
    "! @raising   zcx_mcp2_ajson_error | JSON schema build failure
    METHODS build_approval_schema
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Handle the background_report tool</p>
    "! Starts a task when the client can take one, else answers synchronously.
    "! @parameter result | Task result or synchronous text result
    "! @raising   zcx_mcp2_error       | Task creation failure
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    METHODS handle_report
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_result
      RAISING   zcx_mcp2_error
                zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Schedule the demo background report</p>
    METHODS schedule_report
      IMPORTING task_id TYPE sysuuid_c32
      RAISING   zcx_mcp2_error.

    "! <p class="shorttext synchronized">Handle the approval_required tool</p>
    "! First call elicits an approval; the retry evaluates the answer.
    "! @parameter request | Parsed tools/call request (MRTR state)
    "! @parameter result  | input_required, text or isError result
    "! @raising   zcx_mcp2_error       | Protocol or application error
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    METHODS handle_approval
      IMPORTING !request      TYPE REF TO zcl_mcp2_req_call_tool
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_result
      RAISING   zcx_mcp2_error
                zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Recover the summary from requestState</p>
    "! @parameter state  | requestState echoed back by the client
    "! @parameter result | Summary from the first call, or a fallback label
    METHODS summary_from_state
      IMPORTING state         TYPE string
      RETURNING VALUE(result) TYPE string.

ENDCLASS.


CLASS zcl_mcp2_demo_wf IMPLEMENTATION.
  METHOD zif_mcp2_server~get_name.
    result = `mcp2-demo-wf`.
  ENDMETHOD.

  METHOD zif_mcp2_server~get_version.
    result = `1.0.0`.
  ENDMETHOD.

  METHOD zif_mcp2_server~get_instructions.
    result = `Use approval_required to compare legacy synchronous fallback with modern MRTR. ` &&
             `background_report schedules a 15-second job whose progress can be polled.` ##NO_TEXT.
  ENDMETHOD.

  METHOD zif_mcp2_server~supports_tasks.
    result = abap_true.
  ENDMETHOD.

  METHOD define_tools.
    result = VALUE #(
        ( name         = tool_names-approval_required
          title        = `Approval Required`
          description  = `Returns inputRequired first, then completes when inputResponses are echoed back.`
          input_schema = build_approval_schema( ) )
        ( name         = tool_names-background_report
          title        = `Background Report`
          description  = `Schedules a 15-second background job; poll tasks/get to watch progress.`
          " Declare an explicit empty schema even with no arguments: it tells
          " clients "this tool takes nothing" instead of "schema unknown".
          input_schema = NEW zcl_mcp2_schema_builder( )->to_json( )
          task_support = zif_mcp2_const=>task_support-optional ) ) ##NO_TEXT.
  ENDMETHOD.

  METHOD call_tool.
    CASE request->get_name( ).
      WHEN tool_names-background_report.
        result = handle_report( ).
      WHEN tool_names-approval_required.
        result = handle_approval( request ).
    ENDCASE.
  ENDMETHOD.

  METHOD handle_report.
    " client_supports_tasks( ) is era-aware (modern: declared extension,
    " legacy: per-request params.task opt-in); without it the demo answers
    " synchronously instead of tripping the framework gate.
    IF client_supports_tasks( ) = abap_false.
      result = zcl_mcp2_resp_call_tool=>text(
        `Report finished synchronously: all demo rows processed.` ) ##NO_TEXT.
      RETURN.
    ENDIF.

    " start_task persists a working row and builds the era-appropriate result.
    " The demo then hands the ID to a real immediate background job.
    DATA(report_task) = start_task( poll_ms        = 1000
                                    status_message = `report queued` ) ##NO_TEXT.
    result = report_task-result.
    schedule_report( report_task-task_id ).
  ENDMETHOD.

  METHOD schedule_report.
    DATA job_name TYPE btcjob.
    DATA job_count TYPE btcjobcnt.
    job_name = |MCP2_DEMO_{ task_id(8) }|.

    CALL FUNCTION 'JOB_OPEN'
      EXPORTING jobname          = job_name
      IMPORTING jobcount         = job_count
      EXCEPTIONS cant_create_job = 1
                 invalid_job_data = 2
                 jobname_missing = 3
                 OTHERS           = 4.
    IF sy-subrc <> 0.
      zcl_mcp2_tasks=>fail( task_id = task_id
                            message = `Could not create demo background job` ) ##NO_TEXT.
      zcx_mcp2_error=>raise_internal( `Could not create demo background job` ) ##NO_TEXT.
    ENDIF.

    SUBMIT zmcp2_demo_task
      WITH p_task = task_id
      VIA JOB job_name NUMBER job_count
      AND RETURN.
    IF sy-subrc <> 0.
      zcl_mcp2_tasks=>fail( task_id = task_id
                            message = `Could not add demo report to background job` ) ##NO_TEXT.
      zcx_mcp2_error=>raise_internal( `Could not add demo report to background job` ) ##NO_TEXT.
    ENDIF.

    CALL FUNCTION 'JOB_CLOSE'
      EXPORTING jobcount             = job_count
                jobname              = job_name
                strtimmed            = abap_true
      EXCEPTIONS cant_start_immediate = 1
                 invalid_startdate    = 2
                 jobname_missing      = 3
                 job_close_failed     = 4
                 job_nosteps          = 5
                 job_notex            = 6
                 lock_failed          = 7
                 OTHERS               = 8.
    IF sy-subrc <> 0.
      zcl_mcp2_tasks=>fail( task_id = task_id
                            message = `Could not start demo background job` ) ##NO_TEXT.
      zcx_mcp2_error=>raise_internal( `Could not start demo background job` ) ##NO_TEXT.
    ENDIF.
  ENDMETHOD.

  METHOD handle_approval.
    " Handle the continuation after elicitation. requestState is the only thing
    " that survives the round-trip (the server keeps nothing), so the summary
    " the caller supplied on the FIRST call is read back out of it here.
    IF request->is_retry( ) = abap_true AND request->has_input_responses( ) = abap_true.
      DATA(elicit) = request->try_get_input_response( approval_key ).
      IF elicit IS NOT BOUND.
        " The retry answered some other key: a tool-level error the model can
        " react to, not a protocol error.
        result = zcl_mcp2_resp_call_tool=>error_text(
          |Retry carried no answer for the '{ approval_key }' input request.| ) ##NO_TEXT.
      ELSEIF elicit->is_accept( ) = abap_true.
        DATA(approval_reason) = COND string(
          WHEN elicit->has_content( ) = abap_true
          THEN elicit->get_string( `approval_reason` )
          ELSE `` ) ##NO_TEXT.
        result = zcl_mcp2_resp_call_tool=>text(
          |Approved '{ summary_from_state( request->get_request_state( ) ) }'. | &&
          |Reason given by the user: { approval_reason }.| ) ##NO_TEXT.
      ELSE.
        result = zcl_mcp2_resp_call_tool=>text(
          |Approval { elicit->get_action( ) } by the user for | &&
          |'{ summary_from_state( request->get_request_state( ) ) }'.| ) ##NO_TEXT.
      ENDIF.
      RETURN.
    ENDIF.

    " request_summary describes WHAT is being approved and is supplied by the
    " caller. It is required, so read it as required in both eras.
    DATA(request_summary) = request->require_arg_string( `request_summary` ) ##NO_TEXT.

    " Legacy has no MRTR vocabulary, so the approval cannot be obtained from a
    " user here. Say what would happen instead of claiming a side effect that
    " this demo does not perform - nothing is persisted or queued.
    IF era_is_modern( ) = abap_false.
      result = zcl_mcp2_resp_call_tool=>text(
          |Legacy fallback: '{ request_summary }' would require manual review. | &&
          |No approval was requested and nothing was submitted.| ) ##NO_TEXT.
      RETURN.
    ENDIF.

    " Build the elicitation params with a dedicated flat form schema. A tool
    " input schema must NOT be reused as requestedSchema - it follows different
    " rules (flat, no annotations).
    DATA(form_schema) = NEW zcl_mcp2_elicit_schema( ).
    form_schema->add_string( name        = `approval_reason`
                             title       = `Approval reason`
                             description = `Why should this request be approved?`
                             required    = abap_true ) ##NO_TEXT.

    DATA(elicitation) = NEW zcl_mcp2_input_elicitation( ).
    elicitation->set_form( message          = |Approve '{ request_summary }'?|
                           requested_schema = form_schema ) ##NO_TEXT.

    IF can_request_input( elicitation ) = abap_false.
      result = zcl_mcp2_resp_call_tool=>text(
        `This modern client did not declare form elicitation; approval was not attempted.` ) ##NO_TEXT.
      RETURN.
    ENDIF.

    " requestState carries correlation data forward. The client echoes it back
    " verbatim, so it must be opaque to the client but meaningful to us - and
    " must never contain anything the caller may not see.
    result = input_required( request_key   = approval_key
                             input         = elicitation
                             request_state = |{ state_prefix }{ request_summary }| ).
  ENDMETHOD.

  METHOD summary_from_state.
    " Recover the summary the first call put into requestState. A real
    " application would use an opaque correlation id plus a stored record.
    " Treat the client's echo as untrusted input: check the prefix explicitly
    " (length first, so a short value cannot dump) rather than assuming shape.
    DATA(prefix_len) = strlen( state_prefix ).
    IF strlen( state ) > prefix_len AND state(prefix_len) = state_prefix.
      result = substring( val = state
                          off = prefix_len ).
    ELSE.
      result = `unknown request` ##NO_TEXT.
    ENDIF.
  ENDMETHOD.

  METHOD build_approval_schema.
    " No x-mcp-header here: header mirroring is demonstrated once, by
    " echo_sep2243_mirror in ZCL_MCP2_DEMO_BASIC. Keep one concept per example,
    " and keep the annotation off tools a client is expected to just call.
    result = NEW zcl_mcp2_schema_builder(
      )->add_string( name        = `request_summary`
                     description = `Short description of what should be approved`
                     required    = abap_true
                     min_length  = 1
      )->to_json( ) ##NO_TEXT.
  ENDMETHOD.
ENDCLASS.
