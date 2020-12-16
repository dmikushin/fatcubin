# Get CUDA Module from ELF binary

This utility is used to locate and launch CUDA kernels embedded into arbitrary 3rd-party applications. The launch is possible, given that the NVIDIA fatbinary format is respected, and the CUDA kernel interface (input/output arguments) is known and can be replicated.

Here we reconstruct the full working solution from a snippet provided on [StackOverflow](https://stackoverflow.com/questions/64815293/using-cumoduleload-to-get-current-module-from-elf-binary-from-argv0) by @mriera

## Example usage

```
mkdir build
cd build
cmake ..
$ ./mriera mriera_test
./mriera <elf_filename> <kernel_name>
$ ./mriera mriera_test hello_world
Number of devices is 1
opening elf file
getting file size
Mapping file to memory : 710000
is ELF file : 1
Found valid ELF file
fatbin = 0x68620
Hello, world!
```

