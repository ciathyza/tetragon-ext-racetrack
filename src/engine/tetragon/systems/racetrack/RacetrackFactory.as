/*
 *      _________  __      __
 *    _/        / / /____ / /________ ____ ____  ___
 *   _/        / / __/ -_) __/ __/ _ `/ _ `/ _ \/ _ \
 *  _/________/  \__/\__/\__/_/  \_,_/\_, /\___/_//_/
 *                                   /___/
 * 
 * Tetragon : Game Engine for multi-platform ActionScript projects.
 * http://www.tetragonengine.com/
 * Copyright (c) The respective Copyright Holder (see LICENSE).
 * 
 * Permission is hereby granted, to any person obtaining a copy of this software
 * and associated documentation files (the "Software") under the rules defined in
 * the license found at http://www.tetragonengine.com/license/ or the LICENSE
 * file included within this distribution.
 * 
 * The above copyright notice and this permission notice must be included in all
 * copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND. THE COPYRIGHT
 * HOLDER AND ITS LICENSORS DISCLAIM ALL WARRANTIES AND CONDITIONS, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO ANY IMPLIED WARRANTIES AND CONDITIONS OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT, AND ANY
 * WARRANTIES AND CONDITIONS ARISING OUT OF COURSE OF DEALING OR USAGE OF TRADE.
 * NO ADVICE OR INFORMATION, WHETHER ORAL OR WRITTEN, OBTAINED FROM THE COPYRIGHT
 * HOLDER OR ELSEWHERE WILL CREATE ANY WARRANTY OR CONDITION NOT EXPRESSLY STATED
 * IN THIS AGREEMENT.
 */
package tetragon.systems.racetrack
{
	import tetragon.BaseClass;
	import tetragon.Main;
	import tetragon.data.Settings;
	import tetragon.data.atlas.Atlas;
	import tetragon.data.atlas.TextureAtlas;
	import tetragon.data.racetrack.Racetrack;
	import tetragon.data.racetrack.constants.RTObjectTypes;
	import tetragon.data.racetrack.constants.RTRoadSectionTypes;
	import tetragon.data.racetrack.constants.RTSettingsNames;
	import tetragon.data.racetrack.constants.RTTriggerTypes;
	import tetragon.data.racetrack.proto.*;
	import tetragon.data.racetrack.vo.*;
	import tetragon.debug.Log;
	import tetragon.file.resource.ResourceIndex;
	import tetragon.view.render2d.display.BlendMode2D;
	import tetragon.view.render2d.display.Image2D;
	import tetragon.view.render2d.display.MovieClip2D;
	import tetragon.view.render2d.extensions.scrollimage.ScrollTile2D;
	import tetragon.view.render2d.textures.Texture2D;
	import tetragon.view.render2d.textures.TextureSmoothing2D;

	import com.hexagonstar.types.KeyValuePair;
	import com.hexagonstar.util.string.stringIsEmptyOrNull;

	import flash.utils.Dictionary;
	
	
	/**
	 * RacetrackFactory class
	 *
	 * @author Hexagon
	 */
	public class RacetrackFactory extends BaseClass
	{
		//-----------------------------------------------------------------------------------------
		// Properties
		//-----------------------------------------------------------------------------------------
		
		private var _levelsCatalog:RTLevelsCatalog;
		private var _objectsCatalog:RTObjectsCatalog;
		private var _level:RTLevel;
		private var _textureAtlas:Atlas;
		
		private var _rt:Racetrack;
		
		private var _segmentCount:uint;
		private var _carsCount:uint;
		
		private var _playerZ:Number;
		
		private static var _entityThinningMult:int;
		
		
		//-----------------------------------------------------------------------------------------
		// Constructor
		//-----------------------------------------------------------------------------------------
		
		/**
		 * Creates a new instance of the class.
		 */
		public function RacetrackFactory(levelsCatalogID:String)
		{
			super();
			RacetrackSystem.juggler = Main.instance.screenManager.render2D.juggler;
			_levelsCatalog = resourceIndex.getResourceContent(levelsCatalogID);
		}
		
		
		//-----------------------------------------------------------------------------------------
		// Public Methods
		//-----------------------------------------------------------------------------------------
		
		/**
		 * @private
		 */
		public function createRacetrack(levelID:String):Racetrack
		{
			reset();
			
			if (!_levelsCatalog) return error("No levels catalog provided!");
			
			_level = _levelsCatalog.levels[levelID];
			if (!_level) return error("No level with ID " + levelID + "!");
			_objectsCatalog = resourceIndex.getResourceContent(_level.objectsCatalogID);
			if (!_objectsCatalog) return error("No objects catalog with ID " + _level.objectsCatalogID + "!");
			
			_textureAtlas = getTextureAtlas(_objectsCatalog.textureAtlasID);
			
			_rt = new Racetrack(_level.id);
			
			initDefaults();
			prepareColors();
			prepareBackgroundLayers();
			prepareObjects();
			
			createRoad();
			createEntities();
			createTraffic();
			
			logStats();
			
			return _rt;
		}
		
		
		//-----------------------------------------------------------------------------------------
		// Accessors
		//-----------------------------------------------------------------------------------------
		
		public static function get entityThinningMult():int
		{
			return _entityThinningMult;
		}
		public static function set entityThinningMult(v:int):void
		{
			_entityThinningMult = v;
		}
		
		
		/**
		 * @private
		 */
		private function get lastY():Number
		{
			return (_rt.segments.length == 0)
				? 0.0
				: _rt.segments[_rt.segments.length - 1].point2.world.y;
		}
		
		
		//-----------------------------------------------------------------------------------------
		// Private Methods
		//-----------------------------------------------------------------------------------------
		
		/**
		 * @private
		 */
		private function reset():void
		{
			_level = null;
			_objectsCatalog = null;
			_textureAtlas = null;
		}
	
		
		/**
		 * @private
		 */
		private function initDefaults():void
		{
			_segmentCount = 0;
			_carsCount = 0;
			
			_rt.objectCount = 0;
			_rt.entityCount = 0;
			_rt.dt = 1 / Main.instance.gameLoop.frameRate;
			
			/* Game Settings. */
			var s:Settings = registry.settings;
			var maxSpeedMult:Number = s.getNumber(RTSettingsNames.DEFAULT_MAX_SPEED_MULT) || 1.0;
			var accelerationDiv:Number = s.getNumber(RTSettingsNames.DEFAULT_ACCELERATION_DIV) || 5.0;
			var offRoadLimitDiv:Number = s.getNumber(RTSettingsNames.DEFAULT_OFFROAD_LIMIT_DIV) || 4.0;
			var offRoadDecelDiv:Number = s.getNumber(RTSettingsNames.DEFAULT_OFFROAD_DECEL_DIV) || 2.0;
			
			_rt.drawDistance = s.getNumber(RTSettingsNames.DEFAULT_DRAW_DISTANCE) || 300;			/* 100 - 500 */
			_rt.fov = s.getNumber(RTSettingsNames.DEFAULT_FOV) || 100;								/* 80 - 140 */
			_rt.cameraAltitude = s.getNumber(RTSettingsNames.DEFAULT_CAMERA_ALTITUDE) || 1000;		/* 500 - 5000 */
			_rt.maxCars = s.getNumber(RTSettingsNames.MAX_CARS) || 1000;
			_rt.roadWidth = s.getNumber(RTSettingsNames.DEFAULT_ROAD_WIDTH) || 2000;				/* 500 - 3000 */
			_rt.segmentLength = s.getNumber(RTSettingsNames.DEFAULT_SEGMENT_LENGTH) || 200;
			_rt.rumbleLength = s.getNumber(RTSettingsNames.DEFAULT_RUMBLE_LENGTH) || 3;
			_rt.centrifugal = s.getNumber(RTSettingsNames.DEFAULT_CENTRIFUGAL) || 0.3;
			_rt.playerAnimDynamicFPS = s.getBoolean(RTSettingsNames.PLAYER_ANIM_DYNAMIC_FPS);
			_rt.playerObjectID = s.getString(RTSettingsNames.PLAYER_OBJECT_ID) || "player";
			
			_entityThinningMult = s.getNumber(RTSettingsNames.ENTITY_THINNING_MULT) || 1;
			
			/* Level-based parameters. */
			_rt.hazeDensity = _level.settings[RTSettingsNames.HAZE_DENSITY] || 0;
			_rt.hazeThreshold = _level.settings[RTSettingsNames.HAZE_THRESHOLD] || 0.99;
			_rt.lanes = _level.settings[RTSettingsNames.LANES] || 2;
			_rt.roadWidth = _level.settings[RTSettingsNames.ROAD_WIDTH] || _rt.roadWidth;
			_rt.segmentLength = _level.settings[RTSettingsNames.SEGMENT_LENGTH] || _rt.segmentLength;
			_rt.rumbleLength = _level.settings[RTSettingsNames.RUMBLE_LENGTH] || _rt.rumbleLength;
			_rt.centrifugal = _level.settings[RTSettingsNames.CENTRIFUGAL] || _rt.centrifugal;
			_rt.offRoadDecel = _level.settings[RTSettingsNames.OFFROAD_DECEL_DIV] || _rt.offRoadDecel;
			_rt.fov = _level.settings[RTSettingsNames.FOV] || _rt.fov;
			_rt.cameraAltitude = _level.settings[RTSettingsNames.CAMERA_ALTITUDE] || _rt.cameraAltitude;
			_rt.drawDistance = _level.settings[RTSettingsNames.DRAW_DISTANCE] || _rt.drawDistance;
			_rt.playerJitter = _level.settings[RTSettingsNames.PLAYER_JITTER] || 1.2;
			_rt.playerJitterOffRoad = _level.settings[RTSettingsNames.PLAYER_JITTER_OFFROAD] || 4.2;
			
			maxSpeedMult = _level.settings[RTSettingsNames.MAX_SPEED_MULT] || maxSpeedMult;
			accelerationDiv = _level.settings[RTSettingsNames.ACCELERATION_DIV] || accelerationDiv;
			offRoadLimitDiv = _level.settings[RTSettingsNames.OFFROAD_LIMIT_DIV] || offRoadLimitDiv;
			offRoadDecelDiv = _level.settings[RTSettingsNames.OFFROAD_DECEL_DIV] || offRoadDecelDiv;
			
			/* Derived parameters. */
			var cameraDepth:Number = 1 / Math.tan((_rt.fov / 2) * Math.PI / 180);
			_playerZ = (_rt.cameraAltitude * cameraDepth);
			
			_rt.maxSpeed = Math.ceil(_rt.segmentLength / _rt.dt) * maxSpeedMult;
			_rt.acceleration = _rt.maxSpeed / accelerationDiv;
			_rt.deceleration = -_rt.maxSpeed / accelerationDiv;
			_rt.braking = -_rt.maxSpeed;
			_rt.offRoadDecel = -_rt.maxSpeed / offRoadDecelDiv;
			_rt.offRoadLimit = _rt.maxSpeed / offRoadLimitDiv;
		}
		
		
		/**
		 * @private
		 */
		private function prepareColors():void
		{
			_rt.backgroundColor = _level.colorBackground;
			_rt.hazeColor = _level.colorHaze;
			_rt.colorSetLight  = _level.colorSetLight;
			_rt.colorSetDark = _level.colorSetDark;
			_rt.colorSetStart = _level.colorSetStart;
			_rt.colorSetFinish = _level.colorSetFinish;
		}
		
		
		/**
		 * @private
		 */
		private function prepareBackgroundLayers():void
		{
			if (!_level.backgroundLayerIDs || _level.backgroundLayerIDs.length < 1) return;
			_rt.backgroundScale = _level.backgroundScale;
			_rt.backgroundLayers = new Vector.<ScrollTile2D>(_level.backgroundLayerIDs.length, true);
			var bgAtlas:TextureAtlas = resourceManager.process(_level.backgroundTextureAtlasID);
			
			if (!bgAtlas)
			{
				error("No texture atlas with ID " + _level.backgroundTextureAtlasID
					+ " for background layers!");
				return;
			}
			
			for (var i:uint = 0; i < _rt.backgroundLayers.length; i++)
			{
				var pair:KeyValuePair = _level.backgroundLayerIDs[i];
				var texture:Texture2D = bgAtlas.getImage(pair.key);
				if (!texture)
				{
					Log.warn("No texture with ID " + pair.key, this);
					continue;
				}
				var layer:ScrollTile2D = new ScrollTile2D(texture, true);
				layer.parallax = pair.value;
				_rt.backgroundLayers[i] = layer;
			}
		}
		
		
		/**
		 * @private
		 */
		private function prepareObjects():void
		{
			var placeholder:Texture2D = Texture2D.fromBitmapData(ResourceIndex.getPlaceholderImage());
			var atlas:Atlas;
			var textures:Dictionary;
			var texture:Texture2D;
			var imageID:String;
			
			/* Create empty collections. */
			for each (var c:RTObjectCollection in _objectsCatalog.collections)
			{
				_rt.addCollection(c);
			}
			
			/* Create prototype objects. */
			for each (var obj:RTObject in _objectsCatalog.objects)
			{
				texture = null;
				
				/* Object has no specific texture atlas assigned, so use the global one. */
				if (stringIsEmptyOrNull(obj.textureAtlasID))
				{
					atlas = _textureAtlas;
					textures = atlas.getImageMap();
				}
				else
				{
					atlas = getTextureAtlas(obj.textureAtlasID);
					if (atlas) textures = atlas.getImageMap();
				}
				
				/* Object has animation sequences. */
				if (obj.sequencesNum > 0)
				{
					/* Prepare anim frames for objects that posses a sequence. */
					for each (var seq:RTObjectImageSequence in obj.sequences)
					{
						if (seq.framerate <= 0) seq.framerate = obj.defaultFramerate;
						
						var framesNum:uint = seq.imageIDs.length;
						/* If the sequence has only one frame, use an Image2D because it's cheaper */
						if (framesNum == 1)
						{
							imageID = seq.imageIDs[0];
							if (atlas)
							{
								texture = atlas.getImage(imageID);
							}
							if (!texture)
							{
								Log.warn("Sequence \"" + seq.id + "\" doesn't have image " + imageID, this);
								texture = placeholder;
							}
							seq.image = new Image2D(texture);
							seq.image.blendMode = BlendMode2D.NORMAL;
							seq.image.smoothing = TextureSmoothing2D.NONE;
						}
						/* ... Otherwise create a MovieClip2D */
						else
						{
							var mcTextures:Vector.<Texture2D> = new Vector.<Texture2D>();
							for (var i:uint = 0; i < framesNum; i++)
							{
								imageID = seq.imageIDs[i];
								if (atlas)
								{
									texture = atlas.getImage(imageID);
								}
								if (!texture)
								{
									Log.warn("Sequence \"" + seq.id + "\" doesn't have image " + imageID, this);
									texture = placeholder;
								}
								mcTextures.push(texture);
							}
							if (mcTextures.length > 0)
							{
								var mc:MovieClip2D = new MovieClip2D(mcTextures, seq.framerate);
								mc.blendMode = BlendMode2D.NORMAL;
								mc.smoothing = TextureSmoothing2D.NONE;
								mc.playMode = seq.playMode;
								mc.playDirection = seq.playDirection;
								seq.movieClip = mc;
							}
							else
							{
								Log.warn("Sequence \"" + seq.id + "\" has no images.", this);
							}
						}
					}
				}
				/* Object has a single image ID defined (static image). */
				else if (!stringIsEmptyOrNull(obj.imageID))
				{
					texture = textures[obj.imageID];
					if (!texture)
					{
						Log.warn("Texture not found: " + obj.imageID, this);
						texture = placeholder;
					}
					
					// TODO Generate collision data from the texture's polygonal data!
					//var mask:BitmapData = _textureAtlas.getAlphaMask(obj.imageID);
					//var pData:Vector.<PointInt> = _textureAtlas.getPolygonalData(obj.imageID);
					//if (mask && pData)
					//{
					//	Debug.trace(obj.id + ": " + pData.length);
					//	var b:BitmapData = new BitmapData(mask.width, mask.height, true, 0);
					//	var shape:Shape = new Shape();
					//	shape.graphics.lineStyle(1, 0xFF0000);
					//	shape.graphics.beginFill(0xFF00FF, 0.5);
					//	for (var k:uint = 0; k < pData.length; k++)
					//	{
					//		var pt:PointInt = pData[k];
					//		if (k == 0) shape.graphics.moveTo(pt.x, pt.y);
					//		else shape.graphics.lineTo(pt.x, pt.y);
					//	}
					//	shape.graphics.endFill();
					//	b.draw(shape);
					//	texture = Texture2D.fromBitmapData(b);
					//}
					
					obj.image = new Image2D(texture);
					obj.image.blendMode = BlendMode2D.NORMAL;
					obj.image.smoothing = TextureSmoothing2D.NONE;
				}
				else
				{
					// Might be a marker object without image. Don't bother!
					//Log.warn("Object " + obj.id + " has no image or animation sequences!", this);
				}
				
				/* Set default object state. */
				var success:int = RacetrackSystem.switchObjectState(obj, obj.defaultStateID);
				if (success == -1)
				{
					Log.warn("Could not switch object " + obj.id + " to its default state.", this);
				}
				else if (success == -2)
				{
					Log.warn("Object " + obj.id + " has a default state but no default anim sequence.", this);
				}
				
				/* Add object to collection if it belongs to one. */
				var col:RTObjectCollection = _rt.getCollection(obj.collectionID);
				if (col)
				{
					obj.type = col.type;
					obj.essential = col.essential;
					col.objects.push(obj);
					/* Try to take Y offset from collection if the object has none. */
					if (isNaN(obj.pixelOffsetY))
					{
						obj.pixelOffsetY = col.pixelOffsetY;
					}
				}
				
				/* If offset is still NaN set it to 0. */
				if (isNaN(obj.pixelOffsetY))
				{
					obj.pixelOffsetY = 0;
				}
				
				/* Store object in global objects map. */
				_rt.mapObject(obj);
			}
			
			/* Prepare the player sprite. */
			var playerObj:RTObject = _rt.getObject(_rt.playerObjectID);
			if (playerObj)
			{
				playerObj.isPlayer = true;
				if (!playerObj.image)
				{
					Log.warn("No player image!", this);
					playerObj.image = new Image2D(placeholder);
				}
				
				/* Create player entity */
				_rt.player = newEntity("player", playerObj);
				_rt.mapEntity(_rt.player);
				
				/* The reference sprite width should be 1/3rd the (half-)roadWidth. */
				_rt.objectScale = 0.3 * (1 / _rt.player.width);
			}
			else
			{
				Log.error("No player object!", this);
			}
		}
		
		
		/**
		 * @private
		 */
		private function createRoad():void
		{
			var i:uint;
			var sectionsNum:uint = _level.roadSections.length;
			_rt.segments = new Vector.<RTSegment>();
			
			for (i = 0; i < sectionsNum; i++)
			{
				var section:RTRoadSection = _level.roadSections[i];
				switch (section.type)
				{
					case RTRoadSectionTypes.STRAIGHT:
						addStraight(section.length);
						break;
					case RTRoadSectionTypes.HILL:
						addHill(section.length, section.height);
						break;
					case RTRoadSectionTypes.VALLEY:
						addHill(section.length, -section.height);
						break;
					case RTRoadSectionTypes.LOW_ROLLING_HILLS:
						addLowRollingHills(section.length, section.height);
						break;
					case RTRoadSectionTypes.S_CURVES:
						addSCurves(50, 2, 4, section.height);
						break;
					case RTRoadSectionTypes.CURVE_L:
						addCurve(section.length, -section.curve, section.height);
						break;
					case RTRoadSectionTypes.CURVE_R:
						addCurve(section.length, section.curve, section.height);
						break;
					case RTRoadSectionTypes.BUMPS:
						addBumps();
						break;
					case RTRoadSectionTypes.DOWNHILL_TO_END:
						addDownhillToEnd(section.length, section.curve);
						break;
					default:
						error("createRoad:: Unknown road section type: " + section.type);
				}
			}
			
			/* Paint Start line. */
			//_rt.segments[findSegment(_playerZ).index + 2].colorSet = _rt.colorSetStart;
			//_rt.segments[findSegment(_playerZ).index + 3].colorSet = _rt.colorSetStart;
			
			/* Paint Finish line. */
			//for (i = 0 ; i < _rt.rumbleLength; i++)
			//{
			//	_rt.segments[_rt.segments.length - 1 - i].colorSet = _rt.colorSetFinish;
			//}
			
			/* Calculate track length. */
			_rt.segmentsNum = _rt.segments.length;
			_rt.trackLength = _rt.segmentsNum * _rt.segmentLength;
		}
		
		
		/**
		 * @private
		 */
		private function createEntities():void
		{
			var i:uint;
			var entitiesNum:uint = _level.entityDistributionDefs.length;
			
			for (i = 0; i < entitiesNum; i++)
			{
				var def:RTEntityDistributionDef = _level.entityDistributionDefs[i];
				if (!def) continue;
				
				if (def.multi)
				{
					/* Parse special markers in segment number string. */
					var start:Number = parseOffsetMarker(def.start);
					var end:Number = parseOffsetMarker(def.end);
					
					addEntities(def.objectID, def.collectionID, start, end, def.stepSize,
						def.stepInc, def.subCount, def.segRange, def.scaleRange, def.offsetRange,
						def.offsetX, def.offsetMode, def.preOffset, def.postOffset);
				}
				else
				{
					if (def.segment == null) continue;
					/* Parse special markers in segment number string. */
					var segNum:Number = parseOffsetMarker(def.segment);
					addEntity(segNum, def.objectID, def.offsetX);
				}
			}
		}
		
		
		/**
		 * @private
		 */
		private function createTraffic():void
		{
			var i:uint;
			var carsNum:uint = _level.opponentDistributionDefs.length;
			_rt.cars = new Vector.<RTCar>();
			
			for (i = 0; i < carsNum; i++)
			{
				var def:RTOpponentDistributionDef = _level.opponentDistributionDefs[i];
				if (!def) continue;
				
				if (def.multi)
				{
					addCars(def.collectionID, def.count, def.offsetRange, def.speedFactor);
				}
				else
				{
					// TODO Add support for placing single opponents.
				}
			}
		}
		
		
		/**
		 * Parses number strings in entity distribution parameters that can have special
		 * markers that specify an offset.
		 * 
		 * @private
		 * 
		 * @param value
		 * @return Number
		 */
		private function parseOffsetMarker(value:String):Number
		{
			var num:Number = Number(value);
			var offset:Number;
			var s:String;
			
			if (isNaN(num))
			{
				/* Result is at end of road. */
				if (value == "end")
				{
					num = _rt.segmentsNum - 1;
				}
				/* Result is at end of road minus x segments. */
				else if (value.substr(0, 4) == "end-")
				{
					s = value.substr(4);
					offset = Number(s);
					if (isNaN(offset))
					{
						error("parseOffsetMarker:: Invalid offset value: " + s);
						num = NaN;
					}
					else
					{
						num = _rt.segmentsNum - int(offset);
					}
				}
				else
				{
					error("parseOffsetMarker:: Unknown offset marker: " + value);
					num = NaN;
				}
			}
			
			return num;
		}
		
		
		/**
		 * @private
		 */
		private function logStats():void
		{
			var emptySegs:uint = _segmentCount;
			for each (var s:RTSegment in _rt.segments)
			{
				if (s.entities) --emptySegs;
			}
			
			for (var i:uint = 0; i < _rt.segments.length; i++)
			{
				
			}
			
			Log.trace("Created racetrack with ID \"" + _rt.id + "\""
				+ "\n\ttrackLength: " + _rt.trackLength
				+ "\n\tsegments: " + _segmentCount + " (empty: " + emptySegs + ")"
				+ "\n\tobjects: " + _rt.objectCount
				+ "\n\tentities: " + _rt.entityCount
				+ "\n\tcars: " + _carsCount, this);
			
			//Debug.trace(_rt.dump());
		}
		
		
		// -----------------------------------------------------------------------------------------
		// ENTITY DISTRIBUTION
		// -----------------------------------------------------------------------------------------
		
		/**
		 * Adds entities of a specific racetrack object to the racetrack with specific
		 * distribution parameters.
		 * 
		 * @param objectID
		 * @param start
		 * @param end
		 * @param segmentRandRange
		 * @param stepSize
		 * @param stepInc
		 * @param offset
		 * @param postOffset
		 * @param offsetMode
		 */
		private function addEntities(objectID:String, collectionID:String,
			start:int, end:int, stepSize:int = 1, stepInc:int = 0, subCount:int = 1,
			segRange:Array = null, scaleRange:Array = null, offsetRange:Array = null,
			offsetX:Number = 0.0, offsetMode:String = null, preOffset:Number = 0.0,
			postOffset:Number = 0.0):void
		{
			var collection:RTObjectCollection = collectionID ? _rt.getCollection(collectionID) : null;
			var essential:Boolean = false;
			var id:String = objectID;
			var segAdd:int = 0;
			var count:uint = 0;
			var scale:Number = 1.0;
			
			/* Take essential flag first from collection, if available ... */
			if (collection)
			{
				essential = collection.essential;
			}
			/* ... then override with the object-based flag. */
			if (!stringIsEmptyOrNull(id))
			{
				var obj:RTObject = _rt.getObject(id);
				if (obj) essential = obj.essential;
			}
			
			if (stepSize < 1) stepSize = 1;
			if (subCount < 1) subCount = 1;
			
			/* Entity thinning multiplier should only affect non-essential objects! */
			if (!essential)
			{
				stepSize *= _entityThinningMult;
			}
			
			for (var i:int = start; i < end; i += stepSize + int(i / stepInc))
			{
				for (var j:uint = 0; j < subCount ; j++)
				{
					/* If we got a collection take a random object ID from it every iteration. */
					if (collection) id = randomIDFromCollection(collection);
					if (offsetRange) offsetX = randomChoice(offsetRange);
					if (scaleRange) scale = randomNumber(scaleRange);
					
					if (segRange)
					{
						if (segRange.length == 1) segAdd = segRange[0];
						else segAdd = randomInt(segRange[0], segRange[1]);
					}
					
					var ox:Number = offsetX;
					if (offsetMode == "sub")		ox = offsetX - (preOffset + Math.random() * postOffset);
					else if (offsetMode == "mult")	ox = offsetX * (preOffset + Math.random() * postOffset);
					else if (offsetMode == "rand")	ox = randomNumber(offsetRange);
					else							ox = offsetX + (preOffset + Math.random() * postOffset); // "add" is default offset mode.
					
					addEntity(i + segAdd, id, ox, scale);
					++count;
				}
			}
			
			Log.verbose("Added " + count + " entities from " + (collectionID || id) + ".", this);
		}
		
		
		/**
		 * Adds an entity of a racetrack object to a specific racetrack segment.
		 * 
		 * @param segNum
		 * @param object
		 * @param offset
		 * @param scale Entity-specific scale value.
		 */
		private function addEntity(segNum:Number, objectID:String, offsetX:Number, scale:Number = 1.0):void
		{
			var obj:RTObject = _rt.getObject(objectID);
			if (!obj) return;
			if (segNum >= _rt.segments.length || isNaN(segNum)) return;
			
			/* Calculate scaling bu taking the object's default scaling, the collection
			 * scaling and the entity scale range into account. */
			var col:RTObjectCollection = _rt.getCollection(obj.collectionID);
			var scl:Number = obj.scale;
			if (col) scl *= col.scale;
			scl = scale * scl;
			
			var e:RTEntity = newEntity(createEntityID(), obj, offsetX, scl);
			var seg:RTSegment = _rt.segments[int(segNum)];
			/* Create entities array on segment only if needed. */
			if (!seg.entities) seg.entities = new <RTEntity>[];
			
			/* Check if object has any segment-based triggers assigned. */
			if (obj.triggers)
			{
				var i:uint;
				var tmpSegTriggers:Vector.<RTTrigger> = new <RTTrigger>[];
				for (i = 0; i < obj.triggers.length; i++)
				{
					var trigger:RTTrigger = obj.triggers[i];
					if (trigger && trigger.type == RTTriggerTypes.SEGMENT)
					{
						tmpSegTriggers.push(trigger);
					}
				}
				
				/* Add any found segment triggers to segment in fixed vector. */
				if (tmpSegTriggers.length > 0)
				{
					seg.triggers = new Vector.<RTTrigger>(tmpSegTriggers.length, true);
					seg.triggersNum = seg.triggers.length;
					for (i = 0; i < seg.triggersNum; i++)
					{
						seg.triggers[i] = tmpSegTriggers[i];
					}
				}
			}
			
			if (obj.type == RTObjectTypes.MARKER)
			{
				var id:String = obj.id.toLowerCase();
				if (id == "startline")
				{
					seg.colorSet = _rt.colorSetStart;
				}
				else if (id == "finishline")
				{
					seg.colorSet = _rt.colorSetFinish;
				}
			}
			
			seg.entities.push(e);
			++seg.entitiesNum;
			
			_rt.mapEntity(e);
		}
		
		
		/**
		 * @private
		 */
		private function addCars(collectionID:String, count:int, offsetRange:Array,
			speedFactor:int = 4):void
		{
			if (count < 1) return;
			else if (count >= _rt.maxCars) count = _rt.maxCars;
			var collection:RTObjectCollection = _rt.getCollection(collectionID);
			if (!collection) return;
			
			for (var i:uint = 0; i < count; i++)
			{
				var offset:Number = Math.random() * randomChoice(offsetRange);
				var z:int = int(Math.random() * _rt.segments.length) * _rt.segmentLength;
				var objectID:String = randomIDFromCollection(collection);
				var speedDiv:Number = (objectID == "spr_car_6" ? speedFactor : 2); // Slow speed for Semi Truck
				var speed:Number = _rt.maxSpeed / speedFactor + Math.random() * _rt.maxSpeed / speedDiv;
				addCar(objectID, offset, z, speed);
				++_carsCount;
			}
		}
		
		
		/**
		 * Adds a car entity to a racetrack segment that is dependant on the z value.
		 * 
		 * @param objectID
		 * @param offset
		 * @param z
		 * @param speed
		 */
		private function addCar(objectID:String, offset:Number, z:Number, speed:Number):void
		{
			var object:RTObject = _rt.getObject(objectID);
			if (!object) return;
			
			var car:RTCar = newCar(createEntityID(), object);
			car.carOffset = offset;
			car.carZ = z;
			car.carSpeed = speed;
			
			var segment:RTSegment = findSegment(car.carZ);
			segment.cars.push(car);
			_rt.cars.push(car);
			_rt.mapEntity(car);
		}
		
		
		/**
		 * @private
		 */
		private function newEntity(id:String, obj:RTObject, offsetX:Number = 0.0,
			scale:Number = NaN):RTEntity
		{
			var e:RTEntity = new RTEntity(id);
			e.object = obj;
			e.image = obj.image;
			e.width = obj.image ? obj.image.width : 0;
			e.height = obj.image ? obj.image.height : 0;
			e.pixelOffsetY = obj.pixelOffsetY;
			e.collectionID = obj.collectionID;
			e.type = obj.type;
			e.scale = scale || obj.scale;
			e.offsetX = offsetX;
			e.isOffroad = offsetX < -1 || offsetX > 1;
			e.offsetX2 = e.isOffroad ? (offsetX < 0.0 ? -1.0 : 0.0) : (offsetX - 0.5);
			// TODO Fix collision offset for offroad objects which isn't precise yet!
			e.offsetX3 = e.isOffroad ? (offsetX > 0.0 ? 0.5 : -0.5) : (offsetX);
			e.enabled = true;
			return e;
		}
		
		
		/**
		 * @private
		 */
		private function newCar(id:String, obj:RTObject, offsetX:Number = 0.0,
			scale:Number = NaN):RTCar
		{
			var c:RTCar = new RTCar(id);
			c.object = obj;
			c.image = obj.image;
			c.width = obj.image ? obj.image.width : 0;
			c.height = obj.image ? obj.image.height : 0;
			c.pixelOffsetY = obj.pixelOffsetY;
			c.collectionID = obj.collectionID;
			c.type = obj.type;
			c.scale = scale || obj.scale;
			c.offsetX = offsetX;
			c.isOffroad = offsetX < -1 || offsetX > 1;
			c.offsetX2 = c.isOffroad ? (offsetX < 0.0 ? -1.0 : 0.0) : (offsetX - 0.5);
			// TODO Fix collision offset for offroad objects which isn't precise yet!
			c.offsetX3 = c.isOffroad ? (offsetX > 0.0 ? 0.5 : -0.5) : (offsetX);
			c.enabled = true;
			return c;
		}
		
		
		// -----------------------------------------------------------------------------------------
		// ROAD GEOMETRY CONSTRUCTION
		// -----------------------------------------------------------------------------------------
		
		/**
		 * @private
		 */
		private function addStraight(length:int):void
		{
			addRoad(length, length, length, 0, 0);
		}
		
		
		/**
		 * @private
		 */
		private function addCurve(length:int, curve:int, height:int):void
		{
			addRoad(length, length, length, curve, height);
		}
		
		
		/**
		 * @private
		 */
		private function addSCurves(curveLength:int = 50, curveIn:int = 2, curveOut:int = 4,
			height:int = 0):void
		{
			addRoad(curveLength, curveLength, curveLength, -curveIn, height);
			addRoad(curveLength, curveLength, curveLength, curveOut, height);
			addRoad(curveLength, curveLength, curveLength, curveIn, height);
			addRoad(curveLength, curveLength, curveLength, -curveIn, height);
			addRoad(curveLength, curveLength, curveLength, -curveOut, height);
		}
		
		
		/**
		 * @private
		 */
		private function addHill(length:int, height:int):void
		{
			addRoad(length, length, length, 0, height);
		}
		
		
		/**
		 * @private
		 */
		private function addLowRollingHills(length:int, height:int, curve:int = 2):void
		{
			addRoad(length, length, length, 0, height / 2);
			addRoad(length, length, length, 0, -height);
			addRoad(length, length, length, curve, height);
			addRoad(length, length, length, 0, 0);
			addRoad(length, length, length, -curve, height / 2);
			addRoad(length, length, length, 0, 0);
		}
		
		
		/**
		 * @private
		 */
		private function addBumps():void
		{
			addRoad(10, 10, 10, 0, 5);
			addRoad(10, 10, 10, 0, -2);
			addRoad(10, 10, 10, 0, -5);
			addRoad(10, 10, 10, 0, 8);
			addRoad(10, 10, 10, 0, 5);
			addRoad(10, 10, 10, 0, -7);
			addRoad(10, 10, 10, 0, 5);
			addRoad(10, 10, 10, 0, -2);
		}
		
		
		/**
		 * @private
		 */
		private function addDownhillToEnd(length:int, curve:int):void
		{
			addRoad(length, length, length, curve, -lastY / _rt.segmentLength);
		}
		
		
		/**
		 * @private
		 */
		private function addRoad(enter:int, hold:int, leave:int, curve:Number, y:Number = NaN):void
		{
			var startY:Number = lastY;
			var endY:Number = startY + (int(y) * _rt.segmentLength);
			var total:uint = enter + hold + leave;
			var i:uint;

			for (i = 0; i < enter; i++)
			{
				addSegment(easeIn(0, curve, i / enter), easeInOut(startY, endY, i / total));
			}
			for (i = 0; i < hold; i++)
			{
				addSegment(curve, easeInOut(startY, endY, (enter + i) / total));
			}
			for (i = 0; i < leave; i++)
			{
				addSegment(easeInOut(curve, 0, i / leave), easeInOut(startY, endY, (enter + hold + i) / total));
			}
		}
		
		
		/**
		 * @private
		 */
		private function addSegment(curve:Number, y:Number):void
		{
			var i:uint = _rt.segments.length;
			var segment:RTSegment = new RTSegment();
			segment.index = i;
			segment.point1 = new RTPoint(new RTWorld(lastY, i * _rt.segmentLength), new RTCamera(), new RTScreen());
			segment.point2 = new RTPoint(new RTWorld(y, (i + 1) * _rt.segmentLength), new RTCamera(), new RTScreen());
			segment.curve = curve;
			segment.cars = new Vector.<RTCar>();
			segment.colorSet = int(i / _rt.rumbleLength) % 2 ? _rt.colorSetDark : _rt.colorSetLight;
			_rt.segments.push(segment);
			++_segmentCount;
		}
		
		
		/**
		 * @private
		 */
		private function error(message:String):*
		{
			Log.error(message, this);
			return null;
		}
		
		
		// -----------------------------------------------------------------------------------------
		// Util Functions
		// -----------------------------------------------------------------------------------------
		
		/**
		 * @private
		 */
		private function createEntityID():String
		{
			return "entity" + _rt.entityCount;
		}
		
		
		/**
		 * @private
		 */
		private function getTextureAtlas(atlasID:String):Atlas
		{
			var atlas:Atlas = resourceManager.process(atlasID);
			if (atlas) return atlas;
			return error("No texture atlas found with ID " + atlasID + "!");
		}
		
		
		private function findSegment(z:Number):RTSegment
		{
			return _rt.segments[int(z / _rt.segmentLength) % _rt.segments.length];
		}
		
		
		private function randomInt(min:int, max:int):int
		{
			return mathRound(interpolate(min, max, Math.random()));
		}
		
		
		private function randomNumber(range:Array):Number
		{
			if (!range) return 0.0;
			return interpolate(Number(range[0]), Number(range[1]), Math.random());
		}
		
		
		private function randomChoice(a:Array):*
		{
			return a[randomInt(0, a.length - 1)];
		}
		
		
		//private function randomChoiceFromCollection(c:RTObjectCollection):RTObject
		//{
		//	return c.objects[randomInt(0, c.objects.length - 1)];
		//}
		
		
		private function randomIDFromCollection(c:RTObjectCollection):String
		{
			return c.objects[randomInt(0, c.objects.length - 1)].id;
		}
		
		
		private function mathRound(n:Number):int
		{
			return n + (n < 0 ? -0.5 : +0.5) >> 0;
		}
		
		
		private function interpolate(a:Number, b:Number, percent:Number):Number
		{
			return a + (b - a) * percent;
		}
		
		
		private function easeIn(a:Number, b:Number, percent:Number):Number
		{
			return a + (b - a) * Math.pow(percent, 2);
		}


		//private static function easeOut(a:Number, b:Number, percent:Number):Number
		//{
		//	return a + (b - a) * (1 - Math.pow(1 - percent, 2));
		//}
		
		
		private function easeInOut(a:Number, b:Number, percent:Number):Number
		{
			return a + (b - a) * ((-Math.cos(percent * 3.141592653589793) / 2) + 0.5);
		}
	}
}
