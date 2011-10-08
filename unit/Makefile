def:
	$(MAKE) --directory=../ pre_compile
	mkdir -p bin
#	haxe -cp . -cp ../src -main Unit -cpp bin -debug -D IGNORE_DUMMY
#	bin/Unit
	haxe -cp . -cp ../src -main Unit -neko bin/unit.n -debug -D IGNORE_DUMMY
	neko bin/unit.n
#	haxe -cp . -cp ../src -main Unit -swf bin/unit.swf -swf-version 11 -swf-header 600:600:60:ffffff -debug
#	fp bin/unit.swf
