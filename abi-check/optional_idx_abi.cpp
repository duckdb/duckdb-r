// Throwaway ABI check (duckdb/duckdb-r#3037): the patched duckdb::optional_idx
// (upstream's std::optional<idx_t> storage plus an inline GetIndexOr()) must be
// layout-compatible with upstream's, since prebuilt extensions use upstream's header.
#include "duckdb/common/optional_idx.hpp"

#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <new>
#include <optional>
#include <type_traits>

// Never called here; defined only so that the header's out-of-line declaration links.
void duckdb::optional_idx::ThrowNotSet() {
	throw 0;
}

namespace upstream {
using duckdb::idx_t;
using std::optional;
// Verbatim copy of upstream's class (v2.0-cyanoptera), minus ThrowNotSet's linkage.
class optional_idx {
public:
	constexpr optional_idx() {
	}
	// NOLINTNEXTLINE: allow implicit conversion from idx_t
	constexpr optional_idx(idx_t index_p) : index(index_p) {
	}

	static optional_idx Invalid() {
		return optional_idx();
	}

	bool IsValid() const {
		return index.has_value();
	}

	void SetInvalid() {
		index.reset();
	}

	idx_t GetIndex() const {
		if (!index.has_value()) {
			ThrowNotSet();
		}
		return *index;
	}

	inline bool operator==(const optional_idx &rhs) const {
		return index == rhs.index;
	}

	inline bool operator!=(const optional_idx &rhs) const {
		return index != rhs.index;
	}

private:
	[[noreturn]] static void ThrowNotSet() {
		throw 0;
	}

private:
	optional<idx_t> index;
};
} // namespace upstream

using patched_t = duckdb::optional_idx;
using upstream_t = upstream::optional_idx;

static_assert(sizeof(duckdb::idx_t) == 8, "idx_t is 8 bytes");
static_assert(sizeof(patched_t) == 16, "patched sizeof");
static_assert(sizeof(upstream_t) == 16, "upstream sizeof");
static_assert(sizeof(patched_t) == sizeof(upstream_t), "sizeof equal");
static_assert(alignof(patched_t) == alignof(upstream_t), "alignof equal");
static_assert(std::is_trivially_copyable<patched_t>::value, "patched trivially copyable");
static_assert(std::is_trivially_copyable<upstream_t>::value, "upstream trivially copyable");
static_assert(std::is_trivially_copyable<std::optional<duckdb::idx_t>>::value, "std::optional<idx_t> trivially copyable");
static_assert(std::is_trivially_destructible<patched_t>::value, "patched trivially destructible");
static_assert(std::is_trivially_destructible<upstream_t>::value, "upstream trivially destructible");
static_assert(std::is_standard_layout<patched_t>::value == std::is_standard_layout<upstream_t>::value,
              "standard layout equal");
static_assert(!std::is_polymorphic<patched_t>::value, "patched not polymorphic");

static int failures = 0;
#define CHECK(cond)                                                                                                    \
	do {                                                                                                               \
		bool ok_ = (cond);                                                                                             \
		std::printf("%s  %s\n", ok_ ? "PASS" : "FAIL", #cond);                                                         \
		if (!ok_)                                                                                                      \
			failures++;                                                                                                \
	} while (0)

template <class T>
static void Bytes(const char *label, const T &x) {
	unsigned char b[sizeof(T)];
	std::memcpy(b, &x, sizeof(T));
	std::printf("  %-28s", label);
	for (size_t i = 0; i < sizeof(T); i++) {
		std::printf("%02x%s", b[i], i == 7 ? " | " : " ");
	}
	std::printf("\n");
}

template <class To, class From>
static To Pun(const From &from) {
	static_assert(sizeof(To) == sizeof(From), "size");
	alignas(To) unsigned char buf[sizeof(To)];
	std::memcpy(buf, &from, sizeof(From));
	To to;
	std::memcpy(static_cast<void *>(&to), buf, sizeof(To));
	return to;
}

template <class T>
static uint64_t Word0(const T &x) {
	uint64_t w;
	std::memcpy(&w, &x, 8);
	return w;
}

template <class T>
static unsigned char Byte8(const T &x) {
	unsigned char b[sizeof(T)];
	std::memcpy(b, &x, sizeof(T));
	return b[8];
}

int main() {
#if defined(_MSC_VER) && !defined(__clang__)
	std::printf("compiler: MSVC %d (_MSC_FULL_VER %d)\n", _MSC_VER, _MSC_FULL_VER);
#elif defined(__clang__)
	std::printf("compiler: clang %s\n", __clang_version__);
#elif defined(__GNUC__)
	std::printf("compiler: GCC %s\n", __VERSION__);
#endif
#if defined(_LIBCPP_VERSION)
	std::printf("stdlib: libc++ %d\n", (int)_LIBCPP_VERSION);
#elif defined(__GLIBCXX__)
	std::printf("stdlib: libstdc++ %d\n", (int)__GLIBCXX__);
#elif defined(_MSVC_STL_VERSION)
	std::printf("stdlib: MSVC STL %d\n", (int)_MSVC_STL_VERSION);
#endif
#if defined(__MINGW32__)
	std::printf("target: MinGW\n");
#endif
	std::printf("sizeof: patched=%zu upstream=%zu std::optional<idx_t>=%zu\n", sizeof(patched_t), sizeof(upstream_t),
	            sizeof(std::optional<duckdb::idx_t>));
	std::printf("alignof: patched=%zu upstream=%zu std::optional<idx_t>=%zu\n", alignof(patched_t),
	            alignof(upstream_t), alignof(std::optional<duckdb::idx_t>));

	// Offsets of std::optional<idx_t> (upstream's only member): value word, engaged flag.
	{
		std::optional<duckdb::idx_t> o(0x0102030405060708ULL);
		const unsigned char *base = reinterpret_cast<const unsigned char *>(&o);
		size_t value_off = static_cast<size_t>(reinterpret_cast<const unsigned char *>(&*o) - base);
		std::printf("std::optional<idx_t>: value offset=%zu\n", value_off);
		CHECK(value_off == 0);
		std::optional<duckdb::idx_t> e;
		std::memset(static_cast<void *>(&e), 0xAB, sizeof(e));
		new (&e) std::optional<duckdb::idx_t>();
		std::printf("std::optional<idx_t>: flag byte 8 empty=%u engaged=%u\n", Byte8(e), Byte8(o));
		CHECK(Byte8(o) == 1);
		CHECK(Byte8(e) == 0);
	}

	std::printf("bytes (0-7 value | 8-15 flag + padding):\n");
	patched_t p42(42), pinv;
	upstream_t u42(42), uinv;
	Bytes("patched(42)", p42);
	Bytes("patched()", pinv);
	Bytes("upstream(42)", u42);
	Bytes("upstream()", uinv);

	// Byte-level placement for both types.
	CHECK(Word0(p42) == 42);
	CHECK(Byte8(p42) == 1);
	CHECK(Byte8(pinv) == 0);
	CHECK(Word0(u42) == 42);
	CHECK(Byte8(u42) == 1);
	CHECK(Byte8(uinv) == 0);

	// patched -> upstream
	{
		upstream_t a = Pun<upstream_t>(p42);
		CHECK(a.IsValid() && a.GetIndex() == 42);
		upstream_t b = Pun<upstream_t>(pinv);
		CHECK(!b.IsValid());
		patched_t ps(9);
		ps.SetInvalid();
		CHECK(!Pun<upstream_t>(ps).IsValid());
		CHECK(Pun<upstream_t>(p42) == upstream_t(42));
	}
	// upstream -> patched
	{
		patched_t a = Pun<patched_t>(upstream_t(7));
		CHECK(a.IsValid() && a.GetIndex() == 7);
		CHECK(a == patched_t(7));
		patched_t b = Pun<patched_t>(uinv);
		CHECK(!b.IsValid());
		CHECK(b == patched_t());
		// upstream invalid with garbage payload bytes
		alignas(upstream_t) unsigned char raw[sizeof(upstream_t)];
		std::memset(raw, 0xAB, sizeof(raw));
		upstream_t *g = new (raw) upstream_t();
		Bytes("upstream() over 0xAB", *g);
		CHECK(!g->IsValid());
		patched_t c = Pun<patched_t>(*g);
		CHECK(!c.IsValid());
		CHECK(c == patched_t());
		// upstream valid then SetInvalid: payload stays 5
		upstream_t u5(5);
		u5.SetInvalid();
		Bytes("upstream(5).SetInvalid()", u5);
		patched_t d = Pun<patched_t>(u5);
		CHECK(!d.IsValid());
		CHECK(d == patched_t());
	}

	// GetIndexOr(): unset -> fallback, set -> value, also on objects punned from upstream's class.
	{
		CHECK(patched_t().GetIndexOr(99) == 99);
		CHECK(pinv.GetIndexOr(99) == 99);
		CHECK(patched_t::Invalid().GetIndexOr(7) == 7);
		CHECK(p42.GetIndexOr(99) == 42);
		CHECK(patched_t(0).GetIndexOr(99) == 0);
		patched_t ps(3);
		ps.SetInvalid();
		CHECK(ps.GetIndexOr(99) == 99);
		CHECK(Pun<patched_t>(u42).GetIndexOr(99) == 42);
		CHECK(Pun<patched_t>(uinv).GetIndexOr(99) == 99);
		upstream_t u5(5);
		u5.SetInvalid();
		CHECK(Pun<patched_t>(u5).GetIndexOr(99) == 99);
		alignas(upstream_t) unsigned char raw[sizeof(upstream_t)];
		std::memset(raw, 0xAB, sizeof(raw));
		upstream_t *g = new (raw) upstream_t();
		CHECK(Pun<patched_t>(*g).GetIndexOr(99) == 99);
	}

	std::printf("%s (%d failure(s))\n", failures ? "ABI CHECK FAILED" : "ABI CHECK PASSED", failures);
	return failures ? 1 : 0;
}
