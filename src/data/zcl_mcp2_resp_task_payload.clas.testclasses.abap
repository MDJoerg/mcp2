CLASS ltcl_resp_task_payload DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.

  PUBLIC SECTION.
    METHODS test_result_type    FOR TESTING.
    METHODS test_add_text       FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_is_error       FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_from_prebuilt  FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_related_task   FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_structured_content     FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_structured_data_text   FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_structured_data_notext FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_multiple_text_items    FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_is_error_toggle        FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_related_task_merges_meta FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS test_cache_contract         FOR TESTING.

ENDCLASS.

CLASS ltcl_resp_task_payload IMPLEMENTATION.

  METHOD test_result_type.
    DATA(r) = NEW zcl_mcp2_resp_task_payload( ).
    cl_abap_unit_assert=>assert_equals(
      exp = zif_mcp2_const=>result_types-complete
      act = r->zif_mcp2_result~result_type( ) ).
  ENDMETHOD.

  METHOD test_add_text.
    DATA(r) = NEW zcl_mcp2_resp_task_payload( ).
    r->add_text( `Task completed successfully` ).
    DATA(json) = r->zif_mcp2_result~to_json( ).
    cl_abap_unit_assert=>assert_equals(
      exp = `text`
      act = json->get_string( '/content/1/type' ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = `Task completed successfully`
      act = json->get_string( '/content/1/text' ) ).
    cl_abap_unit_assert=>assert_false( json->exists( '/isError' ) ).
  ENDMETHOD.

  METHOD test_is_error.
    DATA(r) = NEW zcl_mcp2_resp_task_payload( ).
    r->add_text( `Error: something went wrong` ).
    r->set_is_error( ).
    cl_abap_unit_assert=>assert_true( r->get_is_error( ) ).
    DATA(json) = r->zif_mcp2_result~to_json( ).
    cl_abap_unit_assert=>assert_true( json->get_boolean( '/isError' ) ).
  ENDMETHOD.

  METHOD test_from_prebuilt.
    DATA(prebuilt) = zcl_mcp2_ajson=>parse(
      `{"content":[{"type":"text","text":"prebuilt"}]}` ).
    DATA(r) = NEW zcl_mcp2_resp_task_payload( ).
    r->set_from_json( prebuilt ).
    DATA(json) = r->zif_mcp2_result~to_json( ).
    cl_abap_unit_assert=>assert_equals(
      exp = `prebuilt`
      act = json->get_string( '/content/1/text' ) ).
  ENDMETHOD.

  METHOD test_related_task.
    DATA(r) = NEW zcl_mcp2_resp_task_payload( ).
    r->add_text( `done` ).
    r->set_related_task( `AABBCCDDEEFF00112233445566778899` ).
    " Assert on the re-parsed wire: TAB-escaped path reads only resolve on
    " parsed trees - set() stores literal slashes in internal node paths, so
    " exists() on the builder's own tree cannot find slash-named members.
    DATA(wire) = r->zif_mcp2_result~to_json( )->stringify( ).
    cl_abap_unit_assert=>assert_char_cp(
      act = wire
      exp = `*"io.modelcontextprotocol/related-task"*` ).
    DATA(json) = zcl_mcp2_ajson=>parse( wire ).
    DATA(meta_path) = `/_meta/io.modelcontextprotocol`
                   && cl_abap_char_utilities=>horizontal_tab
                   && `related-task/taskId`.
    cl_abap_unit_assert=>assert_true( json->exists( meta_path ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = `AABBCCDDEEFF00112233445566778899`
      act = json->get_string( meta_path ) ).
    " No literally-named ~1 key may appear.
    cl_abap_unit_assert=>assert_false(
      json->exists( '/_meta/io.modelcontextprotocol~1related-task' ) ).
  ENDMETHOD.

  METHOD test_structured_content.
    DATA(content) = zcl_mcp2_ajson=>parse( `{"score":9}` ).
    DATA(r) = NEW zcl_mcp2_resp_task_payload( ).
    r->set_structured_content( content ).
    DATA(json) = r->zif_mcp2_result~to_json( ).
    cl_abap_unit_assert=>assert_equals( exp = 9
                                        act = json->get_integer( '/structuredContent/score' ) ).
  ENDMETHOD.

  METHOD test_structured_data_text.
    " add_text defaults to true: a JSON-text mirror is appended alongside
    " the structured payload.
    TYPES: BEGIN OF ty_data,
             foo TYPE string,
             bar TYPE i,
           END OF ty_data.
    DATA(r) = NEW zcl_mcp2_resp_task_payload( ).
    r->set_structured_data( VALUE ty_data( foo = `hello` bar = 42 ) ).
    DATA(json) = r->zif_mcp2_result~to_json( ).
    cl_abap_unit_assert=>assert_equals( exp = `hello`
                                        act = json->get_string( '/structuredContent/foo' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 42
                                        act = json->get_integer( '/structuredContent/bar' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `text`
                                        act = json->get_string( '/content/1/type' ) ).
    cl_abap_unit_assert=>assert_char_cp( act = json->get_string( '/content/1/text' )
                                         exp = `*hello*` ).
  ENDMETHOD.

  METHOD test_structured_data_notext.
    TYPES: BEGIN OF ty_data,
             foo TYPE string,
           END OF ty_data.
    DATA(r) = NEW zcl_mcp2_resp_task_payload( ).
    r->set_structured_data( data     = VALUE ty_data( foo = `hi` )
                            add_text = abap_false ).
    DATA(json) = r->zif_mcp2_result~to_json( ).
    cl_abap_unit_assert=>assert_equals( exp = `hi`
                                        act = json->get_string( '/structuredContent/foo' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = lines( json->members( '/content' ) ) ).
  ENDMETHOD.

  METHOD test_multiple_text_items.
    DATA(r) = NEW zcl_mcp2_resp_task_payload( ).
    r->add_text( `first` ).
    r->add_text( `second` ).
    DATA(json) = r->zif_mcp2_result~to_json( ).
    cl_abap_unit_assert=>assert_equals( exp = `first`
                                        act = json->get_string( '/content/1/text' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `second`
                                        act = json->get_string( '/content/2/text' ) ).
  ENDMETHOD.

  METHOD test_is_error_toggle.
    DATA(r) = NEW zcl_mcp2_resp_task_payload( ).
    r->set_is_error( abap_true ).
    r->set_is_error( abap_false ).
    cl_abap_unit_assert=>assert_false( r->get_is_error( ) ).
    DATA(json) = r->zif_mcp2_result~to_json( ).
    cl_abap_unit_assert=>assert_false( json->exists( '/isError' ) ).
  ENDMETHOD.

  METHOD test_related_task_merges_meta.
    " An existing _meta on a prebuilt payload must survive alongside the
    " newly-injected related-task entry.
    DATA(prebuilt) = zcl_mcp2_ajson=>parse(
      `{"content":[{"type":"text","text":"x"}],"_meta":{"custom":"keep-me"}}` ).
    DATA(r) = NEW zcl_mcp2_resp_task_payload( ).
    r->set_from_json( prebuilt ).
    r->set_related_task( `AABBCCDDEEFF00112233445566778899` ).
    DATA(json) = zcl_mcp2_ajson=>parse( r->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `keep-me`
                                        act = json->get_string( '/_meta/custom' ) ).
    DATA(meta_path) = `/_meta/io.modelcontextprotocol`
                   && cl_abap_char_utilities=>horizontal_tab
                   && `related-task/taskId`.
    cl_abap_unit_assert=>assert_equals(
      exp = `AABBCCDDEEFF00112233445566778899`
      act = json->get_string( meta_path ) ).
  ENDMETHOD.

  METHOD test_cache_contract.
    " Terminal task payload is never a spec CacheableResult.
    DATA(r) = NEW zcl_mcp2_resp_task_payload( ).
    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = r->zif_mcp2_result~ttl_ms( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `private`
                                        act = r->zif_mcp2_result~cache_scope( ) ).
    cl_abap_unit_assert=>assert_false( r->zif_mcp2_result~is_cacheable( ) ).
  ENDMETHOD.

ENDCLASS.
