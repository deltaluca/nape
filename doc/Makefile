def:
	@echo "Please specify run, or build"
	@echo "For run, optional FILES=file_list can be given for pick-and-choose generation"

run:
	./bin/docs $(FILES)

build:
	caxe -o src cx-src -tc 2 --times
#	haxe -cp src -neko bin/Main.n -main Main -debug --remap cpp:neko 
#	nekotools boot bin/Main.n
#	cp bin/Main bin/docs
	haxe -cp src -cpp cpp -main Main --remap neko:cpp -D HXCPP_M64 -D HXFCGI -D no_traces
	mkdir -p bin
	cp cpp/Main bin/docs
