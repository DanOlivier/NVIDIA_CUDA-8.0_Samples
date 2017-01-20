/*
 * cuda_producer.cpp
 *
 * Copyright 2016 NVIDIA Corporation.  All rights reserved.
 *
 * Please refer to the NVIDIA end user license agreement (EULA) associated
 * with this source code for terms and conditions that govern your use of
 * this software. Any use, reproduction, disclosure, or distribution of
 * this software and related documentation outside the terms of the EULA
 * is strictly prohibited.
 *
 */

//
// DESCRIPTION:   Simple cuda EGL stream producer app
//

#include "cudaEGL.h"
#include "cuda_producer.h"
#include "eglstrm_common.h"

#if defined(EXTENSION_LIST)
EXTENSION_LIST(EXTLST_EXTERN)
#endif

static CUresult
cudaProducerReadYUVFrame(
    FILE *file,
    unsigned int frameNum,
    unsigned int width,
    unsigned int height,
    unsigned char *pBuff
    )
{
    int bOrderUV = 0;
    unsigned char *pYBuff, *pUBuff, *pVBuff, *pChroma;
    unsigned int frameSize = (width * height *3)/2;
    CUresult ret = CUDA_SUCCESS;
    unsigned int i;

    if(!pBuff || !file)
        return CUDA_ERROR_FILE_NOT_FOUND;

    pYBuff = pBuff;

    //YVU order in the buffer
    pVBuff = pYBuff + width * height;
    pUBuff = pVBuff + width * height / 4;

    if(fseek(file, frameNum * frameSize, SEEK_SET)) {
        printf("ReadYUVFrame: Error seeking file: %p\n", file);
        ret = CUDA_ERROR_NOT_PERMITTED;
        goto done;
    }
    //read Y U V separately
    for(i = 0; i < height; i++) {
        if(fread(pYBuff, width, 1, file) != 1) {
            printf("ReadYUVFrame: Error reading file: %p\n", file);
            ret = CUDA_ERROR_NOT_PERMITTED;
            goto done;
        }
        pYBuff += width;
    }

    pChroma = bOrderUV ? pUBuff : pVBuff;
    for(i = 0; i < height / 2; i++) {
        if(fread(pChroma, width / 2, 1, file) != 1) {
            printf("ReadYUVFrame: Error reading file: %p\n", file);
            ret = CUDA_ERROR_NOT_PERMITTED;
            goto done;
        }
        pChroma += width / 2;
    }

    pChroma = bOrderUV ? pVBuff : pUBuff;
    for(i = 0; i < height / 2; i++) {
        if(fread(pChroma, width / 2, 1, file) != 1) {
            printf("ReadYUVFrame: Error reading file: %p\n", file);
            ret = CUDA_ERROR_NOT_PERMITTED;
            goto done;
        }
        pChroma += width / 2;
    }
done:
    return ret;
}

static CUresult
cudaProducerReadARGBFrame(
    FILE *file,
    unsigned int frameNum,
    unsigned int width,
    unsigned int height,
    unsigned char *pBuff)
{
    unsigned int frameSize = width * height * 4;
    CUresult ret = CUDA_SUCCESS;

    if(!pBuff || !file)
        return CUDA_ERROR_FILE_NOT_FOUND;

    if(fseek(file, frameNum * frameSize, SEEK_SET)) {
        printf("ReadYUVFrame: Error seeking file: %p\n", file);
        ret = CUDA_ERROR_NOT_PERMITTED;
        goto done;
    }

    //read ARGB data
    if(fread(pBuff, frameSize, 1, file) != 1) {
        if (feof(file))
            printf("ReadARGBFrame: file read to the end\n");
        else
            printf("ReadARGBFrame: Error reading file: %p\n", file);
        ret = CUDA_ERROR_NOT_PERMITTED;
        goto done;
    }
done:
    return ret;
}

CUresult cudaProducerTest(test_cuda_producer_s *cudaProducer, char *file)
{
    int framenum = 0;
    unsigned char *pBuff = NULL;
    CUarray cudaArr[3] = {0};
    CUDA_ARRAY3D_DESCRIPTOR desc = {0};
    CUdeviceptr cudaPtr[3] = {0};
    unsigned int bufferSize;
    CUresult cuStatus = CUDA_SUCCESS;
    unsigned int i, surfNum, uvOffset[3]={0};
    unsigned int copyWidthInBytes[3]={0}, copyHeight[3]={0};
    CUeglColorFormat eglColorFormat;
    FILE *file_p;
    CUeglFrame cudaEgl;
    CUcontext oldContext;

    file_p = fopen(file, "rb");
    if(!file_p) {
        printf("CudaProducer: Error opening file: %s\n", file);
        goto done;
    }
    pBuff = (unsigned char*) malloc((cudaProducer->width*cudaProducer->height*4));
    if(!pBuff) {
        printf("CudaProducer: Failed to allocate image buffer\n");
        goto done;
    }
    if (cudaProducer->pitchLinearOutput) {
        if (cudaProducer->isARGB) {
            cuStatus = cuMemAlloc(&cudaPtr[0], (cudaProducer->width*cudaProducer->height*4));
            if(cuStatus != CUDA_SUCCESS) {
                printf("Create CUDA pointer failed, cuStatus=%d\n", cuStatus);
                goto done;
            }
        } else { //YUV case
            for (i = 0; i < 3; i++) {
                if (i == 0) {
                    bufferSize = cudaProducer->width * cudaProducer->height;
                }
                else {
                    bufferSize = cudaProducer->width * cudaProducer->height/4;
                }
                cuStatus = cuMemAlloc(&cudaPtr[i], bufferSize);
                if(cuStatus != CUDA_SUCCESS) {
                    printf("Create CUDA pointer %d failed, cuStatus=%d\n", i, cuStatus);
                    goto done;
                }
            }
        }
    } else {
        desc.Format = CU_AD_FORMAT_UNSIGNED_INT8;
        desc.Depth = 1;
        desc.Flags = CUDA_ARRAY3D_SURFACE_LDST;
        if (cudaProducer->isARGB) {
            desc.NumChannels = 4;
            desc.Width = cudaProducer->width * 4;
            desc.Height = cudaProducer->height;
            cuStatus = cuArray3DCreate(&cudaArr[0], &desc);
            if(cuStatus != CUDA_SUCCESS) {
                printf("Create CUDA array failed, cuStatus=%d\n", cuStatus);
                goto done;
            }
        } else { //YUV case
            for (i=0; i < 3; i++) {
                if (i == 0) {
                    desc.NumChannels = 1;
                    desc.Width = cudaProducer->width;
                    desc.Height = cudaProducer->height;
                } else { // U/V surface as planar
                    desc.NumChannels = 1;
                    desc.Width = cudaProducer->width/2;
                    desc.Height = cudaProducer->height/2;
                }
                checkCudaErrors(cuCtxPushCurrent(cudaProducer->context));
                cuStatus = cuArray3DCreate(&cudaArr[i], &desc);
                if(cuStatus != CUDA_SUCCESS) {
                    printf("Create CUDA array failed, cuStatus=%d\n", cuStatus);
                    goto done;
                }
                checkCudaErrors(cuCtxPopCurrent(&oldContext));
            }
        }
    }
    uvOffset[0] = 0;
    if (cudaProducer->isARGB) {
        if (CUDA_SUCCESS != cudaProducerReadARGBFrame(file_p, framenum, cudaProducer->width, cudaProducer->height, pBuff)) {
            printf("cuda producer, read ARGB frame failed\n");
            goto done;
        }
        copyWidthInBytes[0] = cudaProducer->width * 4;
        copyHeight[0] = cudaProducer->height;
        surfNum = 1;
        eglColorFormat = CU_EGL_COLOR_FORMAT_ARGB;
    } else {
        if (CUDA_SUCCESS != cudaProducerReadYUVFrame(file_p, framenum, cudaProducer->width, cudaProducer->height, pBuff)) {
            printf("cuda producer, reading YUV frame failed\n");
            goto done;
        }
        surfNum = 3;
        eglColorFormat = CU_EGL_COLOR_FORMAT_YUV420_PLANAR;
        copyWidthInBytes[0] = cudaProducer->width;
        copyHeight[0] = cudaProducer->height;
        copyWidthInBytes[1] = cudaProducer->width/2;
        copyHeight[1] = cudaProducer->height/2;
        copyWidthInBytes[2] = cudaProducer->width/2;
        copyHeight[2] = cudaProducer->height/2;
        uvOffset[1] = cudaProducer->width *cudaProducer->height;
        uvOffset[2] = uvOffset[1] + cudaProducer->width/2 *cudaProducer->height/2;
    }
    if (cudaProducer->pitchLinearOutput) {
        for (i=0; i<surfNum; i++) {
            cuStatus = cuCtxSynchronize();
            if (cuStatus != CUDA_SUCCESS) {
                printf ("cuCtxSynchronize failed \n");
                goto done;
            }
            cuStatus = cuMemcpy(cudaPtr[i], (CUdeviceptr)(pBuff + uvOffset[i]), copyWidthInBytes[i]*copyHeight[i]);
            if (cuStatus != CUDA_SUCCESS) {
                printf("Cuda producer: cuMemCpy pitchlinear failed, cuStatus =%d\n",cuStatus);
                goto done;
            }
        }
    } else {
        //copy pBuff to cudaArray
        CUDA_MEMCPY3D cpdesc;
        for (i=0; i < surfNum; i++) {
            cuStatus = cuCtxSynchronize();
            if (cuStatus != CUDA_SUCCESS) {
                printf ("cuCtxSynchronize failed \n");
                goto done;
            }
            memset(&cpdesc, 0, sizeof(cpdesc));
            cpdesc.srcXInBytes = cpdesc.srcY = cpdesc.srcZ = cpdesc.srcLOD = 0;
            cpdesc.srcMemoryType = CU_MEMORYTYPE_HOST;
            cpdesc.srcHost = (void *)(pBuff + uvOffset[i]);
            cpdesc.dstXInBytes = cpdesc.dstY = cpdesc.dstZ = cpdesc.dstLOD = 0;
            cpdesc.dstMemoryType = CU_MEMORYTYPE_ARRAY;
            cpdesc.dstArray = cudaArr[i];
            cpdesc.WidthInBytes = copyWidthInBytes[i];
            cpdesc.Height = copyHeight[i];
            cpdesc.Depth = 1;
            cuStatus = cuMemcpy3D(&cpdesc);
            if (cuStatus != CUDA_SUCCESS) {
                printf("Cuda producer: cuMemCpy failed, cuStatus =%d\n",cuStatus);
                goto done;
            }
        }
    }
    for (i=0; i < surfNum; i++) {
        if (cudaProducer->pitchLinearOutput)
            cudaEgl.frame.pPitch[i] = (void *)cudaPtr[i];
        else
            cudaEgl.frame.pArray[i] = cudaArr[i];
    }
    cudaEgl.width = copyWidthInBytes[0];
    cudaEgl.depth = 1;
    cudaEgl.height = copyHeight[0];
    cudaEgl.pitch = cudaProducer->pitchLinearOutput ? cudaEgl.width : 0;
    cudaEgl.frameType = cudaProducer->pitchLinearOutput ?
        CU_EGL_FRAME_TYPE_PITCH : CU_EGL_FRAME_TYPE_ARRAY;
    cudaEgl.planeCount = surfNum;
    cudaEgl.numChannels = (eglColorFormat == CU_EGL_COLOR_FORMAT_ARGB) ? 4: 1;
    cudaEgl.eglColorFormat = eglColorFormat;
    cudaEgl.cuFormat = CU_AD_FORMAT_UNSIGNED_INT8;
    
    cuStatus = cuEGLStreamProducerPresentFrame(&cudaProducer->cudaConn, cudaEgl, NULL);
    if (cuStatus != CUDA_SUCCESS) {
        printf("cuda Producer present frame FAILED with custatus= %d\n", cuStatus);
        goto done;
    }
done:
    if (file_p) {
        fclose(file_p);
        file_p = NULL;
    }
    if (pBuff) {
        free(pBuff);
        pBuff = NULL;
    }
    return cuStatus;
}

CUresult cudaDeviceCreateProducer(test_cuda_producer_s *cudaProducer)
{
    CUdevice device;
    CUresult status = CUDA_SUCCESS;
    if (CUDA_SUCCESS != (status = cuInit(0))) {
        printf("Failed to initialize CUDA\n");
        return status;
    }
    
    if (CUDA_SUCCESS != (status = cuDeviceGet(&device, 0))) {
        printf("failed to get CUDA device\n");
        return status;
    }
    
    if (CUDA_SUCCESS !=  (status = cuCtxCreate(&cudaProducer->context, 0, device)) ) {
        printf("failed to create CUDA context\n");
        return status;
    }
    checkCudaErrors(cuCtxPopCurrent(&cudaProducer->context));
    return status;
}

void cudaProducerInit(test_cuda_producer_s *cudaProducer, EGLDisplay eglDisplay, EGLStreamKHR eglStream, TestArgs *args)
{
    cudaProducer->fileName1 = args->infile1;
    cudaProducer->fileName2 = args->infile2;
    
    cudaProducer->frameCount = 2;
    cudaProducer->width      = args->inputWidth;
    cudaProducer->height     = args->inputHeight;
    cudaProducer->isARGB    = args->isARGB;
    cudaProducer->pitchLinearOutput = args->pitchLinearOutput;
    
    // Set cudaProducer default parameters
    cudaProducer->eglDisplay = eglDisplay;
    cudaProducer->eglStream = eglStream;
}

CUresult cudaProducerDeinit(test_cuda_producer_s *cudaProducer)
{
    return cuEGLStreamProducerDisconnect(&cudaProducer->cudaConn);
}

