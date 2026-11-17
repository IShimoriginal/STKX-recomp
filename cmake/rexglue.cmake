# ==============================================================================
# cmake/rexglue.cmake
# Links the Shutokou Battle X project with the ReXGlue / ShiftGlue SDK
# ==============================================================================

# Search paths for ReXGlue SDK
set(REXSDK_DIR "" CACHE PATH "Path to rexglue-sdk source tree (optional)")

if(REXSDK_DIR AND EXISTS "${REXSDK_DIR}/CMakeLists.txt")
    add_subdirectory("${REXSDK_DIR}" rexglue-sdk)
    message(STATUS "Using ReXGlue SDK from custom directory: ${REXSDK_DIR}")
elseif(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/rexglue-sdk/CMakeLists.txt")
    add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/rexglue-sdk" rexglue-sdk)
    message(STATUS "Using ReXGlue SDK from thirdparty/rexglue-sdk submodule")
elseif(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/shiftglue-sdk/CMakeLists.txt")
    add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/shiftglue-sdk" shiftglue-sdk)
    message(STATUS "Using ShiftGlue SDK from thirdparty/shiftglue-sdk submodule")
else()
    find_package(rexglue QUIET CONFIG)
    if(rexglue_FOUND)
        message(STATUS "Found installed ReXGlue SDK: ${rexglue_DIR}")
    else()
        message(WARNING "ReXGlue SDK not found in system packages or submodules.")
        message(STATUS "Project will configure host stubs. For full build, clone https://github.com/rexglue/rexglue-sdk into thirdparty/rexglue-sdk")
    endif()
endif()

# Recompilation sources directory
set(ENTRYPOINT_GENERATED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/src/generated/entrypoint")

if(EXISTS "${ENTRYPOINT_GENERATED_DIR}/sources.cmake")
    include("${ENTRYPOINT_GENERATED_DIR}/sources.cmake")
    message(STATUS "Found AOT Recompiled C++ Sources in ${ENTRYPOINT_GENERATED_DIR}")
else()
    message(STATUS "No recompiled sources found yet. Run 'scripts/run-codegen.bat' after placing game_root/default.xex.")
endif()

# Setup helper function
function(rexglue_setup_target TARGET_NAME)
    # Include entrypoint headers
    target_include_directories(${TARGET_NAME} PRIVATE
        ${ENTRYPOINT_GENERATED_DIR}
        ${CMAKE_CURRENT_SOURCE_DIR}/include
    )

    # Attach recompiled object sources if available
    if(DEFINED ENTRYPOINT_SOURCES)
        target_sources(${TARGET_NAME} PRIVATE ${ENTRYPOINT_SOURCES})
    endif()

    # Link ReXGlue SDK runtime components
    if(TARGET rex::runtime)
        target_link_libraries(${TARGET_NAME} PRIVATE
            rex::runtime
            rex::kernel
            rex::graphics_d3d12
            rex::graphics_vulkan
            rex::audio_sdl
            rex::ui
        )
    elseif(TARGET rexglue::runtime)
        target_link_libraries(${TARGET_NAME} PRIVATE
            rexglue::runtime
        )
    endif()
endfunction()
