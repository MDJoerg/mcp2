"! <p class="shorttext synchronized">MCP2 server factory</p>
CLASS zcl_mcp2_server_factory DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! <p class="shorttext synchronized">Resolve the configured server instance</p>
    "! Looks up zmcp2_servers and instantiates the registered class.
    "! Unbound means no row is registered; a row whose class cannot be
    "! instantiated or does not implement zif_mcp2_server raises instead, so
    "! misconfiguration is distinguishable from an unknown server.
    "! @parameter area   | ICF service area / application name
    "! @parameter server | Configured MCP server name
    "! @parameter result | The server instance, or unbound when not registered
    "! @raising   zcx_mcp2_error | Registered class is invalid
    CLASS-METHODS get_server
      IMPORTING !area         TYPE string
                server        TYPE string
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_server
      RAISING   zcx_mcp2_error.

ENDCLASS.


CLASS zcl_mcp2_server_factory IMPLEMENTATION.
  METHOD get_server.
    DATA object TYPE REF TO object.

    " Host variables that share a name with a column of the addressed table are
    " read as that column once the downport drops the @ escape - WHERE area =
    " area would then match every row and resolve an arbitrary server class.
    DATA area_arg   TYPE zmcp2_servers-area.
    DATA server_arg TYPE zmcp2_servers-server.
    area_arg   = area.
    server_arg = server.

    SELECT SINGLE class FROM zmcp2_servers
      WHERE area   = @area_arg
        AND server = @server_arg
      INTO @DATA(class_name).
    IF sy-subrc <> 0 OR class_name IS INITIAL.
      RETURN.
    ENDIF.

    TRY.
        CREATE OBJECT object TYPE (class_name).
        result ?= object.
      CATCH cx_sy_create_object_error.
        zcx_mcp2_error=>raise_internal(
          |Registered class { class_name } for { area }/{ server }| &&
          ` cannot be instantiated` ) ##NO_TEXT.
      CATCH cx_sy_move_cast_error.
        zcx_mcp2_error=>raise_internal(
          |Registered class { class_name } for { area }/{ server }| &&
          ` does not implement zif_mcp2_server` ) ##NO_TEXT.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
