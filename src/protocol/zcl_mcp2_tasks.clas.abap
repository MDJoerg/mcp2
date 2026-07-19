"! <p class="shorttext synchronized">MCP2 task persistence</p>
"! Manages the lifecycle of background tasks in the ZMCP2_TASKS table.
"! Instance methods are HTTP-context-scoped (user/area/server bound).
"! Class methods are background-safe and can be called from batch jobs.
CLASS zcl_mcp2_tasks DEFINITION PUBLIC CREATE PUBLIC.

  PUBLIC SECTION.
    "! DB value for status input_required (14 chars won't fit in CHAR10).
    CONSTANTS db_input_req TYPE string VALUE `input_req`.

    "! Default page size for tasks/list.
    CONSTANTS page_size TYPE i VALUE 50.

    TYPES: BEGIN OF task_row,
             task_id        TYPE sysuuid_c32,
             created_by     TYPE syuname,
             area           TYPE string,
             server         TYPE string,
             status         TYPE string,    " wire value (translated from DB)
             protocol_era   TYPE string,    " blank DB values are legacy
             status_message TYPE string,
             error_code     TYPE i,          " JSON-RPC code of a failed task (0 = none stored)
             created_at     TYPE timestamp,
             last_updated   TYPE timestamp,
             ttl_s          TYPE i,         " seconds, 0 = no expiry
             poll_ms        TYPE i,         " milliseconds
           END OF task_row.

    TYPES task_table TYPE STANDARD TABLE OF task_row WITH EMPTY KEY.

    TYPES: BEGIN OF list_result,
             rows        TYPE task_table,
             next_cursor TYPE string,
           END OF list_result.

    TYPES: BEGIN OF consume_result,
             accepted_keys  TYPE string_table,
             remaining_keys TYPE string_table,
             ready          TYPE abap_bool,
           END OF consume_result.

    "! <p class="shorttext synchronized">Construct a scoped instance</p>
    "! @parameter area   | MCP area identifier
    "! @parameter server | Server identifier
    METHODS constructor
      IMPORTING !area  TYPE string
                server TYPE string.

    "! <p class="shorttext synchronized">Create a new task in 'working' state</p>
    "! @parameter poll_ms        | Recommended poll interval in milliseconds
    "! @parameter ttl_s          | Time-to-live in seconds (0 = no expiry)
    "! @parameter status_message | Optional initial human-readable status
    "! @parameter result         | New task ID (32-char hex UUID)
    "! @raising   zcx_mcp2_error | Invalid TTL/poll interval or DB insert failure
    METHODS create_task
      IMPORTING poll_ms        TYPE i DEFAULT 5000
                ttl_s          TYPE i DEFAULT 0
                status_message TYPE string OPTIONAL
                protocol_era   TYPE string DEFAULT zif_mcp2_const=>eras-legacy
      RETURNING VALUE(result)  TYPE sysuuid_c32
      RAISING   zcx_mcp2_error.

    "! <p class="shorttext synchronized">Get task header (no payload)</p>
    "! User-scoped.
    "! @parameter task_id        | 32-char uppercase hex UUID
    "! @parameter result         | Task row
    "! @raising   zcx_mcp2_error | Task not found for the current user
    METHODS get
      IMPORTING task_id       TYPE sysuuid_c32
      RETURNING VALUE(result) TYPE task_row
      RAISING   zcx_mcp2_error.

    "! <p class="shorttext synchronized">Get the stored payload of a task</p>
    "! For a completed/failed task; user-scoped.
    "! @parameter task_id              | 32-char uppercase hex UUID
    "! @parameter result               | Payload JSON
    "! @raising   zcx_mcp2_error       | Task not found or no payload stored
    "! @raising   zcx_mcp2_ajson_error | Payload parse failure
    METHODS get_payload
      IMPORTING task_id       TYPE sysuuid_c32
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_error zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">List tasks (keyset cursor pagination)</p>
    "! User-scoped.
    "! @parameter cursor         | Pagination cursor (empty = first page)
    "! @parameter result         | Rows + optional next_cursor
    "! @raising   zcx_mcp2_error | Invalid cursor
    METHODS list
      IMPORTING cursor        TYPE string OPTIONAL
      RETURNING VALUE(result) TYPE list_result
      RAISING   zcx_mcp2_error.

    "! <p class="shorttext synchronized">Transition task status</p>
    "! Enforces the state machine. Safe to call from batch jobs and background RFCs.
    "! @parameter task_id        | 32-char uppercase hex UUID
    "! @parameter status         | New status (wire value from zif_mcp2_const=>task_statuses)
    "! @parameter message        | Optional status message
    "! @raising   zcx_mcp2_error | Invalid or concurrently-blocked transition
    CLASS-METHODS update_status
      IMPORTING task_id  TYPE sysuuid_c32
                !status  TYPE string
                !message TYPE string OPTIONAL
      RAISING   zcx_mcp2_error.

    "! <p class="shorttext synchronized">Request input for a task (input_req)</p>
    "! Moves the task to input_req status from a typed builder. Safe to call from
    "! batch jobs and background RFCs.
    "! @parameter task_id              | 32-char uppercase hex UUID
    "! @parameter request_key          | Server-chosen key the client answers under
    "! @parameter input                | Elicitation / sampling builder
    "! @raising   zcx_mcp2_error       | Invalid transition or request key
    "! @raising   zcx_mcp2_ajson_error | Input params build failure
    CLASS-METHODS request_input
      IMPORTING task_id       TYPE sysuuid_c32
                request_key   TYPE string
                input         TYPE REF TO zif_mcp2_input_request
      RAISING   zcx_mcp2_error zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Consume responses for outstanding input requests</p>
    "! Verifies the creating user, ignores unknown/already-consumed keys, and retains
    "! unanswered requests. The task resumes working only when all keys are answered.
    "! Safe to call from batch jobs and background RFCs.
    "! @parameter task_id              | 32-char uppercase hex UUID
    "! @parameter input_responses      | Input response JSON from the client
    "! @parameter result               | Accepted/remaining keys and readiness
    "! @raising   zcx_mcp2_error       | Task not found, not waiting, or invalid input
    "! @raising   zcx_mcp2_ajson_error | JSON access failure
    CLASS-METHODS consume_update
      IMPORTING task_id         TYPE sysuuid_c32
                input_responses TYPE REF TO zif_mcp2_ajson
      RETURNING VALUE(result)    TYPE consume_result
      RAISING   zcx_mcp2_error zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Overwrite the payload without a status change</p>
    "! For incremental writes.
    "! @parameter task_id              | 32-char uppercase hex UUID
    "! @parameter payload              | Result payload JSON
    "! @raising   zcx_mcp2_error       | Task not in a writable status
    "! @raising   zcx_mcp2_ajson_error | JSON access failure
    CLASS-METHODS set_payload
      IMPORTING task_id TYPE sysuuid_c32
                payload TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_error zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Store the result and finish the task</p>
    "! Atomically stores the payload and applies the persisted era's terminal semantics.
    "! @parameter task_id              | 32-char uppercase hex UUID
    "! @parameter result               | Terminal task payload
    "! @raising   zcx_mcp2_error       | Task already in a terminal state
    "! @raising   zcx_mcp2_ajson_error | Payload serialization failure
    CLASS-METHODS complete
      IMPORTING task_id  TYPE sysuuid_c32
                !result  TYPE REF TO zcl_mcp2_resp_task_payload
      RAISING   zcx_mcp2_error zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Transition to failed</p>
    "! With an error message and JSON-RPC error code; the code is surfaced by
    "! tasks/get for failed tasks.
    "! @parameter task_id        | 32-char uppercase hex UUID
    "! @parameter message        | Error description
    "! @parameter code           | JSON-RPC error code (default -32603 InternalError)
    "! @raising   zcx_mcp2_error | Task already in a terminal state
    CLASS-METHODS fail
      IMPORTING task_id  TYPE sysuuid_c32
                !message TYPE string
                code     TYPE i DEFAULT -32603
      RAISING   zcx_mcp2_error.

    "! <p class="shorttext synchronized">Cancel a task</p>
    "! User-scoped; idempotent when already cancelled.
    "! @parameter task_id        | 32-char uppercase hex UUID
    "! @raising   zcx_mcp2_error | Task not found or already in a terminal state
    CLASS-METHODS cancel
      IMPORTING task_id TYPE sysuuid_c32
      RAISING   zcx_mcp2_error.

    "! <p class="shorttext synchronized">DB-level status string for a task</p>
    "! @parameter task_id        | 32-char uppercase hex UUID
    "! @parameter result         | DB status string
    "! @raising   zcx_mcp2_error | Task not found
    CLASS-METHODS get_status
      IMPORTING task_id       TYPE sysuuid_c32
      RETURNING VALUE(result) TYPE string
      RAISING   zcx_mcp2_error.

    "! <p class="shorttext synchronized">Delete expired and stuck tasks</p>
    "! Commits before returning.
    "! @parameter result | Number of rows deleted
    CLASS-METHODS delete_outdated_tasks
      RETURNING VALUE(result) TYPE i.

    "! <p class="shorttext synchronized">Whether a status transition is allowed</p>
    "! Both parameters must be DB-level status values.
    "! @parameter current | Current DB status
    "! @parameter next    | Target DB status
    "! @parameter result  | abap_true when the transition is permitted
    CLASS-METHODS is_valid_transition
      IMPORTING current       TYPE clike
                next          TYPE clike
      RETURNING VALUE(result) TYPE abap_bool.

    "! <p class="shorttext synchronized">Translate a wire status to DB form</p>
    "! Only differs for 'input_required' -> 'input_req'.
    "! @parameter wire_val | Wire status (from zif_mcp2_const=>task_statuses)
    "! @parameter result   | DB status value
    CLASS-METHODS wire_to_db
      IMPORTING wire_val      TYPE clike
      RETURNING VALUE(result) TYPE string.

    "! <p class="shorttext synchronized">Translate a DB status to wire form</p>
    "! Only differs for 'input_req' -> 'input_required'.
    "! @parameter db_val | DB status value
    "! @parameter result | Wire status (for use in zif_mcp2_const=>task_statuses)
    CLASS-METHODS db_to_wire
      IMPORTING db_val        TYPE clike
      RETURNING VALUE(result) TYPE string.

  PRIVATE SECTION.
    DATA area   TYPE string.
    DATA server TYPE string.

    "! <p class="shorttext synchronized">Read a raw task row by id</p>
    "! @parameter task_id        | 32-char uppercase hex UUID
    "! @parameter result         | Raw DB row
    "! @raising   zcx_mcp2_error | Task not found
    CLASS-METHODS read_row
      IMPORTING task_id       TYPE sysuuid_c32
      RETURNING VALUE(result) TYPE zmcp2_tasks
      RAISING   zcx_mcp2_error.

    "! <p class="shorttext synchronized">Map a DB row to a task_row struct</p>
    "! @parameter row    | Raw DB row
    "! @parameter result | Task row (status translated to wire form)
    CLASS-METHODS row_to_task
      IMPORTING !row          TYPE zmcp2_tasks
      RETURNING VALUE(result) TYPE task_row.

ENDCLASS.

CLASS zcl_mcp2_tasks IMPLEMENTATION.

  METHOD constructor.
    me->area   = area.
    me->server = server.
  ENDMETHOD.

  METHOD create_task.
    IF poll_ms < 0.
      zcx_mcp2_error=>raise_invalid_params(
        `Task poll interval must not be negative` ) ##NO_TEXT.
    ENDIF.
    zcl_mcp2_task_util=>validate_ttl_s( ttl_s ).

    TRY.
        result = cl_system_uuid=>create_uuid_c32_static( ).
      CATCH cx_uuid_error.
        zcx_mcp2_error=>raise_internal( `Failed to generate task UUID` ) ##NO_TEXT.
    ENDTRY.

    DATA db TYPE zmcp2_tasks.
    db-client         = sy-mandt.
    db-task_id        = result.
    db-created_by     = sy-uname.
    db-area           = me->area.
    db-server         = me->server.
    db-status         = zif_mcp2_const=>task_statuses-working.
    db-protocol_era   = COND #( WHEN protocol_era = zif_mcp2_const=>eras-modern
                                THEN zif_mcp2_const=>eras-modern
                                ELSE zif_mcp2_const=>eras-legacy ).
    db-status_message = status_message.
    db-poll_interval  = poll_ms.
    db-ttl            = ttl_s.
    GET TIME STAMP FIELD db-created_at.
    db-last_updated = db-created_at.

    INSERT zmcp2_tasks FROM @db.
    IF sy-subrc <> 0.
      zcx_mcp2_error=>raise_internal( `Failed to insert task` ) ##NO_TEXT.
    ENDIF.
  ENDMETHOD.

  METHOD get.
    DATA(db) = read_row( task_id ).
    IF db-created_by <> sy-uname.
      zcx_mcp2_error=>raise_invalid_params(
        |Task not found: { task_id }| ) ##NO_TEXT.
    ENDIF.
    result = row_to_task( db ).
  ENDMETHOD.

  METHOD get_payload.
    SELECT SINGLE payload, created_by
      FROM zmcp2_tasks
      WHERE task_id = @task_id
      INTO @DATA(db_row).

    IF sy-subrc <> 0 OR db_row-created_by <> sy-uname.
      zcx_mcp2_error=>raise_invalid_params(
        |Task not found: { task_id }| ) ##NO_TEXT.
    ENDIF.

    IF db_row-payload IS INITIAL.
      zcx_mcp2_error=>raise_internal(
        |Task { task_id } has no stored payload| ) ##NO_TEXT.
    ENDIF.

    result = zcl_mcp2_ajson=>parse( db_row-payload ).
  ENDMETHOD.

  METHOD list.
    DATA cursor_ts      TYPE timestamp.
    DATA cursor_task_id TYPE sysuuid_c32.

    IF cursor IS INITIAL.
      cursor_ts      = '99991231235959'.
      cursor_task_id = 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF'.
    ELSE.
      DATA ts_txt TYPE string.
      DATA id_txt TYPE string.
      SPLIT cursor AT '|' INTO ts_txt id_txt.
      TRY.
          cursor_ts = CONV timestamp( ts_txt ).
          IF cursor_ts = 0.
            zcx_mcp2_error=>raise_invalid_params( `Invalid cursor` ) ##NO_TEXT.
          ENDIF.
        CATCH cx_sy_conversion_no_number cx_sy_conversion_overflow.
          zcx_mcp2_error=>raise_invalid_params( `Invalid cursor` ) ##NO_TEXT.
      ENDTRY.
      IF id_txt IS INITIAL.
        cursor_task_id = 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF'.
      ELSE.
        FIND REGEX `^[0-9A-Fa-f]{32}$` IN id_txt.
        IF sy-subrc <> 0.
          zcx_mcp2_error=>raise_invalid_params( `Invalid cursor` ) ##NO_TEXT.
        ENDIF.
        cursor_task_id = to_upper( id_txt ).
      ENDIF.
    ENDIF.

    DATA(fetch) = page_size + 1.
    DATA(area_arg)   = CONV char40( area ).
    DATA(server_arg) = CONV char40( server ).
    DATA db_rows TYPE TABLE OF zmcp2_tasks.

    SELECT task_id, created_by, area, server, status, protocol_era, status_message,
           error_code, created_at, last_updated, ttl, poll_interval
      FROM zmcp2_tasks
      WHERE area       = @area_arg
        AND server     = @server_arg
        AND created_by = @sy-uname
        AND ( created_at < @cursor_ts
            OR ( created_at = @cursor_ts AND task_id < @cursor_task_id ) )
      ORDER BY created_at DESCENDING,
               task_id DESCENDING
      INTO CORRESPONDING FIELDS OF TABLE @db_rows
      UP TO @fetch ROWS.              "#EC CI_NOFIELD

    IF sy-subrc = 0 AND lines( db_rows ) > page_size.
      DELETE db_rows INDEX lines( db_rows ).
      DATA(last) = db_rows[ lines( db_rows ) ].
      result-next_cursor = |{ last-created_at }\|{ last-task_id }|.
    ENDIF.

    result-rows = VALUE #( FOR r IN db_rows ( row_to_task( r ) ) ).
  ENDMETHOD.

  METHOD update_status.
    DATA(row) = read_row( task_id ).
    DATA(db_next) = wire_to_db( status ).
    IF is_valid_transition( current = row-status
                            next    = db_next ) = abap_false.
      zcx_mcp2_error=>raise_internal(
        |Invalid status transition: { db_to_wire( row-status ) } -> { status }| ) ##NO_TEXT.
    ENDIF.
    DATA now TYPE timestamp.
    GET TIME STAMP FIELD now.
    DATA(db_msg) = message.
    UPDATE zmcp2_tasks
      SET status         = @db_next,
          status_message = @db_msg,
          last_updated   = @now
      WHERE task_id = @task_id
        AND status  = @row-status.
    IF sy-subrc <> 0.
      DATA(re_read) = read_row( task_id ).
      zcx_mcp2_error=>raise_internal(
        |Concurrent transition blocked: { db_to_wire( re_read-status ) } -> { status }| ) ##NO_TEXT.
    ENDIF.
  ENDMETHOD.

  METHOD request_input.
    DATA(row) = read_row( task_id ).
    IF is_valid_transition( current = row-status
                            next    = db_input_req ) = abap_false.
      zcx_mcp2_error=>raise_internal(
        |Cannot request input from { db_to_wire( row-status ) }| ) ##NO_TEXT.
    ENDIF.
    IF request_key IS INITIAL
       OR request_key CA '/'
       OR request_key CA cl_abap_char_utilities=>horizontal_tab.
      zcx_mcp2_error=>raise_internal(
        |Invalid input request key: '{ request_key }'| ) ##NO_TEXT.
    ENDIF.
    DATA(key_history) = COND string( WHEN row-request_keys IS INITIAL
                                     THEN `{}`
                                     ELSE row-request_keys ).
    DATA(history_json) = zcl_mcp2_ajson=>parse( key_history ).
    IF history_json->exists( |/{ request_key }| ) = abap_true.
      zcx_mcp2_error=>raise_internal(
        |Input request key '{ request_key }' was already used by task { task_id }| ) ##NO_TEXT.
    ENDIF.
    history_json->set_boolean( iv_path = |/{ request_key }| iv_val = abap_true ).
    DATA(history_str) = history_json->stringify( ).
    " Persist inputRequests keyed by requestKey (not requestState) - see the
    " MRTR/tasks distinction. The separate history survives payload rewrites.
    DATA(input_required) = zcl_mcp2_ajson=>parse( '{}' ).
    input_required->set_string( iv_path = |/inputRequests/{ request_key }/method|
                                iv_val  = input->get_method( ) ).
    input_required->set( iv_path = |/inputRequests/{ request_key }/params|
                         iv_val  = input->get_params( ) ).
    DATA(payload_str) = input_required->stringify( ).
    DATA now TYPE timestamp.
    GET TIME STAMP FIELD now.
    DATA(db_inp) = db_input_req.
    UPDATE zmcp2_tasks
      SET payload      = @payload_str,
          request_keys = @history_str,
          status       = @db_inp,
          last_updated = @now
      WHERE task_id = @task_id
        AND status  = @row-status.
    IF sy-subrc <> 0.
      zcx_mcp2_error=>raise_internal(
        |request_input: concurrent update for task { task_id }| ) ##NO_TEXT.
    ENDIF.
  ENDMETHOD.

  METHOD consume_update.
    DATA(row) = read_row( task_id ).
    " User-scope check: a task is addressable only by its creating user, like
    " get / get_payload / cancel. Without this any authenticated user holding
    " another user's task UUID could inject inputResponses.
    IF row-created_by <> sy-uname.
      zcx_mcp2_error=>raise_invalid_params(
        |Task not found: { task_id }| ) ##NO_TEXT.
    ENDIF.
    DATA(db_inp) = db_input_req.
    IF row-status <> db_inp.
      zcx_mcp2_error=>raise_invalid_params(
        |Task { task_id } is not waiting for input| ) ##NO_TEXT.
    ENDIF.

    IF input_responses IS NOT BOUND
       OR input_responses->get_node_type( '/' )
          <> zif_mcp2_ajson_types=>node_type-object.
      zcx_mcp2_error=>raise_invalid_params(
        `tasks/update inputResponses must be an object` ) ##NO_TEXT.
    ENDIF.

    " The persisted input request is the source of truth. A client may retry
    " an update or include stale/unknown keys; only still-outstanding keys are
    " copied into the task payload. Unknown and already-satisfied keys are
    " deliberately ignored, not allowed to inject arbitrary task state.
    IF row-payload IS INITIAL.
      zcx_mcp2_error=>raise_internal(
        |Task { task_id } is waiting for input but has no request payload| ) ##NO_TEXT.
    ENDIF.
    DATA(outstanding) = zcl_mcp2_ajson=>parse( row-payload ).
    DATA accepted TYPE REF TO zif_mcp2_ajson.
    accepted = zcl_mcp2_ajson=>parse( '{}' ).
    IF     outstanding->exists( '/inputResponses' ) = abap_true
       AND outstanding->get_node_type( '/inputResponses' )
           = zif_mcp2_ajson_types=>node_type-object.
      accepted = outstanding->slice( '/inputResponses' ).
    ENDIF.
    DATA request_keys TYPE string_table.

    IF     outstanding->exists( '/requestKey' ) = abap_true
       AND outstanding->get_node_type( '/requestKey' )
           = zif_mcp2_ajson_types=>node_type-string.
      DATA(single_key) = outstanding->get_string( '/requestKey' ).
      IF single_key IS NOT INITIAL.
        APPEND single_key TO request_keys.
      ENDIF.
    ENDIF.

    IF     outstanding->exists( '/inputRequests' ) = abap_true
       AND outstanding->get_node_type( '/inputRequests' )
           = zif_mcp2_ajson_types=>node_type-object.
      " Keep method-call results explicitly typed for ABAP 7.02 downport compatibility.
      DATA input_request_keys TYPE string_table.
      input_request_keys = outstanding->members( '/inputRequests' ).
      DATA request_key TYPE string.
      LOOP AT input_request_keys INTO request_key.
        IF     outstanding->exists( |/inputResponses/{ request_key }| ) = abap_false
           AND NOT line_exists( request_keys[ table_line = request_key ] ).
          APPEND request_key TO request_keys.
        ENDIF.
      ENDLOOP.
    ENDIF.

    LOOP AT request_keys INTO DATA(accepted_key).
      DATA(response_path) = |/{ accepted_key }|.
      IF input_responses->exists( response_path ) = abap_true.
        accepted->set( iv_path = response_path
                       iv_val  = input_responses->slice( response_path ) ).
        APPEND accepted_key TO result-accepted_keys.
      ELSE.
        APPEND accepted_key TO result-remaining_keys.
      ENDIF.
    ENDLOOP.

    result-ready = xsdbool( lines( result-remaining_keys ) = 0
                        AND lines( result-accepted_keys ) > 0 ).

    " Unknown-only updates are successful no-ops. Preserve the exact persisted
    " request set and input_required state so a retry cannot lose work.
    IF lines( result-accepted_keys ) = 0.
      RETURN.
    ENDIF.

    DATA(upd_json) = zcl_mcp2_ajson=>parse( '{}' ).
    upd_json->set( iv_path = '/inputResponses' iv_val = accepted ).
    LOOP AT result-remaining_keys INTO DATA(remaining_key).
      upd_json->set( iv_path = |/inputRequests/{ remaining_key }|
                     iv_val  = outstanding->slice( |/inputRequests/{ remaining_key }| ) ).
    ENDLOOP.
    DATA(payload_str) = upd_json->stringify( ).
    DATA(next_status) = COND string( WHEN result-ready = abap_true
                                     THEN zif_mcp2_const=>task_statuses-working
                                     ELSE db_input_req ).
    DATA now TYPE timestamp.
    GET TIME STAMP FIELD now.
    UPDATE zmcp2_tasks
      SET payload      = @payload_str,
          status       = @next_status,
          last_updated = @now
      WHERE task_id = @task_id
        AND status  = @db_inp.
    IF sy-subrc <> 0.
      zcx_mcp2_error=>raise_internal(
        |consume_update: concurrent update for task { task_id }| ) ##NO_TEXT.
    ENDIF.
  ENDMETHOD.

  METHOD set_payload.
    DATA(payload_str) = payload->stringify( ).
    DATA(wstatus) = zif_mcp2_const=>task_statuses-working.
    DATA now TYPE timestamp.
    GET TIME STAMP FIELD now.
    UPDATE zmcp2_tasks
      SET payload      = @payload_str,
          last_updated = @now
      WHERE task_id = @task_id
        AND status  = @wstatus.
    IF sy-subrc <> 0.
      DATA(row) = read_row( task_id ).
      zcx_mcp2_error=>raise_internal(
        |Cannot set payload for task in status { db_to_wire( row-status ) }| ) ##NO_TEXT.
    ENDIF.
  ENDMETHOD.

  METHOD complete.
    DATA(payload_json) = result->zif_mcp2_result~to_json( ).
    DATA(payload_str)  = payload_json->stringify( ).
    DATA(row) = read_row( task_id ).
    " Rows created before PROTOCOL_ERA was added are intentionally legacy.
    DATA(final_status) = COND string(
      WHEN result->get_is_error( ) = abap_true
       AND row-protocol_era <> zif_mcp2_const=>eras-modern
      THEN zif_mcp2_const=>task_statuses-failed
      ELSE zif_mcp2_const=>task_statuses-completed ).
    IF is_valid_transition( current = row-status
                            next    = final_status ) = abap_false.
      zcx_mcp2_error=>raise_internal( `Task has already reached a terminal state` ) ##NO_TEXT.
    ENDIF.
    DATA now TYPE timestamp.
    GET TIME STAMP FIELD now.
    UPDATE zmcp2_tasks
      SET payload      = @payload_str,
          status       = @final_status,
          last_updated = @now
      WHERE task_id = @task_id
        AND status  = @row-status.
    IF sy-subrc <> 0.
      zcx_mcp2_error=>raise_internal( `Task has already reached a terminal state` ) ##NO_TEXT.
    ENDIF.
  ENDMETHOD.

  METHOD fail.
    DATA(row) = read_row( task_id ).
    DATA(fstatus) = zif_mcp2_const=>task_statuses-failed.
    IF is_valid_transition( current = row-status
                            next    = fstatus ) = abap_false.
      zcx_mcp2_error=>raise_internal( `Task has already reached a terminal state` ) ##NO_TEXT.
    ENDIF.
    DATA now TYPE timestamp.
    GET TIME STAMP FIELD now.
    UPDATE zmcp2_tasks
      SET status         = @fstatus,
          status_message = @message,
          error_code     = @code,
          last_updated   = @now
      WHERE task_id = @task_id
        AND status  = @row-status.
    IF sy-subrc <> 0.
      zcx_mcp2_error=>raise_internal( `Task has already reached a terminal state` ) ##NO_TEXT.
    ENDIF.
  ENDMETHOD.

  METHOD cancel.
    SELECT SINGLE task_id, status, created_by
      FROM zmcp2_tasks
      WHERE task_id = @task_id
      INTO @DATA(snap).
    IF sy-subrc <> 0 OR snap-created_by <> sy-uname.
      zcx_mcp2_error=>raise_invalid_params(
        |Task not found: { task_id }| ) ##NO_TEXT.
    ENDIF.
    DATA(cstatus) = zif_mcp2_const=>task_statuses-cancelled.
    IF snap-status = cstatus.
      RETURN.
    ENDIF.
    " Terminal-state cancels are -32602 per the 2025-11-25 tasks spec.
    IF is_valid_transition( current = snap-status
                            next    = cstatus ) = abap_false.
      zcx_mcp2_error=>raise_invalid_params(
        |Cannot cancel task: already in terminal status '{ db_to_wire( snap-status ) }'| ) ##NO_TEXT.
    ENDIF.
    DATA now TYPE timestamp.
    GET TIME STAMP FIELD now.
    UPDATE zmcp2_tasks
      SET status       = @cstatus,
          last_updated = @now
      WHERE task_id    = @task_id
        AND created_by = @sy-uname
        AND status     = @snap-status.
    IF sy-subrc = 0.
      RETURN.
    ENDIF.
    SELECT SINGLE status, created_by
      FROM zmcp2_tasks
      WHERE task_id = @task_id
      INTO @DATA(curr).
    IF sy-subrc <> 0 OR curr-created_by <> sy-uname.
      zcx_mcp2_error=>raise_invalid_params(
        |Task not found: { task_id }| ) ##NO_TEXT.
    ENDIF.
    IF curr-status = cstatus.
      RETURN.
    ENDIF.
    zcx_mcp2_error=>raise_invalid_params(
      |Cannot cancel task: already in terminal status '{ db_to_wire( curr-status ) }'| ) ##NO_TEXT.
  ENDMETHOD.

  METHOD get_status.
    result = read_row( task_id )-status.
  ENDMETHOD.

  METHOD delete_outdated_tasks.
    DATA now TYPE timestamp.
    GET TIME STAMP FIELD now.

    " Terminal tasks whose explicit TTL has elapsed
    DATA ttl_rows TYPE TABLE OF zmcp2_tasks.
    SELECT task_id, last_updated, ttl
      FROM zmcp2_tasks
      WHERE status IN ( @zif_mcp2_const=>task_statuses-completed,
                        @zif_mcp2_const=>task_statuses-failed,
                        @zif_mcp2_const=>task_statuses-cancelled )
        AND ttl > 0
      ORDER BY PRIMARY KEY
      INTO CORRESPONDING FIELDS OF TABLE @ttl_rows. "#EC CI_NOFIELD

    IF sy-subrc = 0.
      DATA expired_ids TYPE RANGE OF sysuuid_c32.
      LOOP AT ttl_rows ASSIGNING FIELD-SYMBOL(<r>).
        DATA cutoff TYPE timestampl.
        cutoff = cl_abap_tstmp=>subtractsecs(
          tstmp = CONV timestampl( now ) secs = <r>-ttl ).
        DATA db_cutoff TYPE timestamp.
        cl_abap_tstmp=>move( EXPORTING tstmp_src = cutoff
                             IMPORTING tstmp_tgt = db_cutoff ).
        IF <r>-last_updated < db_cutoff.
          APPEND VALUE #( sign = 'I' option = 'EQ' low = <r>-task_id )
            TO expired_ids.
        ENDIF.
      ENDLOOP.
      IF expired_ids IS NOT INITIAL.
        DELETE FROM zmcp2_tasks WHERE task_id IN @expired_ids.
        result = result + sy-dbcnt.
      ENDIF.
    ENDIF.

    " Terminal tasks with no TTL after 7-day default retention
    DATA term_cutoff TYPE timestampl.
    DATA db_term TYPE timestamp.
    term_cutoff = cl_abap_tstmp=>subtractsecs(
      tstmp = CONV timestampl( now ) secs = 604800 ).
    cl_abap_tstmp=>move( EXPORTING tstmp_src = term_cutoff
                         IMPORTING tstmp_tgt = db_term ).
    DELETE FROM zmcp2_tasks
      WHERE status IN ( @zif_mcp2_const=>task_statuses-completed,
                        @zif_mcp2_const=>task_statuses-failed,
                        @zif_mcp2_const=>task_statuses-cancelled )
        AND ttl = 0
        AND last_updated < @db_term.  "#EC CI_NOFIELD
    result = result + sy-dbcnt.

    " Stuck working/input_req tasks older than 24 hours
    DATA stuck_cutoff TYPE timestampl.
    DATA db_stuck TYPE timestamp.
    DATA(db_inp) = db_input_req.
    stuck_cutoff = cl_abap_tstmp=>subtractsecs(
      tstmp = CONV timestampl( now ) secs = 86400 ).
    cl_abap_tstmp=>move( EXPORTING tstmp_src = stuck_cutoff
                         IMPORTING tstmp_tgt = db_stuck ).
    DELETE FROM zmcp2_tasks
      WHERE status IN ( @zif_mcp2_const=>task_statuses-working, @db_inp )
        AND created_at < @db_stuck.  "#EC CI_NOFIELD
    result = result + sy-dbcnt.

    IF result > 0.
      COMMIT WORK AND WAIT.
    ENDIF.
  ENDMETHOD.

  METHOD read_row.
    SELECT SINGLE *
      FROM zmcp2_tasks
      WHERE task_id = @task_id
      INTO CORRESPONDING FIELDS OF @result.
    IF sy-subrc <> 0.
      zcx_mcp2_error=>raise_invalid_params(
        |Task not found: { task_id }| ) ##NO_TEXT.
    ENDIF.
  ENDMETHOD.

  METHOD is_valid_transition.
    DATA(w) = zif_mcp2_const=>task_statuses.
    result = xsdbool(
      (    current = w-working
        AND (    next = w-working
              OR next = db_input_req
              OR next = w-completed
              OR next = w-failed
              OR next = w-cancelled ) )
      OR
      (    current = db_input_req
        AND (    next = w-working
              OR next = w-completed
              OR next = w-failed
              OR next = w-cancelled ) ) ).
  ENDMETHOD.

  METHOD wire_to_db.
    result = COND string(
      WHEN wire_val = zif_mcp2_const=>task_statuses-input_required
      THEN db_input_req
      ELSE wire_val ).
  ENDMETHOD.

  METHOD db_to_wire.
    result = COND string(
      WHEN db_val = db_input_req
      THEN zif_mcp2_const=>task_statuses-input_required
      ELSE db_val ).
  ENDMETHOD.

  METHOD row_to_task.
    result-task_id        = row-task_id.
    result-created_by     = row-created_by.
    result-area           = row-area.
    result-server         = row-server.
    result-status         = db_to_wire( row-status ).
    result-protocol_era   = COND #( WHEN row-protocol_era = zif_mcp2_const=>eras-modern
                                    THEN zif_mcp2_const=>eras-modern
                                    ELSE zif_mcp2_const=>eras-legacy ).
    result-status_message = row-status_message.
    result-error_code     = row-error_code.
    result-created_at     = row-created_at.
    result-last_updated   = row-last_updated.
    result-ttl_s          = row-ttl.
    result-poll_ms        = row-poll_interval.
  ENDMETHOD.

ENDCLASS.
