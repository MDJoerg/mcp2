"! <p class="shorttext synchronized">MCP2 task executor contract</p>
"! Optional adapter for background workers that process tasks asynchronously.
"! Implement this interface and wire it into your server's tools/call handler
"! to delegate background execution while the framework manages state and polling.
INTERFACE zif_mcp2_task_executor PUBLIC.

  "! <p class="shorttext synchronized">Execute a newly created task</p>
  "! Called in a background job or RFC; must NOT raise on recoverable errors -
  "! call zcl_mcp2_tasks=>complete or zcl_mcp2_tasks=>fail instead.
  "! @parameter task_id | 32-char uppercase hex UUID of the task to execute
  METHODS execute
    IMPORTING task_id TYPE sysuuid_c32.

  "! <p class="shorttext synchronized">Request cancellation of a running task</p>
  "! Best-effort; the framework will transition status regardless.
  "! @parameter task_id | 32-char uppercase hex UUID of the task to cancel
  METHODS cancel
    IMPORTING task_id TYPE sysuuid_c32.

ENDINTERFACE.
