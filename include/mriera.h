#ifndef MRIERA_H
#define MRIERA_H

#include "elf_util.h"

#ifdef __cplusplus
extern "C"
{
#endif

bool elf_is_elf64(FILE * file);
bool elf64_get_elf_header(FILE * file, Elf64_Ehdr * elf_header);
bool elf64_get_section_header_by_name(FILE * file, const Elf64_Ehdr * elf_header, const char * name, Elf64_Shdr * header);

#ifdef __cplusplus
}
#endif

#endif // MRIERA_H

