flash:
	haxe -cp src -cp / -lib nape -main SymbolicMain -swf symbolic.swf -swf-header 800:600:60:ffffff -swf-version 10 -lib Parsex --connect 9000 --dead-code-elimination -D NAPE_RELEASE_BUILD -debug
	debugfp symbolic.swf

neko:
	haxe -cp src -cp / -lib nape -main SymbolicMain -neko symb.n -lib Parsex --connect 9000 --dead-code-elimination -debug
	neko symb.n

swc:
	haxe -cp src -cp / -cp ../externs --dead-code-elimination --macro "include('symbolic')" -swf symbolic.swc -swf-version 10 -lib Parsex --connect 9000
