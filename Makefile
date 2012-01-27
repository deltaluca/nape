SWFV = 11

local: pre_compile
	mkdir -p bin
	haxe -cp src -main DummyNapeMain -swf bin/nape.swf -swf-version $(SWFV) --times \
	     -swf-header 800:600:60:888888 \
		-D NAPE_ASSERT --no-inline -debug 
#	     -D NAPE_POOL_STATS \
# 			--dead-code-elimination \
#	     -D NAPE_RELEASE_BUILD
#	firefox bin/index.html
	debugfp bin/nape.swf

profile: pre_compile
	mkdir -p bin
	haxe -cp src -main DummyNapeMain -swf bin/nape.swf -swf-version $(SWFV) --times \
		-swf-header 800:600:60:333333 \
#		-D NAPE_RELEASE_BUILD
#		-D NAPE_ASSERT --no-inline -debug 
#	     -D NAPE_POOL_STATS
	proffp bin/nape.swf

cpp: pre_compile
	haxe -cp src -lib nme --remap flash:nme -main DummyNapeMain -cpp cpp -D NAPE_RELEASE_BUILD
	./cpp/DummyNapeMain

pre_compile:
	rm -rf src
	mkdir src
	caxe -o src cx-src -tc 2 --times

SWC_FLAGS = -cp src --dead-code-elimination --macro "include('nape')" --macro "include('zpp_nape')" -D flib -D swc

ASSERT_FLAGS  = $(SWC_FLAGS) -D NAPE_NO_INLINE -D NAPE_ASSERT
DEBUG_FLAGS   = $(SWC_FLAGS)
RELEASE_FLAGS = $(SWC_FLAGS) -D NAPE_RELEASE_BUILD

unit_swf: pre_compile
	mkdir -p bin/release
	haxe -swf bin/release/assert_nape.swc -swf-version $(SWFV) $(ASSERT_FLAGS)
	flib bin/release/assert_nape.swc
	unzip bin/release/assert_nape.swc -x catalog.xml
	mv library.swf bin/release/haxe_assert_nape.swf

demos: pre_compile
	mkdir -p bin/release
	haxe -swf bin/release/release_nape.swc -swf-version $(SWFV) $(RELEASE_FLAGS)
	flib bin/release/release_nape.swc
	unzip bin/release/release_nape.swc -x catalog.xml
	mv library.swf bin/release/haxe_release_nape.swf	

asserts: pre_compile
	haxe -swf bin/release/assert_nape.swc -swf-version $(SWFV) $(ASSERT_FLAGS)
	flib bin/release/assert_nape.swc

release: pre_compile
	mkdir -p bin/release
#	cpp
#	haxe -cp src -main DummyNapeMain -cpp cpp --no-inline -D HXCPP_M64 -D HXFCGI -D no_traces
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
	rm -f bin/release/hx-src.zip
	find src -name "*.hx" -type f | xargs zip bin/release/hx-src
#   haxe 'swcs'
	unzip bin/release/assert_nape.swc -x catalog.xml
	mv library.swf bin/release/haxe_assert_nape.swf
	unzip bin/release/assert_nape9.swc -x catalog.xml
	mv library.swf bin/release/haxe_assert_nape9.swf
	unzip bin/release/debug_nape.swc -x catalog.xml
	mv library.swf bin/release/haxe_debug_nape.swf
	unzip bin/release/debug_nape9.swc -x catalog.xml
	mv library.swf bin/release/haxe_debug_nape9.swf
	unzip bin/release/release_nape.swc -x catalog.xml
	mv library.swf bin/release/haxe_release_nape.swf
	unzip bin/release/release_nape9.swc -x catalog.xml
	mv library.swf bin/release/haxe_release_nape9.swf


clean:
	rm -rvf bin/release/
	mkdir bin/release
	rm -rvf cpp
	rm -rvf src
	rm -f bin/nape.swf

tar:
	find cx-src -name "*.cx" -type f | xargs tar cvfz nape.tar.gz Makefile
	rm -f nape.zip
	find cx-src -name "*.cx" -type f | xargs zip nape Makefile

size_report: pre_compile
	haxe -swf bin/inlined_nape.swc -swf-version $(SWFV) $(RELEASE_FLAGS)
	flib bin/inlined_nape.swc
	du -h bin/inlined_nape.swc > bin/inlined.dat
	flib --report bin/inlined_nape.swc >> bin/inlined.dat
	
	haxe -swf bin/noninlined_nape.swc -swf-version $(SWFV) $(RELEASE_FLAGS) -D NAPE_NO_INLINE
	flib bin/noninlined_nape.swc
	du -h bin/noninlined_nape.swc > bin/noninlined.dat
	flib --report bin/noninlined_nape.swc >> bin/noninlined.dat
