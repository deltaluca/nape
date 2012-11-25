def:

haxe:
	haxe -cp . -main Main -swf Main.swf -lib nape -D NAPE_RELEASE_BUILD \
        -swf-version 11 -swf-header 580:400:60:333333
	fp Main.swf

as3:
	mxmlc Main.as --include-libraries release_nape.swc -optimize -strict \
        -target-player 11 -static-link-runtime-shared-libraries
	fp Main.swf
