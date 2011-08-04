SWFV = 10.3

local: pre_compile
	mkdir -p bin
	haxe -cp src -main DummyNapeMain -swf bin/nape.swf -swf-version $(SWFV) --times \
	     -swf-header 600:600:60:333333 \
	     -D NAPE_TIMES
#	     -D NAPE_ASSERT --no-inline -debug \
#	     -D NAPE_RELEASE_BUILD
#	firefox bin/index.html
	flashplayerdebugger bin/nape.swf

pre_compile:
	rm -rf src
	mkdir src
	caxe -o src cx-src -tc 2 --times

SWC_FLAGS = -cp src --dead-code-elimination --macro "include('nape')" --macro "include('zpp_nape')" -D flib -D swc

ASSERT_FLAGS  = $(SWC_FLAGS) -D NAPE_NO_INLINE -D NAPE_ASSERT
DEBUG_FLAGS   = $(SWC_FLAGS)
RELEASE_FLAGS = $(SWC_FLAGS) -D NAPE_RELEASE_BUILD

release: pre_compile
	mkdir -p bin/release
#	cpp
	haxe -cp src -main DummyNapeMain -cpp cpp --no-inline
#	assert
	haxe -swf bin/release/assert_nape.swc -swf-version $(SWFV) $(ASSERT_FLAGS)
	flib bin/release/assert_nape.swc
	haxe -swf bin/release/assert_nape9.swc -swf-version 9 $(ASSERT_FLAGS)
	flib bin/release/assert_nape9.swc
#	debug
	haxe -swf bin/release/debug_nape.swc -swf-version $(SWFV) $(DEBUG_FLAGS)
	flib bin/release/debug_nape.swc
	haxe -swf bin/release/debug_nape9.swc -swf-version 9 $(DEBUG_FLAGS)
	flib bin/release/debug_nape9.swc
#	release
	haxe -swf bin/release/release_nape.swc -swf-version $(SWFV) $(RELEASE_FLAGS)
	flib bin/release/release_nape.swc
	haxe -swf bin/release/release_nape9.swc -swf-version 9 $(RELEASE_FLAGS)
	flib bin/release/release_nape9.swc
#	tar
	find src -name "*.hx" -type f | xargs tar cvfz bin/release/hx-src.tar.gz

clean:
	rm -rvf bin/release/
	mkdir bin/release
	rm -rvf cpp
	rm -rvf src
	rm bin/nape.swf

tar:
	find cx-src -name "*.cx" -type f | xargs tar cvfz nape.tar.gz Makefile
