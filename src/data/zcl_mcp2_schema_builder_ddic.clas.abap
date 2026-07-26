"! <p class="shorttext synchronized">MCP2 JSON Schema builder from DDIC</p>
"! Builds a JSON Schema by reading DDIC structure/table metadata.
"! Uses zif_mcp2_ddic for all DDIC reads so the cloud impl just swaps the impl class.
CLASS zcl_mcp2_schema_builder_ddic DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES: BEGIN OF field_override,
             field_path  TYPE string,
             name        TYPE string,
             description TYPE string,
             required    TYPE abap_bool,
             required_is_set TYPE abap_bool,
           END OF field_override.
    TYPES field_overrides TYPE STANDARD TABLE OF field_override
                          WITH NON-UNIQUE KEY field_path.

    "! <p class="shorttext synchronized">Build a JSON Schema from a DDIC structure</p>
    "! @parameter structure_name       | DDIC structure or table name
    "! @parameter overrides            | Optional per-field overrides
    "! @parameter ddic                 | DDIC reader; defaults to 7.5x impl
    "! @raising   zcx_mcp2_ddic_error   | Structure not found or invalid override
    "! @raising   zcx_mcp2_ajson_error  | JSON build failure
    METHODS constructor
      IMPORTING structure_name TYPE string
                overrides      TYPE field_overrides OPTIONAL
                ddic           TYPE REF TO zif_mcp2_ddic OPTIONAL
      RAISING   zcx_mcp2_ddic_error
                zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Return the built JSON Schema</p>
    "! @parameter result               | The built JSON Schema
    "! @raising   zcx_mcp2_ajson_error | JSON build failure
    METHODS to_json
      RETURNING VALUE(result) TYPE REF TO zif_mcp2_ajson
      RAISING   zcx_mcp2_ajson_error.

  PRIVATE SECTION.
    DATA builder   TYPE REF TO zcl_mcp2_schema_builder.
    DATA overrides TYPE field_overrides.
    DATA ddic      TYPE REF TO zif_mcp2_ddic.

    "! <p class="shorttext synchronized">Map a DDIC structure into the schema</p>
    "! @parameter structure_name       | DDIC structure or table name
    "! @parameter base_path            | Dotted path prefix for nested structures
    "! @raising   zcx_mcp2_ddic_error   | Structure not found
    "! @raising   zcx_mcp2_ajson_error  | JSON build failure
    METHODS process_structure
      IMPORTING structure_name TYPE string
                base_path      TYPE string OPTIONAL
      RAISING   zcx_mcp2_ddic_error
                zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Map one DDIC field into the schema</p>
    "! @parameter field_info           | DDIC field description
    "! @parameter base_path            | Dotted path prefix of the parent
    "! @raising   zcx_mcp2_ddic_error   | Sub-structure not found
    "! @raising   zcx_mcp2_ajson_error  | JSON build failure
    METHODS process_field
      IMPORTING field_info TYPE dfies
                base_path  TYPE string
      RAISING   zcx_mcp2_ddic_error
                zcx_mcp2_ajson_error.

    "! <p class="shorttext synchronized">Map an ABAP type to a JSON type</p>
    "! @parameter datatype | DDIC data type
    "! @parameter inttype  | ABAP internal type (fallback)
    "! @parameter result   | JSON type (string / integer / number)
    METHODS map_abap_type
      IMPORTING datatype      TYPE clike
                inttype       TYPE clike
      RETURNING VALUE(result) TYPE string.

    "! <p class="shorttext synchronized">Resolve the JSON property name for a field</p>
    "! @parameter field_info | DDIC field description
    "! @parameter base_path  | Dotted path prefix of the parent
    "! @parameter result     | Property name (override or normalized field name)
    METHODS get_field_name
      IMPORTING field_info    TYPE dfies
                base_path     TYPE string
      RETURNING VALUE(result) TYPE string.

    "! <p class="shorttext synchronized">Resolve the description text for a field</p>
    "! @parameter field_info | DDIC field description
    "! @parameter result     | Best available field text
    METHODS get_field_description
      IMPORTING field_info    TYPE dfies
      RETURNING VALUE(result) TYPE string.

    "! <p class="shorttext synchronized">Whether a field is required</p>
    "! @parameter field_info | DDIC field description
    "! @parameter base_path  | Dotted path prefix of the parent
    "! @parameter result     | abap_true when the field is required
    METHODS is_field_required
      IMPORTING field_info    TYPE dfies
                base_path     TYPE string
      RETURNING VALUE(result) TYPE abap_bool.

    "! <p class="shorttext synchronized">Look up a field override by path</p>
    "! @parameter field_path | Dotted field path
    "! @parameter result     | Matching override, or initial when none
    METHODS get_field_override
      IMPORTING field_path    TYPE string
      RETURNING VALUE(result) TYPE field_override.

    "! <p class="shorttext synchronized">Compose a dotted field path</p>
    "! @parameter base_path  | Dotted path prefix of the parent
    "! @parameter field_name | Field name to append
    "! @parameter result     | Combined dotted path
    METHODS build_field_path
      IMPORTING base_path     TYPE string
                field_name    TYPE string
      RETURNING VALUE(result) TYPE string.

    "! <p class="shorttext synchronized">Resolve the length of a field</p>
    "! @parameter field_info | DDIC field description
    "! @parameter result     | Field length, 0 when unknown
    METHODS get_field_length
      IMPORTING field_info    TYPE dfies
      RETURNING VALUE(result) TYPE i.

ENDCLASS.


CLASS zcl_mcp2_schema_builder_ddic IMPLEMENTATION.

  METHOD constructor.
    IF overrides IS SUPPLIED.
      me->overrides = overrides.
      LOOP AT me->overrides INTO DATA(ovr).
        IF ovr-field_path IS INITIAL.
          zcx_mcp2_ddic_error=>raise( |Invalid field override: field_path is empty| ) ##NO_TEXT.
        ENDIF.
      ENDLOOP.
    ENDIF.

    IF ddic IS SUPPLIED AND ddic IS BOUND.
      me->ddic = ddic.
    ELSE.
      me->ddic = NEW zcl_mcp2_ddic_75( ).
    ENDIF.

    builder = NEW zcl_mcp2_schema_builder( ).
    process_structure( to_upper( structure_name ) ).
  ENDMETHOD.

  METHOD to_json.
    result = builder->to_json( ).
  ENDMETHOD.

  METHOD process_structure.
    DATA fields TYPE ddfields.
    " Explicitly typed instead of CONV #( ): the downport cannot infer the
    " target type from the interface parameter and emits TYPE undefined.
    DATA ddic_name TYPE ddobjname.
    ddic_name = structure_name.
    TRY.
        fields = ddic->get_structure_fields( ddic_name ).
      CATCH zcx_mcp2_ddic_error.
        zcx_mcp2_ddic_error=>raise( |Structure not found: { structure_name }| ) ##NO_TEXT.
    ENDTRY.

    LOOP AT fields INTO DATA(field).
      IF field-fieldname = `.INCLUDE` OR field-fieldname IS INITIAL.
        CONTINUE.
      ENDIF.
      process_field( field_info = field
                     base_path  = base_path ).
    ENDLOOP.
  ENDMETHOD.

  METHOD process_field.
    DATA(fname) = get_field_name( field_info = field_info
                                  base_path  = base_path ).
    DATA(fpath) = build_field_path( base_path  = base_path
                                    field_name = fname ).
    DATA(fdesc) = get_field_description( field_info ).
    DATA(fovr)  = get_field_override( fpath ).
    IF fovr-description IS NOT INITIAL.
      fdesc = fovr-description.
    ENDIF.
    DATA(freq) = is_field_required( field_info = field_info
                                    base_path  = base_path ).

    CASE field_info-datatype.
      WHEN `STRU`.
        DATA(sub_struct) = COND string(
          WHEN field_info-rollname IS NOT INITIAL   THEN field_info-rollname
          WHEN field_info-checktable IS NOT INITIAL THEN field_info-checktable
          ELSE                                           field_info-fieldname ).
        builder->begin_object( name        = fname
                               description = fdesc
                               required    = freq ).
        process_structure( structure_name = sub_struct
                           base_path      = fpath ).
        builder->end_object( ).

      WHEN `TTYP`.
        builder->add_string_array( name        = fname
                                   description = fdesc
                                   required    = freq ).

      WHEN OTHERS.
        DATA(json_type) = map_abap_type( datatype = field_info-datatype
                                         inttype  = field_info-inttype ).
        CASE json_type.
          WHEN `string`.
            " Keep method-call results explicitly typed for ABAP 7.02 downport compatibility.
            DATA domain_vals TYPE string_table.
            domain_vals = ddic->get_domain_values( field_info-domname ).
            DATA(flen)        = get_field_length( field_info ).
            DATA(format_hint) = ``.
            DATA(pattern) = ``.
            CASE field_info-datatype.
              WHEN `DATS`.
                format_hint = ` (Date: YYYYMMDD)` ##NO_TEXT.
                pattern = `^[0-9]{8}$`.
              WHEN `TIMS`.
                format_hint = ` (Time: HHMMSS)` ##NO_TEXT.
                pattern = `^[0-9]{6}$`.
              WHEN `ACCP`.
                format_hint = ` (Period: YYYYMM)` ##NO_TEXT.
                pattern = `^[0-9]{6}$`.
              WHEN `NUMC`.
                format_hint = ` (Numeric text)` ##NO_TEXT.
                IF flen > 0.
                  pattern = |^[0-9]\{{ flen }\}$|.
                ENDIF.
            ENDCASE.
            DATA(final_desc) = COND string( WHEN format_hint IS NOT INITIAL
                                            THEN fdesc && format_hint
                                            ELSE fdesc ).
            IF domain_vals IS NOT INITIAL.
              DATA enum_vals TYPE zcl_mcp2_schema_builder=>enum_values.
              enum_vals = domain_vals.
              IF flen > 0.
                builder->add_string( name        = fname
                                     description = final_desc
                                     enum        = enum_vals
                                     required    = freq
                                     max_length  = flen
                                     pattern     = pattern ).
              ELSE.
                builder->add_string( name        = fname
                                     description = final_desc
                                     enum        = enum_vals
                                     required    = freq
                                     pattern     = pattern ).
              ENDIF.
            ELSEIF flen > 0.
              builder->add_string( name        = fname
                                   description = final_desc
                                   required    = freq
                                   min_length  = 0
                                   max_length  = flen
                                   pattern     = pattern ).
            ELSE.
              builder->add_string( name        = fname
                                   description = final_desc
                                   required    = freq
                                   pattern     = pattern ).
            ENDIF.

          WHEN `integer`.
            builder->add_integer( name        = fname
                                  description = fdesc
                                  required    = freq ).

          WHEN `number`.
            builder->add_number( name        = fname
                                 description = fdesc
                                 required    = freq ).

          WHEN OTHERS.
            builder->add_string( name        = fname
                                 description = fdesc
                                 required    = freq ).
        ENDCASE.
    ENDCASE.
  ENDMETHOD.

  METHOD map_abap_type.
    CASE datatype.
      WHEN `CHAR` OR `NUMC` OR `CUKY` OR `UNIT` OR `LANG` OR `CLNT`
        OR `LCHR` OR `LRAW` OR `STRING` OR `SSTRING` OR `DATS` OR `TIMS`
        OR `ACCP` OR `RAW` OR `RAWSTRING`.
        result = `string`.

      WHEN `INT1` OR `INT2` OR `INT4` OR `INT8` OR `PREC`.
        result = `integer`.

      WHEN `DEC` OR `CURR` OR `QUAN` OR `FLTP` OR `D16D` OR `D34D`
        OR `D16R` OR `D34R` OR `DECFLOAT16` OR `DECFLOAT34`.
        result = `number`.

      WHEN OTHERS.
        CASE inttype.
          WHEN `C` OR `N` OR `D` OR `T` OR `g` OR `y` OR `X`.
            result = `string`.
          WHEN `I` OR `b` OR `s` OR `8`.
            result = `integer`.
          WHEN `P` OR `F` OR `a` OR `e` OR `k`.
            result = `number`.
          WHEN OTHERS.
            result = `string`.
        ENDCASE.
    ENDCASE.
  ENDMETHOD.

  METHOD get_field_name.
    DATA(ovr) = get_field_override( build_field_path( base_path  = base_path
                                                      field_name = to_lower( field_info-fieldname ) ) ).
    IF ovr-name IS NOT INITIAL.
      result = ovr-name.
      RETURN.
    ENDIF.
    result = to_lower( field_info-fieldname ).
    REPLACE ALL OCCURRENCES OF `/` IN result WITH `_`.
    REPLACE ALL OCCURRENCES OF `-` IN result WITH `_`.
  ENDMETHOD.

  METHOD get_field_description.
    DATA(texts) = VALUE string_table(
      ( CONV string( field_info-scrtext_l ) )
      ( CONV string( field_info-scrtext_m ) )
      ( CONV string( field_info-scrtext_s ) )
      ( CONV string( field_info-fieldtext ) ) ).
    LOOP AT texts INTO DATA(txt).
      IF txt IS NOT INITIAL.
        result = txt.
        RETURN.
      ENDIF.
    ENDLOOP.
    result = |Field { field_info-fieldname }| ##NO_TEXT.
  ENDMETHOD.

  METHOD is_field_required.
    DATA(fpath) = build_field_path( base_path  = base_path
                                    field_name = to_lower( field_info-fieldname ) ).
    DATA(ovr) = get_field_override( fpath ).
    IF ovr-required_is_set = abap_true OR ovr-required = abap_true.
      result = ovr-required.
      RETURN.
    ENDIF.
    result = xsdbool( field_info-keyflag = abap_true OR field_info-datatype = `CLNT` ).
  ENDMETHOD.

  METHOD get_field_override.
    READ TABLE overrides INTO result
      WITH KEY field_path = field_path.
    IF sy-subrc <> 0.
      DATA parts TYPE TABLE OF string.
      SPLIT field_path AT '.' INTO TABLE parts.
      IF lines( parts ) > 0.
        DATA(last) = parts[ lines( parts ) ].
        READ TABLE overrides INTO result
          WITH KEY field_path = last.
        IF sy-subrc <> 0.
          CLEAR result.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD build_field_path.
    IF base_path IS INITIAL.
      result = field_name.
    ELSE.
      result = |{ base_path }.{ field_name }|.
    ENDIF.
  ENDMETHOD.

  METHOD get_field_length.
    IF field_info-outputlen > 0.
      result = field_info-outputlen.
    ELSEIF field_info-leng > 0.
      result = field_info-leng.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
