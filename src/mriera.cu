#include <cuda.h>
#include <iostream>
#include <sys/mman.h>
#include <sys/stat.h>

#include "mriera.h"

using namespace std;

static unsigned long long _find_cubin_offset(ElfW(Shdr) header,
	void* start_ptr, unsigned long long offset, const char* name)
{
	// TODO Parse the ".nv_fatbin" aligning to byte sequence "50 ed 55 ba 01 00 10 00":
	// ...
	// asm(
	// ".section .nv_fatbin, \"a\"\n"
	// ".align 8\n"
	// "fatbinData:\n"
	// ".quad 0x00100001ba55ed50,0x00000000000008a8,0x0000004001010002,0x00000000000007a8\n"
	// ...
	// TODO Find the cubin related to the global method you want to cuModuleGetFunction.
	return offset;
}

int main(int argc, char * argv[])
{
	if (argc != 3)
	{
		printf("%s <elf_filename> <kernel_name>\n", argv[0]);
		return 0;
	}

	cuInit(0);

	// Get number of devices supporting CUDA
	int deviceCount = 0;
	cuDeviceGetCount(&deviceCount);
	if (deviceCount == 0)
	{
		printf("There is no device supporting CUDA.\n");
		exit(0);
	}
	else
		cout << "Number of devices is "<< deviceCount << endl;

	const char* filename = argv[1];
	const char* kernel_name = argv[2];

	struct stat sb;
	size_t sz = 0;

	// Either Elf64_Ehdr or Elf32_Ehdr depending on architecture.
	ElfW(Ehdr) elf_header;
	ElfW(Shdr) header;

	cout << "opening elf file" << endl;
	FILE* file = fopen(filename, "rb");

	int fd = fileno(file);
	if (fd < 0)
	{
		printf("Could not open file for memory mapping, fd = %i\n", errno);
		exit(1);
	}

	cout << "getting file size" << endl;
	if (fstat(fd, &sb) == -1)					// To obtain file size
		printf("Could not find fstat");
	sz = sb.st_size;

	cout << "Mapping file to memory : " << sz << endl;
	void* start_ptr = mmap(NULL, sz, PROT_READ | PROT_WRITE, MAP_PRIVATE, fd, 0);

	//check if valid elf
	bool b = elf_is_elf64(file);
	fseek(file, 0, SEEK_SET);
	cout << "is ELF file : " << b << endl;
	if (b)
	{
		cout << "Found valid ELF file" << endl;

		unsigned char magic[] = { 0x50, 0xed, 0x55, 0xba, 0x01, 0x00, 0x10, 0x00 };
		size_t cuOffset = (size_t)-1;
		for (size_t i = 0; i < sz - sizeof(magic); i++)
		{
			if (memcmp(start_ptr + i, magic, sizeof(magic)))
				continue;

				cuOffset = i;
				break;
		}
		if (cuOffset == (size_t)-1)
		{
			printf("Could not find the fatbin magic\n");
			exit(1);
		}

		const void * fatbin = &((unsigned char *) start_ptr)[cuOffset];
				
		cout << "fatbin = " << (void*)cuOffset << endl;

		// Get handle for device 0
		CUdevice cuDevice;
		cuDeviceGet(&cuDevice, 0);
		// Create context
		CUcontext cuContext;
		int ret = cuCtxCreate(&cuContext, 0, cuDevice);
		if (ret != CUDA_SUCCESS)
			cout << "Could not create context on device 0" << endl;

		// Call cuModuleLoadFatBinary with a base address of the .nv_fatbin + specific cubin offset.
		CUmodule cuModule;
		ret = cuModuleLoadFatBinary(&cuModule, fatbin);
		if (ret != CUDA_SUCCESS)
		{
			cout << "Failed to load fatbin : " << filename << " : " << ret << endl;
		}

		CUfunction khw;
		ret = cuModuleGetFunction(&khw, cuModule, kernel_name);
		if (ret != CUDA_SUCCESS)
		{
			cout << "Failed to get " << kernel_name << " from " << filename << " : " << ret << endl;
		}
		else ret = cuLaunchKernel(khw, 1, 1, 1, 1, 1, 1, 0, 0, NULL, 0);

		if (ret != CUDA_SUCCESS)
		{
			cout << "Failed to launch : " << kernel_name << " : " << ret << endl;
		}

		ret = cuModuleUnload(cuModule);

		if (ret != CUDA_SUCCESS)
		{
			cout << "Failed to unload self fatbin : " << filename << " : " << ret << endl;
			return -1;
		}

		if (cudaDeviceSynchronize() != cudaSuccess)
		{
			printf ("Cuda call failed\n");
		}

		//unmap sutff
		munmap(start_ptr, sz);
		return 0;
	}

	fclose(file);

	return 0;
}

