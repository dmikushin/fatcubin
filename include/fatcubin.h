#ifndef FATCUBIN_H
#define FATCUBIN_H

#include "elf_util.h"

#include <cstdio>
#include <string>
#include <vector>

extern "C"
{
	bool elf_is_elf64(FILE * file);
	bool elf64_get_elf_header(FILE * file, Elf64_Ehdr * elf_header);
	bool elf64_get_section_header_by_name(FILE * file, const Elf64_Ehdr * elf_header, const char * name, Elf64_Shdr * header);
}

class FatCubin
{
	FILE* file = nullptr;
	void* mmap_addr = nullptr;
	size_t sz;
	
	bool valid = false;

public :

	bool is_valid() const;

	FatCubin(const std::string filename);

	void getAll(std::vector<void*>& cubins);

	void getKernel(const std::string name);

	~FatCubin();
};

#endif // FATCUBIN_H

