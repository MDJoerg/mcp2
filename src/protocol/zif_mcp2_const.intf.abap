"! <p class="shorttext synchronized">MCP2 protocol constants</p>
INTERFACE zif_mcp2_const PUBLIC.

  " Version of this SDK, not of the MCP protocol (see protocol below) and not
  " of the server built on it (that is zif_mcp2_server~get_version).
  CONSTANTS sdk_version TYPE string VALUE `1.0.0`.

  CONSTANTS jsonrpc_version TYPE string VALUE `2.0`.

  CONSTANTS: BEGIN OF protocol,
               v2025_03_26   TYPE string VALUE `2025-03-26`,
               v2025_06_18   TYPE string VALUE `2025-06-18`,
               v2025_11_25   TYPE string VALUE `2025-11-25`,
               v2026_07_28   TYPE string VALUE `2026-07-28`,
               latest_legacy TYPE string VALUE `2025-11-25`,
               latest        TYPE string VALUE `2026-07-28`,
             END OF protocol.

  CONSTANTS: BEGIN OF eras,
               modern TYPE string VALUE `modern`,
               legacy TYPE string VALUE `legacy`,
             END OF eras.

  CONSTANTS: BEGIN OF methods,
               initialize           TYPE string VALUE `initialize`,
               ping                 TYPE string VALUE `ping`,
               server_discover      TYPE string VALUE `server/discover`,
               tools_list           TYPE string VALUE `tools/list`,
               tools_call           TYPE string VALUE `tools/call`,
               resources_list       TYPE string VALUE `resources/list`,
               resources_read       TYPE string VALUE `resources/read`,
               resources_tmpls_list TYPE string VALUE `resources/templates/list`,
               prompts_list         TYPE string VALUE `prompts/list`,
               prompts_get          TYPE string VALUE `prompts/get`,
               completions          TYPE string VALUE `completion/complete`,
               logging_set_level    TYPE string VALUE `logging/setLevel`,
               elicitation_create   TYPE string VALUE `elicitation/create`,
               sampling_create      TYPE string VALUE `sampling/createMessage`,
               tasks_get            TYPE string VALUE `tasks/get`,
               tasks_update         TYPE string VALUE `tasks/update`,
               tasks_cancel         TYPE string VALUE `tasks/cancel`,
               tasks_list           TYPE string VALUE `tasks/list`,
               tasks_result         TYPE string VALUE `tasks/result`,
             END OF methods.

  CONSTANTS: BEGIN OF result_types,
               complete       TYPE string VALUE `complete`,
               input_required TYPE string VALUE `input_required`,
               task           TYPE string VALUE `task`,
             END OF result_types.

  CONSTANTS: BEGIN OF elicit_modes,
               form TYPE string VALUE `form`,
               url  TYPE string VALUE `url`,
             END OF elicit_modes.

  CONSTANTS: BEGIN OF elicit_actions,
               accept  TYPE string VALUE `accept`,
               decline TYPE string VALUE `decline`,
               cancel  TYPE string VALUE `cancel`,
             END OF elicit_actions.

  " The only string formats a StringSchema may declare in elicitation forms.
  CONSTANTS: BEGIN OF elicit_formats,
               date      TYPE string VALUE `date`,
               date_time TYPE string VALUE `date-time`,
               email     TYPE string VALUE `email`,
               uri       TYPE string VALUE `uri`,
             END OF elicit_formats.

  " Icon theme values (spec type Icon; empty theme = usable with any theme).
  CONSTANTS: BEGIN OF icon_themes,
               light TYPE string VALUE `light`,
               dark  TYPE string VALUE `dark`,
             END OF icon_themes.

  CONSTANTS: BEGIN OF extensions,
               tasks TYPE string VALUE `io.modelcontextprotocol/tasks`,
             END OF extensions.

  " Client capability keys declared under clientCapabilities (modern _meta).
  " Roots (deprecated in 2026-07-28, SEP-2577) is intentionally not supported:
  " client filesystem roots are meaningless to a remote ABAP server.
  CONSTANTS: BEGIN OF client_caps,
               elicitation TYPE string VALUE `elicitation`,
               sampling    TYPE string VALUE `sampling`,
             END OF client_caps.

  " Tool-level task negotiation (legacy 2025-11-25 tools/list execution.taskSupport).
  CONSTANTS: BEGIN OF task_support,
               required  TYPE string VALUE `required`,
               optional  TYPE string VALUE `optional`,
               forbidden TYPE string VALUE `forbidden`,
             END OF task_support.

  CONSTANTS: BEGIN OF task_statuses,
               working        TYPE string VALUE `working`,
               completed      TYPE string VALUE `completed`,
               failed         TYPE string VALUE `failed`,
               cancelled      TYPE string VALUE `cancelled`,
               input_required TYPE string VALUE `input_required`,
             END OF task_statuses.

  CONSTANTS: BEGIN OF cache_scopes,
               public  TYPE string VALUE `public`,
               private TYPE string VALUE `private`,
             END OF cache_scopes.

  " Spec-defined JSON-RPC error codes.
  " -32020..-32022 are the correct spec codes (old SDK used non-standard -32001/-32004).
  " -32002 is the latest-legacy resources/read unknown-URI code. The modern
  " dispatcher maps it to -32602 at its era boundary.
  CONSTANTS: BEGIN OF error_codes,
               parse_error         TYPE i VALUE -32700,
               invalid_request     TYPE i VALUE -32600,
               method_not_found    TYPE i VALUE -32601,
               invalid_params      TYPE i VALUE -32602,
               internal_error      TYPE i VALUE -32603,
               resource_not_found  TYPE i VALUE -32002,
               header_mismatch     TYPE i VALUE -32020,
               missing_client_cap  TYPE i VALUE -32021,
               unsupported_version TYPE i VALUE -32022,
             END OF error_codes.

  CONSTANTS: BEGIN OF headers,
               protocol_version TYPE string VALUE `MCP-Protocol-Version` ##NO_TEXT,
               method           TYPE string VALUE `Mcp-Method` ##NO_TEXT,
               name             TYPE string VALUE `Mcp-Name` ##NO_TEXT,
             END OF headers.

  " Literal key names used inside the _meta object (contain forward slashes).
  CONSTANTS: BEGIN OF meta_keys,
               protocol_version    TYPE string VALUE `io.modelcontextprotocol/protocolVersion`,
               client_info         TYPE string VALUE `io.modelcontextprotocol/clientInfo`,
               client_capabilities TYPE string VALUE `io.modelcontextprotocol/clientCapabilities`,
               log_level           TYPE string VALUE `io.modelcontextprotocol/logLevel`,
             END OF meta_keys.

ENDINTERFACE.
