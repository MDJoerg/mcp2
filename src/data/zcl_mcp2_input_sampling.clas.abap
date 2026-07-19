"! <p class="shorttext synchronized">MCP2 sampling/createMessage builder</p>
"! Builds the params for a sampling/createMessage input request (modern MRTR).
"! Feed the result into zcl_mcp2_server_base->input_required( ) or
"! zcl_mcp2_resp_input_req->add_request. Gate it with
"! zcl_mcp2_server_base->can_request_input( ) first.
"! Note: the Sampling feature is deprecated as of 2026-07-28 (SEP-2577) with a
"! >=12-month removal window. It remains supported here because MRTR sampling
"! is the only key-less LLM access path from an ABAP server; prefer direct LLM
"! provider integration for new designs where feasible.
CLASS zcl_mcp2_input_sampling DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_mcp2_input_request.
    ALIASES get_method FOR zif_mcp2_input_request~get_method.
    ALIASES get_params FOR zif_mcp2_input_request~get_params.

    "! <p class="shorttext synchronized">Set the token budget (required)</p>
    "! Maximum number of tokens to sample. Required by the spec.
    "! @parameter tokens | Token budget
    "! @parameter self   | Same instance, for call chaining
    METHODS set_max_tokens
      IMPORTING tokens        TYPE i
      RETURNING VALUE(self)   TYPE REF TO zcl_mcp2_input_sampling.

    "! <p class="shorttext synchronized">Set the optional system prompt</p>
    "! @parameter text | System prompt text
    "! @parameter self | Same instance, for call chaining
    METHODS set_system_prompt
      IMPORTING !text         TYPE string
      RETURNING VALUE(self)   TYPE REF TO zcl_mcp2_input_sampling.

    "! <p class="shorttext synchronized">Append a user-role text message</p>
    "! @parameter text                 | Message text
    "! @parameter self                 | Same instance, for call chaining
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    METHODS add_user_text
      IMPORTING !text         TYPE string
      RETURNING VALUE(self)   TYPE REF TO zcl_mcp2_input_sampling
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Append an assistant-role text message</p>
    "! @parameter text                 | Message text
    "! @parameter self                 | Same instance, for call chaining
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    METHODS add_assistant_text
      IMPORTING !text         TYPE string
      RETURNING VALUE(self)   TYPE REF TO zcl_mcp2_input_sampling
      RAISING   zcx_mcp2_ajson_error.

  PRIVATE SECTION.
    TYPES: BEGIN OF message,
             role TYPE string,
             text TYPE string,
           END OF message.

    DATA messages      TYPE STANDARD TABLE OF message WITH EMPTY KEY.
    DATA max_tokens    TYPE i.
    DATA system_prompt TYPE string.

    "! <p class="shorttext synchronized">Append a message with the given role</p>
    "! @parameter role | Message role (user / assistant)
    "! @parameter text | Message text
    "! @parameter self | Same instance, for call chaining
    METHODS add_message
      IMPORTING role          TYPE string
                !text         TYPE string
      RETURNING VALUE(self)   TYPE REF TO zcl_mcp2_input_sampling.

ENDCLASS.


CLASS zcl_mcp2_input_sampling IMPLEMENTATION.
  METHOD set_max_tokens.
    max_tokens = tokens.
    self = me.
  ENDMETHOD.

  METHOD set_system_prompt.
    system_prompt = text.
    self = me.
  ENDMETHOD.

  METHOD add_user_text.
    self = add_message( role = `user`
                        text = text ).
  ENDMETHOD.

  METHOD add_assistant_text.
    self = add_message( role = `assistant`
                        text = text ).
  ENDMETHOD.

  METHOD add_message.
    APPEND VALUE #( role = role
                    text = text ) TO messages.
    self = me.
  ENDMETHOD.

  METHOD zif_mcp2_input_request~get_method.
    result = zif_mcp2_const=>methods-sampling_create.
  ENDMETHOD.

  METHOD zif_mcp2_input_request~get_params.
    result = zcl_mcp2_ajson=>create_empty( ).
    result->touch_array( '/messages' ).
    LOOP AT messages ASSIGNING FIELD-SYMBOL(<m>).
      DATA(mp) = |/messages/{ sy-tabix }|.
      result->set_string( iv_path = |{ mp }/role|
                          iv_val  = <m>-role ).
      result->set_string( iv_path = |{ mp }/content/type|
                          iv_val  = `text` ).
      result->set_string( iv_path = |{ mp }/content/text|
                          iv_val  = <m>-text ).
    ENDLOOP.
    " maxTokens is required by the spec; emit it (0 when unset is still valid).
    result->set_integer( iv_path = '/maxTokens'
                         iv_val  = max_tokens ).
    IF system_prompt IS NOT INITIAL.
      result->set_string( iv_path = '/systemPrompt'
                          iv_val  = system_prompt ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
