run: build
	neko bin/unit.n

build:
	$(MAKE) --directory=../ pre_compile
	mkdir -p bin
#	haxe -cp . -cp ../src -main Unit -cpp bin -debug -D IGNORE_DUMMY
	haxe -cp . -cp ../src -main Unit -neko bin/unit.n -debug -D IGNORE_DUMMY --no-inline
#	haxe -cp . -cp ../src -main Unit -swf bin/unit.swf -swf-version 11 -swf-header 600:600:60:ffffff -debug
