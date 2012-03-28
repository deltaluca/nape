neko:
	haxe -cp src -cp / -main SymbolicMain -neko symb.n -lib Parsex -debug
	neko symb.n

flash:
	haxe -cp src -cp / -lib nape -main SymbolicMain -swf symbolic.swf -swf-header 800:600:60:ffffff -swf-version 10 -lib Parsex -debug
	debugfp symbolic.swf


