CLASS ltcl_resp_get_prompt DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.
  PUBLIC SECTION.
    METHODS test_user_text         FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_assistant_text    FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_description       FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_custom_message    FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_result_type       FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_multiple_messages FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_no_description    FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_no_cache_hints    FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
ENDCLASS.

CLASS ltcl_resp_get_prompt IMPLEMENTATION.
  METHOD test_user_text.
    DATA resp TYPE REF TO zcl_mcp2_resp_get_prompt.

    resp = NEW #( ).
    resp->add_user_text( `What is ABAP?` ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `user`
                                        act = parsed->get_string( '/messages/1/role' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `text`
                                        act = parsed->get_string( '/messages/1/content/type' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `What is ABAP?`
                                        act = parsed->get_string( '/messages/1/content/text' ) ).
  ENDMETHOD.

  METHOD test_assistant_text.
    DATA resp TYPE REF TO zcl_mcp2_resp_get_prompt.

    resp = NEW #( ).
    resp->add_assistant_text( `ABAP is a programming language.` ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `assistant`
                                        act = parsed->get_string( '/messages/1/role' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `ABAP is a programming language.`
                                        act = parsed->get_string( '/messages/1/content/text' ) ).
  ENDMETHOD.

  METHOD test_description.
    DATA resp TYPE REF TO zcl_mcp2_resp_get_prompt.

    resp = NEW #( ).
    resp->set_description( `A helpful prompt` ).
    resp->add_user_text( `Hello` ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `A helpful prompt`
                                        act = parsed->get_string( '/description' ) ).
  ENDMETHOD.

  METHOD test_custom_message.
    DATA resp TYPE REF TO zcl_mcp2_resp_get_prompt.

    resp = NEW #( ).
    DATA content TYPE REF TO zif_mcp2_ajson.
    content = zcl_mcp2_ajson=>create_empty( ).
    content->set_string( iv_path = '/type'
                         iv_val  = `image` ).
    content->set_string( iv_path = '/data'
                         iv_val  = `aGVsbG8=` ).
    content->set_string( iv_path = '/mimeType'
                         iv_val  = `image/png` ).
    resp->add_message( role    = `user`
                       content = content ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `user`
                                        act = parsed->get_string( '/messages/1/role' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `image`
                                        act = parsed->get_string( '/messages/1/content/type' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `image/png`
                                        act = parsed->get_string( '/messages/1/content/mimeType' ) ).
  ENDMETHOD.

  METHOD test_result_type.
    DATA resp TYPE REF TO zcl_mcp2_resp_get_prompt.

    resp = NEW #( ).
    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>result_types-complete
                                        act = resp->zif_mcp2_result~result_type( ) ).
  ENDMETHOD.

  METHOD test_multiple_messages.
    DATA resp TYPE REF TO zcl_mcp2_resp_get_prompt.

    resp = NEW #( ).
    resp->add_user_text( `Q` ).
    resp->add_assistant_text( `A` ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lines( parsed->members( '/messages' ) ) ).
    cl_abap_unit_assert=>assert_equals( exp = `user`
                                        act = parsed->get_string( '/messages/1/role' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `assistant`
                                        act = parsed->get_string( '/messages/2/role' ) ).
  ENDMETHOD.

  METHOD test_no_description.
    DATA resp TYPE REF TO zcl_mcp2_resp_get_prompt.

    resp = NEW #( ).
    resp->add_user_text( `Hi` ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_false( parsed->exists( '/description' ) ).
  ENDMETHOD.

  METHOD test_no_cache_hints.
    " GetPromptResult is not a CacheableResult - it never carries ttlMs/cacheScope.
    DATA resp TYPE REF TO zcl_mcp2_resp_get_prompt.

    resp = NEW #( ).
    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = resp->zif_mcp2_result~ttl_ms( ) ).
    cl_abap_unit_assert=>assert_initial( resp->zif_mcp2_result~cache_scope( ) ).
  ENDMETHOD.
ENDCLASS.
