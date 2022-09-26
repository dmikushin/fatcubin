#include <errno.h>
#include <iostream>
#include <sys/mman.h>
#include <sys/stat.h>

#include "fatcubin.h"

bool FatCubin::is_valid() const { return valid; }

FatCubin::FatCubin(const std::string filename)
{
	// Opening the file.
	FILE* file = fopen(filename.c_str(), "rb");
	int fd = fileno(file);
	if (fd < 0)
	{
		fprintf(stderr, "Could not open file \"%s\" for reading, errno = %d\n", filename.c_str(), errno);
		return;
	}

	// Obtaining the file size.
	struct stat sb;
	if (fstat(fd, &sb) == -1)
	{
		fprintf(stderr, "Could not obtain the file \"%s\" size, errno = %d\n", filename.c_str(), errno);
		return;
	}
	
	// Mapping file to memory.
	sz = sb.st_size;
	mmap_addr = mmap(NULL, sz, PROT_READ | PROT_WRITE, MAP_PRIVATE, fd, 0);

	// Check whether the file is a valid ELF file.
	if (!elf_is_elf64(file))
	{
		fprintf(stderr, "File \"%s\" is not a valid ELF file\n", filename.c_str());
		return;
	}
	
	fseek(file, 0, SEEK_SET);
	valid = true;
}

void FatCubin::getAll(std::vector<void*>& cubins)
{
	const unsigned char magic[] = { 0x50, 0xed, 0x55, 0xba, 0x01, 0x00, 0x10, 0x00 };

	size_t cuOffset = (size_t)-1;
	for (size_t i = 0; i < sz - sizeof(magic); i++)
	{
		if (memcmp(mmap_addr + i, magic, sizeof(magic)))
			continue;

		cubins.push_back(mmap_addr + i);
	}
}

void FatCubin::getKernel(const std::string name)
{
	// TODO Find kernel in the cubin ELF itself.
#if 0		
	// Either Elf64_Ehdr or Elf32_Ehdr depending on architecture.
	ElfW(Ehdr) elf_header;
	ElfW(Shdr) header;
#endif
}

FatCubin::~FatCubin()
{
	if (file) fclose(file);
	if (mmap_addr) munmap(mmap_addr, sz);
}

