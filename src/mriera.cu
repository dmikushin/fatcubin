#include <cuda.h>
#include <iostream>
#include <sys/mman.h>
#include <sys/stat.h>

#include "mriera.h"

using namespace std;

static unsigned long long _find_cubin_offset(ElfW(Shdr) header,
	void* start_ptr, unsigned long long offset, const char* name)
{
	// TODO Parse the ".nv_fatbin" aligning to byte sequence "50 ed 55 ba 01 00 10 00".
	// TODO Find the cubin related to the global method you want to cuModuleGetFunction.
	return 0;
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

	void* start_ptr = NULL;
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
	start_ptr = mmap(NULL, sz, PROT_READ | PROT_WRITE, MAP_PRIVATE, fd, 0);

	//check if valid elf
	bool b = elf_is_elf64(file);
	fseek(file, 0, SEEK_SET);
	cout << "is ELF file : " << b << endl;
	if (b)
	{
		cout << "Found valid ELF file" << endl;
		//get ELF_Header
		b = elf64_get_elf_header(file, &elf_header);
		fseek(file, 0, SEEK_SET);

		if (b)
		{
			cout << "Found valid ELF Header" << endl;

			// Read the ELF headers and find the ".nv_fatbin" section.
			b = elf64_get_section_header_by_name(file, (const Elf64_Ehdr *) &elf_header, ".nv_fatbin", &header);
			fseek(file, 0, SEEK_SET);

			if (b)
			{
				cout << "Found fatbin section" << endl;

				cout << "sh_addr = " <<	header.sh_addr << endl;
				unsigned long long offset = header.sh_addr;
				
				// Parse the ".nv_fatbin" aligning to byte sequence "50 ed 55 ba 01 00 10 00".
				// Find the cubin related to the global method you want to cuModuleGetFunction.
				unsigned long long cuOffset = _find_cubin_offset(header, start_ptr, offset, kernel_name);

				const void * fatbin = &((unsigned char *) start_ptr)[cuOffset];
				
				cout << "fatbin = " << fatbin << endl;

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
					cout << "Failed to launch : " << kernel_name << endl;
				}

				ret = cuModuleUnload(cuModule);

				if (ret != CUDA_SUCCESS)
				{
					cout << "Failed to unload self fatbin : " << filename << endl;
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
		}

	}

	fclose(file);

	return 0;
}

