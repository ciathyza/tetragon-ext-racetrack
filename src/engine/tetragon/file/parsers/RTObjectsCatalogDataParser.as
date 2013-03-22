/*
 *      _________  __      __
 *    _/        / / /____ / /________ ____ ____  ___
 *   _/        / / __/ -_) __/ __/ _ `/ _ `/ _ \/ _ \
 *  _/________/  \__/\__/\__/_/  \_,_/\_, /\___/_//_/
 *                                   /___/
 * 
 * Tetragon : Game Engine for multi-platform ActionScript projects.
 * http://www.tetragonengine.com/ - Copyright (C) 2012 Sascha Balkau
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
package tetragon.file.parsers
{
	import tetragon.data.racetrack.proto.RTObject;
	import tetragon.data.racetrack.proto.RTObjectCollection;
	import tetragon.data.racetrack.proto.RTObjectImageSequence;
	import tetragon.data.racetrack.proto.RTObjectsCatalog;
	import tetragon.file.resource.ResourceIndex;
	import tetragon.file.resource.loaders.XMLResourceLoader;

	import flash.utils.Dictionary;
	
	
	/**
	 * Data parser for parsing Racetrack object catalogs.
	 */
	public class RTObjectsCatalogDataParser extends DataObjectParser implements IFileDataParser
	{
		//-----------------------------------------------------------------------------------------
		// Public Methods
		//-----------------------------------------------------------------------------------------
		
		/**
		 * @inheritDoc
		 */
		public function parse(loader:XMLResourceLoader, model:*):void
		{
			_xml = loader.xml;
			var index:ResourceIndex = model;
			var xmlList:XMLList = obtainXMLList(_xml, "racetrackObjectsCatalog");
			var x:XML;
			
			for each (var xml:XML in xmlList)
			{
				/* Get the current item's ID. */
				var id:String = extractString(xml, "@id");
				
				/* Only parse the item(s) that we want! */
				if (!loader.hasResourceID(id)) continue;
				
				var catalog:RTObjectsCatalog = new RTObjectsCatalog(id);
				catalog.textureAtlasID = extractString(xml, "@textureAtlasID");
				
				/* Parse the object collections. */
				catalog.collections = new Dictionary();
				for each (x in xml.collections.collection)
				{
					var col:RTObjectCollection = new RTObjectCollection(extractString(x, "@id"));
					col.type = extractString(x, "@type");
					col.scale = extractNumber(x, "@scale");
					if (isNaN(col.scale)) col.scale = 1.0;
					col.objects = new <RTObject>[];
					catalog.collections[col.id] = col;
				}
				
				/* Parse object definitions. */
				catalog.objects = new Dictionary();
				for each (x in xml.objects.object)
				{
					var obj:RTObject = new RTObject(extractString(x, "@id"));
					obj.collectionID = extractString(x, "@collectionID");
					obj.scale = extractNumber(x, "@scale");
					if (isNaN(obj.scale)) obj.scale = 1.0;
					
					/* Static objects have only one imageID assigned! */
					var imageID:String = extractString(x, "@imageID");
					if (imageID && imageID.length > 0)
					{
						obj.imageID = imageID;
					}
					/* Otherwise they must have a sequence of animation frames defined. */
					else
					{
						obj.sequences = new Dictionary();
						/* Parse through animation sequences. */
						for each (var y:XML in x.sequence)
						{
							var seq:RTObjectImageSequence = new RTObjectImageSequence();
							seq.id = extractString(y, "@id");
							seq.imageIDs = new <String>[];
							for each (var f:XML in y.frame)
							{
								seq.imageIDs.push(extractString(f, "@imageID"));
							}
							obj.sequences[seq.id] = seq;
						}
					}
					catalog.objects[obj.id] = obj;
				}
				
				index.addDataResource(catalog);
			}
			
			dispose();
		}
	}
}
