include $(TOP)/../../common/libCUDA.mk

# libNVRTC specific libraries
ifneq (,$(CUDA_PATH))
  ifeq ($(TARGET_OS),darwin)
   LDFLAGS += -L$(CUDA_PATH)/lib -framework CUDA
  else ifeq ($(TARGET_ARCH),x86_64)
   LDFLAGS += -L$(CUDA_PATH)/lib64 -L$(CUDA_PATH)/lib64/stubs
  else ifeq ($(TARGET_ARCH),ppc64le)
   LDFLAGS += -L$(CUDA_PATH)/targets/ppc64le-linux/lib
   LDFLAGS += -L$(CUDA_PATH)/targets/ppc64le-linux/lib/stubs
  endif

  INCLUDES += -I$(CUDA_PATH)/include
endif

LIBRARIES += -lnvrtc
