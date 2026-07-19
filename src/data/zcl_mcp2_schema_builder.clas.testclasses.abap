CLASS ltcl_schema_builder DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.

  PUBLIC SECTION.
    METHODS test_simple_string        FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_required_array       FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_enum_values          FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_string_lengths       FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_number_minmax        FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_integer_minmax       FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_boolean_property     FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_nested_object        FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_array_property       FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_x_mcp_header         FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_chaining             FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_empty_schema         FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_closed_and_pattern   FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_string_array         FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_zero_bounds          FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_slash_property       FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_duplicate_rejected   FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_unclosed_rejected    FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_empty_name_rejected  FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_string_bounds_validation  FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_number_bounds_validation  FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_integer_bounds_validation FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_array_bounds_validation   FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_str_arr_bounds_invalid FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_number_bounds_absent FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_end_obj_at_root_reject FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_end_arr_at_root_reject  FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_mismatched_end_object       FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_mismatched_end_array        FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_deep_nesting                FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_redirect_all_prop_types FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_array_items_addl_props FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_nested_required_flush       FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_same_name_diff_scopes  FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_continue_after_end_object   FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_fluent_nested_chaining      FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_titles                      FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_defaults                    FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_falsy_defaults_kept         FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_defaults_absent             FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_primitive_arrays            FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_prim_array_nested           FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_prim_array_bounds_invalid   FOR TESTING RAISING zcx_mcp2_ajson_error.

ENDCLASS.

CLASS ltcl_schema_builder IMPLEMENTATION.

  METHOD test_simple_string.
    DATA builder TYPE REF TO zcl_mcp2_schema_builder.
    builder = NEW #( ).
    builder->add_string( name        = `reason`
                         description = `A reason` ).
    DATA(json) = zcl_mcp2_ajson=>parse( builder->to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `object`
                                        act = json->get_string( '/type' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `string`
                                        act = json->get_string( '/properties/reason/type' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `A reason`
                                        act = json->get_string( '/properties/reason/description' ) ).
    cl_abap_unit_assert=>assert_false( json->exists( '/required' ) ).
  ENDMETHOD.

  METHOD test_required_array.
    DATA builder TYPE REF TO zcl_mcp2_schema_builder.
    builder = NEW #( ).
    builder->add_string( name     = `name`
                         required = abap_true ).
    builder->add_string( `comment` ).
    DATA(json) = zcl_mcp2_ajson=>parse( builder->to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `name`
                                        act = json->get_string( '/required/1' ) ).
    cl_abap_unit_assert=>assert_false( json->exists( '/required/2' ) ).
  ENDMETHOD.

  METHOD test_enum_values.
    DATA builder TYPE REF TO zcl_mcp2_schema_builder.
    DATA enum TYPE zcl_mcp2_schema_builder=>enum_values.
    APPEND `red`   TO enum.
    APPEND `green` TO enum.
    builder = NEW #( ).
    builder->add_string( name = `color`
                         enum = enum ).
    DATA(json) = zcl_mcp2_ajson=>parse( builder->to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `red`
                                        act = json->get_string( '/properties/color/enum/1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `green`
                                        act = json->get_string( '/properties/color/enum/2' ) ).
  ENDMETHOD.

  METHOD test_string_lengths.
    DATA builder TYPE REF TO zcl_mcp2_schema_builder.
    builder = NEW #( ).
    builder->add_string( name       = `code`
                         min_length = 1
                         max_length = 10 ).
    DATA(json) = zcl_mcp2_ajson=>parse( builder->to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = json->get_integer( '/properties/code/minLength' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 10
                                        act = json->get_integer( '/properties/code/maxLength' ) ).
  ENDMETHOD.

  METHOD test_number_minmax.
    DATA builder TYPE REF TO zcl_mcp2_schema_builder.
    builder = NEW #( ).
    builder->add_number( name    = `price`
                         minimum = '0.0'
                         maximum = '999.99' ).
    DATA(json) = zcl_mcp2_ajson=>parse( builder->to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `number`
                                        act = json->get_string( '/properties/price/type' ) ).
    cl_abap_unit_assert=>assert_true( json->exists( '/properties/price/minimum' ) ).
    cl_abap_unit_assert=>assert_true( json->exists( '/properties/price/maximum' ) ).
  ENDMETHOD.

  METHOD test_integer_minmax.
    DATA builder TYPE REF TO zcl_mcp2_schema_builder.
    builder = NEW #( ).
    builder->add_integer( name    = `qty`
                          minimum = 0
                          maximum = 100 ).
    DATA(json) = zcl_mcp2_ajson=>parse( builder->to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `integer`
                                        act = json->get_string( '/properties/qty/type' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = json->get_integer( '/properties/qty/minimum' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 100
                                        act = json->get_integer( '/properties/qty/maximum' ) ).
  ENDMETHOD.

  METHOD test_boolean_property.
    DATA builder TYPE REF TO zcl_mcp2_schema_builder.
    builder = NEW #( ).
    builder->add_boolean( `active` ).
    DATA(json) = zcl_mcp2_ajson=>parse( builder->to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `boolean`
                                        act = json->get_string( '/properties/active/type' ) ).
  ENDMETHOD.

  METHOD test_nested_object.
    DATA builder TYPE REF TO zcl_mcp2_schema_builder.
    builder = NEW #( ).
    builder->begin_object( `address` ).
    builder->add_string( `city` ).
    builder->end_object( ).
    DATA(json) = zcl_mcp2_ajson=>parse( builder->to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `object`
                                        act = json->get_string( '/properties/address/type' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `string`
                                        act = json->get_string( '/properties/address/properties/city/type' ) ).
  ENDMETHOD.

  METHOD test_array_property.
    DATA builder TYPE REF TO zcl_mcp2_schema_builder.
    builder = NEW #( ).
    builder->begin_array( name      = `items`
                          min_items = 1 ).
    builder->add_string( `label` ).
    builder->end_array( ).
    DATA(json) = zcl_mcp2_ajson=>parse( builder->to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `array`
                                        act = json->get_string( '/properties/items/type' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = json->get_integer( '/properties/items/minItems' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `object`
                                        act = json->get_string( '/properties/items/items/type' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `string`
                                        act = json->get_string( '/properties/items/items/properties/label/type' ) ).
  ENDMETHOD.

  METHOD test_x_mcp_header.
    DATA builder TYPE REF TO zcl_mcp2_schema_builder.
    builder = NEW #( ).
    builder->add_string( name        = `reason`
                         x_mcp_header = `Reason` ).
    DATA(json) = zcl_mcp2_ajson=>parse( builder->to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `Reason`
                                        act = json->get_string( '/properties/reason/x-mcp-header' ) ).
  ENDMETHOD.

  METHOD test_chaining.
    DATA builder TYPE REF TO zcl_mcp2_schema_builder.
    builder = NEW #( ).
    builder->add_string( name = `a` )->add_string( name = `b` )->add_integer( name = `c` ).
    DATA(json) = zcl_mcp2_ajson=>parse( builder->to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_true( json->exists( '/properties/a' ) ).
    cl_abap_unit_assert=>assert_true( json->exists( '/properties/b' ) ).
    cl_abap_unit_assert=>assert_true( json->exists( '/properties/c' ) ).
  ENDMETHOD.

  METHOD test_empty_schema.
    DATA builder TYPE REF TO zcl_mcp2_schema_builder.
    builder = NEW #( ).
    DATA(json) = zcl_mcp2_ajson=>parse( builder->to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `object`
                                        act = json->get_string( '/type' ) ).
    cl_abap_unit_assert=>assert_false( json->exists( '/properties' ) ).
  ENDMETHOD.

  METHOD test_closed_and_pattern.
    DATA builder TYPE REF TO zcl_mcp2_schema_builder.
    builder = NEW #( additional_properties = abap_false ).
    builder->add_string( name = `code` pattern = `^[A-Z]+$` ).
    DATA(json) = builder->to_json( ).
    cl_abap_unit_assert=>assert_false( json->get_boolean( '/additionalProperties' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `^[A-Z]+$`
                                        act = json->get_string( '/properties/code/pattern' ) ).
  ENDMETHOD.

  METHOD test_string_array.
    DATA(json) = NEW zcl_mcp2_schema_builder(
      )->add_string_array( name = `values` min_items = 0 max_items = 2
                           item_pattern = `^[0-9]+$`
      )->to_json( ).
    cl_abap_unit_assert=>assert_equals( exp = `string`
                                        act = json->get_string( '/properties/values/items/type' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = json->get_integer( '/properties/values/minItems' ) ).
  ENDMETHOD.

  METHOD test_zero_bounds.
    DATA(json) = NEW zcl_mcp2_schema_builder(
      )->add_string( name = `empty` min_length = 0 max_length = 0
      )->to_json( ).
    cl_abap_unit_assert=>assert_true( json->exists( '/properties/empty/minLength' ) ).
    cl_abap_unit_assert=>assert_true( json->exists( '/properties/empty/maxLength' ) ).
  ENDMETHOD.

  METHOD test_slash_property.
    DATA(json) = NEW zcl_mcp2_schema_builder(
      )->add_string( name = `a/b` required = abap_true
      )->to_json( ).
    DATA(path) = '/properties/a' && cl_abap_char_utilities=>horizontal_tab && 'b/type'.
    cl_abap_unit_assert=>assert_equals( exp = `string` act = json->get_string( path ) ).
    cl_abap_unit_assert=>assert_equals( exp = `a/b` act = json->get_string( '/required/1' ) ).
  ENDMETHOD.

  METHOD test_duplicate_rejected.
    DATA(builder) = NEW zcl_mcp2_schema_builder( ).
    builder->add_string( `same` ).
    TRY.
        builder->add_integer( `same` ).
        cl_abap_unit_assert=>fail( `Expected duplicate property rejection` ) ##NO_TEXT.
      CATCH zcx_mcp2_ajson_error.
    ENDTRY.
  ENDMETHOD.

  METHOD test_unclosed_rejected.
    DATA(builder) = NEW zcl_mcp2_schema_builder( ).
    builder->begin_object( `nested` ).
    TRY.
        builder->to_json( ).
        cl_abap_unit_assert=>fail( `Expected unclosed object rejection` ) ##NO_TEXT.
      CATCH zcx_mcp2_ajson_error.
    ENDTRY.
  ENDMETHOD.

  METHOD test_empty_name_rejected.
    TRY.
        NEW zcl_mcp2_schema_builder( )->add_string( name = `` ).
        cl_abap_unit_assert=>fail( `Expected empty name rejection` ) ##NO_TEXT.
      CATCH zcx_mcp2_ajson_error.
    ENDTRY.
  ENDMETHOD.

  METHOD test_string_bounds_validation.
    TRY.
        NEW zcl_mcp2_schema_builder( )->add_string( name = `a` min_length = -1 ).
        cl_abap_unit_assert=>fail( `Expected negative minLength rejection` ) ##NO_TEXT.
      CATCH zcx_mcp2_ajson_error.
    ENDTRY.
    TRY.
        NEW zcl_mcp2_schema_builder( )->add_string( name = `a` max_length = -1 ).
        cl_abap_unit_assert=>fail( `Expected negative maxLength rejection` ) ##NO_TEXT.
      CATCH zcx_mcp2_ajson_error.
    ENDTRY.
    TRY.
        NEW zcl_mcp2_schema_builder( )->add_string( name = `a` min_length = 5 max_length = 1 ).
        cl_abap_unit_assert=>fail( `Expected minLength > maxLength rejection` ) ##NO_TEXT.
      CATCH zcx_mcp2_ajson_error.
    ENDTRY.
  ENDMETHOD.

  METHOD test_number_bounds_validation.
    TRY.
        NEW zcl_mcp2_schema_builder( )->add_number( name = `n` minimum = '10.0' maximum = '1.0' ).
        cl_abap_unit_assert=>fail( `Expected minimum > maximum rejection` ) ##NO_TEXT.
      CATCH zcx_mcp2_ajson_error.
    ENDTRY.
  ENDMETHOD.

  METHOD test_integer_bounds_validation.
    TRY.
        NEW zcl_mcp2_schema_builder( )->add_integer( name = `n` minimum = 10 maximum = 1 ).
        cl_abap_unit_assert=>fail( `Expected minimum > maximum rejection` ) ##NO_TEXT.
      CATCH zcx_mcp2_ajson_error.
    ENDTRY.
  ENDMETHOD.

  METHOD test_array_bounds_validation.
    TRY.
        NEW zcl_mcp2_schema_builder( )->begin_array( name = `a` min_items = -1 ).
        cl_abap_unit_assert=>fail( `Expected negative minItems rejection` ) ##NO_TEXT.
      CATCH zcx_mcp2_ajson_error.
    ENDTRY.
    TRY.
        NEW zcl_mcp2_schema_builder( )->begin_array( name = `a` max_items = -1 ).
        cl_abap_unit_assert=>fail( `Expected negative maxItems rejection` ) ##NO_TEXT.
      CATCH zcx_mcp2_ajson_error.
    ENDTRY.
    TRY.
        NEW zcl_mcp2_schema_builder( )->begin_array( name = `a` min_items = 5 max_items = 1 ).
        cl_abap_unit_assert=>fail( `Expected minItems > maxItems rejection` ) ##NO_TEXT.
      CATCH zcx_mcp2_ajson_error.
    ENDTRY.
  ENDMETHOD.

  METHOD test_str_arr_bounds_invalid.
    TRY.
        NEW zcl_mcp2_schema_builder( )->add_string_array( name = `a` min_items = 5 max_items = 1 ).
        cl_abap_unit_assert=>fail( `Expected minItems > maxItems rejection` ) ##NO_TEXT.
      CATCH zcx_mcp2_ajson_error.
    ENDTRY.
  ENDMETHOD.

  METHOD test_number_bounds_absent.
    " Unsupplied minimum/maximum must not appear at all (distinct from 0).
    DATA(json) = NEW zcl_mcp2_schema_builder(
      )->add_number( name = `price`
      )->to_json( ).
    cl_abap_unit_assert=>assert_false( json->exists( '/properties/price/minimum' ) ).
    cl_abap_unit_assert=>assert_false( json->exists( '/properties/price/maximum' ) ).
  ENDMETHOD.

  METHOD test_end_obj_at_root_reject.
    DATA(builder) = NEW zcl_mcp2_schema_builder( ).
    TRY.
        builder->end_object( ).
        cl_abap_unit_assert=>fail( `Expected end_object at root rejection` ) ##NO_TEXT.
      CATCH zcx_mcp2_ajson_error.
    ENDTRY.
  ENDMETHOD.

  METHOD test_end_arr_at_root_reject.
    DATA(builder) = NEW zcl_mcp2_schema_builder( ).
    TRY.
        builder->end_array( ).
        cl_abap_unit_assert=>fail( `Expected end_array at root rejection` ) ##NO_TEXT.
      CATCH zcx_mcp2_ajson_error.
    ENDTRY.
  ENDMETHOD.

  METHOD test_mismatched_end_object.
    " end_object on an array node must be rejected - node_type mismatch.
    DATA(builder) = NEW zcl_mcp2_schema_builder( ).
    DATA(child) = builder->begin_array( `list` ).
    TRY.
        child->end_object( ).
        cl_abap_unit_assert=>fail( `Expected end_object-on-array rejection` ) ##NO_TEXT.
      CATCH zcx_mcp2_ajson_error.
    ENDTRY.
  ENDMETHOD.

  METHOD test_mismatched_end_array.
    " end_array on an object node must be rejected - node_type mismatch.
    DATA(builder) = NEW zcl_mcp2_schema_builder( ).
    DATA(child) = builder->begin_object( `obj` ).
    TRY.
        child->end_array( ).
        cl_abap_unit_assert=>fail( `Expected end_array-on-object rejection` ) ##NO_TEXT.
      CATCH zcx_mcp2_ajson_error.
    ENDTRY.
  ENDMETHOD.

  METHOD test_deep_nesting.
    " object -> array -> object, all mutated through the original root
    " reference to exercise multi-level active-builder redirection.
    DATA builder TYPE REF TO zcl_mcp2_schema_builder.
    builder = NEW #( ).
    builder->begin_object( `outer` ).
    builder->begin_array( `items` ).
    builder->begin_object( `entry` ).
    builder->add_string( name = `id` required = abap_true ).
    builder->end_object( ).
    builder->end_array( ).
    builder->end_object( ).
    DATA(json) = zcl_mcp2_ajson=>parse( builder->to_json( )->stringify( ) ).
    DATA(p) = `/properties/outer/properties/items/items/properties/entry/properties/id`.
    cl_abap_unit_assert=>assert_equals( exp = `string`
                                        act = json->get_string( |{ p }/type| ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = `id`
      act = json->get_string(
        `/properties/outer/properties/items/items/properties/entry/required/1` ) ).
  ENDMETHOD.

  METHOD test_redirect_all_prop_types.
    " Every property-adding method must redirect correctly through the root
    " reference while a nested object is active - not just add_string.
    DATA builder TYPE REF TO zcl_mcp2_schema_builder.
    builder = NEW #( ).
    builder->begin_object( `meta` ).
    builder->add_number( name = `score` minimum = '0.0' maximum = '10.0' ).
    builder->add_integer( name = `count` minimum = 0 ).
    builder->add_boolean( `flag` ).
    builder->begin_array( `tags` ).
    builder->add_string( `label` ).
    builder->end_array( ).
    builder->add_string_array( `codes` ).
    builder->end_object( ).
    DATA(json) = zcl_mcp2_ajson=>parse( builder->to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `number`
                                        act = json->get_string( '/properties/meta/properties/score/type' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `integer`
                                        act = json->get_string( '/properties/meta/properties/count/type' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `boolean`
                                        act = json->get_string( '/properties/meta/properties/flag/type' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `array`
                                        act = json->get_string( '/properties/meta/properties/tags/type' ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = `string`
      act = json->get_string( '/properties/meta/properties/tags/items/properties/label/type' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `array`
                                        act = json->get_string( '/properties/meta/properties/codes/type' ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = `string`
      act = json->get_string( '/properties/meta/properties/codes/items/type' ) ).
  ENDMETHOD.

  METHOD test_array_items_addl_props.
    DATA(json) = NEW zcl_mcp2_schema_builder(
      )->begin_array( name = `rows` additional_properties = abap_false
      )->add_string( `label`
      )->end_array(
      )->to_json( ).
    cl_abap_unit_assert=>assert_false( json->get_boolean( '/properties/rows/items/additionalProperties' ) ).
  ENDMETHOD.

  METHOD test_nested_required_flush.
    " required tracked inside a nested object must flush to that object's
    " own /required, not the schema root's.
    DATA(json) = NEW zcl_mcp2_schema_builder(
      )->begin_object( `address`
      )->add_string( name = `city` required = abap_true
      )->add_string( name = `zip`
      )->end_object(
      )->to_json( ).
    cl_abap_unit_assert=>assert_equals( exp = `city`
                                        act = json->get_string( '/properties/address/required/1' ) ).
    cl_abap_unit_assert=>assert_false( json->exists( '/properties/address/required/2' ) ).
    cl_abap_unit_assert=>assert_false( json->exists( '/required' ) ).
  ENDMETHOD.

  METHOD test_same_name_diff_scopes.
    " property_names is tracked per builder instance, so the same name may
    " reappear in a nested object without tripping the duplicate check.
    DATA(json) = NEW zcl_mcp2_schema_builder(
      )->add_string( name = `name`
      )->begin_object( `nested`
      )->add_string( name = `name`
      )->end_object(
      )->to_json( ).
    cl_abap_unit_assert=>assert_equals( exp = `string`
                                        act = json->get_string( '/properties/name/type' ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = `string`
      act = json->get_string( '/properties/nested/properties/name/type' ) ).
  ENDMETHOD.

  METHOD test_continue_after_end_object.
    " Once end_object returns control to the parent, further properties must
    " land at the parent level, not leak into the closed child.
    DATA(json) = NEW zcl_mcp2_schema_builder(
      )->begin_object( `nested`
      )->add_string( `inner`
      )->end_object(
      )->add_string( `outer`
      )->to_json( ).
    cl_abap_unit_assert=>assert_true( json->exists( '/properties/outer' ) ).
    cl_abap_unit_assert=>assert_false( json->exists( '/properties/nested/properties/outer' ) ).
  ENDMETHOD.

  METHOD test_fluent_nested_chaining.
    " Build purely through chained return values (never holding the root
    " reference) across object -> array -> back to root.
    DATA(json) = NEW zcl_mcp2_schema_builder(
      )->begin_object( `outer`
      )->add_string( `note`
      )->begin_array( `list`
      )->add_integer( `n`
      )->end_array(
      )->end_object(
      )->add_boolean( `done`
      )->to_json( ).
    cl_abap_unit_assert=>assert_equals( exp = `string`
                                        act = json->get_string( '/properties/outer/properties/note/type' ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = `integer`
      act = json->get_string( '/properties/outer/properties/list/items/properties/n/type' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `boolean`
                                        act = json->get_string( '/properties/done/type' ) ).
  ENDMETHOD.

  METHOD test_titles.
    DATA(json) = NEW zcl_mcp2_schema_builder(
      )->add_string(  name = `customer` title = `Customer`
      )->add_integer( name = `qty`      title = `Quantity`
      )->add_number(  name = `rate`     title = `Rate`
      )->add_boolean( name = `express`  title = `Express`
      )->add_string_array( name = `tags` title = `Tags`
      )->begin_object( name = `addr` title = `Address`
      )->end_object(
      )->to_json( ).
    cl_abap_unit_assert=>assert_equals( exp = `Customer`
                                        act = json->get_string( '/properties/customer/title' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `Quantity`
                                        act = json->get_string( '/properties/qty/title' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `Rate`
                                        act = json->get_string( '/properties/rate/title' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `Express`
                                        act = json->get_string( '/properties/express/title' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `Tags`
                                        act = json->get_string( '/properties/tags/title' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `Address`
                                        act = json->get_string( '/properties/addr/title' ) ).
  ENDMETHOD.

  METHOD test_defaults.
    DATA(json) = NEW zcl_mcp2_schema_builder(
      )->add_string(  name = `mode` default = `fast`
      )->add_integer( name = `qty`  default = 5
      )->add_boolean( name = `express` default = abap_true
      )->to_json( ).
    cl_abap_unit_assert=>assert_equals( exp = `fast`
                                        act = json->get_string( '/properties/mode/default' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 5
                                        act = json->get_integer( '/properties/qty/default' ) ).
    cl_abap_unit_assert=>assert_equals( exp = abap_true
                                        act = json->get_boolean( '/properties/express/default' ) ).
  ENDMETHOD.

  METHOD test_falsy_defaults_kept.
    " 0 / false / empty are meaningful defaults - they must not be dropped
    " by ajson's ignore_empty handling.
    DATA(json) = NEW zcl_mcp2_schema_builder(
      )->add_integer( name = `offset` default = 0
      )->add_boolean( name = `debug`  default = abap_false
      )->add_string(  name = `prefix` default = ``
      )->to_json( ).
    cl_abap_unit_assert=>assert_true( json->exists( '/properties/offset/default' ) ).
    cl_abap_unit_assert=>assert_true( json->exists( '/properties/debug/default' ) ).
    cl_abap_unit_assert=>assert_true( json->exists( '/properties/prefix/default' ) ).
    cl_abap_unit_assert=>assert_equals( exp = abap_false
                                        act = json->get_boolean( '/properties/debug/default' ) ).
  ENDMETHOD.

  METHOD test_defaults_absent.
    " No default supplied -> no default key at all.
    DATA(json) = NEW zcl_mcp2_schema_builder(
      )->add_integer( name = `qty`
      )->add_boolean( name = `debug`
      )->to_json( ).
    cl_abap_unit_assert=>assert_false( json->exists( '/properties/qty/default' ) ).
    cl_abap_unit_assert=>assert_false( json->exists( '/properties/debug/default' ) ).
  ENDMETHOD.

  METHOD test_primitive_arrays.
    DATA(json) = NEW zcl_mcp2_schema_builder(
      )->add_integer_array( name = `ids`    min_items = 1
      )->add_number_array(  name = `rates`
      )->add_boolean_array( name = `flags`  max_items = 3
      )->to_json( ).
    cl_abap_unit_assert=>assert_equals( exp = `array`
                                        act = json->get_string( '/properties/ids/type' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `integer`
                                        act = json->get_string( '/properties/ids/items/type' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `number`
                                        act = json->get_string( '/properties/rates/items/type' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `boolean`
                                        act = json->get_string( '/properties/flags/items/type' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = json->get_integer( '/properties/ids/minItems' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 3
                                        act = json->get_integer( '/properties/flags/maxItems' ) ).
  ENDMETHOD.

  METHOD test_prim_array_nested.
    " The active-builder redirect must reach primitive arrays inside objects.
    DATA(json) = NEW zcl_mcp2_schema_builder(
      )->begin_object( `filter`
      )->add_integer_array( name = `plants`
      )->end_object(
      )->to_json( ).
    cl_abap_unit_assert=>assert_equals(
      exp = `integer`
      act = json->get_string( '/properties/filter/properties/plants/items/type' ) ).
  ENDMETHOD.

  METHOD test_prim_array_bounds_invalid.
    TRY.
        NEW zcl_mcp2_schema_builder(
          )->add_integer_array( name = `ids` min_items = 5 max_items = 2 ).
        cl_abap_unit_assert=>fail( `minItems > maxItems must be rejected` ).
      CATCH zcx_mcp2_ajson_error.
        " expected
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
