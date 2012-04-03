SWFV = 11

FILES = $(shell find cx-src -type f -name "*.cx" -print)

local: $(FILES)
	rm -rf src
	mkdir src
	caxe -o src cx-src -tc 2 --times \
		-x DummyCppMain.cx # cpp only
	haxe -cp src -main DummyNapeMain -swf bin/nape.swf -swf-version $(SWFV) --times \
		-swf-header 800:600:60:333333 \
		-lib hscript \
		-D NAPE_ASSERT --no-inline -debug
#		-D NAPE_RELEASE_BUILD
	debugfp bin/nape.swf

cpp: $(FILES)
	rm -rf src
	mkdir src
	caxe -o src cx-src -tc 2 --times \
		-x DummyMemory.cx -x DummyNapeMain.cx # flash only
	haxe -cp src -main DummyCppMain -cpp cpp --times \
		--remap flash:nme -lib nme \
		-D NAPE_RELEASE_BUILD
#		-D NAPE_ASSERT --no-inline -debug
	./cpp/DummyCppMain

#------------------------------------------------------------------------------------

externs: releases
	rm -rf externs
	flib --externs bin/release/haxe_release_nape.swf --include nape --include zpp_nape
#   fix-externs doesn't actually work... hah
#   problem in that it doesn't have fully specified types, Constraint instead of nape.constraint.Constraint for instance
#   cba to fix it now.
#	./fix-externs

#------------------------------------------------------------------------------------

DUMMYS = $(shell find cx-src -type f -name "Dummy*" -print | sed 's/^/-x /')
pre_compile:
	rm -rf src
	mkdir src
	caxe -o src cx-src -tc 2 --times $(DUMMYS)

SWC_FLAGS = -cp src --dead-code-elimination --macro "include('nape')" --macro "include('zpp_nape')" -D flib -D swc

ASSERT_FLAGS = $(SWC_FLAGS) -D NAPE_NO_INLINE -D NAPE_ASSERT
DEBUG_FLAGS  = $(SWC_FLAGS)
RELEASE_FLAGS= $(SWC_FLAGS) -D NAPE_RELEASE_BUILD

#------------------------------------------------------------------------------------

.PHONY: demos
demos:
	./buildlib

releases: pre_compile
	mkdir -p bin/release
	haxe -swf bin/release/release_nape.swc $(RELEASE_FLAGS) -swf-version $(SWFV)
	flib bin/release/release_nape.swc
	unzip bin/release/release_nape.swc -x catalog.xml
	mv library.swf bin/release/haxe_release_nape.swf
	du -h bin/release/release_nape.swc

debugs: pre_compile
	mkdir -p bin/release
	haxe -swf bin/release/debug_nape.swc $(DEBUG_FLAGS) -swf-version $(SWFV)
	flib bin/release/debug_nape.swc
	unzip bin/release/debug_nape.swc -x catalog.xml
	mv library.swf bin/release/haxe_debug_nape.swf
	du -h bin/release/debug_nape.swc

asserts: pre_compile
	mkdir -p bin/release
	haxe -swf bin/release/assert_nape.swc $(ASSERT_FLAGS) -swf-version $(SWFV)
	flib bin/release/assert_nape.swc
	unzip bin/release/assert_nape.swc -x catalog.xml
	mv library.swf bin/release/haxe_assert_nape.swf
	du -h bin/release/assert_nape.swc

#------------------------------------------------------------------------------------

release: pre_compile
	mkdir -p bin/release
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

# ----------------------------------------------------------------------------------
# remotes

server-release:
	rm -rf nape.tar.gz
	tar cvfz nape.tar.gz cx-src Makefile version server-remotes fix-externs
	scp nape.tar.gz deltaluca.me.uk:nape.tar.gz
	echo "ssh deltaluca.me.uk << EOT" > .nape-release
	echo "./nape-release" >> .nape-release
	echo "EOT" >> .nape-release
	sh .nape-release
	rm .nape-release

## --------------------------------------------

server-build-cx-src:

server-build-hx-src: pre_compile
	find src -name "*.hx" -type f | xargs tar cvfz hx-src.tar.gz

server-build-assert:
	tar -xf hx-src.tar.gz
	haxe -swf assert_nape.swc -swf-version $(SWFV) $(ASSERT_FLAGS)
	flib assert_nape.swc
	rm -rf src
server-build-debug:
	tar -xf hx-src.tar.gz
	haxe -swf debug_nape.swc -swf-version $(SWFV) $(DEBUG_FLAGS)
	flib debug_nape.swc
	rm -rf src
server-build-release:
	tar -xf hx-src.tar.gz
	haxe -swf release_nape.swc -swf-version $(SWFV) $(RELEASE_FLAGS)
	flib release_nape.swc
	rm -rf src

server-build-assert9:
	tar -xf hx-src.tar.gz
	haxe -swf assert_nape9.swc -swf-version 9 $(ASSERT_FLAGS)
	flib assert_nape9.swc
	rm -rf src
server-build-debug9:
	tar -xf hx-src.tar.gz
	haxe -swf debug_nape9.swc -swf-version 9 $(DEBUG_FLAGS)
	flib debug_nape9.swc
	rm -rf src
server-build-release9:
	tar -xf hx-src.tar.gz
	haxe -swf release_nape9.swc -swf-version 9 $(RELEASE_FLAGS)
	flib release_nape9.swc
	rm -rf src

server-build-externs:
	tar -xf hx-src.tar.gz
	unzip release_nape.swc -x catalog.xml
	
	flib --externs library.swf --include nape --include zpp_nape
#	./fix-externs # doesn't work at present! oops
	tar cvfz externs.tar.gz externs
	rm -rf externs
	rm -rf src
	rm library.swf
	
