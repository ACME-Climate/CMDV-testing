
MESSAGE("CMDV_PY_DIR=${CMDV_PY_DIR}")
MESSAGE("CLONE_DIR_PATH=${CMDV_PY_DIR}")

EXECUTE_PROCESS(COMMAND bash set_paths.sh ${CMDV_PY_DIR} ${CLONE_DIR_PATH}
    RESULT_VARIABLE ERROR1)
if(ERROR1)
        message(FATAL_ERROR "Error setting paths!")
endif()

EXECUTE_PROCESS(COMMAND bash runUnitTest.sh ${PY_PATH}
    RESULT_VARIABLE ERROR)
if(ERROR)
        message(FATAL_ERROR "Test failed!")
endif()


