CLASS ltcl_resp_call_tool DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.
  PUBLIC SECTION.
    METHODS test_text_content     FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_image_content    FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_is_error         FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_structured       FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_factory_text     FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_factory_error    FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_factory_strucdat FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_factory_strucjsn FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_result_type      FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_input_req_type   FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_audio_content    FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_resource_content FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_resource_blob    FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_resource_link    FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_resource_link_min FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_text_with_annot  FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_annotations_full FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_annot_prio_zero  FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_multiple_content FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_no_cache_hints   FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_structured_data  FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
    METHODS test_struct_data_no_txt FOR TESTING RAISING zcx_mcp2_error zcx_mcp2_ajson_error.
ENDCLASS.

CLASS ltcl_resp_call_tool IMPLEMENTATION.
  METHOD test_text_content.
    DATA resp TYPE REF TO zcl_mcp2_resp_call_tool.

    resp = NEW #( ).
    resp->add_text( `Hello World` ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `text`
                                        act = parsed->get_string( '/content/1/type' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `Hello World`
                                        act = parsed->get_string( '/content/1/text' ) ).
    cl_abap_unit_assert=>assert_false( parsed->exists( '/isError' ) ).
  ENDMETHOD.

  METHOD test_image_content.
    DATA resp TYPE REF TO zcl_mcp2_resp_call_tool.

    resp = NEW #( ).
    resp->add_image( data      = `aGVsbG8=`
                     mime_type = `image/png` ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `image`
                                        act = parsed->get_string( '/content/1/type' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `image/png`
                                        act = parsed->get_string( '/content/1/mimeType' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `aGVsbG8=`
                                        act = parsed->get_string( '/content/1/data' ) ).
  ENDMETHOD.

  METHOD test_is_error.
    DATA resp TYPE REF TO zcl_mcp2_resp_call_tool.

    resp = NEW #( ).
    resp->add_text( `Error: something went wrong` ).
    resp->set_is_error( abap_true ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_true( parsed->get_boolean( '/isError' ) ).
  ENDMETHOD.

  METHOD test_structured.
    DATA resp TYPE REF TO zcl_mcp2_resp_call_tool.

    resp = NEW #( ).
    resp->add_text( `ok` ).
    resp->set_structured_content( zcl_mcp2_ajson=>parse( `{"answer":42}` ) ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = 42
                                        act = parsed->get_integer( '/structuredContent/answer' ) ).
  ENDMETHOD.

  METHOD test_factory_text.
    DATA(resp) = zcl_mcp2_resp_call_tool=>text( `factory ok` ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `factory ok`
                                        act = parsed->get_string( '/content/1/text' ) ).
    cl_abap_unit_assert=>assert_false( parsed->exists( '/isError' ) ).
  ENDMETHOD.

  METHOD test_factory_error.
    DATA(resp) = zcl_mcp2_resp_call_tool=>error_text( `factory error` ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `factory error`
                                        act = parsed->get_string( '/content/1/text' ) ).
    cl_abap_unit_assert=>assert_true( parsed->get_boolean( '/isError' ) ).
  ENDMETHOD.

  METHOD test_factory_strucdat.
    DATA: BEGIN OF payload,
            value TYPE i,
          END OF payload.
    payload-value = 9.

    DATA(resp) = zcl_mcp2_resp_call_tool=>structured_data( payload ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = 9
                                        act = parsed->get_integer( '/structuredContent/value' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `text`
                                        act = parsed->get_string( '/content/1/type' ) ).
  ENDMETHOD.

  METHOD test_factory_strucjsn.
    DATA(resp) = zcl_mcp2_resp_call_tool=>structured_json(
      zcl_mcp2_ajson=>parse( `{"answer":11}` ) ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = 11
                                        act = parsed->get_integer( '/structuredContent/answer' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = lines( parsed->members( '/content' ) ) ).
  ENDMETHOD.

  METHOD test_result_type.
    DATA resp TYPE REF TO zcl_mcp2_resp_call_tool.

    resp = NEW #( ).
    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>result_types-complete
                                        act = resp->zif_mcp2_result~result_type( ) ).
  ENDMETHOD.

  METHOD test_input_req_type.
    DATA resp TYPE REF TO zcl_mcp2_resp_input_req.

    resp = NEW #( ).
    resp->set_request_state( `state-abc` ).
    resp->add_input_request( request_key = `q1`
                             method      = `elicitation/create`
                             params      = zcl_mcp2_ajson=>parse( `{"message":"What is your name?"}` ) ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `state-abc`
                                        act = parsed->get_string( '/requestState' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `elicitation/create`
                                        act = parsed->get_string( '/inputRequests/q1/method' ) ).
    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>result_types-input_required
                                        act = resp->zif_mcp2_result~result_type( ) ).
  ENDMETHOD.

  METHOD test_audio_content.
    DATA resp TYPE REF TO zcl_mcp2_resp_call_tool.

    resp = NEW #( ).
    resp->add_audio( data      = `dGVzdA==`
                     mime_type = `audio/mpeg` ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `audio`
                                        act = parsed->get_string( '/content/1/type' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `dGVzdA==`
                                        act = parsed->get_string( '/content/1/data' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `audio/mpeg`
                                        act = parsed->get_string( '/content/1/mimeType' ) ).
  ENDMETHOD.

  METHOD test_resource_content.
    DATA resp TYPE REF TO zcl_mcp2_resp_call_tool.

    resp = NEW #( ).
    resp->add_resource( VALUE #( uri       = `file:///x`
                                 text      = `hi`
                                 mime_type = `text/plain` ) ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `resource`
                                        act = parsed->get_string( '/content/1/type' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `file:///x`
                                        act = parsed->get_string( '/content/1/resource/uri' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `hi`
                                        act = parsed->get_string( '/content/1/resource/text' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `text/plain`
                                        act = parsed->get_string( '/content/1/resource/mimeType' ) ).
    cl_abap_unit_assert=>assert_false( parsed->exists( '/content/1/resource/blob' ) ).
    cl_abap_unit_assert=>assert_false( parsed->exists( '/content/1/annotations' ) ).
  ENDMETHOD.

  METHOD test_resource_blob.
    " A non-initial blob selects the BlobResourceContents variant - no text.
    DATA resp TYPE REF TO zcl_mcp2_resp_call_tool.

    resp = NEW #( ).
    resp->add_resource( resource    = VALUE #( uri       = `file:///bin`
                                               blob      = `aGVsbG8=`
                                               mime_type = `application/octet-stream` )
                        annotations = VALUE #( audience_assistant = abap_true ) ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `aGVsbG8=`
                                        act = parsed->get_string( '/content/1/resource/blob' ) ).
    cl_abap_unit_assert=>assert_false( parsed->exists( '/content/1/resource/text' ) ).
    " EmbeddedResource annotations sit at block level, not inside resource.
    cl_abap_unit_assert=>assert_equals( exp = `assistant`
                                        act = parsed->get_string( '/content/1/annotations/audience/1' ) ).
    cl_abap_unit_assert=>assert_false( parsed->exists( '/content/1/resource/annotations' ) ).
  ENDMETHOD.

  METHOD test_resource_link.
    DATA resp TYPE REF TO zcl_mcp2_resp_call_tool.

    resp = NEW #( ).
    resp->add_resource_link( VALUE #( uri         = `mcp2://files/report.pdf`
                                      name        = `report.pdf`
                                      title       = `Q2 Report`
                                      description = `Quarterly results`
                                      mime_type   = `application/pdf`
                                      size        = 1024
                                      size_set    = abap_true
                                      icons       = VALUE #( ( src = `https://example.com/pdf.png` ) )
                                      annotations = VALUE #( last_modified = `2026-01-12T15:00:58Z` ) ) ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `resource_link`
                                        act = parsed->get_string( '/content/1/type' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `mcp2://files/report.pdf`
                                        act = parsed->get_string( '/content/1/uri' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `report.pdf`
                                        act = parsed->get_string( '/content/1/name' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `Q2 Report`
                                        act = parsed->get_string( '/content/1/title' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 1024
                                        act = parsed->get_integer( '/content/1/size' ) ).
    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_ajson_types=>node_type-number
                                        act = parsed->get_node_type( '/content/1/size' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `2026-01-12T15:00:58Z`
                                        act = parsed->get_string( '/content/1/annotations/lastModified' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `https://example.com/pdf.png`
                                        act = parsed->get_string( '/content/1/icons/1/src' ) ).
  ENDMETHOD.

  METHOD test_resource_link_min.
    " Only uri + name are required; nothing optional leaks into the block.
    DATA resp TYPE REF TO zcl_mcp2_resp_call_tool.

    resp = NEW #( ).
    resp->add_resource_link( VALUE #( uri  = `mcp2://files/a`
                                      name = `a` ) ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `resource_link`
                                        act = parsed->get_string( '/content/1/type' ) ).
    cl_abap_unit_assert=>assert_false( parsed->exists( '/content/1/title' ) ).
    cl_abap_unit_assert=>assert_false( parsed->exists( '/content/1/description' ) ).
    cl_abap_unit_assert=>assert_false( parsed->exists( '/content/1/mimeType' ) ).
    cl_abap_unit_assert=>assert_false( parsed->exists( '/content/1/size' ) ).
    cl_abap_unit_assert=>assert_false( parsed->exists( '/content/1/annotations' ) ).
  ENDMETHOD.

  METHOD test_text_with_annot.
    DATA resp TYPE REF TO zcl_mcp2_resp_call_tool.

    resp = NEW #( ).
    resp->add_text( text        = `Hi`
                    annotations = VALUE #( audience_user = abap_true ) ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `user`
                                        act = parsed->get_string( '/content/1/annotations/audience/1' ) ).
    cl_abap_unit_assert=>assert_false( parsed->exists( '/content/1/annotations/priority' ) ).
  ENDMETHOD.

  METHOD test_annotations_full.
    DATA resp TYPE REF TO zcl_mcp2_resp_call_tool.

    resp = NEW #( ).
    resp->add_text( text        = `Hi`
                    annotations = VALUE #( audience_user      = abap_true
                                           audience_assistant = abap_true
                                           priority           = '0.8'
                                           priority_set       = abap_true
                                           last_modified      = `2026-07-01T08:00:00Z` ) ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = `user`
                                        act = parsed->get_string( '/content/1/annotations/audience/1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `assistant`
                                        act = parsed->get_string( '/content/1/annotations/audience/2' ) ).
    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_ajson_types=>node_type-number
                                        act = parsed->get_node_type( '/content/1/annotations/priority' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `0.8`
                                        act = parsed->get( '/content/1/annotations/priority' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `2026-07-01T08:00:00Z`
                                        act = parsed->get_string( '/content/1/annotations/lastModified' ) ).
  ENDMETHOD.

  METHOD test_annot_prio_zero.
    " priority 0 is meaningful ("least important") - priority_set forces it out.
    DATA resp TYPE REF TO zcl_mcp2_resp_call_tool.

    resp = NEW #( ).
    resp->add_text( text        = `Hi`
                    annotations = VALUE #( priority_set = abap_true ) ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_true( parsed->exists( '/content/1/annotations/priority' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = parsed->get_integer( '/content/1/annotations/priority' ) ).
  ENDMETHOD.

  METHOD test_multiple_content.
    DATA resp TYPE REF TO zcl_mcp2_resp_call_tool.

    resp = NEW #( ).
    resp->add_text( `A` ).
    resp->add_text( `B` ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lines( parsed->members( '/content' ) ) ).
    cl_abap_unit_assert=>assert_equals( exp = `A`
                                        act = parsed->get_string( '/content/1/text' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `B`
                                        act = parsed->get_string( '/content/2/text' ) ).
  ENDMETHOD.

  METHOD test_no_cache_hints.
    " CallToolResult is not a CacheableResult - it never carries ttlMs/cacheScope.
    DATA resp TYPE REF TO zcl_mcp2_resp_call_tool.

    resp = NEW #( ).
    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = resp->zif_mcp2_result~ttl_ms( ) ).
    cl_abap_unit_assert=>assert_initial( resp->zif_mcp2_result~cache_scope( ) ).
    cl_abap_unit_assert=>assert_false( resp->zif_mcp2_result~is_cacheable( ) ).
  ENDMETHOD.

  METHOD test_structured_data.
    " ABAP data serializes into structuredContent (lowercased keys) and, by
    " default, mirrors a text block carrying the JSON string.
    DATA: BEGIN OF payload,
            value TYPE i,
            label TYPE string,
          END OF payload.
    payload-value = 42.
    payload-label = `test`.

    DATA resp TYPE REF TO zcl_mcp2_resp_call_tool.
    resp = NEW #( ).
    resp->set_structured_data( payload ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = 42
                                        act = parsed->get_integer( '/structuredContent/value' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `test`
                                        act = parsed->get_string( '/structuredContent/label' ) ).
    " Default mirror: a text block was added.
    cl_abap_unit_assert=>assert_equals( exp = `text`
                                        act = parsed->get_string( '/content/1/type' ) ).
  ENDMETHOD.

  METHOD test_struct_data_no_txt.
    DATA: BEGIN OF payload,
            value TYPE i,
          END OF payload.
    payload-value = 7.

    DATA resp TYPE REF TO zcl_mcp2_resp_call_tool.
    resp = NEW #( ).
    resp->set_structured_data( data     = payload
                               add_text = abap_false ).

    DATA(parsed) = zcl_mcp2_ajson=>parse( resp->zif_mcp2_result~to_json( )->stringify( ) ).
    cl_abap_unit_assert=>assert_equals( exp = 7
                                        act = parsed->get_integer( '/structuredContent/value' ) ).
    " No text mirror requested -> content array stays empty.
    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = lines( parsed->members( '/content' ) ) ).
  ENDMETHOD.

ENDCLASS.
