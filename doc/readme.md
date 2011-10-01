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

# Index page

```xml
<index>
	<!-- description -->
</index>
```

With the description appearing as the first thing on the page before tables of examples, tutorials, documentation and API pages.

# API package page

```xml
<package name="full.package.name">
	<short>
		<!-- Description to appear in parent package list/index -->
	</short>

	<description>
		<!-- Description to appear on actual package page before sub-package + class listings -->
	</description>
</package>
```

# API class page

```xml
<class package="full.package.name" name="classname" [super="superclass"]>
	<file> haXe file for imports </file>
	<short>
		<!-- Description to appear in class listing of package page -->
	</short>
	<description>
		<!-- Descrpitiong to appear at top of actual class page before listings -->
	</description>

	[<constructor>
		[<arg name="..." type="..." [const="true"] [optional="true" default="value"]/>]*
		<description>
			<!-- Description to appear in method listings -->
		</description>
		<detail>
			<description>
				<!-- Description to appear at method info -->
				[<throws> <!-- Error condition --> </throws>]*
			</description>
		</detail>
	</constructor>]
</class>
```
