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
	import tetragon.data.racetrack.proto.RTEntityDistributionDef;
	import tetragon.data.racetrack.proto.RTLevel;
	import tetragon.data.racetrack.proto.RTLevelsCatalog;
	import tetragon.data.racetrack.proto.RTOpponentDistributionDef;
	import tetragon.data.racetrack.proto.RTRoadSection;
	import tetragon.data.racetrack.vo.RTColorSet;
	import tetragon.file.resource.ResourceIndex;
	import tetragon.file.resource.loaders.XMLResourceLoader;

	import com.hexagonstar.types.KeyValuePair;

	import flash.utils.Dictionary;
	
	
	/**
	 * Data parser for parsing Racetrack level catalogs.
	 */
	public class RTLevelsCatalogDataParser extends DataObjectParser implements IFileDataParser
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
			var xmlList:XMLList = obtainXMLList(_xml, "racetrackLevelsCatalog");
			var subList:XMLList;
			var x:XML;
			var y:XML;
			var c:uint;
			var str:String;
			
			for each (var xml:XML in xmlList)
			{
				/* Get the current item's ID. */
				var id:String = extractString(xml, "@id");
				
				/* Only parse the item(s) that we want! */
				if (!loader.hasResourceID(id)) continue;
				
				var catalog:RTLevelsCatalog = new RTLevelsCatalog(id);
				
				/* Parse the level definitions. */
				catalog.levels = new Dictionary();
				for each (x in xml.level)
				{
					var level:RTLevel = new RTLevel(extractString(x, "@id"));
					level.objectsCatalogID = extractString(x, "@objectsCatalogID");
					level.nameID = extractString(x, "@nameID");
					level.lanes = extractNumber(x, "@lanes");
					level.hazeDensity = extractNumber(x, "@hazeDensity");
					
					/* Parse level colors. */
					level.colorSetLight = new RTColorSet();
					level.colorSetLight.offroad = extractColorValue(x.colors.light, "@offroad");
					level.colorSetLight.road = extractColorValue(x.colors.light, "@road");
					level.colorSetLight.rumble = extractColorValue(x.colors.light, "@rumble");
					level.colorSetLight.lane = extractColorValue(x.colors.light, "@lane");
					level.colorSetDark = new RTColorSet();
					level.colorSetDark.offroad = extractColorValue(x.colors.dark, "@offroad");
					level.colorSetDark.road = extractColorValue(x.colors.dark, "@road");
					level.colorSetDark.rumble = extractColorValue(x.colors.dark, "@rumble");
					level.colorSetDark.lane = extractColorValue(x.colors.dark, "@lane");
					level.colorSetStart = new RTColorSet();
					level.colorSetStart.offroad = extractColorValue(x.colors.start, "@offroad");
					level.colorSetStart.road = extractColorValue(x.colors.start, "@road");
					level.colorSetStart.rumble = extractColorValue(x.colors.start, "@rumble");
					level.colorSetStart.lane = extractColorValue(x.colors.start, "@lane");
					level.colorSetFinish = new RTColorSet();
					level.colorSetFinish.offroad = extractColorValue(x.colors.finish, "@offroad");
					level.colorSetFinish.road = extractColorValue(x.colors.finish, "@road");
					level.colorSetFinish.rumble  = extractColorValue(x.colors.finish, "@rumble");
					level.colorSetFinish.lane = extractColorValue(x.colors.finish, "@lane");
					level.colorHaze = extractColorValue(x.colors.haze, "@value");
					level.colorSky = extractColorValue(x.colors.sky, "@value");
					
					/* Parse level background layers. */
					level.backgroundTextureAtlasID = extractString(x.background, "@textureAtlasID");
					subList = x.background.layer;
					level.backgroundLayerIDs = new Vector.<KeyValuePair>(subList.length(), true);
					c = 0;
					for each (y in subList)
					{
						var pair:KeyValuePair = new KeyValuePair(extractString(y, "@imageID"),
							extractNumber(y, "@parallax"));
						level.backgroundLayerIDs[c] = pair;
						++c;
					}
					
					/* Parse level road construction. */
					subList = x.road.section;
					level.roadSections = new Vector.<RTRoadSection>(subList.length(), true);
					c = 0;
					for each (y in subList)
					{
						var section:RTRoadSection = new RTRoadSection();
						section.type = extractString(y, "@type");
						section.length = extractNumber(y, "@length");
						section.height = extractNumber(y, "@height");
						section.curve = extractNumber(y, "@curve");
						
						if (isNaN(section.length))
						{
							str = extractString(y, "@length");
							if (str == "short") section.length = 25;
							else if (str == "medium") section.length = 50;
							else if (str == "long") section.length = 100;
							else section.length = 0;
						}
						if (isNaN(section.height))
						{
							str = extractString(y, "@height");
							if (str == "low") section.height = 20;
							else if (str == "medium") section.height = 40;
							else if (str == "high") section.height = 60;
							else if (str == "extreme") section.height = 100;
							else section.height = 0;
						}
						if (isNaN(section.curve))
						{
							str = extractString(y, "@curve");
							if (str == "easy") section.curve = 2;
							else if (str == "medium") section.curve = 4;
							else if (str == "hard") section.curve = 6;
							else if (str == "extreme") section.curve = 10;
							else section.curve = 0;
						}
						
						level.roadSections[c] = section;
						++c;
					}
					
					/* Parse entity distribution defs. */
					subList = x.objects.*;
					level.entityDistributionDefs = new Vector.<RTEntityDistributionDef>(subList.length(), true);
					c = 0;
					for each (y in subList)
					{
						var def:RTEntityDistributionDef = new RTEntityDistributionDef();
						def.multi = String(y.name()) == "entities";
						def.objectID = extractString(y, "@id");
						def.segment = extractString(y, "@segNum");
						def.offset = extractNumber(y, "@offset");
						def.collectionID = extractString(y, "@collectionID");
						def.start = extractString(y, "@start");
						def.end = extractString(y, "@end");
						def.stepSize = extractNumber(y, "@stepSize");
						def.stepInc = extractNumber(y, "@stepInc");
						def.subCount = extractNumber(y, "@subCount");
						def.segRange = extractArray(y, "@segRange");
						def.scaleRange = extractArray(y, "@scaleRange");
						def.offsetRange = extractArray(y, "@offsetRange");
						def.offsetMode = extractString(y, "@offsetMode");
						def.preOffset = extractNumber(y, "@preOffset");
						def.postOffset = extractNumber(y, "@postOffset");
						
						if (!def.objectID && !def.collectionID) continue;
						
						if (def.stepSize < 1) def.stepSize = 1;
						if (def.subCount < 1) def.subCount = 1;
						if (isNaN(def.offset)) def.offset = 0.0;
						if (isNaN(def.preOffset)) def.preOffset = 0.0;
						if (isNaN(def.postOffset)) def.postOffset = 0.0;
						
						level.entityDistributionDefs[c] = def;
						++c;
					}
					
					/* Parse opponent entity defs. */
					subList = x.opponents.*;
					level.opponentDistributionDefs = new Vector.<RTOpponentDistributionDef>(subList.length(), true);
					c = 0;
					for each (y in subList)
					{
						var def2:RTOpponentDistributionDef = new RTOpponentDistributionDef();
						def2.multi = String(y.name()) == "entities";
						def2.collectionID = extractString(y, "@collectionID");
						def2.offsetRange = extractArray(y, "@offsetRange");
						def2.count = extractNumber(y, "@count");
						def2.speedFactor = extractNumber(y, "@speedFactor");
						level.opponentDistributionDefs[c] = def2;
						++c;
					}
					
					/* Store level in catalog. */
					catalog.levels[level.id] = level;
				}
				
				index.addDataResource(catalog);
			}
			
			dispose();
		}
	}
}
