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
	import tetragon.view.render2d.animation.Juggler2D;
	import tetragon.view.render2d.display.Image2D;
	import tetragon.view.render2d.display.MovieClip2D;
	import tetragon.view.render2d.events.Event2D;

	import com.hexagonstar.signals.Signal;
	import com.hexagonstar.time.Interval;

	import flash.utils.Dictionary;
	
	
	/**
	 * @author Hexagon
	 */
	public class RTObject extends DataObject
	{
		//-----------------------------------------------------------------------------------------
		// Properties
		//-----------------------------------------------------------------------------------------
		
		public static var juggler:Juggler2D;
		
		public var collectionID:String;
		public var defaultStateID:String;
		public var defaultFramerate:int;
		public var collisionGrace:Number;
		public var imageID:String;
		public var image:Image2D;
		public var type:String;
		public var scale:Number;
		public var pixelOffsetY:Number;
		public var isPlayer:Boolean;
		
		/**
		 * Maps object states.
		 */
		public var states:Dictionary;
		public var statesNum:int;
		
		/**
		 * A map of RTObjectImageSequence objects.
		 */
		public var sequences:Dictionary;
		public var sequencesNum:uint;
		
		/**
		 * Maps object-specific properties.
		 */
		public var properties:Dictionary;
		public var propertiesNum:uint;
		
		/**
		 * An array of RTTrigger objects.
		 */
		public var triggers:Vector.<RTTrigger>;
		public var triggersNum:uint;
		
		/**
		 * Properties used for state changes.
		 */
		public var interval:Interval;
		public var currentState:RTObjectState;
		public var currentStateID:String;
		public var currentSequence:RTObjectImageSequence;
		public var sequenceCompleteSignal:Signal;
		
		
		//-----------------------------------------------------------------------------------------
		// Constructor
		//-----------------------------------------------------------------------------------------
		
		/**
		 * Creates a new instance of the class.
		 */
		public function RTObject(id:String)
		{
			_id = id;
		}
		
		
		//-----------------------------------------------------------------------------------------
		// Public Methods
		//-----------------------------------------------------------------------------------------
		
		/**
		 * Switches the object to the specified state.
		 * 
		 * @param stateID
		 * @return 1, 0, -1, or -2.
		 */
		public function switchToState(stateID:String):int
		{
			if (!states || stateID == currentStateID || stateID == null || stateID == "") return 0;
			
			var state:RTObjectState = states[stateID];
			if (!state) return -1;
			
			currentStateID = stateID;
			currentState = state;
			
			var seq:RTObjectImageSequence = sequences[state.sequenceID];
			if (!seq) return -2;
			
			/* Disable any currenlty used anim seq. */
			if (image is MovieClip2D)
			{
				(image as MovieClip2D).stop();
				juggler.remove(image as MovieClip2D);
			}
			
			currentSequence = seq;
			
			if (currentSequence.movieClip)
			{
				if (sequenceCompleteSignal && !currentSequence.movieClip.loop)
				{
					currentSequence.movieClip.addEventListener(Event2D.COMPLETE, onSequenceComplete);
				}
				juggler.add(currentSequence.movieClip);
				currentSequence.movieClip.play();
				image = currentSequence.movieClip;
				return 1;
			}
			else if (currentSequence.image)
			{
				image = currentSequence.image;
				return 1;
			}
			
			/* State switching failed! */
			if (currentSequence.movieClip)
			{
				currentSequence.movieClip.removeEventListener(Event2D.COMPLETE, onSequenceComplete);
			}
			return 0;
		}
		
		
		/**
		 * Changes the framerate of the currently played anim sequence.
		 * 
		 * @param fps
		 */
		public function changeAnimFramerate(fps:int):void
		{
			if (!currentSequence || !currentSequence.movieClip) return;
			if (fps < 1) fps = 1;
			else if (fps > 60) fps = 60;
			currentSequence.movieClip.fps = fps;
		}
		
		
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
		}
		
		
		//-----------------------------------------------------------------------------------------
		// Callback Handlers
		//-----------------------------------------------------------------------------------------
		
		/**
		 * @private
		 */
		private function onSequenceComplete(e:Event2D):void
		{
			var mc:MovieClip2D = e.currentTarget as MovieClip2D;
			mc.removeEventListener(Event2D.COMPLETE, onSequenceComplete);
			sequenceCompleteSignal.dispatch(this);
		}
	}
}
