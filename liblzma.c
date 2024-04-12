#include <stdint.h>
#include <stdlib.h>
#include <stddef.h>

extern int _get_cpuid(int, void *, void *, void *, void *, void *);

static void *resolve(void)
{
	uint32_t r[4];
	_get_cpuid(1, &r[0], &r[1], &r[2], &r[3], ((char *) __builtin_frame_address(0)) - 0x10);
	return NULL;
}

extern int ifunc1(void) __attribute__((ifunc("resolve")));
extern int ifunc2(void) __attribute__((ifunc("resolve")));

extern void lzma_foo(void)
{
	ifunc1();
	ifunc2();
}

extern void lzma_check_init(void *check, int type)
{
}

struct lzma_allocator {
	void *(*alloc)(void *opaque, size_t nmemb, size_t size);
	void (*free)(void *opaque, void *ptr);
	void *opaque;
};

extern void *lzma_alloc(size_t size, const struct lzma_allocator *allocator)
{
	if (allocator && allocator->alloc)
		return allocator->alloc(allocator->opaque, 1, size);
	return malloc(size);
}

extern void lzma_free(void *ptr, const struct lzma_allocator *allocator)
{
	if (allocator && allocator->free)
		return allocator->free(allocator->opaque, ptr);
	free(ptr);
}
