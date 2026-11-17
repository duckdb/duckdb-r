# Compiles the vendored engine of a duckdb-r checkout into a shared library,
# with the flags the package's generated src/Makevars passes it.
# Usage: make -f engine.mk SRC=<checkout>/src OUT=<dir> -j4
include $(SRC)/include/sources.mk
FLAGS := $(shell sed -n 's/^PKG_CPPFLAGS = //p' $(SRC)/Makevars | sed 's/-DDUCKDB_RSTRTMGR=[^ ]*/-DDUCKDB_RSTRTMGR=0/')
OBJS := $(addprefix $(OUT)/obj/,$(SOURCES))
CXX := ccache g++
CXXFLAGS := -std=c++17 -O1 -fPIC -w -DNDEBUG
$(OUT)/libduckdb.so: $(OBJS)
	$(CXX) -shared -o $@ $^ -lpthread -ldl
$(OUT)/obj/%.o: $(SRC)/%.cpp
	@mkdir -p $(dir $@)
	@cd $(SRC) && $(CXX) $(CXXFLAGS) $(FLAGS) -c $*.cpp -o $@
$(OUT)/obj/%.o: $(SRC)/%.cc
	@mkdir -p $(dir $@)
	@cd $(SRC) && $(CXX) $(CXXFLAGS) $(FLAGS) -c $*.cc -o $@
