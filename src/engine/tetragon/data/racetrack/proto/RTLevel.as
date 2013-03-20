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
package tetragon.data.racetrack.proto
{
	import tetragon.data.DataObject;
	import tetragon.data.racetrack.vo.RTColorSet;

	import com.hexagonstar.types.KeyValuePair;
	
	
	/**
	 * Prototype value object for a racetrack level.
	 *
	 * @author Hexagon
	 */
	public class RTLevel extends DataObject
	{
		//-----------------------------------------------------------------------------------------
		// Properties
		//-----------------------------------------------------------------------------------------
		
		public var objectsCatalogID:String;
		public var nameID:String;
		public var lanes:int;
		public var hazeDensity:int;
		
		public var colorSetLight:RTColorSet;
		public var colorSetDark:RTColorSet;
		public var colorSetStart:RTColorSet;
		public var colorSetFinish:RTColorSet;
		public var colorHaze:uint;
		public var colorSky:uint;
		
		public var backgroundTextureAtlasID:String;
		public var backgroundLayerIDs:Vector.<KeyValuePair>;
		
		public var roadSections:Vector.<RTRoadSection>;
		public var entityDistributionDefs:Vector.<RTEntityDistributionDef>;
		public var opponentDistributionDefs:Vector.<RTOpponentDistributionDef>;
		
		
		//-----------------------------------------------------------------------------------------
		// Constructor
		//-----------------------------------------------------------------------------------------
		
		/**
		 * Creates a new instance of the class.
		 */
		public function RTLevel(id:String)
		{
			_id = id;
		}
	}
}
