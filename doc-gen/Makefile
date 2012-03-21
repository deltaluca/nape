def:
	@echo "--------------------"
	@echo ">> To compile doc. generator use 'build' target"
	@echo ">> To run generator for all xml files in xml/ folder use 'run' target"
	@echo ">> To run generator for specific files, use 'run' target with FILES=file1,file2...filen"
	@echo ">> To clean generated docs, use 'clean_run' target"
	@echo ">> To clean everywthing, use 'clean' target"

run:
	./bin/docs $(FILES)
	mv doc/index.html doc/index.php

clean: clean_run
	rm -rf bin
	rm -rf src
	rm -rf cpp

.PHONY: clean_run

clean_run:
	find doc -type f -name "*.html" -print0 | xargs -0 rm -rf
	find doc -depth -type d -empty -exec rmdir {} \;

.PHONY: build
build:
	caxe -o src cx-src -tc 2 --times
	mkdir -p bin
#	haxe -cp src -neko bin/Main.n -main Main -debug --remap cpp:neko 
#	nekotools boot bin/Main.n
#	cp bin/Main bin/docs
	haxe -cp src -cpp cpp -main Main --remap neko:cpp -D HXCPP_M64 -D HXFCGI -D no_traces
	mkdir -p bin
	cp cpp/Main bin/docs
