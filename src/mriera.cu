#include <cuda.h>
#include <iostream>
#include <sys/mman.h>
#include <sys/stat.h>

#include "mriera.h"

using namespace std;

static unsigned long long _find_cubin_offset(ElfW(Shdr) header,
	void* start_ptr, unsigned long long offset, const char* name)
{
	return 0;
}

int main(int argc, char * argv[])
{
	void* start_ptr = NULL;
	struct stat sb;
	size_t sz = 0;

	//read_elf_header(argv[0]);
	// Either Elf64_Ehdr or Elf32_Ehdr depending on architecture.
	ElfW(Ehdr) elf_header;
	ElfW(Shdr) header;

	cout << "opening elf file" << endl;
	FILE* file = fopen(argv[0], "rb");

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
			cout << "-Found valid ELF Header" << endl;
			b = elf64_get_section_header_by_name(file, (const Elf64_Ehdr *) &elf_header, ".nv_fatbin", &header);
			fseek(file, 0, SEEK_SET);

			if (b)
			{
				cout << "Found fatbin section" << endl;
				cuInit(0);
				// Get number of devices supporting CUDA
				int deviceCount = 0;
				cuDeviceGetCount(&deviceCount);

				if (deviceCount == 0)
				{
					printf("There is no device supporting CUDA.\n");
					exit (0);
				}
				else cout << "Number of device is "<< deviceCount << endl;

				// Get handle for device 0
				CUdevice cuDevice;
				cuDeviceGet(&cuDevice, 0);
				// Create context
				CUcontext cuContext;
				int ret = cuCtxCreate(&cuContext, 0, cuDevice);
				if (ret != CUDA_SUCCESS)
					cout << "Could not create context on device 0" << endl;
				// Create module from binary file
				CUmodule cuModule;
				cout << "sh_addr = " <<	header.sh_addr << endl;
				unsigned long long offset = header.sh_addr;
				
				unsigned long long cuOffset = _find_cubin_offset(header, start_ptr, offset, "_Z11hello_worldv");

				const void * fatbin = &((unsigned char *) start_ptr)[cuOffset];
				
				 cout << "fat bin = " << fatbin << endl;

				ret = cuModuleLoadFatBinary(&cuModule, fatbin);

				if (ret != CUDA_SUCCESS)
				{
					cout << "Failed to load self fatbin : " << argv[0] << " : " << ret<< endl;
				}

				CUfunction khw;
				//ret = cuModuleGetFunction(&khw, cuModule, "hello_world");
				ret = cuModuleGetFunction(&khw, cuModule, "_Z11hello_worldv");
				if (ret != CUDA_SUCCESS)
				{
					cout << "Failed to get hello_world from " << argv[0] << " : " << ret <<	endl;
				}
				else ret = cuLaunchKernel(khw, 1, 1, 1, 1, 1, 1, 0, 0, NULL, 0);

				if (ret != CUDA_SUCCESS)
				{
					cout << "Failed to launch : hello_world "	<< endl;
				}

				ret = cuModuleUnload(cuModule);

				if (ret != CUDA_SUCCESS)
				{
					cout << "Failed to unload self fatbin : " << argv[0] << endl;
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

