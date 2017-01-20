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

TOP := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
include $(TOP)/../../common/common.mk

################################################################################

# This sample is not supported on Mac OSX
ifeq ($(TARGET_OS),darwin)
  $(info >>> WARNING - cudaDecodeGL is not supported on Mac OSX - waiving sample <<<)
  SAMPLE_ENABLED := 0
endif

# This sample is not supported on ARMv7
ifeq ($(TARGET_ARCH),armv7l)
  $(info >>> WARNING - cudaDecodeGL is not supported on ARMv7 - waiving sample <<<)
  SAMPLE_ENABLED := 0
endif

# This sample is not supported on aarch64
ifeq ($(TARGET_ARCH),aarch64)
  $(info >>> WARNING - cudaDecodeGL is not supported on aarch64 - waiving sample <<<)
  SAMPLE_ENABLED := 0
endif

PTX_FILE := NV12ToARGB_drvapi${TARGET_SIZE}.ptx

# Makefile include to help find GL Libraries
include $(TOP)/../../common/findgllib.mk

# OpenGL specific libraries
ifeq ($(TARGET_OS),darwin)
 # Mac OSX specific libraries and paths to include
 LIBRARIES += -L/System/Library/Frameworks/OpenGL.framework/Libraries
 LIBRARIES += -lGL -lGLU
 ALL_LDFLAGS += -Xlinker -framework -Xlinker GLUT
else
 LIBRARIES += $(GLLINK)
 LIBRARIES += -lGL -lGLU -lX11 -lglut
endif

# Gencode arguments
SMS ?=

ifeq ($(GENCODE_FLAGS),)
# Generate SASS code for each SM architecture listed in $(SMS)
$(foreach sm,$(SMS),$(eval GENCODE_FLAGS += -gencode arch=compute_$(sm),code=sm_$(sm)))

ifeq ($(SMS),)
# Generate PTX code from SM 20
GENCODE_FLAGS += -gencode arch=compute_20,code=compute_20
endif

# Generate PTX code from the highest SM architecture in $(SMS) to guarantee forward-compatibility
HIGHEST_SM := $(lastword $(sort $(SMS)))
ifneq ($(HIGHEST_SM),)
GENCODE_FLAGS += -gencode arch=compute_$(HIGHEST_SM),code=compute_$(HIGHEST_SM)
endif
endif

include $(TOP)/../../common/libCUDA.mk

LIBRARIES += -lcudart -lnvcuvid

################################################################################

# Target rules
all: build

ifeq ($(SAMPLE_ENABLED),0)
build:
	@echo "Sample will be waived due to missing dependencies"
else
build: cudaDecodeGL $(PTX_FILE)

$(PTX_FILE): NV12ToARGB_drvapi.cu
	@$(NVCC) $(INCLUDES) $(ALL_CCFLAGS) $(GENCODE_FLAGS) -o $@ -ptx $<
	@mkdir -p data
	@cp -f $@ ./data
	@mkdir -p ../../bin/$(TARGET_ARCH)/$(TARGET_OS)/$(BUILD_TYPE)
	@cp -f $@ ../../bin/$(TARGET_ARCH)/$(TARGET_OS)/$(BUILD_TYPE)

FrameQueue.o:FrameQueue.cpp
	@$(NVCC) $(INCLUDES) $(ALL_CCFLAGS) $(GENCODE_FLAGS) -o $@ -c $<

ImageGL.o:ImageGL.cpp
	@$(NVCC) $(INCLUDES) $(ALL_CCFLAGS) $(GENCODE_FLAGS) -o $@ -c $<

VideoDecoder.o:VideoDecoder.cpp
	@$(NVCC) $(INCLUDES) $(ALL_CCFLAGS) $(GENCODE_FLAGS) -o $@ -c $<

VideoParser.o:VideoParser.cpp
	@$(NVCC) $(INCLUDES) $(ALL_CCFLAGS) $(GENCODE_FLAGS) -o $@ -c $<

VideoSource.o:VideoSource.cpp
	@$(NVCC) $(INCLUDES) $(ALL_CCFLAGS) $(GENCODE_FLAGS) -o $@ -c $<

cudaModuleMgr.o:cudaModuleMgr.cpp
	@$(NVCC) $(INCLUDES) $(ALL_CCFLAGS) $(GENCODE_FLAGS) -o $@ -c $<

cudaProcessFrame.o:cudaProcessFrame.cpp
	@$(NVCC) $(INCLUDES) $(ALL_CCFLAGS) $(GENCODE_FLAGS) -o $@ -c $<

videoDecodeGL.o:videoDecodeGL.cpp
	@$(NVCC) $(INCLUDES) $(ALL_CCFLAGS) $(GENCODE_FLAGS) -o $@ -c $<

cudaDecodeGL: FrameQueue.o ImageGL.o VideoDecoder.o VideoParser.o VideoSource.o cudaModuleMgr.o cudaProcessFrame.o videoDecodeGL.o
	@$(NVCC) $(ALL_LDFLAGS) $(GENCODE_FLAGS) -o $@ $+ $(LIBRARIES)
	@mkdir -p ../../bin/$(TARGET_ARCH)/$(TARGET_OS)/$(BUILD_TYPE)
	@cp $@ ../../bin/$(TARGET_ARCH)/$(TARGET_OS)/$(BUILD_TYPE)

run: build
	@./cudaDecodeGL

clean:
	rm -f cudaDecodeGL FrameQueue.o ImageGL.o VideoDecoder.o VideoParser.o VideoSource.o cudaModuleMgr.o cudaProcessFrame.o videoDecodeGL.o  data/$(PTX_FILE) $(PTX_FILE)
	rm -rf ../../bin/$(TARGET_ARCH)/$(TARGET_OS)/$(BUILD_TYPE)/cudaDecodeGL
	rm -rf ../../bin/$(TARGET_ARCH)/$(TARGET_OS)/$(BUILD_TYPE)/$(PTX_FILE)

clobber: clean

endif
