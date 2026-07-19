"! <p class="shorttext synchronized">MCP2 typed content-block structures</p>
"! Shared typed structures for tool/prompt content blocks - server authors
"! never hand-build JSON for annotations, embedded resources or resource
"! links.
INTERFACE zif_mcp2_content PUBLIC.

  " One UI icon (spec type Icon). src is required (HTTP/HTTPS URL or data:
  " URI); sizes entries are `WxH` (e.g. `48x48`) or `any` for scalable
  " formats; theme is `light` / `dark` (zif_mcp2_const=>icon_themes) or
  " empty for any theme.
  TYPES: BEGIN OF icon,
           src       TYPE string,
           mime_type TYPE string,
           sizes     TYPE string_table,
           theme     TYPE string,
         END OF icon.
  " Icon set for serverInfo, tools, prompts, resources and resource links.
  TYPES icons TYPE STANDARD TABLE OF icon WITH EMPTY KEY.

  " Optional content annotations (spec type Annotations).
  " priority ranges 0..1 and 0 is meaningful ("least important"), so an
  " explicit priority is only emitted when priority_set = abap_true.
  TYPES: BEGIN OF annotations,
           audience_user      TYPE abap_bool,
           audience_assistant TYPE abap_bool,
           priority           TYPE decfloat16,
           priority_set       TYPE abap_bool,
           last_modified      TYPE string,
         END OF annotations.

  " Embedded resource contents (spec types TextResourceContents /
  " BlobResourceContents). Fill exactly one of text / blob - a non-initial
  " blob (base64) selects the binary variant.
  TYPES: BEGIN OF resource_contents,
           uri       TYPE string,
           text      TYPE string,
           blob      TYPE string,
           mime_type TYPE string,
         END OF resource_contents.

  " The resource link content block represents the spec's ResourceLink type.
  " Its size field is the raw content size in bytes. Zero is meaningful and
  " is therefore emitted only when the size-set flag is true.
  TYPES: BEGIN OF resource_link,
           uri         TYPE string,
           name        TYPE string,
           title       TYPE string,
           description TYPE string,
           mime_type   TYPE string,
           size        TYPE int8,
           size_set    TYPE abap_bool,
           icons       TYPE icons,
           annotations TYPE annotations,
         END OF resource_link.

ENDINTERFACE.
