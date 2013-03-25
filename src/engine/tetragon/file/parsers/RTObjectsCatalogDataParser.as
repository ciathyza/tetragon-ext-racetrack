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
	import tetragon.data.constants.PlayDirection;
	import tetragon.data.constants.PlayMode;
	import tetragon.data.racetrack.constants.RTTriggerActions;
	import tetragon.data.racetrack.constants.RTTriggerTypes;
	import tetragon.data.racetrack.proto.RTObject;
	import tetragon.data.racetrack.proto.RTObjectCollection;
	import tetragon.data.racetrack.proto.RTObjectImageSequence;
	import tetragon.data.racetrack.proto.RTObjectsCatalog;
	import tetragon.data.racetrack.proto.RTTrigger;
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
			var subList:XMLList;
			var x:XML;
			var y:XML;
			var c:uint;
			
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
					
					/* Parse triggers thar are assigned to an object. */
					subList = x.triggers.trigger;
					c = 0;
					if (subList.length() > 0)
					{
						obj.triggers = new Vector.<RTTrigger>(subList.length(), true);
						for each (y in subList)
						{
							var type:String = extractString(y, "@type");
							var action:String = extractString(y, "@action");
							if (!RTTriggerTypes.isValid(type))
							{
								warn("Unknown object trigger type: " + type);
								continue;
							}
							else if (!RTTriggerActions.isValid(action))
							{
								warn("Unknown object trigger action: " + action);
								continue;
							}
							else
							{
								var trigger:RTTrigger = new RTTrigger();
								trigger.type = type;
								trigger.action = action;
								trigger.arguments = extractArray(y, "@arguments");
								obj.triggers[c] = trigger;
							}
							++c;
						}
					}
					
					/* Static objects have only one imageID assigned! */
					var imageID:String = extractString(x, "@imageID");
					if (imageID && imageID.length > 0)
					{
						obj.imageID = imageID;
					}
					/* Otherwise they must have a sequence of animation frames defined. */
					else
					{
						obj.defaultSequenceID = extractString(x, "@defaultSequenceID");
						obj.defaultFramerate = extractNumber(x, "@defaultFramerate", 12);
						if (obj.defaultFramerate < 1) obj.defaultFramerate = 1;
						else if (obj.defaultFramerate > 60) obj.defaultFramerate = 60;
						obj.sequences = new Dictionary();
						/* Parse through animation sequences. */
						for each (y in x.sequence)
						{
							var seq:RTObjectImageSequence = new RTObjectImageSequence();
							seq.id = extractString(y, "@id");
							seq.playMode = extractString(y, "@playMode", PlayMode.LOOP);
							seq.playDirection = extractString(y, "@playDirection", PlayDirection.FORWARD);
							seq.framerate = extractNumber(y, "@framerate");
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
