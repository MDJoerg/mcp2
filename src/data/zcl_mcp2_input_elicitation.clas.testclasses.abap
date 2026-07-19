CLASS ltcl_input_elicitation DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.

  PUBLIC SECTION.
    METHODS test_form_mode         FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_form_default_schema FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_form_with_schema  FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_url_mode          FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_get_method        FOR TESTING.
    METHODS test_generate_json     FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_params_unset      FOR TESTING RAISING zcx_mcp2_ajson_error.

ENDCLASS.

CLASS ltcl_input_elicitation IMPLEMENTATION.

  METHOD test_form_mode.
    DATA cut TYPE REF TO zcl_mcp2_input_elicitation.
    cut = NEW #( ).
    cut->set_form( `Please confirm` ).
    DATA(p) = zcl_mcp2_ajson=>parse( cut->get_params( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `form`
                                        act = p->get_string( '/mode' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `Please confirm`
                                        act = p->get_string( '/message' ) ).
  ENDMETHOD.

  METHOD test_form_default_schema.
    " requestedSchema is required by the spec - a schema-less prompt must
    " still emit an empty object schema.
    DATA cut TYPE REF TO zcl_mcp2_input_elicitation.
    cut = NEW #( ).
    cut->set_form( `Please confirm` ).
    DATA(p) = zcl_mcp2_ajson=>parse( cut->get_params( )->stringify( ) ).
    cl_abap_unit_assert=>assert_true( p->exists( '/requestedSchema' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `object`
                                        act = p->get_string( '/requestedSchema/type' ) ).
    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_ajson_types=>node_type-object
                                        act = p->get_node_type( '/requestedSchema/properties' ) ).
  ENDMETHOD.

  METHOD test_form_with_schema.
    " set_form only accepts the flat elicitation builder - tool input schemas
    " (nesting, x-mcp-header) are structurally impossible here.
    DATA cut TYPE REF TO zcl_mcp2_input_elicitation.
    DATA schema TYPE REF TO zcl_mcp2_elicit_schema.
    schema = NEW #( ).
    schema->add_boolean( name = `approved` required = abap_true ).
    cut = NEW #( ).
    cut->set_form( message          = `Approve?`
                   requested_schema = schema ).
    DATA(p) = zcl_mcp2_ajson=>parse( cut->get_params( )->stringify( ) ).
    cl_abap_unit_assert=>assert_true( p->exists( '/requestedSchema' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `boolean`
                                        act = p->get_string( '/requestedSchema/properties/approved/type' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `approved`
                                        act = p->get_string( '/requestedSchema/required/1' ) ).
  ENDMETHOD.

  METHOD test_url_mode.
    " ElicitRequestURLParams: message, mode, url - and nothing else.
    " elicitationId was removed from the draft; correlation lives in requestState.
    DATA cut TYPE REF TO zcl_mcp2_input_elicitation.
    cut = NEW #( ).
    cut->set_url( message = `Visit link`
                  url     = `https://example.com/auth` ).
    DATA(p) = zcl_mcp2_ajson=>parse( cut->get_params( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `url`
                                        act = p->get_string( '/mode' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `Visit link`
                                        act = p->get_string( '/message' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `https://example.com/auth`
                                        act = p->get_string( '/url' ) ).
    cl_abap_unit_assert=>assert_false( p->exists( '/elicitationId' ) ).
  ENDMETHOD.

  METHOD test_get_method.
    DATA cut TYPE REF TO zcl_mcp2_input_elicitation.
    cut = NEW #( ).
    cl_abap_unit_assert=>assert_equals( exp = `elicitation/create`
                                        act = cut->get_method( ) ).
  ENDMETHOD.

  METHOD test_generate_json.
    DATA cut TYPE REF TO zcl_mcp2_input_elicitation.
    cut = NEW #( ).
    cut->set_form( `Test` ).
    DATA(j) = zcl_mcp2_ajson=>parse( cut->generate_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `elicitation/create`
                                        act = j->get_string( '/method' ) ).
    cl_abap_unit_assert=>assert_true( j->exists( '/params' ) ).
  ENDMETHOD.

  METHOD test_params_unset.
    DATA cut TYPE REF TO zcl_mcp2_input_elicitation.
    cut = NEW #( ).
    DATA(p) = cut->get_params( ).
    cl_abap_unit_assert=>assert_bound( p ).
  ENDMETHOD.

ENDCLASS.
