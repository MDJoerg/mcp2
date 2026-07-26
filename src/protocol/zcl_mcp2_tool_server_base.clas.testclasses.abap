CLASS ltcl_catalog_server DEFINITION FINAL
  INHERITING FROM zcl_mcp2_tool_server_base.
  PUBLIC SECTION.
    DATA called_name        TYPE string.
    DATA define_tools_calls TYPE i.

    METHODS zif_mcp2_server~get_name    REDEFINITION.
    METHODS zif_mcp2_server~get_version REDEFINITION.

  PROTECTED SECTION.
    METHODS define_tools REDEFINITION.
    METHODS call_tool    REDEFINITION.
ENDCLASS.


CLASS ltcl_catalog_server IMPLEMENTATION.
  METHOD zif_mcp2_server~get_name.
    result = `catalog-test`.
  ENDMETHOD.

  METHOD zif_mcp2_server~get_version.
    result = `1.0.0`.
  ENDMETHOD.

  METHOD define_tools.
    define_tools_calls = define_tools_calls + 1.
    DATA(schema) = NEW zcl_mcp2_schema_builder(
      )->add_string( name     = `message`
                     required = abap_true
      )->to_json( ).
    DATA(noop_schema) = NEW zcl_mcp2_schema_builder( )->to_json( ).
    result = VALUE #( ( name         = `echo`
                        title        = `Echo`
                        description  = `Echoes a message`
                        input_schema = schema )
                      ( name         = `noop`
                        title        = `Noop`
                        description  = `Does nothing`
                        input_schema = noop_schema ) )  ##NO_TEXT.
  ENDMETHOD.

  METHOD call_tool.
    called_name = request->get_name( ).
    result = zcl_mcp2_resp_call_tool=>text( request->require_arg_string( `message` ) ).
  ENDMETHOD.
ENDCLASS.


CLASS ltcl_novalidate_server DEFINITION
  INHERITING FROM zcl_mcp2_tool_server_base FINAL.

  PUBLIC SECTION.
    METHODS zif_mcp2_server~get_name    REDEFINITION.
    METHODS zif_mcp2_server~get_version REDEFINITION.

  PROTECTED SECTION.
    METHODS define_tools                  REDEFINITION.
    METHODS call_tool                     REDEFINITION.
    METHODS tool_input_validation_enabled REDEFINITION.
ENDCLASS.

CLASS ltcl_novalidate_server IMPLEMENTATION.
  METHOD zif_mcp2_server~get_name.
    result = `novalidate-test`.
  ENDMETHOD.

  METHOD zif_mcp2_server~get_version.
    result = `1.0.0`.
  ENDMETHOD.

  METHOD define_tools.
    result = VALUE #( ( name         = `noop`
                        title        = `Noop`
                        input_schema = NEW zcl_mcp2_schema_builder( )->to_json( ) ) )  ##NO_TEXT.
  ENDMETHOD.

  METHOD call_tool.
    result = zcl_mcp2_resp_call_tool=>text( `ok` ).
  ENDMETHOD.

  METHOD tool_input_validation_enabled.
    result = abap_false.
  ENDMETHOD.
ENDCLASS.


CLASS ltcl_raising_server DEFINITION
  INHERITING FROM zcl_mcp2_tool_server_base FINAL.

  PUBLIC SECTION.
    METHODS zif_mcp2_server~get_name REDEFINITION.
    METHODS zif_mcp2_server~get_version REDEFINITION.
  PROTECTED SECTION.
    METHODS define_tools REDEFINITION.
    METHODS call_tool REDEFINITION.
ENDCLASS.

CLASS ltcl_raising_server IMPLEMENTATION.
  METHOD zif_mcp2_server~get_name.
    result = `raising-test`.
  ENDMETHOD.

  METHOD zif_mcp2_server~get_version.
    result = `1.0.0`.
  ENDMETHOD.

  METHOD define_tools.
    zcx_mcp2_ajson_error=>raise( `catalog build failed` ) ##NO_TEXT.
  ENDMETHOD.

  METHOD call_tool.
    result = zcl_mcp2_resp_call_tool=>text( `unreachable` ).
  ENDMETHOD.
ENDCLASS.

CLASS ltcl_tool_server_base DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.
  PRIVATE SECTION.
    METHODS test_supports_tools         FOR TESTING.
    METHODS test_tools_list             FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_schema_lookup          FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_validate_default       FOR TESTING.
    METHODS test_unknown_tool           FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_declared_tool_dispatch FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_catalog_built_once     FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_validation_disabled    FOR TESTING.
    METHODS test_multi_tool_lookup      FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_define_tools_raises    FOR TESTING RAISING zcx_mcp2_error.
ENDCLASS.

CLASS ltcl_tool_server_base IMPLEMENTATION.
  METHOD test_supports_tools.
    DATA(server) = NEW ltcl_catalog_server( ).
    cl_abap_unit_assert=>assert_true( server->zif_mcp2_server~supports_tools( ) ).
  ENDMETHOD.

  METHOD test_tools_list.
    DATA(server) = NEW ltcl_catalog_server( ).
    DATA(result) = server->zif_mcp2_server~tools_list( NEW zcl_mcp2_req_list_tools( zcl_mcp2_ajson=>parse( `{}` ) ) ).
    DATA(json) = result->to_json( ).
    cl_abap_unit_assert=>assert_equals( exp = `echo`
                                        act = json->get_string( '/tools/1/name' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `Echo`
                                        act = json->get_string( '/tools/1/title' ) ).
  ENDMETHOD.

  METHOD test_schema_lookup.
    DATA(server) = NEW ltcl_catalog_server( ).
    DATA(schema) = server->zif_mcp2_server~get_tool_schema( `echo` ).
    cl_abap_unit_assert=>assert_bound( schema ).
    cl_abap_unit_assert=>assert_equals( exp = `string`
                                        act = schema->get_string( '/properties/message/type' ) ).

    DATA(missing) = server->zif_mcp2_server~get_tool_schema( `missing` ).
    cl_abap_unit_assert=>assert_not_bound( missing ).
  ENDMETHOD.

  METHOD test_validate_default.
    DATA(server) = NEW ltcl_catalog_server( ).
    cl_abap_unit_assert=>assert_true( server->zif_mcp2_server~validate_tool_input( ) ).
  ENDMETHOD.

  METHOD test_unknown_tool.
    DATA(server) = NEW ltcl_catalog_server( ).
    DATA(request) = NEW zcl_mcp2_req_call_tool( zcl_mcp2_ajson=>parse( `{"name":"missing","arguments":{}}` ) ).

    TRY.
        server->zif_mcp2_server~tools_call( request ).
        cl_abap_unit_assert=>fail( `Unknown tool must raise` ).
      CATCH zcx_mcp2_error INTO DATA(error).
        cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-invalid_params
                                            act = error->code ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_declared_tool_dispatch.
    DATA(server) = NEW ltcl_catalog_server( ).
    DATA(request) = NEW zcl_mcp2_req_call_tool( zcl_mcp2_ajson=>parse( `{"name":"echo","arguments":{"message":"hi"}}` ) ).

    DATA(result) = server->zif_mcp2_server~tools_call( request ).
    DATA(json) = result->to_json( ).
    cl_abap_unit_assert=>assert_equals( exp = `echo`
                                        act = server->called_name ).
    cl_abap_unit_assert=>assert_equals( exp = `hi`
                                        act = json->get_string( '/content/1/text' ) ).
  ENDMETHOD.

  METHOD test_catalog_built_once.
    " define_tools is only called once and the result cached, no matter how
    " many catalog-driven interface methods are invoked afterward.
    DATA(server) = NEW ltcl_catalog_server( ).
    server->zif_mcp2_server~tools_list( NEW zcl_mcp2_req_list_tools( zcl_mcp2_ajson=>parse( `{}` ) ) ).
    server->zif_mcp2_server~get_tool_schema( `echo` ).
    DATA(request) = NEW zcl_mcp2_req_call_tool( zcl_mcp2_ajson=>parse( `{"name":"echo","arguments":{"message":"hi"}}` ) ).
    server->zif_mcp2_server~tools_call( request ).

    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = server->define_tools_calls ).
  ENDMETHOD.

  METHOD test_validation_disabled.
    DATA(server) = NEW ltcl_novalidate_server( ).
    cl_abap_unit_assert=>assert_false( server->zif_mcp2_server~validate_tool_input( ) ).
  ENDMETHOD.

  METHOD test_multi_tool_lookup.
    DATA(server) = NEW ltcl_catalog_server( ).

    DATA(echo_schema) = server->zif_mcp2_server~get_tool_schema( `echo` ).
    cl_abap_unit_assert=>assert_bound( echo_schema ).

    DATA(noop_schema) = server->zif_mcp2_server~get_tool_schema( `noop` ).
    cl_abap_unit_assert=>assert_bound( noop_schema ).

    " find_tool must scan past both entries without a false match.
    DATA(missing) = server->zif_mcp2_server~get_tool_schema( `missing` ).
    cl_abap_unit_assert=>assert_not_bound( missing ).
  ENDMETHOD.

  METHOD test_define_tools_raises.
    " A catalog-build failure propagates uncaught out of the catalog-driven
    " interface methods rather than being silently swallowed.
    DATA(server) = NEW ltcl_raising_server( ).
    TRY.
        server->zif_mcp2_server~tools_list( NEW zcl_mcp2_req_list_tools( zcl_mcp2_ajson=>parse( `{}` ) ) ).
        cl_abap_unit_assert=>fail( `Expected catalog build failure to propagate` ) ##NO_TEXT.
      CATCH zcx_mcp2_ajson_error.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
