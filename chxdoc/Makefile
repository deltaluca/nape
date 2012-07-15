CHX_FILES=../../ext2/chx/Serializer.hx \
			../../ext2/chx/Unserializer.hx \
			../../ext2/chx/Log.hx

all: dependencies chxdoc

chxdoc: dummy
	haxe build.hxml

tests: test-developer test-user

test-developer: chxdoc
	cd test && haxe chx.hxml
	cd test && ../chxdoc -v -f flash.utils -f js.Boot -o doc_developer --footerText="This is the <a href=\"http://www.haxe.org\" target=\"new\">footer link to haxe.org</a>" --tmpDir=__chxdoctmp --templateDir=../src/templates/default --installTemplate=true --developer=true flash9.xml,flash9,flash neko.xml,neko js.xml,js
	cd test && $(RM) *.swf *.n *.js
	cd test && $(RM) -R __chxdoctmp

test-user: chxdoc
	cd test && haxe chx.hxml
	cd test && ../chxdoc -o doc_user --template=../src/templates/default --developer=false flash9.xml,flash,flash9 neko.xml,neko js.xml,js
	cd test && $(RM) *.swf *.n *.js
	cd test && $(RM) -R __chxdoctmp

test-web: chxdoc
	cd test && haxe chx.hxml
	cd test && ../chxdoc -o doc_web --template=../src/templates/default --developer=false flash9.xml,flash,flash9 neko.xml,neko js.xml,js --writeWebConfig
	cd test && $(RM) *.swf *.n *.js
	cd test && $(RM) -R __chxdoctmp

clean:
	cd test && $(RM) -R doc_developer
	cd test && $(RM) -R doc_user
	cd test && $(RM) -f *.swf *.n *.js *.xml
	rm -f make_release
	rm -Rf chxdoc_release
	rm -f chxdoc.n
	rm -f chxtemploc.n
	rm -rf __chxdoctmp

haxelib:
	rm -f chxdoc.zip
	rm -rf haxelib_release
	mkdir haxelib_release
	cd src/Tools && haxe build.hxml
	cp -r src haxelib_release/
	cd haxelib_release/src && find . -name "*~" -exec rm {} \;
	cd haxelib_release/src && zip -r ../chxdoc *
	cd haxelib_release && haxelib test chxdoc.zip
	haxelib run chxdoc compile

windows: dependencies dummy
	wine haxe build.hxml

linux: dependencies dummy
	haxe build.hxml

release: dependencies make_release
	@if [ "${VER}" = "" ]; then echo "Set the VER var"; exit 1; fi;
	@./make_release $(VER)

make_release: make_release.sh

dependencies: $(CHX_FILES)
# 	cp $(CHX_FILES) src/chx/

install: chxdoc
	cp chxdoc ~/bin/

dummy:

