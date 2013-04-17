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
	import tetragon.data.DataObject;
	import tetragon.data.racetrack.proto.RTObject;
	import tetragon.data.racetrack.proto.RTObjectImageSequence;
	import tetragon.data.racetrack.proto.RTObjectState;
	import tetragon.view.render2d.display.Image2D;
	import tetragon.view.render2d.display.MovieClip2D;
	import tetragon.view.render2d.events.Event2D;

	import com.hexagonstar.signals.Signal;
	import com.hexagonstar.time.Interval;
	
	
	/**
	 * @author Hexagon
	 */
	public class RTEntity extends DataObject
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
		public var isColliding:Boolean;
		public var enabled:Boolean;
		
		public var image:Image2D;
		
		/*
		 * Properties used for state changes.
		 */
		public var interval:Interval;
		public var currentState:RTObjectState;
		public var currentStateID:String;
		public var currentSequence:RTObjectImageSequence;
		public var sequenceCompleteSignal:Signal;
		public var completeCallback:Function;
		public var completeCallbackDelay:Number;
		
		
		//-----------------------------------------------------------------------------------------
		// Constructor
		//-----------------------------------------------------------------------------------------
		
		public function RTEntity(id:String)
		{
			_id = id;
		}
		
		
		//-----------------------------------------------------------------------------------------
		// Public Methods
		//-----------------------------------------------------------------------------------------
		
		/**
		 * @inheritDoc
		 */
		override public function dispose():void
		{
			if (currentSequence && currentSequence.movieClip)
			{
				currentSequence.movieClip.removeEventListener(Event2D.COMPLETE, onSequenceComplete);
				currentSequence = null;
			}
			if (sequenceCompleteSignal)
			{
				sequenceCompleteSignal.removeAll();
				sequenceCompleteSignal = null;
			}
			if (interval)
			{
				interval.dispose();
				interval = null;
			}
			completeCallback = null;
		}
		
		
		//-----------------------------------------------------------------------------------------
		// Callback Handlers
		//-----------------------------------------------------------------------------------------
		
		/**
		 * @private
		 */
		public function onSequenceComplete(e:Event2D):void
		{
			var mc:MovieClip2D = e.currentTarget as MovieClip2D;
			mc.removeEventListener(Event2D.COMPLETE, onSequenceComplete);
			sequenceCompleteSignal.dispatch(this);
		}
	}
}
