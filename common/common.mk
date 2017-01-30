################################################################################
#
# Copyright 1993-2015 NVIDIA Corporation.  All rights reserved.
#
# NOTICE TO USER:
#
# This source code is subject to NVIDIA ownership rights under U.S. and
# international Copyright laws.
#
# NVIDIA MAKES NO REPRESENTATION ABOUT THE SUITABILITY OF THIS SOURCE
# CODE FOR ANY PURPOSE.  IT IS PROVIDED "AS IS" WITHOUT EXPRESS OR
# IMPLIED WARRANTY OF ANY KIND.  NVIDIA DISCLAIMS ALL WARRANTIES WITH
# REGARD TO THIS SOURCE CODE, INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY, NONINFRINGEMENT, AND FITNESS FOR A PARTICULAR PURPOSE.
# IN NO EVENT SHALL NVIDIA BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL,
# OR CONSEQUENTIAL DAMAGES, OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS
# OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE
# OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE
# OR PERFORMANCE OF THIS SOURCE CODE.
#
# U.S. Government End Users.  This source code is a "commercial item" as
# that term is defined at 48 C.F.R. 2.101 (OCT 1995), consisting  of
# "commercial computer software" and "commercial computer software
# documentation" as such terms are used in 48 C.F.R. 12.212 (SEPT 1995)
# and is provided to the U.S. Government only as a commercial end item.
# Consistent with 48 C.F.R.12.212 and 48 C.F.R. 227.7202-1 through
# 227.7202-4 (JUNE 1995), all U.S. Government End Users acquire the
# source code with only those rights set forth herein.
#
################################################################################
#
# Makefile project only supported on Mac OS X and Linux Platforms)
#
################################################################################

# Location of the CUDA Toolkit
#CUDA_PATH ?= /usr/local/cuda-8.0

# architecture
HOST_ARCH   := $(shell uname -m)
TARGET_ARCH ?= $(HOST_ARCH)
ifneq (,$(filter $(TARGET_ARCH),x86_64 aarch64 ppc64le armv7l))
    ifneq ($(TARGET_ARCH),$(HOST_ARCH))
        ifneq (,$(filter $(TARGET_ARCH),x86_64 aarch64 ppc64le))
            TARGET_SIZE := 64
        else ifneq (,$(filter $(TARGET_ARCH),armv7l))
            TARGET_SIZE := 32
        endif
    else
        TARGET_SIZE := $(shell getconf LONG_BIT)
    endif
else
    $(error ERROR - unsupported value $(TARGET_ARCH) for TARGET_ARCH!)
endif
ifneq ($(TARGET_ARCH),$(HOST_ARCH))
    ifeq (,$(filter $(HOST_ARCH)-$(TARGET_ARCH),aarch64-armv7l x86_64-armv7l x86_64-aarch64 x86_64-ppc64le))
        $(error ERROR - cross compiling from $(HOST_ARCH) to $(TARGET_ARCH) is not supported!)
    endif
endif

# When on native aarch64 system with userspace of 32-bit, change TARGET_ARCH to armv7l
ifeq ($(HOST_ARCH)-$(TARGET_ARCH)-$(TARGET_SIZE),aarch64-aarch64-32)
    TARGET_ARCH = armv7l
endif

# operating system
HOST_OS   := $(shell uname -s 2>/dev/null | tr "[:upper:]" "[:lower:]")
TARGET_OS ?= $(HOST_OS)
ifeq (,$(filter $(TARGET_OS),linux darwin qnx android))
    $(error ERROR - unsupported value $(TARGET_OS) for TARGET_OS!)
endif

# host compiler
ifeq ($(TARGET_OS),darwin)
    ifeq ($(shell expr `xcodebuild -version | grep -i xcode | awk '{print $$2}' | cut -d'.' -f1` \>= 5),1)
        HOST_COMPILER ?= clang++
    endif
else ifneq ($(TARGET_ARCH),$(HOST_ARCH))
    ifeq ($(HOST_ARCH)-$(TARGET_ARCH),x86_64-armv7l)
        ifeq ($(TARGET_OS),linux)
            HOST_COMPILER ?= arm-linux-gnueabihf-g++
        else ifeq ($(TARGET_OS),qnx)
            ifeq ($(QNX_HOST),)
                $(error ERROR - QNX_HOST must be passed to the QNX host toolchain)
            endif
            ifeq ($(QNX_TARGET),)
                $(error ERROR - QNX_TARGET must be passed to the QNX target toolchain)
            endif
            export QNX_HOST
            export QNX_TARGET
            HOST_COMPILER ?= $(QNX_HOST)/usr/bin/arm-unknown-nto-qnx6.6.0eabi-g++
        else ifeq ($(TARGET_OS),android)
            HOST_COMPILER ?= arm-linux-androideabi-g++
        endif
    else ifeq ($(TARGET_ARCH),aarch64)
        ifeq ($(TARGET_OS), linux)
            HOST_COMPILER ?= aarch64-linux-gnu-g++
        else ifeq ($(TARGET_OS),qnx)
            ifeq ($(QNX_HOST),)
                $(error ERROR - QNX_HOST must be passed to the QNX host toolchain)
            endif
            ifeq ($(QNX_TARGET),)
                $(error ERROR - QNX_TARGET must be passed to the QNX target toolchain)
            endif
            export QNX_HOST
            export QNX_TARGET
            HOST_COMPILER ?= $(QNX_HOST)/usr/bin/aarch64-unknown-nto-qnx7.0.0-g++
        else ifeq ($(TARGET_OS), android)
            HOST_COMPILER ?= aarch64-linux-android-g++
        endif
    else ifeq ($(TARGET_ARCH),ppc64le)
        HOST_COMPILER ?= powerpc64le-linux-gnu-g++
    endif
endif
HOST_COMPILER ?= g++
NVCC          := $(if $(CUDA_PATH),$(CUDA_PATH)/bin/)nvcc -ccbin $(HOST_COMPILER)

# internal flags
NVCCFLAGS   := -m${TARGET_SIZE}
CCFLAGS     :=
LDFLAGS     :=

# build flags
ifeq ($(TARGET_OS),darwin)
ifdef CUDA_PATH
    LDFLAGS += -rpath $(CUDA_PATH)/lib
endif
    CCFLAGS += -arch $(HOST_ARCH)
else ifeq ($(HOST_ARCH)-$(TARGET_ARCH)-$(TARGET_OS),x86_64-armv7l-linux)
    LDFLAGS += --dynamic-linker=/lib/ld-linux-armhf.so.3
    CCFLAGS += -mfloat-abi=hard
else ifeq ($(TARGET_OS),android)
    LDFLAGS += -pie
    CCFLAGS += -fpie -fpic -fexceptions
endif

ifneq ($(TARGET_ARCH),$(HOST_ARCH))
    ifeq ($(TARGET_ARCH)-$(TARGET_OS),armv7l-linux)
        ifneq ($(TARGET_FS),)
            GCCVERSIONLTEQ46 := $(shell expr `$(HOST_COMPILER) -dumpversion` \<= 4.6)
            ifeq ($(GCCVERSIONLTEQ46),1)
                CCFLAGS += --sysroot=$(TARGET_FS)
            endif
            LDFLAGS += --sysroot=$(TARGET_FS)
            LDFLAGS += -rpath-link=$(TARGET_FS)/lib
            LDFLAGS += -rpath-link=$(TARGET_FS)/usr/lib
            LDFLAGS += -rpath-link=$(TARGET_FS)/usr/lib/arm-linux-gnueabihf
        endif
    endif
endif

# Debug build flags
ifeq ($(dbg),1)
      NVCCFLAGS += -g -G
      BUILD_TYPE := debug
else
      BUILD_TYPE := release
endif

ALL_CCFLAGS :=
ALL_CCFLAGS += $(NVCCFLAGS)
ALL_CCFLAGS += $(EXTRA_NVCCFLAGS)
ALL_CCFLAGS += $(addprefix -Xcompiler ,$(CCFLAGS))
ALL_CCFLAGS += $(addprefix -Xcompiler ,$(EXTRA_CCFLAGS))

SAMPLE_ENABLED := 1

ALL_LDFLAGS :=
ALL_LDFLAGS += $(ALL_CCFLAGS)
ALL_LDFLAGS += $(addprefix -Xlinker ,$(LDFLAGS))
ALL_LDFLAGS += $(addprefix -Xlinker ,$(EXTRA_LDFLAGS))

# Common includes and paths for CUDA
INCLUDES  := -I../../common/inc
LIBRARIES :=

################################################################################

# Gencode arguments
SMS ?= 20 30 35 37 50 52 60

# ifeq ($(SMS),)
# $(info >>> WARNING - no SM architectures have been specified - waiving sample <<<)
# SAMPLE_ENABLED := 0
# endif

# Generate SASS code for each SM architecture listed in $(SMS)
GENCODE_FLAGS ?= $(if $(SMS),$(foreach sm,$(SMS),-gencode arch=compute_$(sm),code=sm_$(sm)) $(GENCODE_FLAGS_HIGHEST))

# Generate PTX code from the highest SM architecture in $(SMS) to guarantee forward-compatibility
HIGHEST_SM = $(lastword $(sort $(SMS)))
GENCODE_FLAGS_HIGHEST = $(if $(HIGHEST_SM),-gencode arch=compute_$(HIGHEST_SM),code=compute_$(HIGHEST_SM))

define SMS_ExcludeLessThan
SMS_exclude := $$(shell for i in $(SMS); do if test $$$$i -lt $(1); then echo -n "$$$$i "; fi; done)
SMS := $$(filter-out $$(SMS_exclude),$$(SMS))
ifneq (,$$(SMS_exclude))
$$(info Excluding SM architectures < $(1)... $$(SMS_exclude))
$$(info Compiling only SM $$(SMS))
endif
ifeq ($$(SMS),)
$$(info >>> WARNING - no SM architectures have been specified - waiving sample <<<)
SAMPLE_ENABLED := 0
endif
endef

################################################################################
# Rule variables and templates

V ?= 0

PARTIAL_OUTPUT_PATH=$(TARGET_ARCH)/$(TARGET_OS)/$(BUILD_TYPE)
OBJ_DIR = obj/$(PARTIAL_OUTPUT_PATH)
BIN_DIR = ../../$(PARTIAL_OUTPUT_PATH)/bin
LIB_DIR = ../../$(PARTIAL_OUTPUT_PATH)/lib

NVCC_0 = @echo "Compiling $<..."; $(NVCC)
NVCC_V = $(if $(findstring 0,$(V)),$(NVCC_0),$(NVCC))

LINK_0 = @echo "Linking $@..."; $(NVCC)
LINK_V = $(if $(findstring 0,$(V)),$(NVCC_0),$(NVCC))

AR_0 = @echo "Archiving $@..."; $(AR)
AR_V = $(if $(findstring 0,$(V)),$(AR_0),$(AR))

OBJ_NAME = $(patsubst %.cpp,$(OBJ_DIR)/%.o,\
    $(patsubst %.c,$(OBJ_DIR)/%.o,\
    $(patsubst %.cu,$(OBJ_DIR)/%.o,\
    $(notdir $(1)))))
OBJECTS=$(foreach src,$(1),$(call OBJ_NAME,$(src)))

# Note: CFLAGS, LDFLAGS, LDLIBS will expand with the rule
define OBJ_RULE
-include $(patsubst %.o,%.dep,$(2))
$(2): $(1)
	@if test ! -d $$(@D); then mkdir -p $$(@D); fi
	$(NVCC_V) $(INCLUDES) $(ALL_CCFLAGS) $(CCFLAGS_$(1)) $(GENCODE_FLAGS) -o $$@ -c $$<
	$(NVCC_V) $(INCLUDES) $(filter-out -dc -ptx,$(ALL_CCFLAGS) $(CCFLAGS_$(1))) -odir $$(@D) -M $$< > $$(@:.o=.dep)
endef

LIB_NAME=lib$(strip $(1)).a
LIB_FULLNAME=$(LIB_DIR)/$(call LIB_NAME,$(1))
LIB_FULLNAME_ALL=$(foreach lib,$(1),$(LIB_DIR)/$(call LIB_FULLNAME,$(lib)))

SO_NAME=lib$(strip $(1)).so
SO_FULLNAME=$(LIB_DIR)/$(call SO_NAME,$(1))
SO_FULLNAME_ALL=$(foreach lib,$(1),$(LIB_DIR)/$(call SO_NAME,$(lib)))

TARGETS_ALL=$(foreach t,$(1),$(TARGET_$(t)))

.PHONY: build
.DEFAULT_GOAL=build

define LIBRARY
$$(foreach src,$(2),$$(eval $$(call OBJ_RULE,$$(src),$$(call OBJ_NAME,$$(src)))))

TARGET_NAME = $(call LIB_FULLNAME,$(strip $(1)))
$$(TARGET_NAME): $(call OBJECTS,$(2))
	@if test ! -d $$(@D); then mkdir -p $$(@D); fi
	$$(NVCC_V) $(filter-out -dc -ptx,$(ALL_CCFLAGS) $(CCFLAGS_$(strip $(1))) ) -lib -o $$@ $$(filter %.o,$$^)

build: $$(TARGET_NAME)

endef

define SHARED_OBJECT
$$(foreach src,$(2),$$(eval $$(call OBJ_RULE,$$(src),$$(call OBJ_NAME,$$(src)))))

TARGET_NAME = $(call SO_FULLNAME,$(1))
$$(TARGET_NAME): $(call OBJECTS,$(2)) $(call TARGETS_ALL,$(3))
	@if test ! -d $$(@D); then mkdir -p $$(@D); fi
	$$(NVCC_V) $(ALL_LDFLAGS) -shared $$(filter %.o,$$^) -o $$@ \
		-L$(LIB_DIR) $(foreach lib,$(3),-l$(lib)) \
		$(LIBRARIES)

build: $$(TARGET_NAME)

clean:
	-rm -fr $$(TARGET_NAME) $(OBJ_DIR)
endef

define EXECUTABLE
$$(foreach src,$(2),$$(eval $$(call OBJ_RULE,$$(src),$$(call OBJ_NAME,$$(src)))))

TARGET_NAME = $(BIN_DIR)/$(strip $(1))
$$(TARGET_NAME): $(call OBJECTS,$(2)) $(call TARGETS_ALL,$(3))
	@if test ! -d $$(@D); then mkdir -p $$(@D); fi
	$$(NVCC_V) $(ALL_LDFLAGS) $$(filter %.o,$$^) -o $$@ \
		-L$(LIB_DIR) $(foreach lib,$(3),-l$(lib)) \
		$(LIBRARIES)

build: $$(TARGET_NAME)

run: $$(TARGET_NAME)
	@$$(TARGET_NAME)

clean:
	-rm -fr $$(TARGET_NAME) $(OBJ_DIR)
endef

build:

run: 

clean:
