CLASS ltcl_resp_list_prompts DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.
  PUBLIC SECTION.
    METHODS test_empty_list   FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_no_args      FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_with_args    FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_required_arg FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_with_cursor  FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_no_cursor    FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_result_type  FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_set_cache    FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_icons        FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
ENDCLASS.

CLASS ltcl_resp_list_prompts IMPLEMENTATION.
  METHOD test_empty_list.
    DATA resp TYPE REF TO zcl_mcp2_resp_list_prompts.

    resp = NEW #( ).
    DATA(json) = resp->zif_mcp2_result~to_json( ).
    cl_abap_unit_assert=>assert_true( json->exists( '/prompts' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = lines( json->members( '/prompts' ) ) ).
  ENDMETHOD.

  METHOD test_no_args.
    DATA resp TYPE REF TO zcl_mcp2_resp_list_prompts.

    resp = NEW #( ).
    resp->add_prompt( VALUE #( name        = `greet`
                               description = `Greeting prompt`
                               title       = `Greet` ) ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `greet`
                                        act = parsed->get_string( '/prompts/1/name' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `Greeting prompt`
                                        act = parsed->get_string( '/prompts/1/description' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `Greet`
                                        act = parsed->get_string( '/prompts/1/title' ) ).
    cl_abap_unit_assert=>assert_false( parsed->exists( '/prompts/1/arguments' ) ).
  ENDMETHOD.

  METHOD test_with_args.
    DATA resp TYPE REF TO zcl_mcp2_resp_list_prompts.

    resp = NEW #( ).
    resp->add_prompt( VALUE #( name      = `translate`
                               arguments = VALUE #(
                                   ( name = `text` description = `Text to translate` required = abap_true )
                                   ( name = `lang` description = `Target language` ) ) ) ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lines( parsed->members( '/prompts/1/arguments' ) ) ).
    cl_abap_unit_assert=>assert_equals( exp = `text`
                                        act = parsed->get_string( '/prompts/1/arguments/1/name' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `lang`
                                        act = parsed->get_string( '/prompts/1/arguments/2/name' ) ).
  ENDMETHOD.

  METHOD test_required_arg.
    DATA resp TYPE REF TO zcl_mcp2_resp_list_prompts.

    resp = NEW #( ).
    resp->add_prompt( VALUE #( name      = `p1`
                               arguments = VALUE #( ( name = `req`  required = abap_true )
                                                    ( name = `opt`  required = abap_false ) ) ) ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_true( parsed->get_boolean( '/prompts/1/arguments/1/required' ) ).
    cl_abap_unit_assert=>assert_false( parsed->exists( '/prompts/1/arguments/2/required' ) ).
  ENDMETHOD.

  METHOD test_with_cursor.
    DATA resp TYPE REF TO zcl_mcp2_resp_list_prompts.

    resp = NEW #( ).
    resp->add_prompt( VALUE #( name = `p1` ) ).
    resp->set_next_cursor( `page2` ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `page2`
                                        act = parsed->get_string( '/nextCursor' ) ).
  ENDMETHOD.

  METHOD test_no_cursor.
    DATA resp TYPE REF TO zcl_mcp2_resp_list_prompts.

    resp = NEW #( ).
    resp->add_prompt( VALUE #( name = `p1` ) ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_false( parsed->exists( '/nextCursor' ) ).
  ENDMETHOD.

  METHOD test_result_type.
    DATA resp TYPE REF TO zcl_mcp2_resp_list_prompts.

    resp = NEW #( ).
    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>result_types-complete
                                        act = resp->zif_mcp2_result~result_type( ) ).
  ENDMETHOD.

  METHOD test_set_cache.
    DATA resp TYPE REF TO zcl_mcp2_resp_list_prompts.

    resp = NEW #( ).
    resp->set_cache( ttl_ms      = 5000
                     cache_scope = `public` ).
    cl_abap_unit_assert=>assert_equals( exp = 5000
                                        act = resp->zif_mcp2_result~ttl_ms( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `public`
                                        act = resp->zif_mcp2_result~cache_scope( ) ).
  ENDMETHOD.

  METHOD test_icons.
    DATA resp TYPE REF TO zcl_mcp2_resp_list_prompts.

    resp = NEW #( ).
    resp->add_prompt( VALUE #( name  = `fancy`
                               icons = VALUE #( ( src   = `https://example.com/p.png`
                                                  theme = zif_mcp2_const=>icon_themes-light ) ) ) ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `https://example.com/p.png`
                                        act = parsed->get_string( '/prompts/1/icons/1/src' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `light`
                                        act = parsed->get_string( '/prompts/1/icons/1/theme' ) ).
  ENDMETHOD.

ENDCLASS.
