cmake_minimum_required(VERSION 3.10)

project(dnr LANGUAGES NONE) #DOS Commander Revived (DNR)

# Set directories
set(PASCAL_SRC_DIR ${CMAKE_SOURCE_DIR}/src/pascal)
set(ASM_SRC_DIR ${CMAKE_SOURCE_DIR}/src/asm)

# Collect source files
file(GLOB PASCAL_SOURCES ${PASCAL_SRC_DIR}/*.pas)
file(GLOB ASM_SOURCES ${ASM_SRC_DIR}/*.nasm)

# Custom command to compile Assembly files using NASM
foreach(ASM_FILE ${ASM_SOURCES})
    get_filename_component(ASM_OBJ ${ASM_FILE} NAME_WE)
    set(ASM_OBJ ${CMAKE_SOURCE_DIR}/bin/asm_${ASM_OBJ}.obj)
    add_custom_command(
        OUTPUT ${ASM_OBJ}
        # COMMAND nasm -f obj -o ${ASM_OBJ} ${ASM_FILE}
        COMMAND nasm -f win64 -o ${ASM_OBJ} ${ASM_FILE}
        DEPENDS ${ASM_FILE}
        COMMENT "Assembling ${ASM_FILE}"
    )
    list(APPEND OBJ_FILES ${ASM_OBJ})
endforeach()

# Custom command to compile Pascal files using FPC
#[===[
foreach(PAS_FILE ${PASCAL_SOURCES})
    get_filename_component(PAS_OBJ ${PAS_FILE} NAME_WE)
    set(PAS_OBJ ${CMAKE_SOURCE_DIR}/bin/pas_${PAS_OBJ}.obj)
    add_custom_command(
        OUTPUT ${PAS_OBJ}
        COMMAND fpc -g -al -s -o${PAS_OBJ} ${PAS_FILE}
        DEPENDS ${PAS_FILE}
        COMMENT "Compiling ${PAS_FILE}"
    )
    list(APPEND OBJ_FILES ${PAS_OBJ})
endforeach()
]===]


# Custom target to group all object files
add_custom_target(
    compile_all_obj
    DEPENDS ${OBJ_FILES}
)

# Link object files using platform-specific linkers
if(${CMAKE_SYSTEM_NAME} MATCHES "Windows" OR ${CMAKE_SYSTEM_NAME} MATCHES "Linux")
    add_custom_command(
        OUTPUT ${PROJECT_NAME}.exe
        COMMAND ld -o ${PROJECT_NAME}.exe ${OBJ_FILES}
        DEPENDS compile_all_obj
        COMMENT "Linking objects into ${PROJECT_NAME}.exe using GNU LD"
    )
elseif(${CMAKE_SYSTEM_NAME} MATCHES "Darwin") # macOS
    add_custom_command(
        OUTPUT ${PROJECT_NAME}.exe
        COMMAND ld64 -o ${PROJECT_NAME}.exe ${OBJ_FILES}
        DEPENDS compile_all_obj
        COMMENT "Linking objects into ${PROJECT_NAME}.exe using ld64"
    )
endif()

add_custom_target(
    link_exe ALL
    DEPENDS ${PROJECT_NAME}.exe
)

