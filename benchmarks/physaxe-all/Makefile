all:
	echo "specify flash or cpp"

flash: Main.hx
	haxelib run nme update Phx.nmml flash
	haxelib run nme build Phx.nmml flash
#	haxelib run nme run Phx.nmml flash
	fp bin/flash/bin/PhxBench.swf

cpp: Main.hx
	haxelib run nme update Phx.nmml linux -64
	haxelib run nme build Phx.nmml linux -64
	haxelib run nme run Phx.nmml linux -64

clean:
	rm -rf bin
