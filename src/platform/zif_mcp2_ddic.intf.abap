"! <p class="shorttext synchronized">MCP2 DDIC metadata abstraction</p>
"! Wraps DDIC metadata reads used by the schema builder. The 7.5x implementation
"! calls DDIF_FIELDINFO_GET and DD_DOMVALUES_GET (classic function modules not
"! available in ABAP Cloud). A future cloud implementation provides equivalents
"! via RTTI or released APIs.
INTERFACE zif_mcp2_ddic
  PUBLIC.

  "! <p class="shorttext synchronized">Get fields of a DDIC structure or table</p>
  "! Returns the field list as produced by DDIF_FIELDINFO_GET.
  "! @parameter structure_name      | DDIC structure/table name
  "! @parameter result              | Field descriptions
  "! @raising   zcx_mcp2_ddic_error | Structure not found or internal error
  METHODS get_structure_fields
    IMPORTING structure_name TYPE ddobjname
    RETURNING VALUE(result)  TYPE ddfields
    RAISING   zcx_mcp2_ddic_error.

  "! <p class="shorttext synchronized">Get fixed domain values</p>
  "! Returns the human-readable fixed values for a domain. Returns empty table
  "! when domain_name is initial or has no fixed values.
  "! @parameter domain_name | DDIC domain name
  "! @parameter result      | Fixed values (low values, language-dependent)
  METHODS get_domain_values
    IMPORTING domain_name   TYPE domname
    RETURNING VALUE(result) TYPE string_table.

ENDINTERFACE.
