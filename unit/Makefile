def:
	$(MAKE) --directory=../ unit_swf
	mkdir -p bin
	haxe -cp . -swf-lib ../bin/release/haxe_assert_nape.swf -main Unit -swf bin/unit.swf -swf-version 11 -swf-header 600:600:60:ffffff -debug
	debugfp bin/unit.swf

build:
	$(MAKE) --directory=../ pre_compile
	mkdir -p bin
	haxe -cp . -cp ../src -main Unit -cpp bin -debug -D IGNORE_DUMMY
