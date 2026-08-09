#include <cassert>
#include <cstddef>

#if FORM == 0
#define D_ASSERT(condition) assert(condition) // the status quo: ((void)0) under NDEBUG
#elif FORM == 1
#define D_ASSERT(condition) ((void)sizeof((condition) ? 1 : 0))
#elif FORM == 2
#define D_ASSERT(condition) ((void)(sizeof(condition), 0))
#elif FORM == 3
#define D_ASSERT(condition) ((void)sizeof((condition) ? 1 : 0), (void)0)
#endif

struct Vec {
	int size() const {
		return 2;
	}
};
static Vec GetEntries() {
	return Vec();
}

// (a) a binding used only by an assert
static int UnusedBinding() {
	auto &&entries = GetEntries();
	D_ASSERT(entries.size() <= 2);
	return 1;
}

// (b) a static function called only from an assert
static bool IsOk(int x) {
	return x > 0;
}
static int UnusedFunction() {
	D_ASSERT(IsOk(1));
	return 2;
}

// (c) a bit-field as the condition
struct Bits {
	unsigned flag : 1;
};
static int BitField(Bits b) {
	D_ASSERT(b.flag);
	return 3;
}

// (d) a condition with no conversion to bool -- a typo an assert should catch
struct NotBool {
	int a;
};
static int NonBoolean(NotBool n) {
	D_ASSERT(n);
	return 4;
}

int main() {
	return UnusedBinding() + UnusedFunction() + BitField(Bits {1}) + NonBoolean(NotBool {1});
}
