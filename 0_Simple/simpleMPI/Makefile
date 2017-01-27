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

MPI_CCFLAGS :=
MPI_CCFLAGS += $(CCFLAGS)
MPI_CCFLAGS += $(EXTRA_CCFLAGS)

MPI_LDFLAGS :=
MPI_LDFLAGS += $(addprefix -Xlinker ,$(LDFLAGS))
MPI_LDFLAGS += $(addprefix -Xlinker ,$(EXTRA_LDFLAGS))

# MPI check and binaries
MPICXX ?= $(shell which mpicxx 2>/dev/null)

ifneq ($(TARGET_ARCH),$(HOST_ARCH))
      $(info -----------------------------------------------------------------------------------------------)
      $(info WARNING - Cross Compilation not supported for MPI Samples.)
      $(info -----------------------------------------------------------------------------------------------)
      $(info   Waiving the build )
      $(info   This will be a dry-run of the Makefile.)
      $(info   For more information on how to set up your environment to build and run this )
      $(info   sample, please refer the CUDA Samples documentation and release notes)
      $(info -----------------------------------------------------------------------------------------------)
      MPICXX=mpicxx
      SAMPLE_ENABLED := 0
endif

ifeq ($(MPICXX),)
      $(info -----------------------------------------------------------------------------------------------)
      $(info WARNING - No MPI compiler found.)
      $(info -----------------------------------------------------------------------------------------------)
      $(info   CUDA Sample "simpleMPI" cannot be built without an MPI Compiler.)
      $(info   This will be a dry-run of the Makefile.)
      $(info   For more information on how to set up your environment to build and run this )
      $(info   sample, please refer the CUDA Samples documentation and release notes)
      $(info -----------------------------------------------------------------------------------------------)
      MPICXX=mpicxx
      SAMPLE_ENABLED := 0
else
      MPI_GCC := $(shell $(MPICXX) -v 2>&1 | grep gcc | wc -l | tr -d ' ')
ifeq ($(MPI_GCC),0)
ifneq ($(TARGET_OS),darwin)
      MPI_CCFLAGS += -stdlib=libstdc++
      MPI_LDFLAGS += -stdlib=libstdc++
endif
endif
endif

ifdef CUDA_PATH
ifneq ($(TARGET_OS),darwin)
ifeq ($(TARGET_SIZE),64)
LIBSIZE := 64
endif
endif

LIBRARIES += -L$(CUDA_PATH)/lib$(LIBSIZE)
endif

LIBRARIES += -lcudart

################################################################################

# Target rules
all: build

ifeq ($(SAMPLE_ENABLED),0)
build:
	@echo "Sample will be waived due to missing dependencies"
else

# TODO: Override rules for main.cpp (mpicxx + flags) 
#$(eval $(call EXECUTABLE, simpleMPI, simpleMPI.cu main.cpp))
build:
	@echo "Skipping simpleMPI"

endif
