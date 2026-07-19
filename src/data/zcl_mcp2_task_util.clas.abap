"! <p class="shorttext synchronized">MCP2 task helper utilities</p>
"! Shared formatting and validation helpers for the Tasks extension, so the
"! request and response classes do not each carry their own copy.
CLASS zcl_mcp2_task_util DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    " ABAP type i is the wire representation for millisecond values. Keep
    " this bound in one place so conversions never wrap or truncate.
    CONSTANTS max_milliseconds TYPE i VALUE 2147483647.
    CONSTANTS max_ttl_seconds  TYPE i VALUE 2147483.

    "! <p class="shorttext synchronized">Format a timestamp as ISO 8601 UTC</p>
    "! Renders a packed UTC timestamp as YYYY-MM-DDThh:mm:ssZ.
    "! @parameter ts     | UTC timestamp
    "! @parameter result | ISO 8601 string with trailing Z
    CLASS-METHODS ts_to_iso
      IMPORTING !ts           TYPE timestamp
      RETURNING VALUE(result) TYPE string.

    "! <p class="shorttext synchronized">Validate an integer-backed TTL</p>
    "! Positive TTL seconds must fit in the millisecond wire representation.
    "! Zero means unlimited; negative values are invalid.
    "! @parameter ttl_s  | TTL in seconds
    "! @raising   zcx_mcp2_error | Value cannot be represented or is negative
    CLASS-METHODS validate_ttl_s
      IMPORTING ttl_s TYPE i
      RAISING   zcx_mcp2_error.

    "! <p class="shorttext synchronized">TTL seconds to milliseconds</p>
    "! Call validate_ttl_s first. Zero stays zero (unlimited).
    "! @parameter ttl_s  | TTL in seconds
    "! @parameter result | TTL in milliseconds within the int4 bound
    "! @raising   zcx_mcp2_error | TTL is negative or exceeds the representable bound
    CLASS-METHODS ttl_s_to_ms
      IMPORTING ttl_s         TYPE i
      RETURNING VALUE(result) TYPE i
      RAISING   zcx_mcp2_error.

    "! <p class="shorttext synchronized">Parse a JSON millisecond value</p>
    "! Range-checks the raw digits before the ABAP integer round-trip.
    "! @parameter raw            | Raw non-negative integer string
    "! @parameter result         | Parsed value within the int4 bound
    "! @raising   zcx_mcp2_error | Not an integer or outside the representable bound
    CLASS-METHODS parse_milliseconds
      IMPORTING !raw          TYPE string
      RETURNING VALUE(result) TYPE i
      RAISING   zcx_mcp2_error.

    "! <p class="shorttext synchronized">Validate and normalise a task ID</p>
    "! Accepts a 32-character hex string and returns it upper-cased.
    "! @parameter raw            | Raw taskId from the request
    "! @parameter result         | Upper-cased 32-char hex UUID
    "! @raising   zcx_mcp2_error | taskId is not a 32-character hex UUID
    CLASS-METHODS normalize_task_id
      IMPORTING !raw          TYPE string
      RETURNING VALUE(result) TYPE sysuuid_c32
      RAISING   zcx_mcp2_error.

    "! <p class="shorttext synchronized">Emit legacy task fields under a path prefix</p>
    "! Writes the common legacy task header (taskId, status, optional message,
    "! timestamps, ttl in ms or null, pollInterval) under the given JSON prefix.
    "! Pass an empty prefix for root-level shapes, '/task' for nested shapes.
    "! @parameter json         | Target ajson document
    "! @parameter prefix       | Path prefix ('' = root, '/task', '/tasks/1', ...)
    "! @parameter task_id      | 32-char uppercase hex UUID
    "! @parameter status       | Task status
    "! @parameter status_msg   | Optional status description
    "! @parameter created_at   | Creation UTC timestamp
    "! @parameter last_updated | Last-update UTC timestamp
    "! @parameter ttl_s        | TTL in seconds (0 = no expiry -> null on wire)
    "! @parameter poll_ms      | Recommended poll interval in milliseconds
    "! @raising   zcx_mcp2_ajson_error | JSON build failure or TTL out of range
    CLASS-METHODS write_task_fields
      IMPORTING !json        TYPE REF TO zif_mcp2_ajson
                !prefix      TYPE string
                task_id      TYPE sysuuid_c32
                !status      TYPE string
                status_msg   TYPE string    OPTIONAL
                created_at   TYPE timestamp OPTIONAL
                last_updated TYPE timestamp OPTIONAL
                ttl_s        TYPE i         OPTIONAL
                poll_ms      TYPE i         OPTIONAL
      RAISING   zcx_mcp2_ajson_error.

ENDCLASS.

CLASS zcl_mcp2_task_util IMPLEMENTATION.

  METHOD ts_to_iso.
    DATA s TYPE string.
    s = |{ ts }|.
    WHILE strlen( s ) < 14.
      s = |0{ s }|.
    ENDWHILE.
    result = |{ s+0(4) }-{ s+4(2) }-{ s+6(2) }T{ s+8(2) }:{ s+10(2) }:{ s+12(2) }Z|.
  ENDMETHOD.

  METHOD ttl_s_to_ms.
    validate_ttl_s( ttl_s ).
    result = ttl_s * 1000.
  ENDMETHOD.

  METHOD validate_ttl_s.
    IF ttl_s < 0.
      zcx_mcp2_error=>raise_invalid_params(
        `Task TTL must be zero or a positive number of seconds` ) ##NO_TEXT.
    ENDIF.
    IF ttl_s > max_ttl_seconds.
      zcx_mcp2_error=>raise_invalid_params(
        |Task TTL { ttl_s } seconds exceeds the representable millisecond bound { max_milliseconds }| ) ##NO_TEXT.
    ENDIF.
  ENDMETHOD.

  METHOD parse_milliseconds.
    IF raw IS INITIAL.
      zcx_mcp2_error=>raise_invalid_params(
        `Millisecond value must be a non-negative integer` ) ##NO_TEXT.
    ENDIF.
    FIND REGEX `^[0-9]+$` IN raw.
    IF sy-subrc <> 0.
      zcx_mcp2_error=>raise_invalid_params(
        `Millisecond value must be a non-negative integer` ) ##NO_TEXT.
    ENDIF.
    TRY.
        DATA(value) = CONV decfloat34( raw ).
      CATCH cx_root.
        zcx_mcp2_error=>raise_invalid_params(
          `Millisecond value is outside the ABAP range` ) ##NO_TEXT.
    ENDTRY.
    IF value > max_milliseconds.
      zcx_mcp2_error=>raise_invalid_params(
        |Millisecond value { raw } exceeds the representable bound { max_milliseconds }| ) ##NO_TEXT.
    ENDIF.
    result = CONV i( raw ).
  ENDMETHOD.

  METHOD normalize_task_id.
    IF strlen( raw ) <> 32.
      zcx_mcp2_error=>raise_invalid_params( `taskId must be a 32-character hex UUID` ) ##NO_TEXT.
    ENDIF.
    FIND REGEX `^[0-9A-Fa-f]{32}$` IN raw ##NO_TEXT.
    IF sy-subrc <> 0.
      zcx_mcp2_error=>raise_invalid_params( `taskId must be a 32-character hex UUID` ) ##NO_TEXT.
    ENDIF.
    result = to_upper( raw ).
  ENDMETHOD.

  METHOD write_task_fields.
    IF ttl_s < 0.
      zcx_mcp2_ajson_error=>raise(
        `Task TTL must be zero or a positive number of seconds` ) ##NO_TEXT.
    ENDIF.
    json->set_string( iv_path = |{ prefix }/taskId|
                      iv_val  = task_id ).
    json->set_string( iv_path = |{ prefix }/status|
                      iv_val  = status ).
    IF status_msg IS NOT INITIAL.
      json->set_string( iv_path = |{ prefix }/statusMessage|
                        iv_val  = status_msg ).
    ENDIF.
    IF created_at IS NOT INITIAL.
      json->set_string( iv_path = |{ prefix }/createdAt|
                        iv_val  = ts_to_iso( created_at ) ).
    ENDIF.
    IF last_updated IS NOT INITIAL.
      json->set_string( iv_path = |{ prefix }/lastUpdatedAt|
                        iv_val  = ts_to_iso( last_updated ) ).
    ENDIF.
    IF ttl_s > 0.
      IF ttl_s > max_ttl_seconds.
        zcx_mcp2_ajson_error=>raise(
          |Task TTL { ttl_s } seconds exceeds the representable millisecond bound { max_milliseconds }| ) ##NO_TEXT.
      ENDIF.
      json->set_integer( iv_path = |{ prefix }/ttl|
                         iv_val  = ttl_s * 1000 ).
    ELSE.
      json->set_null( |{ prefix }/ttl| ).
    ENDIF.
    IF poll_ms > 0.
      json->set_integer( iv_path = |{ prefix }/pollInterval|
                         iv_val  = poll_ms ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
