*&---------------------------------------------------------------------*
*& Report ZMCP2_CLEAR_TASKS
*& Delete expired and stuck MCP2 background tasks from the ZMCP2_TASKS
*& table. Schedule this report as a periodic background job (e.g. daily).
*&---------------------------------------------------------------------*
REPORT zmcp2_clear_tasks.

START-OF-SELECTION.
  DATA(deleted) = zcl_mcp2_tasks=>delete_outdated_tasks( ).
  WRITE: / |Deleted { deleted } outdated task(s).| ##NO_TEXT.
