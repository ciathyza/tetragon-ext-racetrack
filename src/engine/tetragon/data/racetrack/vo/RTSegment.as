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
	import tetragon.data.racetrack.proto.RTTrigger;
	/**
	 * Defines a single segment of a racetrack.
	 * 
	 * @author Hexagon
	 */
	public class RTSegment
	{
		/**
		 * The index of the segment in the segments list.
		 */
		public var index:int;
		
		/**
		 * The start coordinate point of the segment.
		 */
		public var point1:RTPoint;
		
		/**
		 * The end coordinate point of the segment.
		 */
		public var point2:RTPoint;
		
		/**
		 * The list of entities that are placed on the segment. This property
		 * is null if the segment has no entities placed on it.
		 */
		public var entities:Vector.<RTEntity>;
		
		/**
		 * Number of triggers.
		 */
		public var entitiesNum:uint;
		
		/**
		 * The list of cars that are on the segment.
		 * TODO Replace with faster linked list because cars are often removed and added
		 * from/to a segment!
		 */
		public var cars:Vector.<RTCar>;
		
		/**
		 * Segment-based triggers. Null if no triggers are assigned to the segment.
		 */
		public var triggers:Vector.<RTTrigger>;
		
		/**
		 * Number of triggers.
		 */
		public var triggersNum:uint;
		
		/**
		 * The color set that makes up the appearance of the segment.
		 */
		public var colorSet:RTColorSet;
		
		/**
		 * The curve value of the segment.
		 */
		public var curve:Number;
		
		/**
		 * The exponential haze value of the segment.
		 * Set by the racetrack system dynamically!
		 */
		public var haze:Number;
		
		/**
		 * Clip value used to determine clipping of entities.
		 * Set by the racetrack system dynamically!
		 */
		public var clip:Number;
		
		/**
		 * Determines whether the segment is looped or not. A segment is looped if it's
		 * index is smaller than the base segment index. This influences the projected
		 * cameraZ value of the segment. Set by the racetrack system dynamically!
		 */
		public var looped:Boolean;
	}
}
