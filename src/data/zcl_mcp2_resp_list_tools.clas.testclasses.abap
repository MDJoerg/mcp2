CLASS ltcl_resp_list_tools DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.
  PUBLIC SECTION.
    METHODS test_empty_list          FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_single_tool         FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_with_cursor         FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_icons               FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_readonly_annotation FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_destructive_false   FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_default_input_schema FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_output_schema        FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_annotation_title     FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_idempotent_annot     FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_task_support         FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_open_world_false     FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_result_type          FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_set_cache            FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
ENDCLASS.

CLASS ltcl_resp_list_tools IMPLEMENTATION.

  METHOD test_empty_list.
    DATA resp TYPE REF TO zcl_mcp2_resp_list_tools.
    resp = NEW #( ).
    DATA(json) = resp->zif_mcp2_result~to_json( ).
    cl_abap_unit_assert=>assert_true( json->exists( '/tools' ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = 0
      act = lines( json->members( '/tools' ) ) ).
  ENDMETHOD.


  METHOD test_single_tool.
    DATA resp TYPE REF TO zcl_mcp2_resp_list_tools.
    resp = NEW #( ).

    DATA schema TYPE REF TO zif_mcp2_ajson.
    schema = zcl_mcp2_ajson=>parse( `{"type":"object","properties":{"x":{"type":"number"}}}` ).

    resp->add_tool(
      VALUE #( name        = `calc`
               description = `A calculator`
               input_schema = schema ) ).

    DATA(json) = resp->zif_mcp2_result~to_json( )->stringify( ).
    DATA(parsed) = zcl_mcp2_ajson=>parse( json ).
    cl_abap_unit_assert=>assert_equals( exp = `calc`         act = parsed->get_string( '/tools/1/name' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `A calculator` act = parsed->get_string( '/tools/1/description' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `object`       act = parsed->get_string( '/tools/1/inputSchema/type' ) ).
    cl_abap_unit_assert=>assert_false( parsed->exists( '/nextCursor' ) ).
  ENDMETHOD.


  METHOD test_with_cursor.
    DATA resp TYPE REF TO zcl_mcp2_resp_list_tools.
    resp = NEW #( ).
    resp->add_tool( VALUE #( name = `t1` ) ).
    resp->set_next_cursor( `page2` ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `page2` act = parsed->get_string( '/nextCursor' ) ).
  ENDMETHOD.


  METHOD test_icons.
    DATA resp TYPE REF TO zcl_mcp2_resp_list_tools.
    resp = NEW #( ).
    resp->add_tool(
      VALUE #( name  = `with_icon`
               icons = VALUE #( ( src       = `data:image/png;base64,AA==`
                                  mime_type = `image/png`
                                  theme     = `dark`
                                  sizes     = VALUE #( ( `48x48` ) ( `any` ) ) ) ) ) ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = `data:image/png;base64,AA==`
      act = parsed->get_string( '/tools/1/icons/1/src' ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = `image/png`
      act = parsed->get_string( '/tools/1/icons/1/mimeType' ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = `dark`
      act = parsed->get_string( '/tools/1/icons/1/theme' ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = `48x48`
      act = parsed->get_string( '/tools/1/icons/1/sizes/1' ) ).
  ENDMETHOD.


  METHOD test_readonly_annotation.
    DATA resp TYPE REF TO zcl_mcp2_resp_list_tools.
    resp = NEW #( ).
    resp->add_tool(
      VALUE #( name        = `safe`
               annotations = VALUE #( read_only_hint = abap_true ) ) ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_true(
      parsed->get_boolean( '/tools/1/annotations/readOnlyHint' ) ).
    cl_abap_unit_assert=>assert_false(
      parsed->exists( '/tools/1/annotations/destructiveHint' ) ).
  ENDMETHOD.


  METHOD test_destructive_false.
    DATA resp TYPE REF TO zcl_mcp2_resp_list_tools.
    resp = NEW #( ).
    resp->add_tool(
      VALUE #( name        = `safe`
               annotations = VALUE #( destructive_hint     = abap_false
                                      destructive_hint_set = abap_true ) ) ).
    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    " The node must exist as an explicit boolean false - a missing node would
    " also read as abap_false via get_boolean.
    cl_abap_unit_assert=>assert_equals(
      exp = zif_mcp2_ajson_types=>node_type-boolean
      act = parsed->get_node_type( '/tools/1/annotations/destructiveHint' ) ).
    cl_abap_unit_assert=>assert_false(
      parsed->get_boolean( '/tools/1/annotations/destructiveHint' ) ).
  ENDMETHOD.


  METHOD test_default_input_schema.
    DATA resp TYPE REF TO zcl_mcp2_resp_list_tools.
    resp = NEW #( ).
    resp->add_tool( VALUE #( name = `t` ) ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = `object` act = parsed->get_string( '/tools/1/inputSchema/type' ) ).
  ENDMETHOD.


  METHOD test_output_schema.
    DATA resp TYPE REF TO zcl_mcp2_resp_list_tools.
    resp = NEW #( ).
    resp->add_tool(
      VALUE #( name          = `t`
               output_schema = zcl_mcp2_ajson=>parse(
                 `{"type":"object","properties":{"result":{"type":"string"}}}` ) ) ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = `object` act = parsed->get_string( '/tools/1/outputSchema/type' ) ).
  ENDMETHOD.


  METHOD test_annotation_title.
    DATA resp TYPE REF TO zcl_mcp2_resp_list_tools.
    resp = NEW #( ).
    resp->add_tool(
      VALUE #( name        = `t`
               annotations = VALUE #( title = `My Tool` ) ) ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = `My Tool` act = parsed->get_string( '/tools/1/annotations/title' ) ).
  ENDMETHOD.


  METHOD test_idempotent_annot.
    DATA resp TYPE REF TO zcl_mcp2_resp_list_tools.
    resp = NEW #( ).
    resp->add_tool(
      VALUE #( name        = `t`
               annotations = VALUE #( idempotent_hint = abap_true ) ) ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_true(
      parsed->get_boolean( '/tools/1/annotations/idempotentHint' ) ).
  ENDMETHOD.


  METHOD test_open_world_false.
    DATA resp TYPE REF TO zcl_mcp2_resp_list_tools.
    resp = NEW #( ).
    resp->add_tool(
      VALUE #( name        = `t`
               annotations = VALUE #( open_world_hint     = abap_false
                                      open_world_hint_set = abap_true ) ) ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    " The node must exist as an explicit boolean false - a missing node would
    " also read as abap_false via get_boolean.
    cl_abap_unit_assert=>assert_equals(
      exp = zif_mcp2_ajson_types=>node_type-boolean
      act = parsed->get_node_type( '/tools/1/annotations/openWorldHint' ) ).
    cl_abap_unit_assert=>assert_false(
      parsed->get_boolean( '/tools/1/annotations/openWorldHint' ) ).
  ENDMETHOD.


  METHOD test_result_type.
    DATA resp TYPE REF TO zcl_mcp2_resp_list_tools.
    resp = NEW #( ).
    cl_abap_unit_assert=>assert_equals(
      exp = zif_mcp2_const=>result_types-complete
      act = resp->zif_mcp2_result~result_type( ) ).
  ENDMETHOD.


  METHOD test_set_cache.
    DATA resp TYPE REF TO zcl_mcp2_resp_list_tools.
    resp = NEW #( ).
    resp->set_cache( ttl_ms = 5000 cache_scope = `public` ).
    cl_abap_unit_assert=>assert_equals( exp = 5000     act = resp->zif_mcp2_result~ttl_ms( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `public` act = resp->zif_mcp2_result~cache_scope( ) ).
    " ListToolsResult is a spec CacheableResult - the dispatcher stamps it.
    cl_abap_unit_assert=>assert_true( resp->zif_mcp2_result~is_cacheable( ) ).
  ENDMETHOD.

  METHOD test_task_support.
    " Legacy 2025-11-25 tool-level negotiation: execution.taskSupport.
    DATA resp TYPE REF TO zcl_mcp2_resp_list_tools.
    resp = NEW #( ).
    resp->add_tool( VALUE #( name         = `long_job`
                             task_support = zif_mcp2_const=>task_support-optional ) ).
    resp->add_tool( VALUE #( name = `quick` ) ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = `optional`
      act = parsed->get_string( '/tools/1/execution/taskSupport' ) ).
    cl_abap_unit_assert=>assert_false( parsed->exists( '/tools/2/execution' ) ).
  ENDMETHOD.

ENDCLASS.
