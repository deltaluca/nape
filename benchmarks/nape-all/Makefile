all:
	echo "specify flash or cpp"

flash:
	haxe -cp . -main Main -swf Main.swf -lib nape -swf-header 500:500:120:333333 -swf-version 11 -D NAPE_RELEASE_BUILD
	fp Main.swf

cpp:
	haxe -cp . -main Main -cpp cpp -lib nape -lib nme --remap flash:nme -D NAPE_RELEASE_BUILD
	cp cpp/Main Main
	./Main

clean:
	rm -f Main.swf
	rm -f Main	
	rm -rf cpp
