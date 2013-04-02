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
package tetragon.data.racetrack.vo
{
	import tetragon.data.racetrack.proto.RTObject;
	
	
	/**
	 * @author Hexagon
	 */
	public class RTEntity
	{
		//-----------------------------------------------------------------------------------------
		// Properties
		//-----------------------------------------------------------------------------------------
		
		public var object:RTObject;
		public var collectionID:String;
		public var width:Number;
		public var height:Number;
		public var type:String;
		public var offsetX:Number;
		public var offsetX2:Number;
		public var offsetX3:Number;
		public var pixelOffsetY:int;
		public var scale:Number;
		public var isOffroad:Boolean;
		public var enabled:Boolean;
		
		
		//-----------------------------------------------------------------------------------------
		// Constructor
		//-----------------------------------------------------------------------------------------
		
		public function RTEntity(obj:RTObject, offsetX:Number = 0.0, scale:Number = NaN)
		{
			object = obj;
			width = object.image ? object.image.width : 0;
			height = object.image ? object.image.height : 0;
			pixelOffsetY = object.pixelOffsetY;
			collectionID = object.collectionID;
			type = object.type;
			this.offsetX = offsetX;
			this.scale = scale || obj.scale;
			isOffroad = offsetX < -1 || offsetX > 1;
			offsetX2 = isOffroad ? (offsetX < 0.0 ? -1.0 : 0.0) : (offsetX - 0.5);
			offsetX3 = isOffroad ? (offsetX > 0.0 ? 1.0 : -1.0) : (offsetX);
			enabled = true;
		}
	}
}
