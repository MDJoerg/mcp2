CLASS ltcl_schema_validator DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PUBLIC SECTION.
    METHODS test_valid_object         FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_missing_required     FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_wrong_type           FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_enum_valid           FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_enum_invalid         FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_min_length           FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_max_length           FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_integer_range        FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_nested_object        FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_unbound_json         FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_root_must_object     FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_fraction_integer     FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_closed_object        FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_pattern              FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_invalid_pattern      FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_string_array         FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_slash_property       FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_valorraise_ok        FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_valorraise_fail      FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_valorraise_no_json   FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_unbound_schema       FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_schema_root_not_obj  FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_number_type          FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_number_range         FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_boolean_valid        FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_boolean_mismatch     FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_object_type_mismatch FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_array_type_mismatch  FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_array_min_items      FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_array_max_items      FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_array_items_object   FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_array_items_number   FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_array_item_mismatch  FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_integer_overflow     FOR TESTING RAISING zcx_mcp2_ajson_error.

ENDCLASS.

CLASS ltcl_schema_validator IMPLEMENTATION.
  METHOD test_valid_object.
    DATA(schema) = zcl_mcp2_ajson=>parse(
                       `{"type":"object","properties":{"name":{"type":"string"}},"required":["name"]}` ).
    DATA(json) = zcl_mcp2_ajson=>parse( `{"name":"Alice"}` ).
    DATA(v) = NEW zcl_mcp2_schema_validator( schema ).
    cl_abap_unit_assert=>assert_true( v->validate( json ) ).
    cl_abap_unit_assert=>assert_initial( v->get_errors( ) ).
  ENDMETHOD.

  METHOD test_missing_required.
    DATA(schema) = zcl_mcp2_ajson=>parse(
                       `{"type":"object","properties":{"name":{"type":"string"}},"required":["name"]}` ).
    DATA(json) = zcl_mcp2_ajson=>parse( `{}` ).
    DATA(v) = NEW zcl_mcp2_schema_validator( schema ).
    cl_abap_unit_assert=>assert_false( v->validate( json ) ).
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lines( v->get_errors( ) ) ).
  ENDMETHOD.

  METHOD test_wrong_type.
    DATA(schema) = zcl_mcp2_ajson=>parse( `{"type":"object","properties":{"age":{"type":"integer"}}}` ).
    DATA(json) = zcl_mcp2_ajson=>parse( `{"age":"not-a-number"}` ).
    DATA(v) = NEW zcl_mcp2_schema_validator( schema ).
    cl_abap_unit_assert=>assert_false( v->validate( json ) ).
  ENDMETHOD.

  METHOD test_enum_valid.
    DATA(schema) = zcl_mcp2_ajson=>parse(
      `{"type":"object","properties":{"color":{"type":"string","enum":["red","green"]}}}` ).
    DATA(json)   = zcl_mcp2_ajson=>parse( `{"color":"red"}` ).
    DATA(v) = NEW zcl_mcp2_schema_validator( schema ).
    cl_abap_unit_assert=>assert_true( v->validate( json ) ).
  ENDMETHOD.

  METHOD test_enum_invalid.
    DATA(schema) = zcl_mcp2_ajson=>parse(
                       `{"type":"object","properties":{"color":{"type":"string","enum":["red","green"]}}}` ).
    DATA(json) = zcl_mcp2_ajson=>parse( `{"color":"blue"}` ).
    DATA(v) = NEW zcl_mcp2_schema_validator( schema ).
    cl_abap_unit_assert=>assert_false( v->validate( json ) ).
  ENDMETHOD.

  METHOD test_min_length.
    DATA(schema) = zcl_mcp2_ajson=>parse( `{"type":"object","properties":{"code":{"type":"string","minLength":3}}}` ).
    DATA(json) = zcl_mcp2_ajson=>parse( `{"code":"ab"}` ).
    DATA(v) = NEW zcl_mcp2_schema_validator( schema ).
    cl_abap_unit_assert=>assert_false( v->validate( json ) ).
  ENDMETHOD.

  METHOD test_max_length.
    DATA(schema) = zcl_mcp2_ajson=>parse( `{"type":"object","properties":{"code":{"type":"string","maxLength":5}}}` ).
    DATA(json) = zcl_mcp2_ajson=>parse( `{"code":"toolong"}` ).
    DATA(v) = NEW zcl_mcp2_schema_validator( schema ).
    cl_abap_unit_assert=>assert_false( v->validate( json ) ).
  ENDMETHOD.

  METHOD test_integer_range.
    DATA(schema) = zcl_mcp2_ajson=>parse(
                       `{"type":"object","properties":{"qty":{"type":"integer","minimum":1,"maximum":10}}}` ).
    DATA(json_ok)  = zcl_mcp2_ajson=>parse( `{"qty":5}` ).
    DATA(json_bad) = zcl_mcp2_ajson=>parse( `{"qty":0}` ).
    DATA(v) = NEW zcl_mcp2_schema_validator( schema ).
    cl_abap_unit_assert=>assert_true( v->validate( json_ok ) ).
    v = NEW zcl_mcp2_schema_validator( schema ).
    cl_abap_unit_assert=>assert_false( v->validate( json_bad ) ).
  ENDMETHOD.

  METHOD test_nested_object.
    DATA(schema) = zcl_mcp2_ajson=>parse( |\{| &&
      |"type":"object",| &&
      |"properties":\{"addr":\{"type":"object","properties":\{"city":\{"type":"string"\}\},"required":["city"]\}\}| &&
      |\}| ).
    DATA(json_ok)  = zcl_mcp2_ajson=>parse( `{"addr":{"city":"Berlin"}}` ).
    DATA(json_bad) = zcl_mcp2_ajson=>parse( `{"addr":{}}` ).
    DATA(v) = NEW zcl_mcp2_schema_validator( schema ).
    cl_abap_unit_assert=>assert_true( v->validate( json_ok ) ).
    v = NEW zcl_mcp2_schema_validator( schema ).
    cl_abap_unit_assert=>assert_false( v->validate( json_bad ) ).
  ENDMETHOD.

  METHOD test_unbound_json.
    DATA(schema) = zcl_mcp2_ajson=>parse( `{"type":"object"}` ).
    DATA(v) = NEW zcl_mcp2_schema_validator( schema ).
    DATA unbound TYPE REF TO zif_mcp2_ajson.
    cl_abap_unit_assert=>assert_false( v->validate( unbound ) ).
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lines( v->get_errors( ) ) ).
  ENDMETHOD.

  METHOD test_root_must_object.
    DATA(schema) = zcl_mcp2_ajson=>parse( `{"type":"object"}` ).
    DATA(v) = NEW zcl_mcp2_schema_validator( schema ).
    cl_abap_unit_assert=>assert_false( v->validate( zcl_mcp2_ajson=>parse( `[]` ) ) ).
  ENDMETHOD.

  METHOD test_fraction_integer.
    DATA(schema) = zcl_mcp2_ajson=>parse( `{"type":"object","properties":{"qty":{"type":"integer"}}}` ).
    DATA(v) = NEW zcl_mcp2_schema_validator( schema ).
    cl_abap_unit_assert=>assert_false( v->validate( zcl_mcp2_ajson=>parse( `{"qty":1.5}` ) ) ).
  ENDMETHOD.

  METHOD test_closed_object.
    DATA(schema) = zcl_mcp2_ajson=>parse(
                       `{"type":"object","additionalProperties":false,"properties":{"known":{"type":"string"}}}` ).
    DATA(v) = NEW zcl_mcp2_schema_validator( schema ).
    cl_abap_unit_assert=>assert_false( v->validate( zcl_mcp2_ajson=>parse( `{"known":"yes","extra":1}` ) ) ).
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lines( v->get_errors( ) ) ).
  ENDMETHOD.

  METHOD test_pattern.
    DATA(schema) = zcl_mcp2_ajson=>parse(
                       `{"type":"object","properties":{"code":{"type":"string","pattern":"^[A-Z]+$"}}}` ).
    DATA(v) = NEW zcl_mcp2_schema_validator( schema ).
    cl_abap_unit_assert=>assert_true( v->validate( zcl_mcp2_ajson=>parse( `{"code":"ABC"}` ) ) ).
    cl_abap_unit_assert=>assert_false( v->validate( zcl_mcp2_ajson=>parse( `{"code":"Abc"}` ) ) ).
  ENDMETHOD.

  METHOD test_invalid_pattern.
    DATA(schema) = zcl_mcp2_ajson=>parse( `{"type":"object","properties":{"code":{"type":"string","pattern":"["}}}` ).
    DATA(v) = NEW zcl_mcp2_schema_validator( schema ).
    cl_abap_unit_assert=>assert_false( v->validate( zcl_mcp2_ajson=>parse( `{"code":"x"}` ) ) ).
  ENDMETHOD.

  METHOD test_string_array.
    DATA(schema) = zcl_mcp2_ajson=>parse(
        `{"type":"object","properties":{"codes":{"type":"array","items":{"type":"string","pattern":"^[0-9]+$"}}}}` ).
    DATA(v) = NEW zcl_mcp2_schema_validator( schema ).
    cl_abap_unit_assert=>assert_true( v->validate( zcl_mcp2_ajson=>parse( `{"codes":["12"]}` ) ) ).
    cl_abap_unit_assert=>assert_false( v->validate( zcl_mcp2_ajson=>parse( `{"codes":["x"]}` ) ) ).
  ENDMETHOD.

  METHOD test_slash_property.
    DATA(schema) = zcl_mcp2_ajson=>parse( `{"type":"object","properties":{"a/b":{"type":"string"}},"required":["a/b"]}` ).
    DATA(v) = NEW zcl_mcp2_schema_validator( schema ).
    cl_abap_unit_assert=>assert_true( v->validate( zcl_mcp2_ajson=>parse( `{"a/b":"ok"}` ) ) ).
  ENDMETHOD.

  METHOD test_valorraise_ok.
    DATA(schema) = zcl_mcp2_ajson=>parse( `{"type":"object","properties":{"name":{"type":"string"}}}` ).
    DATA(json) = zcl_mcp2_ajson=>parse( `{"name":"Alice"}` ).
    zcl_mcp2_schema_validator=>validate_or_raise( schema = schema json = json ).
  ENDMETHOD.

  METHOD test_valorraise_fail.
    DATA(schema) = zcl_mcp2_ajson=>parse(
                       `{"type":"object","properties":{"name":{"type":"string"}},"required":["name"]}` ).
    DATA(json) = zcl_mcp2_ajson=>parse( `{}` ).
    TRY.
        zcl_mcp2_schema_validator=>validate_or_raise( schema = schema
                                                      json   = json ).
        cl_abap_unit_assert=>fail( `Expected InvalidParams rejection` ) ##NO_TEXT.
      CATCH zcx_mcp2_error INTO DATA(err).
        cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>error_codes-invalid_params
                                            act = err->code ).
        cl_abap_unit_assert=>assert_char_cp( exp = `*name*`
                                             act = err->reason ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_valorraise_no_json.
    " Unbound json param defaults to an empty object instance.
    DATA(schema) = zcl_mcp2_ajson=>parse( `{"type":"object"}` ).
    DATA unbound TYPE REF TO zif_mcp2_ajson.
    zcl_mcp2_schema_validator=>validate_or_raise( schema = schema
                                                  json   = unbound ).
  ENDMETHOD.

  METHOD test_unbound_schema.
    DATA schema TYPE REF TO zif_mcp2_ajson.

    DATA(v) = NEW zcl_mcp2_schema_validator( schema ).
    DATA(json) = zcl_mcp2_ajson=>parse( `{}` ).
    cl_abap_unit_assert=>assert_false( v->validate( json ) ).
    DATA(errors) = v->get_errors( ).
    cl_abap_unit_assert=>assert_char_cp( exp = `*Schema is not bound*`
                                         act = errors[ 1 ] ).
  ENDMETHOD.

  METHOD test_schema_root_not_obj.
    " The schema's own declared root type is checked separately from the
    " instance's actual node type.
    DATA(schema) = zcl_mcp2_ajson=>parse( `{"type":"array"}` ).
    DATA(v) = NEW zcl_mcp2_schema_validator( schema ).
    DATA(json) = zcl_mcp2_ajson=>parse( `{}` ).
    cl_abap_unit_assert=>assert_false( v->validate( json ) ).
    DATA(errors) = v->get_errors( ).
    cl_abap_unit_assert=>assert_char_cp( exp = `*Schema root must be of type object*`
                                         act = errors[ 1 ] ).
  ENDMETHOD.

  METHOD test_number_type.
    DATA(schema) = zcl_mcp2_ajson=>parse( `{"type":"object","properties":{"score":{"type":"number"}}}` ).
    DATA(v) = NEW zcl_mcp2_schema_validator( schema ).
    cl_abap_unit_assert=>assert_true( v->validate( zcl_mcp2_ajson=>parse( `{"score":3.5}` ) ) ).
    v = NEW zcl_mcp2_schema_validator( schema ).
    cl_abap_unit_assert=>assert_false( v->validate( zcl_mcp2_ajson=>parse( `{"score":"bad"}` ) ) ).
  ENDMETHOD.

  METHOD test_number_range.
    DATA(schema) = zcl_mcp2_ajson=>parse(
      `{"type":"object","properties":{"score":{"type":"number","minimum":0.0,"maximum":1.0}}}` ).
    DATA(v) = NEW zcl_mcp2_schema_validator( schema ).
    cl_abap_unit_assert=>assert_true( v->validate( zcl_mcp2_ajson=>parse( `{"score":0.5}` ) ) ).
    v = NEW zcl_mcp2_schema_validator( schema ).
    cl_abap_unit_assert=>assert_false( v->validate( zcl_mcp2_ajson=>parse( `{"score":1.5}` ) ) ).
  ENDMETHOD.

  METHOD test_boolean_valid.
    DATA(schema) = zcl_mcp2_ajson=>parse( `{"type":"object","properties":{"active":{"type":"boolean"}}}` ).
    DATA(v) = NEW zcl_mcp2_schema_validator( schema ).
    cl_abap_unit_assert=>assert_true( v->validate( zcl_mcp2_ajson=>parse( `{"active":true}` ) ) ).
  ENDMETHOD.

  METHOD test_boolean_mismatch.
    DATA(schema) = zcl_mcp2_ajson=>parse( `{"type":"object","properties":{"active":{"type":"boolean"}}}` ).
    DATA(v) = NEW zcl_mcp2_schema_validator( schema ).
    cl_abap_unit_assert=>assert_false( v->validate( zcl_mcp2_ajson=>parse( `{"active":"yes"}` ) ) ).
  ENDMETHOD.

  METHOD test_object_type_mismatch.
    DATA(schema) = zcl_mcp2_ajson=>parse( `{"type":"object","properties":{"addr":{"type":"object"}}}` ).
    DATA(v) = NEW zcl_mcp2_schema_validator( schema ).
    cl_abap_unit_assert=>assert_false( v->validate( zcl_mcp2_ajson=>parse( `{"addr":"not-an-object"}` ) ) ).
  ENDMETHOD.

  METHOD test_array_type_mismatch.
    DATA(schema) = zcl_mcp2_ajson=>parse( `{"type":"object","properties":{"tags":{"type":"array"}}}` ).
    DATA(v) = NEW zcl_mcp2_schema_validator( schema ).
    cl_abap_unit_assert=>assert_false( v->validate( zcl_mcp2_ajson=>parse( `{"tags":"not-an-array"}` ) ) ).
  ENDMETHOD.

  METHOD test_array_min_items.
    DATA(schema) = zcl_mcp2_ajson=>parse( `{"type":"object","properties":{"tags":{"type":"array","minItems":2}}}` ).
    DATA(v) = NEW zcl_mcp2_schema_validator( schema ).
    cl_abap_unit_assert=>assert_false( v->validate( zcl_mcp2_ajson=>parse( `{"tags":["a"]}` ) ) ).
  ENDMETHOD.

  METHOD test_array_max_items.
    DATA(schema) = zcl_mcp2_ajson=>parse( `{"type":"object","properties":{"tags":{"type":"array","maxItems":1}}}` ).
    DATA(v) = NEW zcl_mcp2_schema_validator( schema ).
    cl_abap_unit_assert=>assert_false( v->validate( zcl_mcp2_ajson=>parse( `{"tags":["a","b"]}` ) ) ).
  ENDMETHOD.

  METHOD test_array_items_object.
    DATA(schema) = zcl_mcp2_ajson=>parse(
                       |\{"type":"object","properties":\{"rows":\{"type":"array","items":\{"type":"object",| &&
                       |"properties":\{"id":\{"type":"string"\}\},"required":["id"]\}\}\}\}| ).
    DATA(v) = NEW zcl_mcp2_schema_validator( schema ).
    cl_abap_unit_assert=>assert_true( v->validate( zcl_mcp2_ajson=>parse( `{"rows":[{"id":"a"}]}` ) ) ).
    v = NEW zcl_mcp2_schema_validator( schema ).
    cl_abap_unit_assert=>assert_false( v->validate( zcl_mcp2_ajson=>parse( `{"rows":[{}]}` ) ) ).
  ENDMETHOD.

  METHOD test_array_items_number.
    DATA(schema) = zcl_mcp2_ajson=>parse(
        `{"type":"object","properties":{"scores":{"type":"array","items":{"type":"number","minimum":0.0}}}}` ).
    DATA(v) = NEW zcl_mcp2_schema_validator( schema ).
    cl_abap_unit_assert=>assert_true( v->validate( zcl_mcp2_ajson=>parse( `{"scores":[1.5,2.5]}` ) ) ).
    v = NEW zcl_mcp2_schema_validator( schema ).
    cl_abap_unit_assert=>assert_false( v->validate( zcl_mcp2_ajson=>parse( `{"scores":[-1.0]}` ) ) ).
  ENDMETHOD.

  METHOD test_array_item_mismatch.
    " Item present with the wrong node type (not just a pattern mismatch).
    DATA(schema) = zcl_mcp2_ajson=>parse(
                       `{"type":"object","properties":{"tags":{"type":"array","items":{"type":"string"}}}}` ).
    DATA(v) = NEW zcl_mcp2_schema_validator( schema ).
    cl_abap_unit_assert=>assert_false( v->validate( zcl_mcp2_ajson=>parse( `{"tags":[1]}` ) ) ).
    DATA(errors) = v->get_errors( ).
    cl_abap_unit_assert=>assert_char_cp( exp = `*expected string*`
                                         act = errors[ 1 ] ).
  ENDMETHOD.

  METHOD test_integer_overflow.
    DATA(schema) = zcl_mcp2_ajson=>parse( `{"type":"object","properties":{"n":{"type":"integer"}}}` ).
    DATA(json) = zcl_mcp2_ajson=>parse( `{"n":99999999999999999999}` ).
    DATA(v) = NEW zcl_mcp2_schema_validator( schema ).
    cl_abap_unit_assert=>assert_false( v->validate( json ) ).
    DATA(errors) = v->get_errors( ).
    cl_abap_unit_assert=>assert_char_cp( exp = `*outside*`
                                         act = errors[ 1 ] ).
  ENDMETHOD.

ENDCLASS.
