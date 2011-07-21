SWFV = 10.3

local: pre_compile
	haxe -cp src -main DummyNapeMain -swf bin/nape.swf -swf-version $(SWFV) \
	     -swf-header 600:600:60:333333 \
	     -D NAPE_ASSERT --no-inline -debug \
	     -D NAPE_TIMES
#	     -D NAPE_RELEASE_BUILD
#	firefox bin/index.html
	flashplayerdebugger bin/nape.swf

pre_compile:
	rm -rf src
	mkdir src
	caxe -o src cx-src -tc 2 --times

release: pre_compile
#	cpp
	haxe -cp src -main DummyNapeMain -cpp cpp --no-inline
#	assert
	haxe -cp src -main DummyNapeMain -swf bin/release/assert_nape.swc \
	     -swf-version $(SWFV) -D swc -D flib -D NAPE_NO_INLINE -D NAPE_ASSERT
	flib bin/release/assert_nape.swc
	haxe -cp src -main DummyNapeMain -swf bin/release/assert_nape9.swc \
	     -swf-version 9 -D swc -D flib -D NAPE_NO_INLINE -D NAPE_ASSERT
	flib bin/release/assert_nape9.swc
#	debug
	haxe -cp src -main DummyNapeMain -swf bin/release/debug_nape.swc \
	     -swf-version $(SWFV) -D swc -D flib --dead-code-elimination
	flib bin/release/debug_nape.swc
	haxe -cp src -main DummyNapeMain -swf bin/release/debug_nape9.swc \
	     -swf-version 9 -D swc -D flib --dead-code-elimination
	flib bin/release/debug_nape9.swc
#	release
	haxe -cp src -main DummyNapeMain -swf bin/release/release_nape.swc \
	     -swf-version $(SWFV) -D swc -D flib --dead-code-elimination \
	     -D NAPE_RELEASE_BUILD
	flib bin/release/release_nape.swc
	haxe -cp src -main DummyNapeMain -swf bin/release/release_nape9.swc \
	     -swf-version $(SWFV) -D swc -D flib --dead-code-elimination \
	     -D NAPE_RELEASE_BUILD
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
