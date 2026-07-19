"! <p class="shorttext synchronized">MCP2 server configuration reader</p>
CLASS zcl_mcp2_config DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES origins TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    TYPES cors_mode TYPE c LENGTH 1.

    CONSTANTS cors_mode_check   TYPE cors_mode VALUE 'C'.
    CONSTANTS cors_mode_ignore  TYPE cors_mode VALUE 'I'.
    CONSTANTS cors_mode_enforce TYPE cors_mode VALUE 'E'.

    "! <p class="shorttext synchronized">Create a config reader for one server</p>
    "! @parameter area_name   | ICF service area / application name
    "! @parameter server_name | Configured MCP server name
    METHODS constructor
      IMPORTING area_name   TYPE string
                server_name TYPE string.

    "! <p class="shorttext synchronized">Allowed origins for this server</p>
    "! Read from zmcp2_origins (exact entries plus wildcard fallback).
    "! @parameter result | Allowed origin patterns
    METHODS get_allowed_origins
      RETURNING VALUE(result) TYPE origins.

    "! <p class="shorttext synchronized">Configured CORS mode (check/ignore/enforce)</p>
    "! @parameter result | One of cors_mode_check / _ignore / _enforce
    METHODS get_cors_mode
      RETURNING VALUE(result) TYPE cors_mode.

  PRIVATE SECTION.
    DATA area   TYPE string.
    DATA server TYPE string.

ENDCLASS.


CLASS zcl_mcp2_config IMPLEMENTATION.

  METHOD constructor.
    area   = area_name.
    server = server_name.
  ENDMETHOD.

  METHOD get_allowed_origins.
    SELECT origin FROM zmcp2_origins
      WHERE area   = @area
        AND server = @server
      ORDER BY PRIMARY KEY
      INTO TABLE @result.
    IF sy-subrc = 0.
      RETURN.
    ENDIF.

    SELECT origin FROM zmcp2_origins
      WHERE area   = @area
        AND server = '*'
      ORDER BY PRIMARY KEY
      INTO TABLE @result.
    IF sy-subrc = 0.
      RETURN.
    ENDIF.

    SELECT origin FROM zmcp2_origins
      WHERE area   = '*'
        AND server = @server
      ORDER BY PRIMARY KEY
      INTO TABLE @result.
    IF sy-subrc = 0.
      RETURN.
    ENDIF.

    SELECT origin FROM zmcp2_origins
      WHERE area   = '*'
        AND server = '*'
      ORDER BY PRIMARY KEY
      INTO TABLE @result.
    IF sy-subrc = 0.
      RETURN.
    ENDIF.

    " No configured origins: deny all (empty list).
    " Add a wildcard * or explicit origins in zmcp2_origins to allow requests.
  ENDMETHOD.

  METHOD get_cors_mode.
    SELECT SINGLE cors_mode FROM zmcp2_config
      INTO @result.
    IF sy-subrc <> 0 OR result IS INITIAL.
      result = cors_mode_check.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
