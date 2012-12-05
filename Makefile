SWFV = 11

FILES = $(shell find cx-src -type f -name "*.cx" -print)

local: $(FILES)
	rm -rf src
	mkdir src
	caxe -o src cx-src -tc 2 --times \
		-x DummyCppMain.cx -x DummyJSMain # cpp only
	haxe -cp src -main DummyNapeMain -swf bin/nape.swf -swf-version $(SWFV) --times \
		-swf-header 600:600:60:333333 -D haxe3 \
		-D NAPE_DEBUG --no-inline -debug -D NAPE_LOG
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
#		-D NAPE_DEBUG --no-inline -debug
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

externs: debugs
	rm -rf externs
	flib --externs bin/release/haxe_debug_nape.swf --include nape --include zpp_nape
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

DEBUG_FLAGS = $(SWC_FLAGS) -D NAPE_NO_INLINE -D NAPE_DEBUG
DEV_FLAGS  = $(SWC_FLAGS)
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

developments: pre_compile
	mkdir -p bin/release
	haxe -swf bin/release/development_nape.swc $(DEV_FLAGS) -swf-version $(SWFV)
	flib bin/release/development_nape.swc
	unzip bin/release/development_nape.swc -x catalog.xml
	mv library.swf bin/release/haxe_development_nape.swf
	du -h bin/release/development_nape.swc

debugs: pre_compile
	mkdir -p bin/release
	haxe -swf bin/release/debug_nape.swc $(DEBUG_FLAGS) -swf-version $(SWFV)
	flib bin/release/debug_nape.swc
	unzip bin/release/debug_nape.swc -x catalog.xml
	mv library.swf bin/release/haxe_debug_nape.swf
	du -h bin/release/debug_nape.swc
