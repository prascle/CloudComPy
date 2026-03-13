project( viewerPy VERSION 1.38.0 )

	add_library( ${PROJECT_NAME} STATIC )

set_property(TARGET ${PROJECT_NAME} PROPERTY AUTOMOC ON)

target_sources( ${PROJECT_NAME}
    PRIVATE
    viewerPy.h
    viewerPy.cpp
    viewerPyApplication.h
    viewerPyApplication.cpp
    )

target_include_directories( ${PROJECT_NAME} PRIVATE
    ${CC_FBO_LIB_SOURCE_DIR}/include
    ${CCCoreLib_SOURCE_DIR}/include
    ${QCC_DB_LIB_SOURCE_DIR}
    ${CMAKE_CURRENT_BINARY_DIR}
    ) 
 
file( GLOB ui_list ${CMAKE_CURRENT_SOURCE_DIR}/../CloudCompare/ccViewer/ui_templates/*.ui )
file( GLOB qrc_list ${CMAKE_CURRENT_SOURCE_DIR}/../CloudCompare/qCC/*.qrc )
file( GLOB rc_list ${CMAKE_CURRENT_SOURCE_DIR}/../CloudCompare/qCC/*.rc )
 
qt6_wrap_ui( generated_ui_list ${ui_list} )
qt6_add_resources( generated_qrc_list ${qrc_list} )

target_sources( ${PROJECT_NAME} PRIVATE ${generated_ui_list} ${generated_qrc_list} ${rc_list} )

target_link_libraries( ${PROJECT_NAME}
    CCAppCommon
    )
    
# Qt libraries

target_link_libraries( ${PROJECT_NAME}
    Qt6::Core
    Qt6::Gui
    Qt6::Widgets
    Qt6::OpenGL
    Qt6::PrintSupport
    )


    