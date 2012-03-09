all:
	echo "specify flash or cpp"

flash: Main.hx
	haxelib run nme update Nape.nmml flash
	haxelib run nme build Nape.nmml flash
#	haxelib run nme run Nape.nmml flash
	fp bin/flash/bin/NapeBench.swf

cpp: Main.hx
	haxelib run nme update Nape.nmml linux -64
	haxelib run nme build Nape.nmml linux -64
	haxelib run nme run Nape.nmml linux -64

clean:
	rm -rf bin
