#include <stdint.h>
#include <stdlib.h>
#include <stddef.h>

extern void _Llzma_delta_props_encoder(void *);

static void *resolve(void)
{
	int64_t ctx[8];
	static int count;
	if (count++ != 1) return NULL;
	_Llzma_delta_props_encoder(&ctx);
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
