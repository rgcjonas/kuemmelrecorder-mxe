# This file is part of MXE. See LICENSE.md for licensing information.

# MXE provides a fully featured build of Qt. Some users want more control...
# https://lists.nongnu.org/archive/html/mingw-cross-env-list/2013-08/msg00010.html
# https://lists.nongnu.org/archive/html/mingw-cross-env-list/2012-05/msg00019.html
#
# build of qt and deps is (say):  25 mins with 12.5 MB test program
# custom with minimal deps is:     4 mins with  7.6 MB test program
# custom min deps and cflags is:   4 mins with  5.9 MB test program
#
# make qt MXE_PLUGIN_DIRS='plugins/custom-qt-min'

$(info == Qt5 overrides: $(lastword $(MAKEFILE_LIST)))

qtbase_DEPS     := cc jpeg libpng pcre2 sqlite zlib

define qtbase_BUILD
    # ICU is buggy. See #653. TODO: reenable it some time in the future.
    cd '$(1)' && \
        PKG_CONFIG="${TARGET}-pkg-config" \
        PKG_CONFIG_SYSROOT_DIR="/" \
        PKG_CONFIG_LIBDIR="$(PREFIX)/$(TARGET)/lib/pkgconfig" \
        ./configure \
            -opensource \
            -confirm-license \
            -xplatform win32-g++ \
            -device-option CROSS_COMPILE=${TARGET}- \
            -device-option PKG_CONFIG='${TARGET}-pkg-config' \
            -pkg-config \
            -force-pkg-config \
            -no-use-gold-linker \
            -release \
            -static \
            -prefix '$(PREFIX)/$(TARGET)/qt5' \
            -no-icu \
            -no-opengl \
            -no-glib \
            -accessibility \
            -nomake examples \
            -nomake tests \
            -no-sql-mysql \
            -plugin-sql-sqlite \
            -plugin-sql-odbc \
            -no-sql-psql \
            -no-sql-tds \
            -system-zlib \
            -system-libpng \
            -system-libjpeg \
            -system-sqlite \
            -no-fontconfig \
            -no-freetype \
            -no-harfbuzz \
            -system-pcre \
            -no-openssl \
            -no-dbus \
            -no-pch \
            -v \
            $($(PKG)_CONFIGURE_OPTS)

    $(MAKE) -C '$(1)' -j '$(JOBS)'
    rm -rf '$(PREFIX)/$(TARGET)/qt5'
    $(MAKE) -C '$(1)' -j 1 install
    ln -sf '$(PREFIX)/$(TARGET)/qt5/bin/qmake' '$(PREFIX)/bin/$(TARGET)'-qmake-qt5

    mkdir            '$(1)/test-qt'
    cd               '$(1)/test-qt' && '$(PREFIX)/$(TARGET)/qt5/bin/qmake' '$(PWD)/src/qt-test.pro'
    $(MAKE)       -C '$(1)/test-qt' -j '$(JOBS)' $(BUILD_TYPE)
    $(INSTALL) -m755 '$(1)/test-qt/$(BUILD_TYPE)/test-qt5.exe' '$(PREFIX)/$(TARGET)/bin/'

    # build test the manual way
    mkdir '$(1)/test-$(PKG)-pkgconfig'
    '$(PREFIX)/$(TARGET)/qt5/bin/uic' -o '$(1)/test-$(PKG)-pkgconfig/ui_qt-test.h' '$(TOP_DIR)/src/qt-test.ui'
    '$(PREFIX)/$(TARGET)/qt5/bin/moc' \
        -o '$(1)/test-$(PKG)-pkgconfig/moc_qt-test.cpp' \
        -I'$(1)/test-$(PKG)-pkgconfig' \
        '$(TOP_DIR)/src/qt-test.hpp'
    '$(PREFIX)/$(TARGET)/qt5/bin/rcc' -name qt-test -o '$(1)/test-$(PKG)-pkgconfig/qrc_qt-test.cpp' '$(TOP_DIR)/src/qt-test.qrc'
    '$(TARGET)-g++' \
        -W -Wall -Werror -std=c++0x -pedantic \
        '$(TOP_DIR)/src/qt-test.cpp' \
        '$(1)/test-$(PKG)-pkgconfig/moc_qt-test.cpp' \
        '$(1)/test-$(PKG)-pkgconfig/qrc_qt-test.cpp' \
        -o '$(PREFIX)/$(TARGET)/bin/test-$(PKG)-pkgconfig.exe' \
        -I'$(1)/test-$(PKG)-pkgconfig' \
        `'$(TARGET)-pkg-config' Qt5Widgets$(BUILD_TYPE_SUFFIX) --cflags --libs`

    # setup cmake toolchain
    echo 'set(CMAKE_SYSTEM_PREFIX_PATH "$(PREFIX)/$(TARGET)/qt5" ${CMAKE_SYSTEM_PREFIX_PATH})' > '$(CMAKE_TOOLCHAIN_DIR)/$(PKG).cmake'

    # batch file to run test programs
    (printf 'set PATH=..\\lib;..\\qt5\\bin;..\\qt5\\lib;%%PATH%%\r\n'; \
     printf 'set QT_QPA_PLATFORM_PLUGIN_PATH=..\\qt5\\plugins\r\n'; \
     printf 'test-qt5.exe\r\n'; \
     printf 'test-qtbase-pkgconfig.exe\r\n';) \
     > '$(PREFIX)/$(TARGET)/bin/test-qt5.bat'

    # add libs to CMake config of Qt5Core to fix static linking
    $(SED) -i 's,set(_Qt5Core_LIB_DEPENDENCIES \"\"),set(_Qt5Core_LIB_DEPENDENCIES \"ole32;uuid;ws2_32;advapi32;shell32;user32;kernel32;mpr;version;winmm;z;pcre2-16;netapi32;userenv\"),g' '$(PREFIX)/$(TARGET)/qt5/lib/cmake/Qt5Core/Qt5CoreConfig.cmake'
    $(SED) -i 's,set(_Qt5Gui_LIB_DEPENDENCIES \"Qt5::Core\"),set(_Qt5Gui_LIB_DEPENDENCIES \"Qt5::Core;ole32;uuid;ws2_32;advapi32;shell32;user32;kernel32;mpr;version;winmm;z;pcre2-16;png16;harfbuzz;z\"),g' '$(PREFIX)/$(TARGET)/qt5/lib/cmake/Qt5Gui/Qt5GuiConfig.cmake'
    $(SED) -i 's,set(_Qt5Widgets_LIB_DEPENDENCIES \"Qt5::Gui;Qt5::Core\"),set(_Qt5Widgets_LIB_DEPENDENCIES \"Qt5::Gui;Qt5::Core;gdi32;comdlg32;oleaut32;imm32;opengl32;png16;harfbuzz;ole32;uuid;ws2_32;advapi32;shell32;user32;kernel32;mpr;version;winmm;z;pcre2-16;shell32;uxtheme;dwmapi\"),g' '$(PREFIX)/$(TARGET)/qt5/lib/cmake/Qt5Widgets/Qt5WidgetsConfig.cmake'
endef
