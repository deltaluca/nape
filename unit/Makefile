def:
	$(MAKE) --directory=../ unit_lib
	mkdir -p bin
	haxe -swf-lib ../bin/release/haxe_assert_nape.swf -cp . -main Unit -swf bin/unit.swf -swf-version 11 -swf-header 600:600:60:ffffff -debug
	debugfp bin/unit.swf
