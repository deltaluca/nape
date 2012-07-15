/*
 * Copyright (c) 2008-2009, The Caffeine-hx project contributors
 * Original author : Russell Weir
 * Contributors: Niel Drummond
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE CAFFEINE-HX PROJECT CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE CAFFEINE-HX PROJECT CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

package chxdoc;

import chxdoc.Defines;
import chxdoc.Types;

/**
	<ul>
	<li> Code surrounded by \[\] is placed in either a \<code\> or \<pre\> block, \<pre\> if there are embedded newlines
	<li> To embed the actual \[ or \] character, prefix it with a backslash (\)
	<ul>
**/
class DocProcessor {
	var pkg : PackageContext;
	var ctx : Ctx;
	var docCtx : DocsContext;
	/** The original doc, unixified in constructor **/
	var doc		: String;

	private function new(pkg : PackageContext, ctx: Ctx, doc : String) {
		this.pkg = pkg;
		this.ctx = ctx;
		this.docCtx = {
			comments 		: null,
			authors			: new Array(),
			deprecated		: false,
			deprecatedMsg 	: null,
			params 			: new Array(),
			requires		: new Array(),
			returns 		: new Array(),
			see				: new Array(),
			since			: new Array(),
			throws 			: new Array(),
			todos			: new Array(),
			typeParams		: new Array(),
			version			: new Array(),
			forcePrivate	: false,
		};
		this.doc = doc.split("\r\n").join("\n").split("\r").join("\n");
	}

	public static function process(pkg : PackageContext, ctx: Ctx, doc : String) : DocsContext
	{
		if( doc == null || doc.length == 0)
			return null;
		var p = new DocProcessor(pkg, ctx, doc);
		return p.convert();
	}

	/**
	**/
	function convert() : DocsContext {
		// trim stars
		doc = ~/^([ \t]*)\*+/gm.replace(doc, "$1");
		doc = ~/\**[ \t]*$/gm.replace(doc, "");

		var parts = doTags(doc.split("\n"));

		var ch = doCodeBlockShortcut(parts.join("\n"));

		// separate into paragraphs
		parts = ~/\n[ \t]*\n/g.split(ch.parsed);
		if( parts.length == 1 )
			doc = parts[0];
		else
			doc = Lambda.map(parts,function(x) { return "<p>"+StringTools.trim(x)+"</p>"; }).join("\n");

		// put back code parts
		var i = 0;
		for( c in ch.codeBlocks )
			ch.parsed = ch.parsed.split("##__code__"+(i++)+"##").join(c);
		docCtx.comments = ch.parsed;

		// since tags are parsed bottom->up, we will reverse all the
		// arrays just so docs reflect the same order
		docCtx.authors.reverse();
		docCtx.params.reverse();
		docCtx.requires.reverse();
		docCtx.returns.reverse();
		docCtx.see.reverse();
		docCtx.throws.reverse();
		docCtx.todos.reverse();
		docCtx.typeParams.reverse();
		return docCtx;
	}




	function doEmbeddedTags(s : String) : String {
		//{@revision Date msg}
		//  for @author Bob {@revision 2008-12-01 Fixed bad bug}
		//{@link ...}
		return s;
	}

	/**
		Parses out all @tag lines from the array of strings provided,
		populating [this.docCtx] with tags encountered
		@param parts Newline separated array of doc lines
		@returns Array<String> New array of doc lines with tag lines removed
		@todo Enable Todo's
	**/
	function doTags(parts : Array<String>) : Array<String> {
		var accum : Array<String> = new Array();

		/**
			param cur must be the current text that is not yet in the accum
		**/
		var packAccum = function(cur : String) : String {
			accum.reverse();
			var s = accum.join(" ");
			s = cur + (s.length > 0 ? " " : "") + s;
			s = ~/[ \t]+/g.replace(s, " ");
			return s;
		}

		var i = parts.length;
		while(--i >= 0) {
			var tagEreg = ~/^[ \t]*@([A-Za-z]+)[ \t]*(.*)/;
			if(!tagEreg.match(parts[i])) {
				accum.push(parts[i]);
				continue;
			}
			switch(tagEreg.matched(1)) {
			case "author":
				var msg = packAccum(tagEreg.matched(2));
				if(ChxDocMain.config.showAuthorTags) {
					docCtx.authors.push(
						doEmbeddedTags(packAccum(tagEreg.matched(2)))
					);
				}
			case "deprecated":
				docCtx.deprecated = true;
				try {
					docCtx.deprecatedMsg = doEmbeddedTags(packAccum(tagEreg.matched(2)));
				} catch(e:Dynamic) {
					docCtx.deprecatedMsg = "";
				}
			case "param":
				var p = packAccum(tagEreg.matched(2)).split(" ");
				docCtx.params.push({
					arg : p.shift(),
					desc : doEmbeddedTags(p.join(" "))
				});
			case "requires":
				docCtx.requires.push(
					doEmbeddedTags(packAccum(tagEreg.matched(2)))
				);
			case "return", "returns":
				docCtx.returns.push(
					doEmbeddedTags(packAccum(tagEreg.matched(2)))
				);
			case "see":
				docCtx.see.push(
					doEmbeddedTags(packAccum(tagEreg.matched(2)))
				);
			case "since":
				docCtx.since.push(
					doEmbeddedTags(packAccum(tagEreg.matched(2)))
				);
			case "throw", "throws":
				var p = packAccum(tagEreg.matched(2)).split(" ");
				var e = p.shift();
				docCtx.throws.push( {
					name : e,
					uri : pkg.rootRelative + (StringTools.replace(e,".","/")) + ChxDocMain.config.htmlFileExtension,
					desc : doEmbeddedTags(p.join(" ")),
				});
			case "private":
				docCtx.forcePrivate = true;
			case "todo":
				var msg = doEmbeddedTags(packAccum(tagEreg.matched(2)));
				ChxDocMain.registerTodo(pkg, ctx, msg);
				if(ChxDocMain.config.showTodoTags)
					docCtx.todos.push(msg);
			case "type":
				var p = packAccum(tagEreg.matched(2)).split(" ");
				docCtx.typeParams.push({
					arg : p.shift(),
					desc : doEmbeddedTags(p.join(" "))
				});
			case "version":
				docCtx.version.push(
					doEmbeddedTags(packAccum(tagEreg.matched(2)))
				);
			default:
				ChxDocMain.logWarning("Unrecognized tag " + parts[i]);
			}
			accum = new Array();
		}
		accum.reverse();
		return accum;
	}

	/**
		Processes the \[\] style shortcut embedding &lt;code&gt; or &lt;pre&gt;, All instances of \[ are replaced with ##__code__12## where 12 would be
		an index to the text in the codeBlocks array.
		@return String remaining
		@return Array<String> Array of replacements to parsed
	**/
	static function doCodeBlockShortcut(s : String) {
		var rx = ~/\[/;
		var buf = new StringBuf();
		var codes = new Array<String>();

		while (rx.match(s)) {
			buf.add( rx.matchedLeft() );

			var code = rx.matchedRight();
			var brackets = 1;
			var i = 0;
			while( i < code.length && brackets > 0 ) {
				switch( code.charCodeAt(i++) ) {
				case 91: brackets++;
				case 93: brackets--;
				}
			}
			s = code.substr(i);
			code = code.substr(0, i-1);
			code = Utils.htmlSpecialChars(code, false); // false = no " change

			var tag = "##__code__"+codes.length+"##";
			if( code.indexOf('\n') != -1 ) {
				buf.add("<pre>");
				buf.add(tag);
				buf.add("</pre>");
				codes.push(code.split("\t").join("    "));
			} else {
				buf.add("<code>");
				buf.add(tag);
				buf.add("</code>");
				codes.push(code);
			}
		}
		buf.add(s);
		return { parsed : buf.toString(), codeBlocks : codes };
	}

}
