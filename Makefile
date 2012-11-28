SWFV = 11

FILES = $(shell find cx-src -type f -name "*.cx" -print)

local: $(FILES)
	rm -rf src
	mkdir src
	caxe -o src cx-src -tc 2 --times \
		-x DummyCppMain.cx -x DummyJSMain # cpp only
	haxe -cp src -main DummyNapeMain -swf bin/nape.swf -swf-version $(SWFV) --times \
		-swf-header 600:600:60:333333 -D haxe3 \
		-D NAPE_ASSERT --no-inline -debug -D NAPE_LOG
#		-D NAPE_RELEASE_BUILD
	debugfp bin/nape.swf

js: $(FILES)
	rm -rf src
	mkdir src
	caxe -o src cx-src -tc 2 --times \
		-x DummyMemory.cx -x DummyNapeMain.cx -x DummyCppMain.cx
	haxe -cp src -main DummyJSMain -js bin/nape.js --times \
        -D haxe3 --js-modern --dce full


cpp: $(FILES)
	rm -rf src
	mkdir src
	caxe -o src cx-src -tc 2 --times \
		-x DummyMemory.cx -x DummyNapeMain.cx -x DummyJSMain # flash only
	haxe -cp src -main DummyCppMain -cpp cpp --times \
		--remap flash:nme -lib nme \
		-D NAPE_RELEASE_BUILD
#		-D NAPE_ASSERT --no-inline -debug
	./cpp/DummyCppMain

#------------------------------------------------------------------------------------

docs: pre_compile
	haxe -cp src -xml nape.xml --macro "include('nape')" -D NAPE_RELEASE_BUILD -swf nape.xml.swf -swf-version 10.1 \
         -cp ../nape-hacks/src --macro "include('nape.hacks')" \
         -cp ../nape-symbolic/src --macro "include('nape.symbolic')" -lib Parsex -D haxe3
	./chxdoc/chxdoc -o ../www.napephys.com/docs --templateDir=chxdoc/src/templates/default \
		-f zpp_nape -f haxe -f flash --ignoreRoot=true -f com \
		--title="Nape Physics Library" nape.xml

#------------------------------------------------------------------------------------

externs: asserts
	rm -rf externs
	flib --externs bin/release/haxe_assert_nape.swf --include nape --include zpp_nape
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

SWC_FLAGS = -cp src --dce full --macro "include('nape')" --macro "include('zpp_nape')" -D flib -D nape_swc

ASSERT_FLAGS = $(SWC_FLAGS) -D NAPE_NO_INLINE -D NAPE_ASSERT
DEBUG_FLAGS  = $(SWC_FLAGS)
RELEASE_FLAGS= $(SWC_FLAGS) -D NAPE_RELEASE_BUILD

#------------------------------------------------------------------------------------

.PHONY: demos
demos:
	./buildlib
	$(MAKE) releases
	cp bin/release/release_nape.swc ../www.napephys.com/nape-release.swc
	$(MAKE) docs

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
	./server-release

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

