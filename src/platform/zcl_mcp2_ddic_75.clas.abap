"! <p class="shorttext synchronized">MCP2 DDIC metadata - 7.5x impl</p>
"! 7.5x implementation of ZIF_MCP2_DDIC. Uses the classic function modules
"! DDIF_FIELDINFO_GET and DD_DOMVALUES_GET which are not available on ABAP Cloud.
"! When cloud support is required, only this class (and the factory) changes.
CLASS zcl_mcp2_ddic_75 DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_mcp2_ddic.

ENDCLASS.


CLASS zcl_mcp2_ddic_75 IMPLEMENTATION.
  METHOD zif_mcp2_ddic~get_structure_fields.
    CALL FUNCTION 'DDIF_FIELDINFO_GET'
      EXPORTING  tabname        = structure_name
                 langu          = sy-langu
      TABLES     dfies_tab      = result
      EXCEPTIONS not_found      = 1
                 internal_error = 2
                 OTHERS         = 3.

    IF sy-subrc <> 0.
      zcx_mcp2_ddic_error=>raise( |Structure not found: { structure_name }| ) ##NO_TEXT.
    ENDIF.
  ENDMETHOD.

  METHOD zif_mcp2_ddic~get_domain_values.
    IF domain_name IS INITIAL.
      RETURN.
    ENDIF.

    DATA domain_values TYPE TABLE OF dd07v.
    CALL FUNCTION 'DD_DOMVALUES_GET'
      EXPORTING  domname        = domain_name
                 text           = abap_true
                 langu          = sy-langu
      TABLES     dd07v_tab      = domain_values
      EXCEPTIONS wrong_textflag = 1
                 OTHERS         = 2.

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    LOOP AT domain_values INTO DATA(val) WHERE valpos IS NOT INITIAL.
      APPEND val-domvalue_l TO result.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
