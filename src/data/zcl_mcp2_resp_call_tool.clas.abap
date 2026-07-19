"! <p class="shorttext synchronized">MCP2 tools/call response</p>
"! Use zcl_mcp2_resp_input_req to request more input instead of returning here.
CLASS zcl_mcp2_resp_call_tool DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_mcp2_result.

    "! <p class="shorttext synchronized">Create a text-only success response</p>
    "! @parameter text                 | Text payload
    "! @parameter annotations          | Optional content annotations
    "! @parameter result               | New tools/call response
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    CLASS-METHODS text
      IMPORTING !text       TYPE string
                annotations TYPE zif_mcp2_content=>annotations OPTIONAL
      RETURNING VALUE(result) TYPE REF TO zcl_mcp2_resp_call_tool
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Create a text-only tool error response</p>
    "! @parameter text                 | Error text payload
    "! @parameter annotations          | Optional content annotations
    "! @parameter result               | New tools/call response with isError=true
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    CLASS-METHODS error_text
      IMPORTING !text       TYPE string
                annotations TYPE zif_mcp2_content=>annotations OPTIONAL
      RETURNING VALUE(result) TYPE REF TO zcl_mcp2_resp_call_tool
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Create a structured response from ABAP data</p>
    "! Serializes ABAP data into structuredContent and optionally mirrors a
    "! text block carrying the JSON string.
    "! @parameter data                 | ABAP structure or table to serialize
    "! @parameter add_text             | Also add a text representation (default true)
    "! @parameter result               | New tools/call response
    "! @raising   zcx_mcp2_ajson_error | Serialization failure
    CLASS-METHODS structured_data
      IMPORTING !data    TYPE any
                add_text TYPE abap_bool DEFAULT abap_true
      RETURNING VALUE(result) TYPE REF TO zcl_mcp2_resp_call_tool
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Create a structured response from JSON</p>
    "! @parameter content | Structured result object grafted in as-is
    "! @parameter result  | New tools/call response
    CLASS-METHODS structured_json
      IMPORTING !content TYPE REF TO zif_mcp2_ajson
      RETURNING VALUE(result) TYPE REF TO zcl_mcp2_resp_call_tool.

    "! <p class="shorttext synchronized">Append a text content block</p>
    "! @parameter text                 | Text payload
    "! @parameter annotations          | Optional content annotations
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    METHODS add_text
      IMPORTING !text       TYPE string
                annotations TYPE zif_mcp2_content=>annotations OPTIONAL
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Append an image content block</p>
    "! @parameter data                 | Base64-encoded image data
    "! @parameter mime_type            | Image MIME type
    "! @parameter annotations          | Optional content annotations
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    METHODS add_image
      IMPORTING !data       TYPE string
                mime_type   TYPE string
                annotations TYPE zif_mcp2_content=>annotations OPTIONAL
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Append an audio content block</p>
    "! @parameter data                 | Base64-encoded audio data
    "! @parameter mime_type            | Audio MIME type
    "! @parameter annotations          | Optional content annotations
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    METHODS add_audio
      IMPORTING !data       TYPE string
                mime_type   TYPE string
                annotations TYPE zif_mcp2_content=>annotations OPTIONAL
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Append an embedded resource content block</p>
    "! Embeds the resource contents directly in the result. Fill exactly one
    "! of resource-text / resource-blob (a non-initial blob wins).
    "! @parameter resource             | Resource uri, text or blob, MIME type
    "! @parameter annotations          | Optional content annotations
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    METHODS add_resource
      IMPORTING resource    TYPE zif_mcp2_content=>resource_contents
                annotations TYPE zif_mcp2_content=>annotations OPTIONAL
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Append a resource_link content block</p>
    "! Links to a resource the client may fetch via resources/read instead of
    "! embedding the contents.
    "! @parameter entry                | Link uri, name, optional metadata and annotations
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    METHODS add_resource_link
      IMPORTING !entry TYPE zif_mcp2_content=>resource_link
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Mark the result as a tool error</p>
    "! Set to true when the tool returned an error payload (not an exception).
    "! @parameter flag | abap_true marks the result as an error, abap_false clears it
    METHODS set_is_error
      IMPORTING flag TYPE abap_bool DEFAULT abap_true.

    "! <p class="shorttext synchronized">Set the structuredContent payload (modern)</p>
    "! @parameter content | Structured result object grafted in as-is
    METHODS set_structured_content
      IMPORTING content TYPE REF TO zif_mcp2_ajson.

    "! <p class="shorttext synchronized">Set structuredContent from ABAP data</p>
    "! Serializes any ABAP structure/table into structuredContent - no manual
    "! JSON. By default also mirrors a text block carrying the JSON string, which
    "! the spec recommends so clients that ignore structuredContent still get a
    "! readable result.
    "! @parameter data                 | ABAP structure or table to serialize
    "! @parameter add_text             | Also add a text representation (default true)
    "! @raising   zcx_mcp2_ajson_error | Serialization failure
    METHODS set_structured_data
      IMPORTING !data    TYPE any
                add_text TYPE abap_bool DEFAULT abap_true
      RAISING   zcx_mcp2_ajson_error.

  PRIVATE SECTION.
    DATA content            TYPE STANDARD TABLE OF REF TO zif_mcp2_ajson WITH EMPTY KEY.
    DATA structured_content TYPE REF TO zif_mcp2_ajson.
    DATA error_set          TYPE abap_bool.

    "! <p class="shorttext synchronized">Emit typed annotations onto a content block</p>
    "! @parameter block                | Content-block JSON node
    "! @parameter ann                  | Typed annotation values
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    METHODS emit_annotations
      IMPORTING block TYPE REF TO zif_mcp2_ajson
                ann   TYPE zif_mcp2_content=>annotations
      RAISING   zcx_mcp2_ajson_error.

ENDCLASS.


CLASS zcl_mcp2_resp_call_tool IMPLEMENTATION.
  METHOD text.
    result = NEW zcl_mcp2_resp_call_tool( ).
    result->add_text( text        = text
                      annotations = annotations ).
  ENDMETHOD.

  METHOD error_text.
    result = text( text        = text
                   annotations = annotations ).
    result->set_is_error( abap_true ).
  ENDMETHOD.

  METHOD structured_data.
    result = NEW zcl_mcp2_resp_call_tool( ).
    result->set_structured_data( data     = data
                                 add_text = add_text ).
  ENDMETHOD.

  METHOD structured_json.
    result = NEW zcl_mcp2_resp_call_tool( ).
    result->set_structured_content( content ).
  ENDMETHOD.

  METHOD zif_mcp2_result~to_json.
    result = zcl_mcp2_ajson=>create_empty( ).
    result->touch_array( '/content' ).
    LOOP AT content ASSIGNING FIELD-SYMBOL(<blk>).
      result->set( iv_path = |/content/{ sy-tabix }|
                   iv_val  = <blk> ).
    ENDLOOP.
    IF error_set = abap_true.
      result->set( iv_path = '/isError'
                   iv_val  = abap_true ).
    ENDIF.
    IF structured_content IS BOUND.
      result->set( iv_path = '/structuredContent'
                   iv_val  = structured_content ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_mcp2_result~result_type.
    result = zif_mcp2_const=>result_types-complete.
  ENDMETHOD.

  METHOD zif_mcp2_result~ttl_ms.
    " CallToolResult is not a CacheableResult in the spec - no cache hints.
    result = 0.
  ENDMETHOD.

  METHOD zif_mcp2_result~cache_scope.
    " CallToolResult is not a CacheableResult in the spec - no cache hints.
    result = ``.
  ENDMETHOD.

  METHOD zif_mcp2_result~is_cacheable.
    " Not a spec CacheableResult - never stamped with ttlMs/cacheScope.
  ENDMETHOD.

  METHOD add_text.
    DATA block TYPE REF TO zif_mcp2_ajson.

    block = zcl_mcp2_ajson=>create_empty( ).
    block->set_string( iv_path = '/type'
                       iv_val  = `text` ).
    block->set_string( iv_path = '/text'
                       iv_val  = text ).
    emit_annotations( block = block
                      ann   = annotations ).
    APPEND block TO content.
  ENDMETHOD.

  METHOD add_image.
    DATA block TYPE REF TO zif_mcp2_ajson.

    block = zcl_mcp2_ajson=>create_empty( ).
    block->set_string( iv_path = '/type'
                       iv_val  = `image` ).
    block->set_string( iv_path = '/data'
                       iv_val  = data ).
    block->set_string( iv_path = '/mimeType'
                       iv_val  = mime_type ).
    emit_annotations( block = block
                      ann   = annotations ).
    APPEND block TO content.
  ENDMETHOD.

  METHOD add_audio.
    DATA block TYPE REF TO zif_mcp2_ajson.

    block = zcl_mcp2_ajson=>create_empty( ).
    block->set_string( iv_path = '/type'
                       iv_val  = `audio` ).
    block->set_string( iv_path = '/data'
                       iv_val  = data ).
    block->set_string( iv_path = '/mimeType'
                       iv_val  = mime_type ).
    emit_annotations( block = block
                      ann   = annotations ).
    APPEND block TO content.
  ENDMETHOD.

  METHOD add_resource.
    DATA block TYPE REF TO zif_mcp2_ajson.

    block = zcl_mcp2_ajson=>create_empty( ).
    block->set_string( iv_path = '/type'
                       iv_val  = `resource` ).
    block->set_string( iv_path = '/resource/uri'
                       iv_val  = resource-uri ).
    IF resource-blob IS NOT INITIAL.
      block->set_string( iv_path = '/resource/blob'
                         iv_val  = resource-blob ).
    ELSE.
      block->set_string( iv_path = '/resource/text'
                         iv_val  = resource-text ).
    ENDIF.
    IF resource-mime_type IS NOT INITIAL.
      block->set_string( iv_path = '/resource/mimeType'
                         iv_val  = resource-mime_type ).
    ENDIF.
    emit_annotations( block = block
                      ann   = annotations ).
    APPEND block TO content.
  ENDMETHOD.

  METHOD add_resource_link.
    DATA block TYPE REF TO zif_mcp2_ajson.

    block = zcl_mcp2_ajson=>create_empty( ).
    block->set_string( iv_path = '/type'
                       iv_val  = `resource_link` ).
    block->set_string( iv_path = '/uri'
                       iv_val  = entry-uri ).
    block->set_string( iv_path = '/name'
                       iv_val  = entry-name ).
    IF entry-title IS NOT INITIAL.
      block->set_string( iv_path = '/title'
                         iv_val  = entry-title ).
    ENDIF.
    IF entry-description IS NOT INITIAL.
      block->set_string( iv_path = '/description'
                         iv_val  = entry-description ).
    ENDIF.
    IF entry-mime_type IS NOT INITIAL.
      block->set_string( iv_path = '/mimeType'
                         iv_val  = entry-mime_type ).
    ENDIF.
    IF entry-size_set = abap_true.
      " iv_ignore_empty would swallow a size of 0 (empty resource).
      block->set( iv_path         = '/size'
                  iv_val          = entry-size
                  iv_ignore_empty = abap_false ).
    ENDIF.
    zcl_mcp2_icons=>emit( json  = block
                          path  = '/icons'
                          icons = entry-icons ).
    emit_annotations( block = block
                      ann   = entry-annotations ).
    APPEND block TO content.
  ENDMETHOD.

  METHOD emit_annotations.
    DATA index TYPE i.

    IF ann IS INITIAL.
      RETURN.
    ENDIF.
    IF ann-audience_user = abap_true OR ann-audience_assistant = abap_true.
      block->touch_array( '/annotations/audience' ).
      IF ann-audience_user = abap_true.
        index = index + 1.
        block->set_string( iv_path = |/annotations/audience/{ index }|
                           iv_val  = `user` ).
      ENDIF.
      IF ann-audience_assistant = abap_true.
        index = index + 1.
        block->set_string( iv_path = |/annotations/audience/{ index }|
                           iv_val  = `assistant` ).
      ENDIF.
    ENDIF.
    IF ann-priority_set = abap_true.
      " iv_ignore_empty would swallow a priority of 0 ("least important").
      block->set( iv_path         = '/annotations/priority'
                  iv_val          = ann-priority
                  iv_ignore_empty = abap_false ).
    ENDIF.
    IF ann-last_modified IS NOT INITIAL.
      block->set_string( iv_path = '/annotations/lastModified'
                         iv_val  = ann-last_modified ).
    ENDIF.
  ENDMETHOD.

  METHOD set_is_error.
    error_set = flag.
  ENDMETHOD.

  METHOD set_structured_content.
    structured_content = content.
  ENDMETHOD.

  METHOD set_structured_data.
    DATA(json) = zcl_mcp2_ajson=>create_empty( ).
    json->set( iv_path = '/'
               iv_val  = data ).
    structured_content = json.
    IF add_text = abap_true.
      add_text( json->stringify( ) ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
