![](http://deltaluca.me.uk/obiwan.jpg)

This is _not_ the nape documentation you are looking for!

This is rather the source required to create the documentation which is instead available at http://deltaluca.me.uk/docnew

# wtf is this?

To generate the nape documentation pages, this program takes a whole bunch of hand written .xml files describing the pages and generates all the .html and tables and what have you for the pretty documentation.

The generator is written with caxe and compiles to both neko and the current target (for better speed) C++ requiring haxecpp of course.

# Format

Probably the best way to see how the .xml is formatted if you are contributing to the documentation is to the view the existing .xml though this might be slightly dangerous as deprecated elements may/do exist in the .xml which are now ignored :P So I list them here also.

Everything from index page, to 404 is described in the .xml as follows:

# 404 Page

```xml
<e404>
	<!-- description -->
</e404>
```
