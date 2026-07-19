CLASS ltcl_resp_read_resource DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.
  PUBLIC SECTION.
    METHODS test_text_content   FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_blob_content   FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_mime_type      FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_multiple_items FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_empty_contents FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_result_type    FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_set_cache      FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
ENDCLASS.

CLASS ltcl_resp_read_resource IMPLEMENTATION.
  METHOD test_text_content.
    DATA resp TYPE REF TO zcl_mcp2_resp_read_resource.

    resp = NEW #( ).
    resp->add_text_content( uri  = `file:///hello.txt`
                            text = `Hello World` ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `file:///hello.txt`
                                        act = parsed->get_string( '/contents/1/uri' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `Hello World`
                                        act = parsed->get_string( '/contents/1/text' ) ).
    cl_abap_unit_assert=>assert_false( parsed->exists( '/contents/1/mimeType' ) ).
  ENDMETHOD.

  METHOD test_blob_content.
    DATA resp TYPE REF TO zcl_mcp2_resp_read_resource.

    resp = NEW #( ).
    resp->add_blob_content( uri  = `file:///img.png`
                            blob = `aGVsbG8=` ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `file:///img.png`
                                        act = parsed->get_string( '/contents/1/uri' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `aGVsbG8=`
                                        act = parsed->get_string( '/contents/1/blob' ) ).
    cl_abap_unit_assert=>assert_false( parsed->exists( '/contents/1/text' ) ).
  ENDMETHOD.

  METHOD test_mime_type.
    DATA resp TYPE REF TO zcl_mcp2_resp_read_resource.

    resp = NEW #( ).
    resp->add_text_content( uri       = `file:///data.csv`
                            text      = `a,b`
                            mime_type = `text/csv` ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `text/csv`
                                        act = parsed->get_string( '/contents/1/mimeType' ) ).
  ENDMETHOD.

  METHOD test_multiple_items.
    DATA resp TYPE REF TO zcl_mcp2_resp_read_resource.

    resp = NEW #( ).
    resp->add_text_content( uri  = `file:///a.txt`
                            text = `AAA` ).
    resp->add_blob_content( uri  = `file:///b.png`
                            blob = `QkJC` ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lines( parsed->members( '/contents' ) ) ).
    cl_abap_unit_assert=>assert_equals( exp = `file:///a.txt`
                                        act = parsed->get_string( '/contents/1/uri' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `file:///b.png`
                                        act = parsed->get_string( '/contents/2/uri' ) ).
  ENDMETHOD.

  METHOD test_empty_contents.
    DATA resp TYPE REF TO zcl_mcp2_resp_read_resource.

    resp = NEW #( ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_true( parsed->exists( '/contents' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = lines( parsed->members( '/contents' ) ) ).
  ENDMETHOD.

  METHOD test_result_type.
    DATA resp TYPE REF TO zcl_mcp2_resp_read_resource.

    resp = NEW #( ).
    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>result_types-complete
                                        act = resp->zif_mcp2_result~result_type( ) ).
  ENDMETHOD.

  METHOD test_set_cache.
    DATA resp TYPE REF TO zcl_mcp2_resp_read_resource.

    resp = NEW #( ).
    resp->set_cache( ttl_ms      = 5000
                     cache_scope = `public` ).
    cl_abap_unit_assert=>assert_equals( exp = 5000
                                        act = resp->zif_mcp2_result~ttl_ms( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `public`
                                        act = resp->zif_mcp2_result~cache_scope( ) ).
  ENDMETHOD.
ENDCLASS.
