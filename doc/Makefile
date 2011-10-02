def:
	@echo "Please specify run, or build"

run:
	./bin/docs

build:
	caxe -o src cx-src -tc 2 --times
#	haxe -cp src -neko bin/main.n -main Main --remap cpp:neko
#	nekotools boot bin/main.n
	haxe -cp src -cpp cpp -main Main --remap neko:cpp -D HXCPP_M64 -D HXFCGI -D no_traces
	mkdir -p bin
	cp cpp/Main bin/docs
