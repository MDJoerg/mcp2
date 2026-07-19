"! <p class="shorttext synchronized">MCP2 version negotiation and era detection</p>
"! All methods are class-methods.
"! Era: legacy = 2025-*, modern = 2026-07-28+.
CLASS zcl_mcp2_version DEFINITION PUBLIC FINAL CREATE PUBLIC.

  PUBLIC SECTION.
    CONSTANTS era_legacy TYPE string VALUE `legacy`.
    CONSTANTS era_modern TYPE string VALUE `modern`.

    "! <p class="shorttext synchronized">Whether a version is supported</p>
    "! @parameter version | Protocol version string
    "! @parameter result  | abap_true when in the supported set
    CLASS-METHODS is_supported
      IMPORTING !version      TYPE string
      RETURNING VALUE(result) TYPE abap_bool.

    "! <p class="shorttext synchronized">Whether a version is the modern era</p>
    "! True for 2026-07-28 and later (currently only 2026-07-28).
    "! @parameter version | Protocol version string
    "! @parameter result  | abap_true for a modern version
    CLASS-METHODS is_modern
      IMPORTING !version      TYPE string
      RETURNING VALUE(result) TYPE abap_bool.

    "! <p class="shorttext synchronized">Whether a version is the legacy era</p>
    "! True for any 2025-* version.
    "! @parameter version | Protocol version string
    "! @parameter result  | abap_true for a legacy version
    CLASS-METHODS is_legacy
      IMPORTING !version      TYPE string
      RETURNING VALUE(result) TYPE abap_bool.

    "! <p class="shorttext synchronized">Negotiate the legacy initialize version</p>
    "! A supported legacy version is echoed back exactly. Any other requested
    "! version (older, unknown, or modern) is answered with a counter-offer of
    "! our latest legacy version, as the 2025 spec revisions require: the
    "! server MUST respond with a version it supports when it does not
    "! support the requested one. Raises invalid_params only when the
    "! required protocolVersion field is missing/empty.
    "! @parameter client_ver     | Version requested by the client
    "! @parameter result         | Negotiated version (echo or counter-offer)
    "! @raising   zcx_mcp2_error | protocolVersion is missing or empty
    CLASS-METHODS negotiate_legacy
      IMPORTING client_ver    TYPE string
      RETURNING VALUE(result) TYPE string
      RAISING   zcx_mcp2_error.

    "! <p class="shorttext synchronized">Detect the era of a request</p>
    "! initialize -> legacy; server/discover -> modern; otherwise the header or
    "! the _meta protocolVersion selects the era.
    "! @parameter method         | JSON-RPC method name
    "! @parameter params         | Request params (checked for _meta version)
    "! @parameter header_ver     | MCP-Protocol-Version header, when present
    "! @parameter result         | Era (legacy / modern)
    "! @raising   zcx_mcp2_error | Header/body mismatch or unsupported version
    CLASS-METHODS detect_era
      IMPORTING !method       TYPE string
                params        TYPE REF TO zif_mcp2_ajson OPTIONAL
                header_ver    TYPE string                OPTIONAL
      RETURNING VALUE(result) TYPE string
      RAISING   zcx_mcp2_error.

ENDCLASS.


CLASS zcl_mcp2_version IMPLEMENTATION.
  METHOD is_supported.
    result = xsdbool(
         version = zif_mcp2_const=>protocol-v2025_03_26
      OR version = zif_mcp2_const=>protocol-v2025_06_18
      OR version = zif_mcp2_const=>protocol-v2025_11_25
      OR version = zif_mcp2_const=>protocol-v2026_07_28 ).
  ENDMETHOD.

  METHOD is_modern.
    result = xsdbool( version = zif_mcp2_const=>protocol-v2026_07_28 ).
  ENDMETHOD.

  METHOD is_legacy.
    result = xsdbool(
         version = zif_mcp2_const=>protocol-v2025_03_26
      OR version = zif_mcp2_const=>protocol-v2025_06_18
      OR version = zif_mcp2_const=>protocol-v2025_11_25 ).
  ENDMETHOD.

  METHOD negotiate_legacy.
    IF client_ver IS INITIAL.
      zcx_mcp2_error=>raise_invalid_params( `initialize requires protocolVersion` ) ##NO_TEXT.
    ENDIF.

    " Accept any known legacy version and echo it back so the client
    " knows exactly which data shapes to use.
    IF is_legacy( client_ver ) = abap_true.
      result = client_ver.
      RETURN.
    ENDIF.

    " Requested version not supported (older, unknown, or modern): the 2025
    " spec revisions require a counter-offer of a version we do support,
    " preferably the latest. The client disconnects if it cannot use it.
    " (Modern clients negotiate via server/discover instead of initialize.)
    result = zif_mcp2_const=>protocol-v2025_11_25.
  ENDMETHOD.

  METHOD detect_era.
    DATA body_ver TYPE string.
    DATA has_body_ver TYPE abap_bool.

    " For modern requests the header and the _meta body are two signals for
    " the same version. Compare them before checking whether either value is
    " supported, so the two possible failures are unambiguous:
    " different values -> HeaderMismatch (-32020); equal unknown value ->
    " UnsupportedProtocolVersion (-32022).
    DATA(tab)            = cl_abap_char_utilities=>horizontal_tab.
    DATA(path_proto_ver) = '/_meta/io.modelcontextprotocol' && tab && 'protocolVersion'.
    IF params IS BOUND AND params->exists( path_proto_ver ).
      body_ver = params->get_string( path_proto_ver ).
      has_body_ver = abap_true.
    ENDIF.

    IF header_ver IS SUPPLIED AND header_ver IS NOT INITIAL
       AND has_body_ver = abap_true
       AND header_ver <> body_ver.
      zcx_mcp2_error=>raise_header_mismatch(
        |MCP-Protocol-Version header '{ header_ver }' does not match _meta '{ body_ver }'| ) ##NO_TEXT.
    ENDIF.

    " Method name is the most reliable signal.
    CASE method.
      WHEN zif_mcp2_const=>methods-initialize.
        result = era_legacy.
        RETURN.
      WHEN zif_mcp2_const=>methods-server_discover.
        result = era_modern.
        RETURN.
    ENDCASE.

    " Other methods prefer the header when present and otherwise use the
    " version in metadata. The symmetric comparison above happens before
    " support is checked for the selected value.
    IF header_ver IS SUPPLIED AND header_ver IS NOT INITIAL.
      IF is_supported( header_ver ) = abap_false.
        zcx_mcp2_error=>raise_unsupported_ver( header_ver ).
      ENDIF.
      IF is_modern( header_ver ) = abap_true.
        result = era_modern.
      ELSE.
        result = era_legacy.
      ENDIF.
      RETURN.
    ENDIF.

    " Fall back to _meta in the request body.
    IF has_body_ver = abap_true.
      IF is_supported( body_ver ) = abap_false.
        zcx_mcp2_error=>raise_unsupported_ver( body_ver ).
      ENDIF.
      IF is_modern( body_ver ) = abap_true.
        result = era_modern.
      ELSE.
        result = era_legacy.
      ENDIF.
      RETURN.
    ENDIF.

    " Default: assume legacy (no version signal -> old client).
    result = era_legacy.
  ENDMETHOD.

ENDCLASS.
