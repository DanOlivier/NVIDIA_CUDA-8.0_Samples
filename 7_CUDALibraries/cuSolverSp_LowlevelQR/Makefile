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

# This sample is not supported on ARMv7
ifeq ($(TARGET_ARCH),armv7l)
  $(info >>> WARNING - cuSolverSp_LowlevelQR is not supported on ARMv7 - waiving sample <<<)
  SAMPLE_ENABLED := 0
endif

# This sample is not supported on aarch64
ifeq ($(TARGET_ARCH),aarch64)
  $(info >>> WARNING - cuSolverSp_LowlevelQR is not supported on aarch64 - waiving sample <<<)
  SAMPLE_ENABLED := 0
endif

# Attempt to compile a minimal OpenMP application. If a.out exists, OpenMP is properly set up.
ifneq ($(TARGET_OS),darwin)
LIBRARIES += -lgomp
ALL_CCFLAGS += -Xcompiler -fopenmp
$(shell echo "#include <omp.h>" > test.c ; echo "int main() { omp_get_num_threads(); return 0; }" >> test.c ; $(HOST_COMPILER) -fopenmp test.c)
OPENMP ?= $(shell find a.out 2>/dev/null)

ifeq ($(OPENMP),)
      $(info -----------------------------------------------------------------------------------------------)
      $(info WARNING - OpenMP is unable to compile)
      $(info -----------------------------------------------------------------------------------------------)
      $(info   This CUDA Sample cannot be built if the OpenMP compiler is not set up correctly.)
      $(info   This will be a dry-run of the Makefile.)
      $(info   For more information on how to set up your environment to build and run this )
      $(info   sample, please refer the CUDA Samples documentation and release notes)
      $(info -----------------------------------------------------------------------------------------------)
      SAMPLE_ENABLED := 0
endif

$(shell rm a.out test.c 2>/dev/null)
endif

ifeq ($(TARGET_OS),linux)
ALL_CCFLAGS += -Xcompiler \"-Wl,--no-as-needed\"
endif

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

ifeq ($(SMS),)
$(info >>> WARNING - no SM architectures have been specified - waiving sample <<<)
SAMPLE_ENABLED := 0
endif

ifeq ($(GENCODE_FLAGS),)
# Generate SASS code for each SM architecture listed in $(SMS)
$(foreach sm,$(SMS),$(eval GENCODE_FLAGS += -gencode arch=compute_$(sm),code=sm_$(sm)))

# Generate PTX code from the highest SM architecture in $(SMS) to guarantee forward-compatibility
HIGHEST_SM := $(lastword $(sort $(SMS)))
ifneq ($(HIGHEST_SM),)
GENCODE_FLAGS += -gencode arch=compute_$(HIGHEST_SM),code=compute_$(HIGHEST_SM)
endif
endif

LIBRARIES += -lcusolver -lcusparse

################################################################################

# Target rules
all: build

ifeq ($(SAMPLE_ENABLED),0)
build:
	@echo "Sample will be waived due to missing dependencies"
else

$(eval $(call EXECUTABLE, cuSolverSp_LowlevelQR, \
	cuSolverSp_LowlevelQR.cpp mmio.c mmio_wrapper.cpp ))

endif
