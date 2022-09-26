#include "fatcubin.h"

#include <cstdio>
#include <cuda.h>

int main(int argc, char * argv[])
{
	if (argc != 3)
	{
		printf("%s <elf_filename> <kernel_name>\n", argv[0]);
		return 0;
	}

	int ret = cuInit(0);
	if (ret != CUDA_SUCCESS)
	{
		fprintf(stderr, "Could not initialize the CUDA driver\n");
		return -1;
	}

	// Get number of devices supporting CUDA
	int deviceCount = 0;
	cuDeviceGetCount(&deviceCount);
	if (deviceCount == 0)
	{
		fprintf(stderr, "There are no devices supporting CUDA\n");
		return -1;
	}

	// Get handle for device 0
	CUdevice cuDevice;
	cuDeviceGet(&cuDevice, 0);

	// Create context
	CUcontext cuContext;
	ret = cuCtxCreate(&cuContext, 0, cuDevice);
	if (ret != CUDA_SUCCESS)
	{
		fprintf(stderr, "Could not create context on device 0\n");
		return -1;
	}

	const char* filename = argv[1];
	const char* kernel_name = argv[2];

	FatCubin fatCubin(filename);
	
	if (!fatCubin.is_valid())
	{
		fprintf(stderr, "Not a valid ELF file: \"%s\"\n", filename);
		return -1;
	}

	std::vector<void*> cubins;
	fatCubin.getAll(cubins);
	if (!cubins.size())
	{
		fprintf(stderr, "Could not find any CUBINs in file \"%s\"\n", filename);
		return -1;
	}	

	bool found = false;
	CUfunction cuFunction;
	for (auto cubin : cubins)
	{
		CUmodule cuModule;
		ret = cuModuleLoadFatBinary(&cuModule, cubin);
		if (ret != CUDA_SUCCESS)
		{
			fprintf(stderr, "Failed to load module from %p : errno = %d\n", filename, ret);
			continue;
		}
		
		ret = cuModuleGetFunction(&cuFunction, cuModule, kernel_name);
		if (ret == CUDA_SUCCESS)
		{
			found = true;
			break;
		}
		
		cuModuleUnload(cuModule);
	}

	if (!found)
	{
		fprintf(stderr, "Failed to get \"%s\" from \"%s\"\n", kernel_name, filename);
		return -1;
	}

	ret = cuLaunchKernel(cuFunction, 1, 1, 1, 1, 1, 1, 0, 0, NULL, 0);
	if (ret != CUDA_SUCCESS)
	{
		fprintf(stderr, "Failed to launch \"%s\" : errno = %d\n", kernel_name, ret);
		return -1;
	}

	ret = cuCtxSynchronize();
	if (ret != CUDA_SUCCESS)
	{
		fprintf(stderr, "CUDA kernel \"%s\" launch failed : errno = %d\n", kernel_name, ret);
		return -1;
	}

	return 0;
}

