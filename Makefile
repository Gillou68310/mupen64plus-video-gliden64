#/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
# *   Mupen64plus-video-gliden64 - Makefile                                 *
# *   Mupen64Plus homepage: http://code.google.com/p/mupen64plus/           *
# *   Copyright (C) 2007-2009 Richard Goedeken                              *
# *   Copyright (C) 2007-2008 DarkJeztr Tillin9                             *
# *                                                                         *
# *   This program is free software; you can redistribute it and/or modify  *
# *   it under the terms of the GNU General Public License as published by  *
# *   the Free Software Foundation; either version 2 of the License, or     *
# *   (at your option) any later version.                                   *
# *                                                                         *
# *   This program is distributed in the hope that it will be useful,       *
# *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
# *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
# *   GNU General Public License for more details.                          *
# *                                                                         *
# *   You should have received a copy of the GNU General Public License     *
# *   along with this program; if not, write to the                         *
# *   Free Software Foundation, Inc.,                                       *
# *   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.          *
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
# Makefile for GlideN64 plugin in Mupen64Plus

# detect operating system
UNAME ?= $(shell uname -s)
OS := NONE
ifeq ("$(UNAME)","Linux")
  OS = LINUX
  SO_EXTENSION = so
  SHARED = -shared
endif
ifeq ("$(UNAME)","linux")
  OS = LINUX
  SO_EXTENSION = so
  SHARED = -shared
endif
ifneq ("$(filter GNU hurd,$(UNAME))","")
  OS = LINUX
  SO_EXTENSION = so
  SHARED = -shared
endif
ifeq ("$(UNAME)","Darwin")
  OS = OSX
  SO_EXTENSION = dylib
  SHARED = -bundle
  PIC = 1  # force PIC under OSX
endif
ifeq ("$(UNAME)","FreeBSD")
  OS = FREEBSD
  SO_EXTENSION = so
  SHARED = -shared
endif
ifeq ("$(UNAME)","OpenBSD")
  OS = FREEBSD
  SO_EXTENSION = so
  SHARED = -shared
endif
ifneq ("$(filter GNU/kFreeBSD kfreebsd,$(UNAME))","")
  OS = LINUX
  SO_EXTENSION = so
  SHARED = -shared
endif
ifeq ("$(patsubst MINGW%,MINGW,$(UNAME))","MINGW")
  OS = MINGW
  SHARED = -shared
  SO_EXTENSION = dll
  PIC = 0
endif
ifeq ("$(OS)","NONE")
  $(error OS type "$(UNAME)" not supported.  Please file bug report at 'http://code.google.com/p/mupen64plus/issues')
endif

# detect system architecture
HOST_CPU ?= $(shell uname -m)
CPU := NONE
ifneq ("$(filter x86_64 amd64,$(HOST_CPU))","")
  CPU := X86
  ifeq ("$(BITS)", "32")
    ARCH_DETECTED := 64BITS_32
    PIC ?= 0
  else
    ARCH_DETECTED := 64BITS
    PIC ?= 1
  endif
endif
ifneq ("$(filter pentium i%86,$(HOST_CPU))","")
  CPU := X86
  ARCH_DETECTED := 32BITS
  PIC ?= 0
endif
ifneq ("$(filter ppc macppc socppc powerpc,$(HOST_CPU))","")
  CPU := PPC
  ARCH_DETECTED := 32BITS
  BIG_ENDIAN := 1
  PIC ?= 1
  $(warning Architecture "$(HOST_CPU)" not officially supported.')
endif
ifneq ("$(filter ppc64 powerpc64,$(HOST_CPU))","")
  CPU := PPC
  ARCH_DETECTED := 64BITS
  BIG_ENDIAN := 1
  PIC ?= 1
  $(warning Architecture "$(HOST_CPU)" not officially supported.')
endif
ifneq ("$(filter arm%,$(HOST_CPU))","")
  ifeq ("$(filter arm%b,$(HOST_CPU))","")
    CPU := ARM
    ARCH_DETECTED := 32BITS
    PIC ?= 1
    $(warning Architecture "$(HOST_CPU)" not officially supported.')
  endif
endif
ifneq ("$(filter aarch64,$(HOST_CPU))","")
    CPU := ARM
    ARCH_DETECTED := 64BITS
    PIC ?= 1
endif
ifeq ("$(CPU)","NONE")
  $(error CPU type "$(HOST_CPU)" not supported.  Please file bug report at 'http://code.google.com/p/mupen64plus/issues')
endif

# base CFLAGS, LDLIBS, and LDFLAGS
OPTFLAGS ?= -O3 -flto
WARNFLAGS ?= -Wall -Wno-sign-compare -Wno-unused-function -Wno-unused-but-set-variable -Wno-unused-variable
CFLAGS += $(OPTFLAGS) $(WARNFLAGS) -ffast-math -fno-strict-aliasing -fvisibility=hidden -IGLideN64/src -IGLideN64/src/osal -DMUPENPLUSAPI -DTXFILTER_LIB
CXXFLAGS += -fvisibility-inlines-hidden -std=c++11
LDFLAGS += $(SHARED)

ifeq ($(CPU), X86)
  CFLAGS +=  -mmmx -msse
endif

# Since we are building a shared library, we must compile with -fPIC on some architectures
# On 32-bit x86 systems we do not want to use -fPIC because we don't have to and it has a big performance penalty on this arch
ifeq ($(PIC), 1)
  CFLAGS += -fPIC
else
  CFLAGS += -fno-PIC
endif

ifeq ($(BIG_ENDIAN), 1)
  CFLAGS += -DM64P_BIG_ENDIAN
endif

# tweak flags for 32-bit build on 64-bit system
ifeq ($(ARCH_DETECTED), 64BITS_32)
  ifeq ($(OS), FREEBSD)
    $(error Do not use the BITS=32 option with FreeBSD, use -m32 and -m elf_i386)
  endif
  CFLAGS += -m32
  LDFLAGS += -Wl,-m,elf_i386
endif

# set special flags per-system
ifeq ($(OS), MINGW)
  CFLAGS += -DMINGW -DOS_WINDOWS -DWIN32 -U__STRICT_ANSI__
else ifeq ($(OS), LINUX)
  CFLAGS += -DOS_LINUX
  LDLIBS += -ldl
  # only export api symbols
  # LDFLAGS += -Wl,-version-script,$(SRCDIR)/video_api_export.ver
else ifeq ($(OS), OSX)
  CFLAGS += -DOS_MAC_OS_X
  #xcode-select has been around since XCode 3.0, i.e. OS X 10.5
  OSX_SDK_ROOT = $(shell xcode-select -print-path)/Platforms/MacOSX.platform/Developer/SDKs
  OSX_SDK_PATH = $(OSX_SDK_ROOT)/$(shell ls $(OSX_SDK_ROOT) | tail -1)

  ifeq ($(CPU), X86)
    ifeq ($(ARCH_DETECTED), 64BITS)
      CFLAGS += -pipe -arch x86_64 -mmacosx-version-min=10.5 -isysroot $(OSX_SDK_PATH)
      LDFLAGS += -bundle
      LDLIBS += -ldl
    else
      CFLAGS += -pipe -mmmx -msse -fomit-frame-pointer -arch i686 -mmacosx-version-min=10.5 -isysroot $(OSX_SDK_PATH)
      LDFLAGS += -bundle
      LDLIBS += -ldl
    endif
  endif
endif

ifeq ($(VEC4_OPT), 1)
  CFLAGS += -D__VEC4_OPT
endif

ifeq ($(NEON_OPT), 1)
ifeq ($(CPU), ARM)
ifeq ($(ARCH_DETECTED), 32BITS)
  CFLAGS += -mfpu=neon
endif
endif
  CFLAGS += -D__NEON_OPT
endif

ifeq ($(ODROID), 1)
  CFLAGS += -DODROID
endif

# test for essential build dependencies
ifeq ($(origin PKG_CONFIG), undefined)
  PKG_CONFIG = $(CROSS_COMPILE)pkg-config
  ifeq ($(shell which $(PKG_CONFIG) 2>/dev/null),)
    $(error $(PKG_CONFIG) not found)
  endif
endif

ifeq ($(origin FREETYPE2_CFLAGS) $(origin FREETYPE2_LDLIBS), undefined undefined)
  ifeq ($(shell $(PKG_CONFIG) --modversion freetype2 2>/dev/null),)
    $(error No freetype2 development libraries found!)
  endif
  FREETYPE2_CFLAGS += $(shell $(PKG_CONFIG) --cflags freetype2)
  FREETYPE2_LDLIBS +=  $(shell $(PKG_CONFIG) --libs freetype2)
endif
CFLAGS += $(FREETYPE2_CFLAGS)
LDLIBS += $(FREETYPE2_LDLIBS)

# search for OpenGL libraries
ifeq ($(VC), 1)
  GL_CFLAGS += -DVC -I/opt/vc/include -I/opt/vc/include/interface/vcos/pthreads -I/opt/vc/include/vmcs_host/linux
  GL_LDLIBS += -L/opt/vc/lib -lEGL -lbcm_host -lvcos -lvchiq_arm
  USE_EGL=1
endif
ifeq ($(USE_EGL), 1)
  CFLAGS += -DEGL
  ifeq ($(shell $(PKG_CONFIG) --modversion egl 2>/dev/null),)
    $(error No EGL development libraries found!)
  endif
  GL_CFLAGS += $(shell $(PKG_CONFIG) --cflags egl)
  GL_LDLIBS +=  $(shell $(PKG_CONFIG) --libs egl)
endif
ifeq ($(OS), OSX)
  GL_LDLIBS = -framework OpenGL
endif
ifeq ($(OS), MINGW)
  GL_LDLIBS = -lopengl32
endif
ifeq ($(origin GL_CFLAGS) $(origin GL_LDLIBS), undefined undefined)
  ifeq ($(shell $(PKG_CONFIG) --modversion gl 2>/dev/null),)
    $(error No OpenGL development libraries found!)
  endif
  GL_CFLAGS += $(shell $(PKG_CONFIG) --cflags gl)
  GL_LDLIBS +=  $(shell $(PKG_CONFIG) --libs gl)
endif
CFLAGS += $(GL_CFLAGS)
LDLIBS += $(GL_LDLIBS)

# set mupen64plus core API header path
ifneq ("$(APIDIR)","")
  CFLAGS += "-I$(APIDIR)"
else
  TRYDIR = ../mupen64plus-core/src/api
  ifneq ("$(wildcard $(TRYDIR)/m64p_types.h)","")
    CFLAGS += -I$(TRYDIR)
  else
    TRYDIR = /usr/local/include/mupen64plus
    ifneq ("$(wildcard $(TRYDIR)/m64p_types.h)","")
      CFLAGS += -I$(TRYDIR)
    else
      TRYDIR = /usr/include/mupen64plus
      ifneq ("$(wildcard $(TRYDIR)/m64p_types.h)","")
        CFLAGS += -I$(TRYDIR)
      else
        $(error Mupen64Plus API header files not found! Use makefile parameter APIDIR to force a location.)
      endif
    endif
  endif
endif

# reduced compile output when running make without V=1
ifneq ($(findstring $(MAKEFLAGS),s),s)
ifndef V
	Q_CC  = @echo '    CC  '$@;
	Q_CXX = @echo '    CXX '$@;
	Q_LD  = @echo '    LD  '$@;
endif
endif

# set base program pointers and flags
CC        = $(CROSS_COMPILE)gcc
CXX       = $(CROSS_COMPILE)g++
RM       ?= rm -f
INSTALL  ?= install
MKDIR    ?= mkdir -p
COMPILE.c = $(Q_CC)$(CC) $(CFLAGS) $(CPPFLAGS) $(TARGET_ARCH) -c
COMPILE.cc = $(Q_CXX)$(CXX) $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH) -c
LINK.o = $(Q_LD)$(CXX) $(CXXFLAGS) $(LDFLAGS) $(TARGET_ARCH)

# set special flags for given Makefile parameters
ifeq ($(DEBUG),1)
  CFLAGS += -g -DGL_DEBUG
  INSTALL_STRIP_FLAG ?= 
else
  ifneq ($(OS),OSX)
    INSTALL_STRIP_FLAG ?= -s
  endif
endif

# set installation options
ifeq ($(PREFIX),)
  PREFIX := /usr/local
endif
ifeq ($(SHAREDIR),)
  SHAREDIR := $(PREFIX)/share/mupen64plus
endif
ifeq ($(LIBDIR),)
  LIBDIR := $(PREFIX)/lib
endif
ifeq ($(PLUGINDIR),)
  PLUGINDIR := $(LIBDIR)/mupen64plus
endif

SRCDIR = GLideN64/src
OBJDIR = _obj$(POSTFIX)

# list of source files to compile
SOURCE = \
	$(SRCDIR)/Combiner.cpp \
	$(SRCDIR)/CombinerKey.cpp \
	$(SRCDIR)/CommonPluginAPI.cpp \
	$(SRCDIR)/Config.cpp \
	$(SRCDIR)/convert.cpp \
	$(SRCDIR)/DebugDump.cpp \
	$(SRCDIR)/Debugger.cpp \
	$(SRCDIR)/DepthBuffer.cpp \
	$(SRCDIR)/DisplayWindow.cpp \
	$(SRCDIR)/DisplayLoadProgress.cpp \
	$(SRCDIR)/FrameBuffer.cpp \
	$(SRCDIR)/FrameBufferInfo.cpp \
	$(SRCDIR)/GBI.cpp \
	$(SRCDIR)/gDP.cpp \
	$(SRCDIR)/GLideN64.cpp \
	$(SRCDIR)/GraphicsDrawer.cpp \
	$(SRCDIR)/gSP.cpp \
	$(SRCDIR)/Log.cpp \
	$(SRCDIR)/N64.cpp \
	$(SRCDIR)/NoiseTexture.cpp \
	$(SRCDIR)/PaletteTexture.cpp \
	$(SRCDIR)/Performance.cpp \
	$(SRCDIR)/PostProcessor.cpp \
	$(SRCDIR)/RDP.cpp \
	$(SRCDIR)/RSP.cpp \
	$(SRCDIR)/SoftwareRender.cpp \
	$(SRCDIR)/TexrectDrawer.cpp \
	$(SRCDIR)/TextDrawer.cpp \
	$(SRCDIR)/TextureFilterHandler.cpp \
	$(SRCDIR)/Textures.cpp \
	$(SRCDIR)/VI.cpp \
	$(SRCDIR)/ZlutTexture.cpp \
	$(SRCDIR)/BufferCopy/BlueNoiseTexture.cpp \
	$(SRCDIR)/BufferCopy/ColorBufferToRDRAM.cpp \
	$(SRCDIR)/BufferCopy/DepthBufferToRDRAM.cpp \
	$(SRCDIR)/BufferCopy/RDRAMtoColorBuffer.cpp \
	$(SRCDIR)/DepthBufferRender/ClipPolygon.cpp \
	$(SRCDIR)/DepthBufferRender/DepthBufferRender.cpp \
	$(SRCDIR)/common/CommonAPIImpl_common.cpp \
	$(SRCDIR)/Graphics/ColorBufferReader.cpp \
	$(SRCDIR)/Graphics/CombinerProgram.cpp \
	$(SRCDIR)/Graphics/Context.cpp \
	$(SRCDIR)/Graphics/ObjectHandle.cpp \
	$(SRCDIR)/Graphics/OpenGLContext/GLFunctions.cpp \
	$(SRCDIR)/Graphics/OpenGLContext/ThreadedOpenGl/opengl_Command.cpp \
	$(SRCDIR)/Graphics/OpenGLContext/ThreadedOpenGl/opengl_ObjectPool.cpp \
	$(SRCDIR)/Graphics/OpenGLContext/ThreadedOpenGl/opengl_Wrapper.cpp \
	$(SRCDIR)/Graphics/OpenGLContext/ThreadedOpenGl/opengl_WrappedFunctions.cpp \
	$(SRCDIR)/Graphics/OpenGLContext/ThreadedOpenGl/RingBufferPool.cpp \
	$(SRCDIR)/Graphics/OpenGLContext/opengl_Attributes.cpp \
	$(SRCDIR)/Graphics/OpenGLContext/opengl_BufferedDrawer.cpp \
	$(SRCDIR)/Graphics/OpenGLContext/opengl_BufferManipulationObjectFactory.cpp \
	$(SRCDIR)/Graphics/OpenGLContext/opengl_CachedFunctions.cpp \
	$(SRCDIR)/Graphics/OpenGLContext/opengl_ColorBufferReaderWithBufferStorage.cpp \
	$(SRCDIR)/Graphics/OpenGLContext/opengl_ColorBufferReaderWithPixelBuffer.cpp \
	$(SRCDIR)/Graphics/OpenGLContext/opengl_ColorBufferReaderWithReadPixels.cpp \
	$(SRCDIR)/Graphics/OpenGLContext/opengl_ContextImpl.cpp \
	$(SRCDIR)/Graphics/OpenGLContext/opengl_GLInfo.cpp \
	$(SRCDIR)/Graphics/OpenGLContext/opengl_Parameters.cpp \
	$(SRCDIR)/Graphics/OpenGLContext/opengl_TextureManipulationObjectFactory.cpp \
	$(SRCDIR)/Graphics/OpenGLContext/opengl_UnbufferedDrawer.cpp \
	$(SRCDIR)/Graphics/OpenGLContext/opengl_Utils.cpp \
	$(SRCDIR)/Graphics/OpenGLContext/GLSL/glsl_CombinerInputs.cpp \
	$(SRCDIR)/Graphics/OpenGLContext/GLSL/glsl_CombinerProgramBuilder.cpp \
	$(SRCDIR)/Graphics/OpenGLContext/GLSL/glsl_CombinerProgramImpl.cpp \
	$(SRCDIR)/Graphics/OpenGLContext/GLSL/glsl_CombinerProgramUniformFactory.cpp \
	$(SRCDIR)/Graphics/OpenGLContext/GLSL/glsl_FXAA.cpp \
	$(SRCDIR)/Graphics/OpenGLContext/GLSL/glsl_ShaderStorage.cpp \
	$(SRCDIR)/Graphics/OpenGLContext/GLSL/glsl_SpecialShadersFactory.cpp \
	$(SRCDIR)/Graphics/OpenGLContext/GLSL/glsl_Utils.cpp \
	$(SRCDIR)/uCodes/F3D.cpp \
	$(SRCDIR)/uCodes/F3DAM.cpp \
	$(SRCDIR)/uCodes/F3DBETA.cpp \
	$(SRCDIR)/uCodes/F3DDKR.cpp \
	$(SRCDIR)/uCodes/F3DEX.cpp \
	$(SRCDIR)/uCodes/F3DEX2.cpp \
	$(SRCDIR)/uCodes/F3DEX2ACCLAIM.cpp \
	$(SRCDIR)/uCodes/F3DEX2CBFD.cpp \
	$(SRCDIR)/uCodes/F3DFLX2.cpp \
	$(SRCDIR)/uCodes/F3DGOLDEN.cpp \
	$(SRCDIR)/uCodes/F3DPD.cpp \
	$(SRCDIR)/uCodes/F3DSETA.cpp \
	$(SRCDIR)/uCodes/F3DTEXA.cpp \
	$(SRCDIR)/uCodes/F3DZEX2.cpp \
	$(SRCDIR)/uCodes/F5Indi_Naboo.cpp \
	$(SRCDIR)/uCodes/F5Rogue.cpp \
	$(SRCDIR)/uCodes/L3D.cpp \
	$(SRCDIR)/uCodes/L3DEX.cpp \
	$(SRCDIR)/uCodes/L3DEX2.cpp \
	$(SRCDIR)/uCodes/S2DEX.cpp \
	$(SRCDIR)/uCodes/S2DEX2.cpp \
	$(SRCDIR)/uCodes/T3DUX.cpp \
	$(SRCDIR)/uCodes/Turbo3D.cpp \
	$(SRCDIR)/uCodes/ZSort.cpp \
	$(SRCDIR)/uCodes/ZSortBOSS.cpp \
	$(SRCDIR)/MupenPlusPluginAPI.cpp \
	$(SRCDIR)/mupenplus/Config_mupenplus.cpp \
	$(SRCDIR)/mupenplus/CommonAPIImpl_mupenplus.cpp \
	$(SRCDIR)/mupenplus/MemoryStatus_mupenplus.cpp \
	$(SRCDIR)/mupenplus/MupenPlusAPIImpl.cpp \
	$(SRCDIR)/Graphics/OpenGLContext/mupen64plus/mupen64plus_DisplayWindow.cpp \
	$(SRCDIR)/TxFilterStub.cpp

ifeq ($(CRC_ARMV8), 1)
	SOURCE += \
		$(SRCDIR)/CRC32_ARMV8.cpp
else ifeq ($(CRC_OPT), 1)
	SOURCE += \
		$(SRCDIR)/CRC_OPT.cpp
else ifeq ($(CRC_NEON), 1)
	SOURCE += \
		$(SRCDIR)/Neon/CRC_OPT_NEON.cpp
else
	SOURCE += \
		$(SRCDIR)/CRC32.cpp
endif

ifeq ($(X86_OPT), 1)
	SOURCE += \
		$(SRCDIR)/3DMath.cpp \
		$(SRCDIR)/RSP_LoadMatrixX86.cpp
else ifeq ($(NEON_OPT), 1)
	SOURCE += \
		$(SRCDIR)/Neon/3DMathNeon.cpp \
		$(SRCDIR)/Neon/gSPNeon.cpp \
		$(SRCDIR)/Neon/RSP_LoadMatrixNeon.cpp \
		$(SRCDIR)/Neon/WriteToRDRAM_Neon.cpp
else
	SOURCE += \
		$(SRCDIR)/3DMath.cpp \
		$(SRCDIR)/RSP_LoadMatrix.cpp
endif

ifeq ($(OS),MINGW)
SOURCE += $(SRCDIR)/osal/osal_files_win32.c
SOURCE += $(SRCDIR)/osal/osal_keys_win.c
else
SOURCE += $(SRCDIR)/osal/osal_files_unix.c
SOURCE += $(SRCDIR)/osal/osal_keys_unix.c
endif

# generate a list of object files build, make a temporary directory for them
OBJECTS := $(patsubst $(SRCDIR)/%.c, $(OBJDIR)/%.o, $(filter %.c, $(SOURCE)))
OBJECTS += $(patsubst $(SRCDIR)/%.cpp, $(OBJDIR)/%.o, $(filter %.cpp, $(SOURCE)))
OBJDIRS = $(dir $(OBJECTS))
$(shell $(MKDIR) $(OBJDIRS))

# build targets
TARGET = mupen64plus-video-gliden64$(POSTFIX).$(SO_EXTENSION)

targets:
	@echo "Mupen64plus-video-gliden64 N64 Graphics plugin makefile. "
	@echo "  Targets:"
	@echo "    all           == Build Mupen64plus-video-gliden64 plugin"
	@echo "    clean         == remove object files"
	@echo "    rebuild       == clean and re-build all"
	@echo "    install       == Install Mupen64Plus-video-gliden64 plugin"
	@echo "    uninstall     == Uninstall Mupen64Plus-video-gliden64 plugin"
	@echo "  Options:"
	@echo "    BITS=32       == build 32-bit binaries on 64-bit machine"
	@echo "    USE_EGL=1     == "
	@echo "    VC=1          == "
	@echo "    ODROID=1      == "
	@echo "    VEC4_OPT=1    == "
	@echo "    CRC_OPT=1     == "
	@echo "    CRC_NEON1     == "
	@echo "    CRC_ARMV8=1   == "
	@echo "    X86_OPT=1     == "
	@echo "    NEON_OPT=1    == "
	@echo "    APIDIR=path   == path to find Mupen64Plus Core headers"
	@echo "    OPTFLAGS=flag == compiler optimization (default: -O3 -flto)"
	@echo "    WARNFLAGS=flag == compiler warning levels (default: -Wall)"
	@echo "    PIC=(1|0)     == Force enable/disable of position independent code"
	@echo "    POSTFIX=name  == String added to the name of the the build (default: '')"
	@echo "  Install Options:"
	@echo "    PREFIX=path   == install/uninstall prefix (default: /usr/local)"
	@echo "    SHAREDIR=path == path to install shared data files (default: PREFIX/share/mupen64plus)"
	@echo "    LIBDIR=path   == library prefix (default: PREFIX/lib)"
	@echo "    PLUGINDIR=path == path to install plugin libraries (default: LIBDIR/mupen64plus)"
	@echo "    DESTDIR=path  == path to prepend to all installation paths (only for packagers)"
	@echo "  Debugging Options:"
	@echo "    DEBUG=1       == add debugging symbols"
	@echo "    V=1           == show verbose compiler output"

all: $(TARGET)

install: $(TARGET)
	$(INSTALL) -d "$(DESTDIR)$(PLUGINDIR)"
	$(INSTALL) -m 0644 $(INSTALL_STRIP_FLAG) $(TARGET) "$(DESTDIR)$(PLUGINDIR)"
	$(INSTALL) -d "$(DESTDIR)$(SHAREDIR)"
	$(INSTALL) -m 0644 "GLideN64/ini/GLideN64.custom.ini" "$(DESTDIR)$(SHAREDIR)"

uninstall:
	$(RM) "$(DESTDIR)$(PLUGINDIR)/$(TARGET)"
	$(RM) "$(DESTDIR)$(SHAREDIR)/GLideN64.custom.ini"

clean:
	$(RM) -r $(OBJDIR) $(TARGET)

rebuild: clean all

# build dependency files
CFLAGS += -MD -MP
-include $(OBJECTS:.o=.d)

CXXFLAGS += $(CFLAGS)

# standard build rules
$(OBJDIR)/%.o: $(SRCDIR)/%.c
	$(COMPILE.c) -o $@ $<

$(OBJDIR)/%.o: $(SRCDIR)/%.cpp
	$(COMPILE.cc) -o $@ $<

$(TARGET): $(OBJECTS)
	$(LINK.o) $^ $(LOADLIBES) $(LDLIBS) -o $@

.PHONY: all clean install uninstall targets
