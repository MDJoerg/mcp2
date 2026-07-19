*&---------------------------------------------------------------------*
*& Report ZMCP2_DEMO_TASK
*& Small background worker for ZCL_MCP2_DEMO_WF. It deliberately takes
*& about 15 seconds so an MCP client can observe task progress by polling.
*&---------------------------------------------------------------------*
REPORT zmcp2_demo_task.

PARAMETERS p_task TYPE sysuuid_c32 OBLIGATORY.

START-OF-SELECTION.
  TRY.
      DO 3 TIMES.
        WAIT UP TO 5 SECONDS.

        IF zcl_mcp2_tasks=>get_status( p_task ) = zif_mcp2_const=>task_statuses-cancelled.
          WRITE / `Task was cancelled; worker stopped.` ##NO_TEXT.
          RETURN.
        ENDIF.

        zcl_mcp2_tasks=>update_status(
          task_id = p_task
          status  = zif_mcp2_const=>task_statuses-working
          message = |Demo report progress: { sy-index } of 3 steps| ) ##NO_TEXT.
      ENDDO.

      DATA(payload) = NEW zcl_mcp2_resp_task_payload( ).
      payload->add_text( `Report finished: all demo rows processed.` ) ##NO_TEXT.
      zcl_mcp2_tasks=>complete( task_id = p_task
                                result  = payload ).
      WRITE / `Demo task completed.` ##NO_TEXT.
    CATCH zcx_mcp2_error zcx_mcp2_ajson_error INTO DATA(worker_error).
      TRY.
          zcl_mcp2_tasks=>fail( task_id = p_task
                                message = worker_error->get_text( ) ).
        CATCH zcx_mcp2_error.
          " The task may already have been cancelled or otherwise completed.
      ENDTRY.
      WRITE / worker_error->get_text( ).
  ENDTRY.
