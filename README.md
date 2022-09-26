# Get CUDA Module from ELF binary

This utility is used to locate and launch CUDA kernels embedded into arbitrary 3rd-party applications. The launch is possible, given that the NVIDIA fatbinary format is respected, and the CUDA kernel interface (input/output arguments) is known and can be replicated.

Here we reconstruct the full working solution from a snippet provided on [StackOverflow](https://stackoverflow.com/questions/64815293/using-cumoduleload-to-get-current-module-from-elf-binary-from-argv0) by @mriera

## Prerequisites

```
sudo apt install libelf-dev
```

## Building

```
mkdir build
cd build
cmake ..
make
```

## Testing

```
./fatcubin_test
./fatcubin_test <elf_filename> <kernel_name>

./fatcubin_test sample_app hello_world
Hello, world!
```

