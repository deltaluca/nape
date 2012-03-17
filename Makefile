SWFV = 11

FILES = $(shell find cx-src -type f -name "*.cx" -print)

local: $(FILES)
	rm -rf src
	mkdir src
	caxe -o src cx-src -tc 2 --times \
		-x DummyCppMain.cx # cpp only
	haxe -cp src -main DummyNapeMain -swf bin/nape.swf -swf-version $(SWFV) --times \
		-swf-header 800:600:60:333333 \
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
	tar cvfz nape.tar.gz cx-src Makefile version
	scp nape.tar.gz deltaluca.me.uk:nape.tar.gz
	echo "ssh deltaluca.me.uk << EOT" > .nape-release
	echo "./nape-release" >> .nape-release
	echo "EOT" >> .nape-release
	sh .nape-release
	rm .nape-release

## --------------------------------------------
## build targets

server-targets:
	cat > .targets <<EOT
	cx-src     :: nape.tar.gz            :: Caxe source (.tar.gz)
	hx-src     :: hx-src.tar.gz          :: Haxe source (.tar.gz)
	
	assert     :: assert_nape.swc        :: AS3 assert build (.swc)
	debug      :: debug_nape.swc         :: AS3 debug build (.swc)
	release    :: release_nape.swc       :: AS3 release build (.swc)
	
	assert9    :: assert_nape9.swc       :: AS3 assert build (.swc) for fp9
	debug9     :: debug_nape9.swc        :: AS3 debug build (.swc) for fp9
	release9   :: release_nape9.swc      :: AS3 release build (.swc) for fp9
	
	hx-assert  :: haxe_assert_nape.swf   :: Haxe assert build (.swc)
	hx-debug   :: haxe_debug_nape.swf    :: Haxe debug build (.swc)
	hx-release :: haxe_release_nape.swf  :: Haxe release build (.swc)
	
	hx-assert9 :: haxe_assert_nape9.swf  :: Haxe assert build (.swc) for fp9
	hx-debug9  :: haxe_debug_nape9.swf   :: Haxe debug build (.swc) for fp9
	hx-release9:: haxe_release_nape9.swf :: Haxe release build (.swc) for fp9
	EOT

.PHONY: server-build-cx-src
server-build-cx-src:

server-build-hx-src: pre_compile
	find src -name "*.hx" -type f | xargs tar cvfz hx-src.tar.gz

server-build-assert:
	haxe -swf assert_nape.swc -swf-version $(SWFV) $(ASSERT_FLAGS)
	flib assert_nape.swc
server-build-debug:
	haxe -swf debug_nape.swc -swf-version $(SWFV) $(DEBUG_FLAGS)
	flib debug_nape.swc
server-build-release:
	haxe -swf release_nape.swc -swf-version $(SWFV) $(RELEASE_FLAGS)
	flib release_nape.swc

server-build-assert9:
	haxe -swf assert_nape9.swc -swf-version 9 $(ASSERT_FLAGS)
	flib assert_nape9.swc
server-build-debug9:
	haxe -swf debug_nape9.swc -swf-version 9 $(DEBUG_FLAGS)
	flib debug_nape9.swc
server-build-release9:
	haxe -swf release_nape9.swc -swf-version 9 $(RELEASE_FLAGS)
	flib release_nape9.swc

server-build-hx-assert:
	unzip assert_nape.swc -x catalog.xml
	mv library.swf haxe_assert_nape.swf
server-build-hx-debug:
	unzip debug_nape.swc -x catalog.xml
	mv library.swf haxe_debug_nape.swf
server-build-hx-release:
	unzip release_nape.swc -x catalog.xml
	mv library.swf haxe_release_nape.swf

server-build-hx-assert9:
	unzip assert_nape9.swc -x catalog.xml
	mv library.swf haxe_assert_nape9.swf
server-build-hx-debug9:
	unzip debug_nape.swc -x catalog.xml
	mv library.swf haxe_debug_nape9.swf
server-build-hx-release9:
	unzip release_nape9.swc -x catalog.xml
	mv library.swf haxe_release_nape9.swf
