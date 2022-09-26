#include <stdio.h>

extern "C" __global__ void hello_world()
{
	printf("Hello, world!\n");
}

int main(int argc, char* argv[])
{
	hello_world<<<1, 1>>>();
	cudaDeviceSynchronize();
	return 0;
}
