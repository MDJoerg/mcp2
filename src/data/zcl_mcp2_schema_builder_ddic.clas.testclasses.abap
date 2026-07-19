"! Tests use a mock zif_mcp2_ddic returning canned field metadata.
CLASS ltcl_mock_ddic DEFINITION FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_mcp2_ddic.
    DATA fields          TYPE ddfields.
    " Optional second structure, returned instead of fields when the
    " requested structure_name matches sub_structure - lets tests exercise
    " the STRU (nested object) branch of process_field.
    DATA sub_structure    TYPE string.
    DATA sub_fields       TYPE ddfields.
    DATA domain_values    TYPE string_table.
    DATA raise_not_found  TYPE abap_bool.
ENDCLASS.
CLASS ltcl_mock_ddic IMPLEMENTATION.
  METHOD zif_mcp2_ddic~get_structure_fields.
    IF raise_not_found = abap_true.
      zcx_mcp2_ddic_error=>raise( `mock: structure not found` ) ##NO_TEXT.
    ENDIF.
    IF sub_structure IS NOT INITIAL AND structure_name = sub_structure.
      result = sub_fields.
    ELSE.
      result = fields.
    ENDIF.
  ENDMETHOD.
  METHOD zif_mcp2_ddic~get_domain_values.
    result = domain_values.
  ENDMETHOD.
ENDCLASS.

CLASS ltcl_builder_ddic DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.

  PUBLIC SECTION.
    METHODS test_string_field   FOR TESTING RAISING zcx_mcp2_ddic_error zcx_mcp2_ajson_error.
    METHODS test_integer_field  FOR TESTING RAISING zcx_mcp2_ddic_error zcx_mcp2_ajson_error.
    METHODS test_key_required   FOR TESTING RAISING zcx_mcp2_ddic_error zcx_mcp2_ajson_error.
    METHODS test_override_desc  FOR TESTING RAISING zcx_mcp2_ddic_error zcx_mcp2_ajson_error.
    METHODS test_empty_struct   FOR TESTING RAISING zcx_mcp2_ddic_error zcx_mcp2_ajson_error.
    METHODS test_include_skip   FOR TESTING RAISING zcx_mcp2_ddic_error zcx_mcp2_ajson_error.
    METHODS test_desc_keeps_required FOR TESTING RAISING zcx_mcp2_ddic_error zcx_mcp2_ajson_error.
    METHODS test_explicit_optional FOR TESTING RAISING zcx_mcp2_ddic_error zcx_mcp2_ajson_error.
    METHODS test_ttyp_string_array FOR TESTING RAISING zcx_mcp2_ddic_error zcx_mcp2_ajson_error.
    METHODS test_abap_patterns FOR TESTING RAISING zcx_mcp2_ddic_error zcx_mcp2_ajson_error.
    METHODS test_ctor_empty_ovr_path   FOR TESTING RAISING zcx_mcp2_ddic_error zcx_mcp2_ajson_error.
    METHODS test_struct_not_found      FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_nested_struct         FOR TESTING RAISING zcx_mcp2_ddic_error zcx_mcp2_ajson_error.
    METHODS test_override_last_segment FOR TESTING RAISING zcx_mcp2_ddic_error zcx_mcp2_ajson_error.
    METHODS test_number_field          FOR TESTING RAISING zcx_mcp2_ddic_error zcx_mcp2_ajson_error.
    METHODS test_type_by_inttype       FOR TESTING RAISING zcx_mcp2_ddic_error zcx_mcp2_ajson_error.
    METHODS test_enum_with_maxlen      FOR TESTING RAISING zcx_mcp2_ddic_error zcx_mcp2_ajson_error.
    METHODS test_enum_no_maxlen        FOR TESTING RAISING zcx_mcp2_ddic_error zcx_mcp2_ajson_error.
    METHODS test_pattern_tims_accp     FOR TESTING RAISING zcx_mcp2_ddic_error zcx_mcp2_ajson_error.
    METHODS test_name_override         FOR TESTING RAISING zcx_mcp2_ddic_error zcx_mcp2_ajson_error.
    METHODS test_fieldname_sanitize    FOR TESTING RAISING zcx_mcp2_ddic_error zcx_mcp2_ajson_error.
    METHODS test_desc_fallback_chain   FOR TESTING RAISING zcx_mcp2_ddic_error zcx_mcp2_ajson_error.
    METHODS test_desc_default_fallback FOR TESTING RAISING zcx_mcp2_ddic_error zcx_mcp2_ajson_error.
    METHODS test_required_clnt         FOR TESTING RAISING zcx_mcp2_ddic_error zcx_mcp2_ajson_error.
    METHODS test_override_required_true FOR TESTING RAISING zcx_mcp2_ddic_error zcx_mcp2_ajson_error.
    METHODS test_length_precedence     FOR TESTING RAISING zcx_mcp2_ddic_error zcx_mcp2_ajson_error.

  PRIVATE SECTION.
    DATA mock TYPE REF TO ltcl_mock_ddic.
    METHODS setup.
    METHODS add_field
      IMPORTING fieldname TYPE fieldname
                datatype  TYPE datatype_d
                inttype   TYPE inttype
                leng      TYPE ddleng    DEFAULT 0
                outputlen TYPE outputlen DEFAULT 0
                keyflag   TYPE keyflag   DEFAULT abap_false
                scrtext_l TYPE scrtext_l DEFAULT ``.
ENDCLASS.

CLASS ltcl_builder_ddic IMPLEMENTATION.
  METHOD setup.
    mock = NEW #( ).
    CLEAR mock->fields.
  ENDMETHOD.

  METHOD add_field.
    APPEND VALUE dfies( fieldname = fieldname
                        datatype  = datatype
                        inttype   = inttype
                        leng      = leng
                        outputlen = outputlen
                        keyflag   = keyflag
                        scrtext_l = scrtext_l ) TO mock->fields.
  ENDMETHOD.

  METHOD test_string_field.
    add_field( fieldname = `NAME` datatype = `CHAR` inttype = `C`
               leng = 40 scrtext_l = `Full Name` ).
    DATA(b) = NEW zcl_mcp2_schema_builder_ddic( structure_name = `TEST`
                                                 ddic           = mock ).
    DATA(json) = zcl_mcp2_ajson=>parse( b->to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `string`
                                        act = json->get_string( '/properties/name/type' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `Full Name`
                                        act = json->get_string( '/properties/name/description' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 40
                                        act = json->get_integer( '/properties/name/maxLength' ) ).
  ENDMETHOD.

  METHOD test_integer_field.
    add_field( fieldname = `QUANTITY` datatype = `INT4` inttype = `I` ).
    DATA(b) = NEW zcl_mcp2_schema_builder_ddic( structure_name = `TEST`
                                                 ddic           = mock ).
    DATA(json) = zcl_mcp2_ajson=>parse( b->to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `integer`
                                        act = json->get_string( '/properties/quantity/type' ) ).
  ENDMETHOD.

  METHOD test_key_required.
    add_field( fieldname = `ID` datatype = `CHAR` inttype = `C`
               keyflag = abap_true ).
    DATA(b) = NEW zcl_mcp2_schema_builder_ddic( structure_name = `TEST`
                                                 ddic           = mock ).
    DATA(json) = zcl_mcp2_ajson=>parse( b->to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `id`
                                        act = json->get_string( '/required/1' ) ).
  ENDMETHOD.

  METHOD test_override_desc.
    add_field( fieldname = `STATUS` datatype = `CHAR` inttype = `C`
               scrtext_l = `Status` ).
    DATA ovr TYPE zcl_mcp2_schema_builder_ddic=>field_overrides.
    APPEND VALUE #( field_path   = `status`
                    description  = `Custom status description` ) TO ovr.
    DATA(b) = NEW zcl_mcp2_schema_builder_ddic( structure_name = `TEST`
                                                 overrides      = ovr
                                                 ddic           = mock ).
    DATA(json) = zcl_mcp2_ajson=>parse( b->to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = `Custom status description`
      act = json->get_string( '/properties/status/description' ) ).
  ENDMETHOD.

  METHOD test_empty_struct.
    DATA(b) = NEW zcl_mcp2_schema_builder_ddic( structure_name = `EMPTY`
                                                 ddic           = mock ).
    DATA(json) = zcl_mcp2_ajson=>parse( b->to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `object`
                                        act = json->get_string( '/type' ) ).
  ENDMETHOD.

  METHOD test_include_skip.
    APPEND VALUE dfies( fieldname = `.INCLUDE` datatype = `STRU` inttype = `u` )
      TO mock->fields.
    add_field( fieldname = `REAL` datatype = `CHAR` inttype = `C` ).
    DATA(b) = NEW zcl_mcp2_schema_builder_ddic( structure_name = `TEST`
                                                 ddic           = mock ).
    DATA(json) = zcl_mcp2_ajson=>parse( b->to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_true( json->exists( '/properties/real' ) ).
    cl_abap_unit_assert=>assert_false( json->exists( '/properties/.include' ) ).
  ENDMETHOD.

  METHOD test_desc_keeps_required.
    add_field( fieldname = `ID` datatype = `CHAR` inttype = `C` keyflag = abap_true ).
    DATA ovr TYPE zcl_mcp2_schema_builder_ddic=>field_overrides.
    APPEND VALUE #( field_path = `id` description = `Identifier` ) TO ovr.
    DATA(json) = NEW zcl_mcp2_schema_builder_ddic(
      structure_name = `TEST` overrides = ovr ddic = mock )->to_json( ).
    cl_abap_unit_assert=>assert_equals( exp = `id` act = json->get_string( '/required/1' ) ).
  ENDMETHOD.

  METHOD test_explicit_optional.
    add_field( fieldname = `ID` datatype = `CHAR` inttype = `C` keyflag = abap_true ).
    DATA ovr TYPE zcl_mcp2_schema_builder_ddic=>field_overrides.
    APPEND VALUE #( field_path = `id` required_is_set = abap_true required = abap_false ) TO ovr.
    DATA(json) = NEW zcl_mcp2_schema_builder_ddic(
      structure_name = `TEST` overrides = ovr ddic = mock )->to_json( ).
    cl_abap_unit_assert=>assert_false( json->exists( '/required' ) ).
  ENDMETHOD.

  METHOD test_ttyp_string_array.
    add_field( fieldname = `ROWS` datatype = `TTYP` inttype = `h` ).
    DATA(json) = NEW zcl_mcp2_schema_builder_ddic(
      structure_name = `TEST` ddic = mock )->to_json( ).
    cl_abap_unit_assert=>assert_equals(
      exp = `string` act = json->get_string( '/properties/rows/items/type' ) ).
    cl_abap_unit_assert=>assert_false( json->exists( '/properties/rows/items/properties/item' ) ).
  ENDMETHOD.

  METHOD test_abap_patterns.
    add_field( fieldname = `DATE` datatype = `DATS` inttype = `D` outputlen = 8 ).
    add_field( fieldname = `CODE` datatype = `NUMC` inttype = `N` outputlen = 4 ).
    DATA(json) = NEW zcl_mcp2_schema_builder_ddic(
      structure_name = `TEST` ddic = mock )->to_json( ).
    cl_abap_unit_assert=>assert_equals(
      exp = `^[0-9]{8}$` act = json->get_string( '/properties/date/pattern' ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = `^[0-9]{4}$` act = json->get_string( '/properties/code/pattern' ) ).
  ENDMETHOD.

  METHOD test_ctor_empty_ovr_path.
    add_field( fieldname = `ID` datatype = `CHAR` inttype = `C` ).
    DATA ovr TYPE zcl_mcp2_schema_builder_ddic=>field_overrides.
    APPEND VALUE #( field_path = `` description = `x` ) TO ovr.
    TRY.
        NEW zcl_mcp2_schema_builder_ddic( structure_name = `TEST`
                                           overrides      = ovr
                                           ddic           = mock ).
        cl_abap_unit_assert=>fail( `Expected empty field_path rejection` ) ##NO_TEXT.
      CATCH zcx_mcp2_ddic_error.
    ENDTRY.
  ENDMETHOD.

  METHOD test_struct_not_found.
    mock->raise_not_found = abap_true.
    TRY.
        NEW zcl_mcp2_schema_builder_ddic( structure_name = `MISSING`
                                           ddic           = mock ).
        cl_abap_unit_assert=>fail( `Expected structure-not-found rejection` ) ##NO_TEXT.
      CATCH zcx_mcp2_ddic_error INTO DATA(err).
        cl_abap_unit_assert=>assert_char_cp( act = err->message
                                             exp = `*Structure not found*` ).
    ENDTRY.
  ENDMETHOD.

  METHOD test_nested_struct.
    " STRU field resolved via rollname; base_path propagates as a dotted
    " prefix into the nested structure's own fields.
    APPEND VALUE dfies( fieldname = `ADDR` datatype = `STRU` inttype = `u`
                        rollname  = `ADDR_STRUCT` ) TO mock->fields.
    mock->sub_structure = `ADDR_STRUCT`.
    APPEND VALUE dfies( fieldname = `CITY` datatype = `CHAR` inttype = `C` leng = 20 )
      TO mock->sub_fields.
    DATA(json) = NEW zcl_mcp2_schema_builder_ddic(
      structure_name = `TEST` ddic = mock )->to_json( ).
    cl_abap_unit_assert=>assert_equals( exp = `object`
                                        act = json->get_string( '/properties/addr/type' ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = `string`
      act = json->get_string( '/properties/addr/properties/city/type' ) ).
  ENDMETHOD.

  METHOD test_override_last_segment.
    " Override keyed by the bare field name (no dotted prefix) must still
    " match a nested field via get_field_override's last-segment fallback.
    APPEND VALUE dfies( fieldname = `ADDR` datatype = `STRU` inttype = `u`
                        rollname  = `ADDR_STRUCT` ) TO mock->fields.
    mock->sub_structure = `ADDR_STRUCT`.
    APPEND VALUE dfies( fieldname = `CITY` datatype = `CHAR` inttype = `C` leng = 20 )
      TO mock->sub_fields.
    DATA ovr TYPE zcl_mcp2_schema_builder_ddic=>field_overrides.
    APPEND VALUE #( field_path = `city` description = `City name` ) TO ovr.
    DATA(json) = NEW zcl_mcp2_schema_builder_ddic(
      structure_name = `TEST` overrides = ovr ddic = mock )->to_json( ).
    cl_abap_unit_assert=>assert_equals(
      exp = `City name`
      act = json->get_string( '/properties/addr/properties/city/description' ) ).
  ENDMETHOD.

  METHOD test_number_field.
    add_field( fieldname = `PRICE` datatype = `CURR` inttype = `P` ).
    DATA(json) = NEW zcl_mcp2_schema_builder_ddic(
      structure_name = `TEST` ddic = mock )->to_json( ).
    cl_abap_unit_assert=>assert_equals( exp = `number`
                                        act = json->get_string( '/properties/price/type' ) ).
  ENDMETHOD.

  METHOD test_type_by_inttype.
    " Unmatched datatype falls back to inttype-based dispatch.
    add_field( fieldname = `FLAG` datatype = `` inttype = `I` ).
    DATA(json) = NEW zcl_mcp2_schema_builder_ddic(
      structure_name = `TEST` ddic = mock )->to_json( ).
    cl_abap_unit_assert=>assert_equals( exp = `integer`
                                        act = json->get_string( '/properties/flag/type' ) ).
  ENDMETHOD.

  METHOD test_enum_with_maxlen.
    add_field( fieldname = `COLOR` datatype = `CHAR` inttype = `C` leng = 10 ).
    mock->fields[ 1 ]-domname = `COLOR_DOM`.
    mock->domain_values = VALUE #( ( `red` ) ( `green` ) ( `blue` ) ).
    DATA(json) = NEW zcl_mcp2_schema_builder_ddic(
      structure_name = `TEST` ddic = mock )->to_json( ).
    cl_abap_unit_assert=>assert_equals( exp = `red`
                                        act = json->get_string( '/properties/color/enum/1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 10
                                        act = json->get_integer( '/properties/color/maxLength' ) ).
  ENDMETHOD.

  METHOD test_enum_no_maxlen.
    add_field( fieldname = `COLOR` datatype = `CHAR` inttype = `C` ).
    mock->fields[ 1 ]-domname = `COLOR_DOM`.
    mock->domain_values = VALUE #( ( `red` ) ( `green` ) ).
    DATA(json) = NEW zcl_mcp2_schema_builder_ddic(
      structure_name = `TEST` ddic = mock )->to_json( ).
    cl_abap_unit_assert=>assert_equals( exp = `red`
                                        act = json->get_string( '/properties/color/enum/1' ) ).
    cl_abap_unit_assert=>assert_false( json->exists( '/properties/color/maxLength' ) ).
  ENDMETHOD.

  METHOD test_pattern_tims_accp.
    add_field( fieldname = `START_TIME` datatype = `TIMS` inttype = `T` outputlen = 6 ).
    add_field( fieldname = `PERIOD`     datatype = `ACCP` inttype = `N` outputlen = 6 ).
    DATA(json) = NEW zcl_mcp2_schema_builder_ddic(
      structure_name = `TEST` ddic = mock )->to_json( ).
    cl_abap_unit_assert=>assert_equals(
      exp = `^[0-9]{6}$` act = json->get_string( '/properties/start_time/pattern' ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = `^[0-9]{6}$` act = json->get_string( '/properties/period/pattern' ) ).
  ENDMETHOD.

  METHOD test_name_override.
    add_field( fieldname = `STATUS` datatype = `CHAR` inttype = `C` ).
    DATA ovr TYPE zcl_mcp2_schema_builder_ddic=>field_overrides.
    APPEND VALUE #( field_path = `status` name = `state` ) TO ovr.
    DATA(json) = NEW zcl_mcp2_schema_builder_ddic(
      structure_name = `TEST` overrides = ovr ddic = mock )->to_json( ).
    cl_abap_unit_assert=>assert_true( json->exists( '/properties/state' ) ).
    cl_abap_unit_assert=>assert_false( json->exists( '/properties/status' ) ).
  ENDMETHOD.

  METHOD test_fieldname_sanitize.
    add_field( fieldname = `A/B-C` datatype = `CHAR` inttype = `C` ).
    DATA(json) = NEW zcl_mcp2_schema_builder_ddic(
      structure_name = `TEST` ddic = mock )->to_json( ).
    cl_abap_unit_assert=>assert_true( json->exists( '/properties/a_b_c' ) ).
  ENDMETHOD.

  METHOD test_desc_fallback_chain.
    " scrtext_l is empty - must fall through to scrtext_m.
    APPEND VALUE dfies( fieldname = `NOTE` datatype = `CHAR` inttype = `C`
                        scrtext_m = `Medium text` ) TO mock->fields.
    DATA(json) = NEW zcl_mcp2_schema_builder_ddic(
      structure_name = `TEST` ddic = mock )->to_json( ).
    cl_abap_unit_assert=>assert_equals(
      exp = `Medium text`
      act = json->get_string( '/properties/note/description' ) ).
  ENDMETHOD.

  METHOD test_desc_default_fallback.
    " No text field populated at all - falls back to "Field <name>".
    add_field( fieldname = `QTY` datatype = `INT4` inttype = `I` ).
    DATA(json) = NEW zcl_mcp2_schema_builder_ddic(
      structure_name = `TEST` ddic = mock )->to_json( ).
    cl_abap_unit_assert=>assert_equals(
      exp = `Field QTY`
      act = json->get_string( '/properties/qty/description' ) ).
  ENDMETHOD.

  METHOD test_required_clnt.
    " CLNT fields are treated as required even without keyflag.
    add_field( fieldname = `MANDT` datatype = `CLNT` inttype = `C` leng = 3 ).
    DATA(json) = NEW zcl_mcp2_schema_builder_ddic(
      structure_name = `TEST` ddic = mock )->to_json( ).
    cl_abap_unit_assert=>assert_equals( exp = `mandt`
                                        act = json->get_string( '/required/1' ) ).
  ENDMETHOD.

  METHOD test_override_required_true.
    " Override can force required=true even though the field isn't a key.
    add_field( fieldname = `NOTE` datatype = `CHAR` inttype = `C` ).
    DATA ovr TYPE zcl_mcp2_schema_builder_ddic=>field_overrides.
    APPEND VALUE #( field_path       = `note`
                    required_is_set  = abap_true
                    required         = abap_true ) TO ovr.
    DATA(json) = NEW zcl_mcp2_schema_builder_ddic(
      structure_name = `TEST` overrides = ovr ddic = mock )->to_json( ).
    cl_abap_unit_assert=>assert_equals( exp = `note`
                                        act = json->get_string( '/required/1' ) ).
  ENDMETHOD.

  METHOD test_length_precedence.
    " outputlen takes precedence over leng when both are set.
    add_field( fieldname = `CODE` datatype = `CHAR` inttype = `C`
               leng = 20 outputlen = 5 ).
    DATA(json) = NEW zcl_mcp2_schema_builder_ddic(
      structure_name = `TEST` ddic = mock )->to_json( ).
    cl_abap_unit_assert=>assert_equals( exp = 5
                                        act = json->get_integer( '/properties/code/maxLength' ) ).
  ENDMETHOD.

ENDCLASS.
