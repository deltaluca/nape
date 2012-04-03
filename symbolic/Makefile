flash:
	haxe -cp src -cp / -lib nape -main SymbolicMain -swf symbolic.swf -swf-header 800:600:60:ffffff -swf-version 10 -lib Parsex --connect 9000 --dead-code-elimination -D NAPE_RELEASE_BUILD
	fp symbolic.swf

swc:
	haxe -cp src -cp / -cp ../externs --dead-code-elimination --macro "include('symbolic')" -swf symbolic.swc -swf-version 10 -lib Parsex --connect 9000

haxelib:
	cd src
	rm -f symboliclib.zip
	zip -r symboliclib .
	haxelib test symboliclib.zip
	cd ../
