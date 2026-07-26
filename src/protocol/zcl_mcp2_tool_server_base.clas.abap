"! <p class="shorttext synchronized">MCP2 tool-catalog server base</p>
"! Convenience base for servers whose primary surface is tools.
"! Subclasses declare the tool catalog once and implement call_tool; this base
"! derives tools/list, get_tool_schema, supports_tools and validation policy.
CLASS zcl_mcp2_tool_server_base DEFINITION
  PUBLIC
  INHERITING FROM zcl_mcp2_server_base ABSTRACT
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS zif_mcp2_server~supports_tools      REDEFINITION.
    METHODS zif_mcp2_server~tools_list          REDEFINITION.
    METHODS zif_mcp2_server~tools_call          REDEFINITION.
    METHODS zif_mcp2_server~get_tool_schema     REDEFINITION.
    METHODS zif_mcp2_server~validate_tool_input REDEFINITION.

  PROTECTED SECTION.
    TYPES tool      TYPE zcl_mcp2_resp_list_tools=>tool.
    TYPES tool_list TYPE zcl_mcp2_resp_list_tools=>tool_list.

    "! <p class="shorttext synchronized">Declare all tools served by this server</p>
    "! The returned metadata is used for tools/list, schema lookup, header
    "! mirroring and argument validation.
    "! @parameter result               | Tool catalog
    "! @raising   zcx_mcp2_ajson_error | JSON schema build failure
    METHODS define_tools ABSTRACT
      RETURNING VALUE(result) TYPE tool_list
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Handle one declared tools/call</p>
    "! Called only after the requested tool name exists in define_tools.
    "! @parameter request              | Parsed tools/call request
    "! @parameter result               | Tool, input_required or task result
    "! @raising   zcx_mcp2_error       | Protocol or application error
    "! @raising   zcx_mcp2_ajson_error | JSON build/parse failure
    METHODS call_tool ABSTRACT
      IMPORTING !request      TYPE REF TO zcl_mcp2_req_call_tool
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_result
      RAISING   zcx_mcp2_error
                zcx_mcp2_ajson_error ##NEEDED.

    "! <p class="shorttext synchronized">Whether catalog schemas validate input</p>
    "! Default true: advertised-schema violations become isError tool results
    "! in both eras. Redefine to abap_false if handlers validate.
    "! @parameter result | abap_true to validate against the catalog schemas
    METHODS tool_input_validation_enabled
      RETURNING VALUE(result) TYPE abap_bool.

  PRIVATE SECTION.
    DATA tool_catalog   TYPE tool_list.
    DATA catalog_loaded TYPE abap_bool.

    "! <p class="shorttext synchronized">Lazily build and cache the tool catalog</p>
    "! @parameter result               | Tool catalog (built once via define_tools)
    "! @raising   zcx_mcp2_ajson_error | JSON schema build failure
    METHODS get_catalog
      RETURNING VALUE(result) TYPE tool_list
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Find a tool by name in the catalog</p>
    "! @parameter tool_name            | Tool name to look up
    "! @parameter found                | abap_true when a matching tool exists
    "! @parameter tool                 | The matching tool, or cleared when not found
    "! @raising   zcx_mcp2_ajson_error | JSON schema build failure
    METHODS find_tool
      IMPORTING tool_name TYPE string
      EXPORTING !found    TYPE abap_bool
                tool      TYPE tool
      RAISING   zcx_mcp2_ajson_error.

ENDCLASS.


CLASS zcl_mcp2_tool_server_base IMPLEMENTATION.
  METHOD zif_mcp2_server~supports_tools.
    result = abap_true.
  ENDMETHOD.

  METHOD zif_mcp2_server~tools_list.
    DATA(response) = NEW zcl_mcp2_resp_list_tools( ).
    DATA(tools) = get_catalog( ).

    LOOP AT tools INTO DATA(tool).
      response->add_tool( tool ).
    ENDLOOP.

    result = response.
  ENDMETHOD.

  METHOD zif_mcp2_server~tools_call.
    DATA found TYPE abap_bool.
    DATA tool  TYPE tool.

    find_tool( EXPORTING tool_name = request->get_name( )
               IMPORTING found     = found
                         tool      = tool ).
    IF found = abap_false.
      zcx_mcp2_error=>raise_invalid_params( |Unknown tool: { request->get_name( ) }| ) ##NO_TEXT.
    ENDIF.

    result = call_tool( request ).
  ENDMETHOD.

  METHOD zif_mcp2_server~get_tool_schema.
    DATA found TYPE abap_bool.
    DATA tool  TYPE tool.

    find_tool( EXPORTING tool_name = tool_name
               IMPORTING found     = found
                         tool      = tool ).
    IF found = abap_true.
      result = tool-input_schema.
    ENDIF.
  ENDMETHOD.

  METHOD zif_mcp2_server~validate_tool_input.
    result = tool_input_validation_enabled( ).
  ENDMETHOD.

  METHOD tool_input_validation_enabled.
    result = abap_true.
  ENDMETHOD.

  METHOD get_catalog.
    IF catalog_loaded = abap_false.
      tool_catalog = define_tools( ).
      catalog_loaded = abap_true.
    ENDIF.
    result = tool_catalog.
  ENDMETHOD.

  METHOD find_tool.
    DATA(tools) = get_catalog( ).
    LOOP AT tools INTO tool WHERE name = tool_name.
      found = abap_true.
      RETURN.
    ENDLOOP.
    CLEAR tool.
    found = abap_false.
  ENDMETHOD.
ENDCLASS.
