CLASS ltcl_input_sampling DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS DURATION SHORT.
  PRIVATE SECTION.
    METHODS method_is_sampling  FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS params_carry_message FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS params_carry_assistant_text FOR TESTING RAISING zcx_mcp2_ajson_error.
    METHODS implements_interface FOR TESTING RAISING zcx_mcp2_ajson_error.
ENDCLASS.

CLASS ltcl_input_sampling IMPLEMENTATION.
  METHOD method_is_sampling.
    DATA(builder) = NEW zcl_mcp2_input_sampling( ).
    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>methods-sampling_create
                                        act = builder->get_method( ) ).
  ENDMETHOD.

  METHOD params_carry_message.
    DATA(builder) = NEW zcl_mcp2_input_sampling( ).
    builder->set_max_tokens( 256 )->add_user_text( `Hello` )->set_system_prompt( `be brief` ).

    DATA(params) = builder->get_params( ).
    cl_abap_unit_assert=>assert_equals( exp = `user`
                                        act = params->get_string( '/messages/1/role' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `text`
                                        act = params->get_string( '/messages/1/content/type' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `Hello`
                                        act = params->get_string( '/messages/1/content/text' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 256
                                        act = params->get_integer( '/maxTokens' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `be brief`
                                        act = params->get_string( '/systemPrompt' ) ).
  ENDMETHOD.

  METHOD params_carry_assistant_text.
    DATA(builder) = NEW zcl_mcp2_input_sampling( ).
    builder->set_max_tokens( 128
      )->add_user_text( `Hello`
      )->add_assistant_text( `Hi, how can I help?` ).

    DATA(params) = builder->get_params( ).
    cl_abap_unit_assert=>assert_equals( exp = `user`
                                        act = params->get_string( '/messages/1/role' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `assistant`
                                        act = params->get_string( '/messages/2/role' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `text`
                                        act = params->get_string( '/messages/2/content/type' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `Hi, how can I help?`
                                        act = params->get_string( '/messages/2/content/text' ) ).
  ENDMETHOD.

  METHOD implements_interface.
    " Must be usable through the uniform input-request interface.
    DATA input TYPE REF TO zif_mcp2_input_request.
    input = NEW zcl_mcp2_input_sampling( ).
    cl_abap_unit_assert=>assert_equals( exp = zif_mcp2_const=>methods-sampling_create
                                        act = input->get_method( ) ).
  ENDMETHOD.
ENDCLASS.
