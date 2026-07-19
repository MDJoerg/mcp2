"! <p class="shorttext synchronized">MCP2 basic demo server</p>
CLASS zcl_mcp2_demo_basic DEFINITION
  PUBLIC
  INHERITING FROM zcl_mcp2_tool_server_base
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS zif_mcp2_server~get_name             REDEFINITION.
    METHODS zif_mcp2_server~get_version          REDEFINITION.
    METHODS zif_mcp2_server~get_title            REDEFINITION.
    METHODS zif_mcp2_server~get_description      REDEFINITION.
    METHODS zif_mcp2_server~get_instructions     REDEFINITION.
    METHODS zif_mcp2_server~get_discover_cache   REDEFINITION.
    METHODS zif_mcp2_server~supports_resources   REDEFINITION.
    METHODS zif_mcp2_server~supports_prompts     REDEFINITION.
    METHODS zif_mcp2_server~supports_completions REDEFINITION.
    METHODS zif_mcp2_server~resources_list       REDEFINITION.
    METHODS zif_mcp2_server~resources_read       REDEFINITION.
    METHODS zif_mcp2_server~resources_tmpls_list REDEFINITION.
    METHODS zif_mcp2_server~prompts_list         REDEFINITION.
    METHODS zif_mcp2_server~prompts_get          REDEFINITION.
    METHODS zif_mcp2_server~completions_complete REDEFINITION.

  PROTECTED SECTION.
    METHODS define_tools REDEFINITION.
    METHODS call_tool REDEFINITION.

  PRIVATE SECTION.
    " Shared by define_tools and call_tool so the catalog and the dispatch
    " cannot drift apart.
    CONSTANTS: BEGIN OF tool_names,
                 echo        TYPE string VALUE `echo`,
                 text_stats  TYPE string VALUE `text_stats`,
                 price_quote TYPE string VALUE `price_quote`,
                 ddic_schema TYPE string VALUE `ddic_schema`,
                 request_info TYPE string VALUE `request_info`,
               END OF tool_names.

    " Field names double as the JSON property names (bind_arguments and
    " set_structured_data match by name), so keep them lower snake_case.
    TYPES: BEGIN OF text_stats_args,
             text              TYPE string,
             uppercase_preview TYPE abap_bool,
           END OF text_stats_args.
    TYPES: BEGIN OF text_stats_result,
             chars   TYPE i,
             words   TYPE i,
             preview TYPE string,
           END OF text_stats_result.
    " Amounts are decfloat34 rather than a binary float so the money values
    " survive the round trip exactly.
    TYPES: BEGIN OF price_quote_result,
             line_count TYPE i,
             units      TYPE i,
             tag_count  TYPE i,
             gross      TYPE decfloat34,
             net        TYPE decfloat34,
           END OF price_quote_result.
    " Client and server task capability are separate facts. Reporting only the
    " client side would claim tasks are usable on an endpoint that does not
    " advertise them - the dispatcher gates tasks/* on the SERVER flag.
    TYPES: BEGIN OF request_info_result,
             era                         TYPE string,
             protocol_version            TYPE string,
             client_name                 TYPE string,
             client_accepts_task_results TYPE abap_bool,
             server_offers_tasks         TYPE abap_bool,
           END OF request_info_result.

    "! <p class="shorttext synchronized">Build the input schema for the echo tool</p>
    "! @parameter result | JSON Schema for the echo tool arguments
    "! @raising zcx_mcp2_ajson_error | JSON build/parse failure
    METHODS build_echo_schema
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Build the input schema for text_stats</p>
    "! @parameter result | JSON Schema for the text_stats arguments
    "! @raising zcx_mcp2_ajson_error | JSON build/parse failure
    METHODS build_stats_schema
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Build the output schema for text_stats</p>
    "! @parameter result | JSON Schema for the text_stats structured result
    "! @raising zcx_mcp2_ajson_error | JSON build/parse failure
    METHODS build_stats_output
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Build the input schema for price_quote</p>
    "! @parameter result | JSON Schema for the price_quote arguments
    "! @raising zcx_mcp2_ajson_error | JSON build/parse failure
    METHODS build_price_quote_schema
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Build the output schema for price_quote</p>
    "! @parameter result | JSON Schema for the price_quote structured result
    "! @raising zcx_mcp2_ajson_error | JSON build/parse failure
    METHODS build_price_quote_output
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Build the input schema for ddic_schema</p>
    "! @parameter result | JSON Schema for the ddic_schema arguments
    "! @raising zcx_mcp2_ajson_error | JSON build/parse failure
    METHODS build_ddic_tool_schema
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Build the output schema for request_info</p>
    METHODS build_request_info_output
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Handle the echo tool</p>
    "! @parameter request | Parsed tools/call request
    "! @parameter result  | Text result echoing the message argument
    "! @raising zcx_mcp2_ajson_error | JSON build failure
    METHODS handle_echo
      IMPORTING !request      TYPE REF TO zcl_mcp2_req_call_tool
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_result
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Handle the text_stats tool</p>
    "! Binds the arguments into a typed structure and returns structured data.
    "! @parameter request | Parsed tools/call request
    "! @parameter result  | Structured statistics result
    "! @raising zcx_mcp2_ajson_error | JSON build failure
    METHODS handle_text_stats
      IMPORTING !request      TYPE REF TO zcl_mcp2_req_call_tool
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_result
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Handle the price_quote tool</p>
    "! Shows decimal and array arguments: decfloat34 money via get_arg_number
    "! plus get_arg_string_table / get_arg_integer_table for the arrays.
    "! @parameter request | Parsed tools/call request
    "! @parameter result  | Structured quote result
    "! @raising zcx_mcp2_error       | Missing required argument
    "! @raising zcx_mcp2_ajson_error | JSON build failure
    METHODS handle_price_quote
      IMPORTING !request      TYPE REF TO zcl_mcp2_req_call_tool
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_result
      RAISING   zcx_mcp2_error
                zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Handle the ddic_schema tool</p>
    "! Generates a JSON Schema from a DDIC structure via the DDIC builder.
    "! @parameter request | Parsed tools/call request
    "! @parameter result  | Structured schema result, or isError for bad names
    "! @raising zcx_mcp2_error | Missing structure_name argument
    "! @raising zcx_mcp2_ajson_error | JSON build failure
    METHODS handle_ddic_schema
      IMPORTING !request      TYPE REF TO zcl_mcp2_req_call_tool
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_result
      RAISING   zcx_mcp2_error
                zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Show the era-aware request context</p>
    METHODS handle_request_info
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_result
      RAISING   zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Add candidates that start with the typed prefix</p>
    "! Completion returns whole values, never the prefix plus a suffix.
    "! @parameter response   | Completion response being built
    "! @parameter candidates | Full candidate values for this argument
    "! @parameter prefix     | What the user has typed so far (may be empty)
    METHODS add_matching
      IMPORTING response   TYPE REF TO zcl_mcp2_resp_complete
                candidates TYPE string_table
                prefix     TYPE string.

ENDCLASS.


CLASS zcl_mcp2_demo_basic IMPLEMENTATION.
  METHOD zif_mcp2_server~get_name.
    result = `mcp2-demo-basic`.
  ENDMETHOD.

  METHOD zif_mcp2_server~get_version.
    result = `1.0.0`.
  ENDMETHOD.

  METHOD zif_mcp2_server~get_title.
    " Shown in client UIs instead of the technical get_name value.
    result = `MCP2 Basic Demo` ##NO_TEXT.
  ENDMETHOD.

  METHOD zif_mcp2_server~get_description.
    result = `Reference server for the MCP2 ABAP SDK: tools, schemas, resources, ` &&
             `prompts, completions and era-aware request context.` ##NO_TEXT.
  ENDMETHOD.

  METHOD zif_mcp2_server~get_instructions.
    result = `Start with request_info to see which protocol era was negotiated. ` &&
             `Then try echo, text_stats, ddic_schema, resources, prompts, and completions.` ##NO_TEXT.
  ENDMETHOD.

  METHOD zif_mcp2_server~get_discover_cache.
    " Discovery describes the shape of the server, not user data: it changes
    " only when this class is re-transported, so it tolerates a long TTL and is
    " safe to share across authorization contexts. Keep the conservative base
    " default (ttl 0 / private) instead whenever the catalog varies per user.
    result-ttl_ms      = 3600000.
    result-cache_scope = zif_mcp2_const=>cache_scopes-public.
  ENDMETHOD.

  METHOD zif_mcp2_server~supports_resources.
    result = abap_true.
  ENDMETHOD.

  METHOD zif_mcp2_server~supports_prompts.
    result = abap_true.
  ENDMETHOD.

  METHOD zif_mcp2_server~supports_completions.
    result = abap_true.
  ENDMETHOD.

  METHOD define_tools.
    " Every tool here only reads: annotate them so a client can present them
    " without a confirmation prompt. Note the tri-state rule - destructive_hint
    " and open_world_hint default to TRUE in the spec, so an explicit false
    " needs the paired *_set flag; read_only_hint and idempotent_hint do not.
    DATA(read_only) = VALUE zcl_mcp2_resp_list_tools=>tool_annotations(
        read_only_hint      = abap_true
        idempotent_hint     = abap_true
        destructive_hint    = abap_false
        destructive_hint_set = abap_true
        open_world_hint     = abap_false
        open_world_hint_set = abap_true ).

    result = VALUE #(
        ( name         = tool_names-echo
          title        = `Echo`
          description  = `Returns the message argument and mirrors it through Mcp-Param-Message.`
          input_schema = build_echo_schema( )
          annotations  = read_only )
        ( name          = tool_names-text_stats
          title         = `Text statistics`
          description   = `Counts characters and words of a text and returns a structured result.`
          input_schema  = build_stats_schema( )
          output_schema = build_stats_output( )
          annotations   = read_only )
        ( name          = tool_names-price_quote
          title         = `Price quote`
          description   = `Totals order-line quantities at a unit price and applies a discount.`
          input_schema  = build_price_quote_schema( )
          output_schema = build_price_quote_output( )
          annotations   = read_only )
        ( name         = tool_names-ddic_schema
          title        = `DDIC JSON Schema`
          description  = `Generates a JSON Schema from a DDIC structure or table name.`
          input_schema = build_ddic_tool_schema( )
          annotations  = read_only )
        ( name          = tool_names-request_info
          title         = `Request compatibility info`
          description   = `Shows the negotiated protocol era plus client and server task capability.`
          input_schema  = NEW zcl_mcp2_schema_builder( )->to_json( )
          output_schema = build_request_info_output( )
          annotations   = read_only ) ) ##NO_TEXT.
  ENDMETHOD.

  METHOD call_tool.
    " The base class rejects names outside define_tools before this runs and
    " validates the arguments against the declared input schema.
    CASE request->get_name( ).
      WHEN tool_names-echo.
        result = handle_echo( request ).
      WHEN tool_names-text_stats.
        result = handle_text_stats( request ).
      WHEN tool_names-price_quote.
        result = handle_price_quote( request ).
      WHEN tool_names-ddic_schema.
        result = handle_ddic_schema( request ).
      WHEN tool_names-request_info.
        result = handle_request_info( ).
    ENDCASE.
  ENDMETHOD.

  METHOD handle_request_info.
    DATA info TYPE request_info_result.
    info-era = COND #( WHEN era_is_modern( ) = abap_true THEN `modern` ELSE `legacy` ).
    info-protocol_version = get_protocol_version( ).
    info-client_name = get_client_name( ).
    " Client side: would this caller accept a task result (modern extension /
    " legacy per-call params.task)?
    info-client_accepts_task_results = client_supports_tasks( ).
    " Server side: does THIS endpoint advertise tasks at all? This demo does not
    " (see ZCL_MCP2_DEMO_WF), so a task can never be created here even when the
    " client would accept one. Reporting only the client flag would be a lie.
    info-server_offers_tasks = zif_mcp2_server~supports_tasks( ).
    result = zcl_mcp2_resp_call_tool=>structured_data( info ).
  ENDMETHOD.

  METHOD handle_echo.
    DATA(message) = request->get_arg_string_or( name          = `message`
                                                default_value = `Hello from MCP2` ) ##NO_TEXT.

    result = zcl_mcp2_resp_call_tool=>text( message ).
  ENDMETHOD.

  METHOD handle_price_quote.
    " get_arg_number returns decfloat34 and converts from the raw JSON
    " literal, so a price like 19.99 stays exact instead of being rounded
    " through a binary float. Use it for money rather than a float getter.
    DATA(unit_price) = request->require_arg_number( `unit_price` ).

    " The schema declares default 0, but a client is not obliged to send it -
    " the handler still supplies the fallback itself.
    DATA(discount_pct) = request->get_arg_number_or( name          = `discount_pct`
                                                     default_value = 0 ).

    " Arrays of primitives have typed readers too - no raw JSON, and no need
    " to declare a structure just to bind one argument.
    " Explicitly typed: string_table returns are not inferrable by the
    " downport tooling.
    DATA tags TYPE string_table.
    tags = request->get_arg_string_table( `tags` ).
    DATA(quantities) = request->get_arg_integer_table( `quantities` ).

    DATA quote TYPE price_quote_result.
    quote-line_count = lines( quantities ).
    quote-tag_count  = lines( tags ).
    LOOP AT quantities INTO DATA(quantity).
      quote-units = quote-units + quantity.
    ENDLOOP.

    quote-gross = unit_price * quote-units.
    quote-net   = quote-gross * ( 1 - discount_pct / 100 ).

    result = zcl_mcp2_resp_call_tool=>structured_data( quote ).
  ENDMETHOD.

  METHOD handle_text_stats.
    " No manual JSON: bind_arguments fills the typed structure by field name,
    " structured_data serializes one back into structuredContent (plus a
    " mirrored text block for clients that ignore structured results).
    DATA args TYPE text_stats_args.
    request->bind_arguments( CHANGING target = args ).

    DATA stats TYPE text_stats_result.
    stats-chars = strlen( args-text ).

    DATA(condensed) = condense( args-text ).
    IF condensed IS NOT INITIAL.
      SPLIT condensed AT ` ` INTO TABLE DATA(words).
      stats-words = lines( words ).
    ENDIF.

    stats-preview = COND #( WHEN args-uppercase_preview = abap_true
                            THEN to_upper( condensed )
                            ELSE condensed ).
    IF strlen( stats-preview ) > 32.
      stats-preview = stats-preview(32).
    ENDIF.

    result = zcl_mcp2_resp_call_tool=>structured_data( stats ).
  ENDMETHOD.

  METHOD handle_ddic_schema.
    DATA(structure_name) = to_upper( request->require_arg_string( `structure_name` ) ) ##NO_TEXT.

    DATA schema TYPE REF TO zif_mcp2_ajson.
    TRY.
        schema = NEW zcl_mcp2_schema_builder_ddic( structure_name )->to_json( ).
      CATCH zcx_mcp2_ddic_error INTO DATA(ddic_error).
        " A bad structure name is a tool-level failure the model can react to:
        " return an isError result instead of raising a protocol error.
        result = zcl_mcp2_resp_call_tool=>error_text(
          |{ structure_name }: { ddic_error->get_text( ) }| ).
        RETURN.
    ENDTRY.

    DATA(response) = zcl_mcp2_resp_call_tool=>structured_json( schema ).
    response->add_text( schema->stringify( 2 ) ).
    result = response.
  ENDMETHOD.

  METHOD zif_mcp2_server~resources_list.
    DATA(response) = NEW zcl_mcp2_resp_list_resources( ).
    response->add_resource( VALUE #( uri         = `mcp2://demo/readme`
                                     name        = `readme`
                                     title       = `Demo README`
                                     description = `Static text resource`
                                     mime_type   = `text/plain` ) ) ##NO_TEXT.
    result = response.
  ENDMETHOD.

  METHOD zif_mcp2_server~resources_read.
    DATA(uri) = request->get_uri( ).
    IF uri CP `mcp2://demo/greeting/*`.
      DATA(name) = uri+21.
      IF name IS INITIAL.
        zcx_mcp2_error=>raise_resource_not_found( uri ).
      ENDIF.
      DATA(greeting) = NEW zcl_mcp2_resp_read_resource( ).
      greeting->add_text_content( uri       = uri
                                  text      = |Hello { name } from an expanded resource template.|
                                  mime_type = `text/plain` ) ##NO_TEXT.
      result = greeting.
      RETURN.
    ELSEIF uri <> `mcp2://demo/readme`.
      zcx_mcp2_error=>raise_resource_not_found( request->get_uri( ) ).
    ENDIF.

    DATA(response) = NEW zcl_mcp2_resp_read_resource( ).
    response->add_text_content( uri       = request->get_uri( )
                                text      = `This is a stateless MCP2 demo resource.`
                                mime_type = `text/plain` ) ##NO_TEXT.
    result = response.
  ENDMETHOD.

  METHOD zif_mcp2_server~resources_tmpls_list.
    DATA(response) = NEW zcl_mcp2_resp_list_res_tmpls( ).
    response->add_template( VALUE #( uri_template = `mcp2://demo/greeting/{name}`
                                     name         = `greeting-by-name`
                                     title        = `Greeting by name`
                                     description  = `Expand the template and read the resulting URI`
                                     mime_type    = `text/plain` ) ) ##NO_TEXT.
    result = response.
  ENDMETHOD.

  METHOD zif_mcp2_server~prompts_list.
    DATA(response) = NEW zcl_mcp2_resp_list_prompts( ).
    response->add_prompt( VALUE #( name        = `summarize`
                                   title       = `Summarize`
                                   description = `Create a short summary request`
                                   arguments   = VALUE #(
                                       ( name = `topic` description = `Topic to summarize` required = abap_true ) ) ) ) ##NO_TEXT.
    result = response.
  ENDMETHOD.

  METHOD zif_mcp2_server~prompts_get.
    IF request->get_name( ) <> `summarize`.
      zcx_mcp2_error=>raise_invalid_params( |Unknown prompt: { request->get_name( ) }| ) ##NO_TEXT.
    ENDIF.

    " topic is declared required in prompts_list, so read it as required.
    DATA(topic) = request->require_arg_string( `topic` ) ##NO_TEXT.

    DATA(response) = NEW zcl_mcp2_resp_get_prompt( ).
    response->set_description( `Demo summarization prompt` ) ##NO_TEXT.
    response->add_user_text( |Summarize { topic } in three bullets.| ) ##NO_TEXT.
    result = response.
  ENDMETHOD.

  METHOD zif_mcp2_server~completions_complete.
    " A completion returns whole candidate values that START WITH what the user
    " has typed - it never appends to the partial input. The client replaces the
    " argument with the chosen value, so returning "{typed}Ada" would produce
    " "AAda" for input "A".
    DATA(response) = NEW zcl_mcp2_resp_complete( ).
    " Candidates sit in a typed local rather than an inline VALUE argument so
    " the downport tooling can rewrite the constructor.
    DATA candidates TYPE string_table.
    IF request->get_ref_type( ) = zcl_mcp2_req_complete=>ref_type-resource
       AND request->get_ref_uri( ) = `mcp2://demo/greeting/{name}`
       AND request->get_argument_name( ) = `name`.
      candidates = VALUE #( ( `Ada` ) ( `Alan` ) ( `Basti` ) ) ##NO_TEXT.
      add_matching( response   = response
                    candidates = candidates
                    prefix     = request->get_argument_value( ) ).
    ELSEIF request->get_ref_type( ) = zcl_mcp2_req_complete=>ref_type-prompt
       AND request->get_ref_name( ) = `summarize`
       AND request->get_argument_name( ) = `topic`.
      candidates = VALUE #( ( `ABAP` ) ( `MCP` ) ) ##NO_TEXT.
      add_matching( response   = response
                    candidates = candidates
                    prefix     = request->get_argument_value( ) ).
    ELSE.
      " Unrelated reference: complete nothing rather than guessing.
      response->set_total( 0 ).
    ENDIF.
    response->set_has_more( abap_false ).
    result = response.
  ENDMETHOD.

  METHOD add_matching.
    DATA(matches) = 0.
    LOOP AT candidates INTO DATA(candidate).
      " Case-insensitive prefix match; an empty prefix offers every candidate.
      IF prefix IS INITIAL OR to_upper( candidate ) CP |{ to_upper( prefix ) }*|.
        response->add_value( candidate ).
        matches = matches + 1.
      ENDIF.
    ENDLOOP.
    response->set_total( matches ).
  ENDMETHOD.

  METHOD build_echo_schema.
    result = NEW zcl_mcp2_schema_builder(
      )->add_string( name         = `message`
                     description  = `Message to echo`
                     x_mcp_header = `Message`
      )->to_json( ) ##NO_TEXT.
  ENDMETHOD.

  METHOD build_price_quote_schema.
    " title is what a client shows instead of the raw property name; default
    " is emitted even when it is 0, so the client can prefill the field.
    result = NEW zcl_mcp2_schema_builder(
      )->add_number( name        = `unit_price`
                     title       = `Unit price`
                     description = `Price of a single unit`
                     required    = abap_true
                     minimum     = '0.0'
      )->add_integer_array( name        = `quantities`
                            title       = `Quantities`
                            description = `One quantity per order line`
                            required    = abap_true
                            min_items   = 1
      )->add_number( name        = `discount_pct`
                     title       = `Discount %`
                     description = `Percentage taken off the gross amount`
                     default     = '0.0'
                     minimum     = '0.0'
                     maximum     = '100.0'
      )->add_string_array( name        = `tags`
                           title       = `Tags`
                           description = `Free labels stored with the quote`
      )->to_json( ) ##NO_TEXT.
  ENDMETHOD.

  METHOD build_price_quote_output.
    result = NEW zcl_mcp2_schema_builder(
      )->add_integer( name = `line_count` title = `Order lines`
      )->add_integer( name = `units`      title = `Total units`
      )->add_integer( name = `tag_count`  title = `Tag count`
      )->add_number(  name = `gross`      title = `Gross amount`
      )->add_number(  name = `net`        title = `Net amount`
      )->to_json( ) ##NO_TEXT.
  ENDMETHOD.

  METHOD build_stats_schema.
    result = NEW zcl_mcp2_schema_builder(
      )->add_string( name        = `text`
                     description = `Text to analyze`
                     required    = abap_true
      )->add_boolean( name        = `uppercase_preview`
                      description = `Return the preview in upper case`
      )->to_json( ) ##NO_TEXT.
  ENDMETHOD.

  METHOD build_stats_output.
    result = NEW zcl_mcp2_schema_builder(
      )->add_integer( name        = `chars`
                      description = `Character count`
                      required    = abap_true
      )->add_integer( name        = `words`
                      description = `Word count`
                      required    = abap_true
      )->add_string( name        = `preview`
                     description = `First 32 characters of the text`
                     required    = abap_true
      )->to_json( ) ##NO_TEXT.
  ENDMETHOD.

  METHOD build_ddic_tool_schema.
    result = NEW zcl_mcp2_schema_builder(
      )->add_string( name        = `structure_name`
                     description = `DDIC structure or table name, e.g. ZMCP2_SERVERS`
                     required    = abap_true
                     min_length  = 1
      )->to_json( ) ##NO_TEXT.
  ENDMETHOD.

  METHOD build_request_info_output.
    result = NEW zcl_mcp2_schema_builder(
      )->add_string( name = `era` required = abap_true
      )->add_string( name = `protocol_version` required = abap_true
      )->add_string( name = `client_name` required = abap_true
      )->add_boolean( name = `client_accepts_task_results` required = abap_true
      )->add_boolean( name = `server_offers_tasks` required = abap_true
      )->to_json( ).
  ENDMETHOD.

ENDCLASS.
