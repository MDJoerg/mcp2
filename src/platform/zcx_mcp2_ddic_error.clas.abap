"! <p class="shorttext synchronized">MCP2 DDIC error</p>
CLASS zcx_mcp2_ddic_error DEFINITION
  PUBLIC FINAL
  INHERITING FROM cx_static_check
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_t100_message.

    CONSTANTS:
      BEGIN OF zcx_mcp2_ddic_error,
        msgid TYPE symsgid  VALUE '00',
        msgno TYPE symsgno  VALUE '001',
        attr1 TYPE scx_attrname VALUE 'A1',
        attr2 TYPE scx_attrname VALUE 'A2',
        attr3 TYPE scx_attrname VALUE 'A3',
        attr4 TYPE scx_attrname VALUE 'A4',
      END OF zcx_mcp2_ddic_error.

    DATA message  TYPE string READ-ONLY.
    DATA a1 TYPE symsgv READ-ONLY.
    DATA a2 TYPE symsgv READ-ONLY.
    DATA a3 TYPE symsgv READ-ONLY.
    DATA a4 TYPE symsgv READ-ONLY.

    "! <p class="shorttext synchronized">Create a DDIC error</p>
    "! @parameter textid   | Optional T100 message key
    "! @parameter previous | Optional chained exception
    "! @parameter message  | Human-readable message (also split into a1..a4)
    "! @parameter a1       | Message placeholder 1
    "! @parameter a2       | Message placeholder 2
    "! @parameter a3       | Message placeholder 3
    "! @parameter a4       | Message placeholder 4
    METHODS constructor
      IMPORTING
        textid   LIKE if_t100_message=>t100key OPTIONAL
        previous LIKE previous                 OPTIONAL
        message  TYPE string                   OPTIONAL
        a1       TYPE symsgv                   OPTIONAL
        a2       TYPE symsgv                   OPTIONAL
        a3       TYPE symsgv                   OPTIONAL
        a4       TYPE symsgv                   OPTIONAL.

    "! <p class="shorttext synchronized">Raise a DDIC error with a message</p>
    "! @parameter msg | Human-readable error message
    "! @raising   zcx_mcp2_ddic_error | Always
    CLASS-METHODS raise
      IMPORTING msg TYPE string
      RAISING   zcx_mcp2_ddic_error.

ENDCLASS.


CLASS zcx_mcp2_ddic_error IMPLEMENTATION.

  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    CALL METHOD super->constructor
      EXPORTING
        previous = previous.
    me->message = message.
    me->a1      = a1.
    me->a2      = a2.
    me->a3      = a3.
    me->a4      = a4.
    CLEAR me->textid.
    IF textid IS INITIAL.
      if_t100_message~t100key = zcx_mcp2_ddic_error.
    ELSE.
      if_t100_message~t100key = textid.
    ENDIF.
    DATA parts TYPE c LENGTH 220.
    parts = message.
    me->a1 = parts(55).
    me->a2 = parts+55(55).
    me->a3 = parts+110(55).
    me->a4 = parts+165(55).
  ENDMETHOD.


  METHOD raise.
    RAISE EXCEPTION TYPE zcx_mcp2_ddic_error
      EXPORTING
        message = msg.
  ENDMETHOD.

ENDCLASS.
