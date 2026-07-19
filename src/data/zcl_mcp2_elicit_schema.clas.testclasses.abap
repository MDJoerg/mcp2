CLASS ltcl_elicit_schema DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.

  PUBLIC SECTION.
    METHODS test_empty_schema      FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_string_full       FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_string_min_zero   FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_number_bounds     FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_integer_zero_dflt FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_integer_bounds    FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_boolean_dflt_false FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_boolean_dflt_true  FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_boolean_no_dflt   FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_single_select     FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_single_sel_no_dflt FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_single_sel_titled FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_multi_select      FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_multi_sel_titled  FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_required_list     FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_fluent_chaining   FOR TESTING RAISING zcx_mcp2_ajson_error.

  PRIVATE SECTION.
    METHODS render
      IMPORTING cut           TYPE REF TO zcl_mcp2_elicit_schema
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_ajson_error.
ENDCLASS.

CLASS ltcl_elicit_schema IMPLEMENTATION.
  METHOD render.
    result = zcl_mcp2_ajson=>parse( cut->to_json( )->stringify( ) ).
  ENDMETHOD.

  METHOD test_empty_schema.
    " A field-less builder still yields a valid empty object schema.
    DATA(parsed) = render( NEW zcl_mcp2_elicit_schema( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `object`
                                        act = parsed->get_string( '/type' ) ).
    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_ajson_types=>node_type-object
                                        act = parsed->get_node_type( '/properties' ) ).
    cl_abap_unit_assert=>assert_false( parsed->exists( '/required' ) ).
  ENDMETHOD.

  METHOD test_string_full.
    DATA(cut) = NEW zcl_mcp2_elicit_schema( ).
    cut->add_string( name        = `email`
                     title       = `E-mail`
                     description = `Work address`
                     format      = zif_mcp2_const=>elicit_formats-email
                     default     = `user@example.com`
                     min_length  = 3
                     max_length  = 64 ).
    DATA(parsed) = render( cut ).
    DATA(p) = `/properties/email`.
    cl_abap_unit_assert=>assert_equals( exp = `string`
                                        act = parsed->get_string( |{ p }/type| ) ).
    cl_abap_unit_assert=>assert_equals( exp = `E-mail`
                                        act = parsed->get_string( |{ p }/title| ) ).
    cl_abap_unit_assert=>assert_equals( exp = `email`
                                        act = parsed->get_string( |{ p }/format| ) ).
    cl_abap_unit_assert=>assert_equals( exp = `user@example.com`
                                        act = parsed->get_string( |{ p }/default| ) ).
    cl_abap_unit_assert=>assert_equals( exp = 3
                                        act = parsed->get_integer( |{ p }/minLength| ) ).
    cl_abap_unit_assert=>assert_equals( exp = 64
                                        act = parsed->get_integer( |{ p }/maxLength| ) ).
  ENDMETHOD.

  METHOD test_string_min_zero.
    " Supplied zero bounds must be emitted, unsupplied ones must not.
    DATA(cut) = NEW zcl_mcp2_elicit_schema( ).
    cut->add_string( name       = `note`
                     min_length = 0 ).
    DATA(parsed) = render( cut ).
    cl_abap_unit_assert=>assert_true( parsed->exists( '/properties/note/minLength' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = parsed->get_integer( '/properties/note/minLength' ) ).
    cl_abap_unit_assert=>assert_false( parsed->exists( '/properties/note/maxLength' ) ).
    cl_abap_unit_assert=>assert_false( parsed->exists( '/properties/note/default' ) ).
    cl_abap_unit_assert=>assert_false( parsed->exists( '/properties/note/format' ) ).
  ENDMETHOD.

  METHOD test_number_bounds.
    DATA(cut) = NEW zcl_mcp2_elicit_schema( ).
    cut->add_number( name    = `score`
                     minimum = 0
                     maximum = 1
                     default = '0.5' ).
    DATA(parsed) = render( cut ).
    cl_abap_unit_assert=>assert_equals( exp = `number`
                                        act = parsed->get_string( '/properties/score/type' ) ).
    " minimum 0 is meaningful and must survive serialization.
    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_ajson_types=>node_type-number
                                        act = parsed->get_node_type( '/properties/score/minimum' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = parsed->get_integer( '/properties/score/minimum' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = parsed->get_integer( '/properties/score/maximum' ) ).
    cl_abap_unit_assert=>assert_equals( exp = '0.5'
                                        act = parsed->get_string( '/properties/score/default' ) ).
  ENDMETHOD.

  METHOD test_integer_zero_dflt.
    DATA(cut) = NEW zcl_mcp2_elicit_schema( ).
    cut->add_integer( name    = `count`
                      default = 0 ).
    DATA(parsed) = render( cut ).
    cl_abap_unit_assert=>assert_equals( exp = `integer`
                                        act = parsed->get_string( '/properties/count/type' ) ).
    cl_abap_unit_assert=>assert_true( parsed->exists( '/properties/count/default' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = parsed->get_integer( '/properties/count/default' ) ).
    cl_abap_unit_assert=>assert_false( parsed->exists( '/properties/count/minimum' ) ).
  ENDMETHOD.

  METHOD test_integer_bounds.
    DATA(cut) = NEW zcl_mcp2_elicit_schema( ).
    cut->add_integer( name    = `age`
                      minimum = 18
                      maximum = 99 ).
    DATA(parsed) = render( cut ).
    cl_abap_unit_assert=>assert_equals( exp = `integer`
                                        act = parsed->get_string( '/properties/age/type' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 18
                                        act = parsed->get_integer( '/properties/age/minimum' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 99
                                        act = parsed->get_integer( '/properties/age/maximum' ) ).
    cl_abap_unit_assert=>assert_false( parsed->exists( '/properties/age/default' ) ).
  ENDMETHOD.

  METHOD test_boolean_dflt_false.
    " default = abap_false must be emitted as an explicit boolean false.
    DATA(cut) = NEW zcl_mcp2_elicit_schema( ).
    cut->add_boolean( name    = `subscribe`
                      default = abap_false ).
    DATA(parsed) = render( cut ).
    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_ajson_types=>node_type-boolean
                                        act = parsed->get_node_type( '/properties/subscribe/default' ) ).
    cl_abap_unit_assert=>assert_false( parsed->get_boolean( '/properties/subscribe/default' ) ).
  ENDMETHOD.

  METHOD test_boolean_dflt_true.
    DATA(cut) = NEW zcl_mcp2_elicit_schema( ).
    cut->add_boolean( name    = `subscribe`
                      default = abap_true ).
    DATA(parsed) = render( cut ).
    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_ajson_types=>node_type-boolean
                                        act = parsed->get_node_type( '/properties/subscribe/default' ) ).
    cl_abap_unit_assert=>assert_true( parsed->get_boolean( '/properties/subscribe/default' ) ).
  ENDMETHOD.

  METHOD test_boolean_no_dflt.
    " Omitted default must not appear in the schema at all.
    DATA(cut) = NEW zcl_mcp2_elicit_schema( ).
    cut->add_boolean( `subscribe` ).
    DATA(parsed) = render( cut ).
    cl_abap_unit_assert=>assert_false( parsed->exists( '/properties/subscribe/default' ) ).
  ENDMETHOD.

  METHOD test_single_select.
    DATA(cut) = NEW zcl_mcp2_elicit_schema( ).
    cut->add_single_select( name    = `color`
                            values  = VALUE #( ( `red` ) ( `green` ) ( `blue` ) )
                            default = `green` ).
    DATA(parsed) = render( cut ).
    DATA(p) = `/properties/color`.
    cl_abap_unit_assert=>assert_equals( exp = `string`
                                        act = parsed->get_string( |{ p }/type| ) ).
    cl_abap_unit_assert=>assert_equals( exp = 3
                                        act = lines( parsed->members( |{ p }/enum| ) ) ).
    cl_abap_unit_assert=>assert_equals( exp = `red`
                                        act = parsed->get_string( |{ p }/enum/1| ) ).
    cl_abap_unit_assert=>assert_equals( exp = `green`
                                        act = parsed->get_string( |{ p }/default| ) ).
  ENDMETHOD.

  METHOD test_single_sel_no_dflt.
    " Omitted default must not appear in the schema at all.
    DATA(cut) = NEW zcl_mcp2_elicit_schema( ).
    cut->add_single_select( name   = `color`
                            values = VALUE #( ( `red` ) ( `green` ) ) ).
    DATA(parsed) = render( cut ).
    cl_abap_unit_assert=>assert_false( parsed->exists( '/properties/color/default' ) ).
  ENDMETHOD.

  METHOD test_single_sel_titled.
    DATA(cut) = NEW zcl_mcp2_elicit_schema( ).
    cut->add_single_select_titled(
        name    = `env`
        options = VALUE #( ( value = `dev`  title = `Development` )
                           ( value = `prod` title = `Production` ) )
        default = `prod` ).
    DATA(parsed) = render( cut ).
    DATA(p) = `/properties/env`.
    cl_abap_unit_assert=>assert_equals( exp = `string`
                                        act = parsed->get_string( |{ p }/type| ) ).
    cl_abap_unit_assert=>assert_equals( exp = `dev`
                                        act = parsed->get_string( |{ p }/oneOf/1/const| ) ).
    cl_abap_unit_assert=>assert_equals( exp = `Development`
                                        act = parsed->get_string( |{ p }/oneOf/1/title| ) ).
    cl_abap_unit_assert=>assert_equals( exp = `Production`
                                        act = parsed->get_string( |{ p }/oneOf/2/title| ) ).
    cl_abap_unit_assert=>assert_equals( exp = `prod`
                                        act = parsed->get_string( |{ p }/default| ) ).
    cl_abap_unit_assert=>assert_false( parsed->exists( |{ p }/enum| ) ).
  ENDMETHOD.

  METHOD test_multi_select.
    DATA(cut) = NEW zcl_mcp2_elicit_schema( ).
    cut->add_multi_select( name      = `toppings`
                           values    = VALUE #( ( `cheese` ) ( `ham` ) )
                           defaults  = VALUE #( ( `cheese` ) )
                           min_items = 1
                           max_items = 2 ).
    DATA(parsed) = render( cut ).
    DATA(p) = `/properties/toppings`.
    cl_abap_unit_assert=>assert_equals( exp = `array`
                                        act = parsed->get_string( |{ p }/type| ) ).
    cl_abap_unit_assert=>assert_equals( exp = `string`
                                        act = parsed->get_string( |{ p }/items/type| ) ).
    cl_abap_unit_assert=>assert_equals( exp = `cheese`
                                        act = parsed->get_string( |{ p }/items/enum/1| ) ).
    cl_abap_unit_assert=>assert_equals( exp = `cheese`
                                        act = parsed->get_string( |{ p }/default/1| ) ).
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = parsed->get_integer( |{ p }/minItems| ) ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = parsed->get_integer( |{ p }/maxItems| ) ).
  ENDMETHOD.

  METHOD test_multi_sel_titled.
    DATA(cut) = NEW zcl_mcp2_elicit_schema( ).
    cut->add_multi_select_titled(
        name      = `channels`
        options   = VALUE #( ( value = `mail` title = `E-mail` )
                             ( value = `sms`  title = `Text message` ) )
        defaults  = VALUE #( ( `mail` ) )
        min_items = 1
        max_items = 2 ).
    DATA(parsed) = render( cut ).
    DATA(p) = `/properties/channels`.
    cl_abap_unit_assert=>assert_equals( exp = `array`
                                        act = parsed->get_string( |{ p }/type| ) ).
    cl_abap_unit_assert=>assert_equals( exp = `mail`
                                        act = parsed->get_string( |{ p }/items/anyOf/1/const| ) ).
    cl_abap_unit_assert=>assert_equals( exp = `Text message`
                                        act = parsed->get_string( |{ p }/items/anyOf/2/title| ) ).
    cl_abap_unit_assert=>assert_equals( exp = `mail`
                                        act = parsed->get_string( |{ p }/default/1| ) ).
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = parsed->get_integer( |{ p }/minItems| ) ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = parsed->get_integer( |{ p }/maxItems| ) ).
  ENDMETHOD.

  METHOD test_required_list.
    DATA(cut) = NEW zcl_mcp2_elicit_schema( ).
    cut->add_string( name     = `reason`
                     required = abap_true ).
    cut->add_boolean( `urgent` ).
    cut->add_integer( name     = `amount`
                      required = abap_true ).
    DATA(parsed) = render( cut ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lines( parsed->members( '/required' ) ) ).
    cl_abap_unit_assert=>assert_equals( exp = `reason`
                                        act = parsed->get_string( '/required/1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `amount`
                                        act = parsed->get_string( '/required/2' ) ).
  ENDMETHOD.

  METHOD test_fluent_chaining.
    DATA(parsed) = render( NEW zcl_mcp2_elicit_schema(
      )->add_string( name = `a`
      )->add_boolean( name = `b`
      )->add_single_select( name   = `c`
                            values = VALUE #( ( `x` ) ) ) ).
    cl_abap_unit_assert=>assert_equals( exp = 3
                                        act = lines( parsed->members( '/properties' ) ) ).
  ENDMETHOD.
ENDCLASS.
