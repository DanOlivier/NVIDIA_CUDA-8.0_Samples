
ifeq ($(TARGET_OS),darwin)
  ALL_LDFLAGS += -Xcompiler -F/Library/Frameworks -Xlinker -framework -Xlinker CUDA
else
  ifneq (,$(CUDA_PATH))
    CUDA_SEARCH_PATH ?=
    ifneq ($(TARGET_ARCH),$(HOST_ARCH))
      ifeq ($(TARGET_ARCH)-$(TARGET_OS),armv7l-linux)
        ifneq ($(TARGET_FS),)
          LIBRARIES += -L$(TARGET_FS)/usr/lib
          CUDA_SEARCH_PATH += $(TARGET_FS)/usr/lib
          CUDA_SEARCH_PATH += $(TARGET_FS)/usr/lib/arm-linux-gnueabihf
        endif
        CUDA_SEARCH_PATH += $(CUDA_PATH)/targets/armv7-linux-gnueabihf/lib/stubs
        CUDA_SEARCH_PATH += /usr/arm-linux-gnueabihf/lib
      else ifeq ($(TARGET_ARCH)-$(TARGET_OS),aarch64-linux)
        CUDA_SEARCH_PATH += $(CUDA_PATH)/targets/aarch64-linux/lib/stubs
      else ifeq ($(TARGET_ARCH)-$(TARGET_OS),armv7l-android)
        CUDA_SEARCH_PATH += $(CUDA_PATH)/targets/armv7-linux-androideabi/lib/stubs
      else ifeq ($(TARGET_ARCH)-$(TARGET_OS),aarch64-android)
        CUDA_SEARCH_PATH += $(CUDA_PATH)/targets/aarch64-linux-androideabi/lib/stubs
      else ifeq ($(TARGET_ARCH)-$(TARGET_OS),armv7l-qnx)
        CUDA_SEARCH_PATH += $(CUDA_PATH)/targets/ARMv7-linux-QNX/lib/stubs
      else ifeq ($(TARGET_ARCH)-$(TARGET_OS),aarch64-qnx)
        CUDA_SEARCH_PATH += $(CUDA_PATH)/targets/aarch64-qnx/lib/stubs
      else ifeq ($(TARGET_ARCH)-$(TARGET_OS),ppc64le-linux)
        CUDA_SEARCH_PATH += $(CUDA_PATH)/targets/ppc64le-linux/lib/stubs
      endif
    else
      UBUNTU = $(shell lsb_release -i -s 2>/dev/null | grep -i ubuntu)
      ifneq ($(UBUNTU),)
        CUDA_SEARCH_PATH += /usr/lib
      else
        CUDA_SEARCH_PATH += /usr/lib64
      endif
  
      ifeq ($(TARGET_ARCH),x86_64)
        CUDA_SEARCH_PATH += $(CUDA_PATH)/lib64/stubs
      endif
  
      ifeq ($(TARGET_ARCH),armv7l)
        CUDA_SEARCH_PATH += $(CUDA_PATH)/targets/armv7-linux-gnueabihf/lib/stubs
        CUDA_SEARCH_PATH += /usr/lib/arm-linux-gnueabihf
      endif
  
      ifeq ($(TARGET_ARCH),aarch64)
        CUDA_SEARCH_PATH += /usr/lib
        CUDA_SEARCH_PATH += $(CUDA_PATH)/targets/aarch64-linux/lib/stubs
      endif
  
      ifeq ($(TARGET_ARCH),ppc64le)
        CUDA_SEARCH_PATH += $(CUDA_PATH)/targets/ppc64le-linux/lib/stubs
        CUDA_SEARCH_PATH += /usr/lib/powerpc64le-linux-gnu
      endif
    endif
  
    CUDALIB ?= $(shell find -L $(CUDA_SEARCH_PATH) -maxdepth 1 -name libcuda.so)
    ifeq ($(CUDALIB),)
      $(info >>> WARNING - libcuda.so not found, CUDA Driver is not installed.  Please re-install the driver. <<<)
      SAMPLE_ENABLED := 0
    endif
  endif

  LIBRARIES += -lcuda
endif