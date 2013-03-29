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
package view.racing
{
	import modules.audio.AudioManager;

	import tetragon.data.racetrack.Racetrack;
	import tetragon.debug.Log;
	import tetragon.input.KeyMode;
	import tetragon.systems.racetrack.RacetrackFactory;
	import tetragon.systems.racetrack.RacetrackSystem;
	import tetragon.view.Screen;
	import tetragon.view.render2d.core.Render2D;

	import flash.media.Sound;
	import flash.utils.Dictionary;
	
	
	/**
	 * @author Hexagon
	 */
	public class RacingScreen extends Screen
	{
		// -----------------------------------------------------------------------------------------
		// Constants
		// -----------------------------------------------------------------------------------------
		
		public static const ID:String = "racingScreen";
		
		
		// -----------------------------------------------------------------------------------------
		// Properties
		// -----------------------------------------------------------------------------------------
		
		private var _render2D:Render2D;
		private var _rootView:RacingView;
		
		private var _racetrackSystem:RacetrackSystem;
		private var _racetrackFactory:RacetrackFactory;
		private var _racetrack:Racetrack;
		
		private var _width:int;
		private var _height:int;
		
		private var _audioManager:AudioManager;
		private var _sounds:Dictionary;
		
		
		// -----------------------------------------------------------------------------------------
		// Signals
		// -----------------------------------------------------------------------------------------
		
		
		// -----------------------------------------------------------------------------------------
		// Public Methods
		// -----------------------------------------------------------------------------------------
		
		/**
		 * @inheritDoc
		 */
		override public function start():void
		{
			super.start();
			
			main.keyInputManager.assign("CURSORUP", KeyMode.DOWN, onKeyDown, "u");
			main.keyInputManager.assign("CURSORDOWN", KeyMode.DOWN, onKeyDown, "d");
			main.keyInputManager.assign("CURSORLEFT", KeyMode.DOWN, onKeyDown, "l");
			main.keyInputManager.assign("CURSORRIGHT", KeyMode.DOWN, onKeyDown, "r");
			main.keyInputManager.assign("SPACE", KeyMode.DOWN, onKeyDown, "space");
			main.keyInputManager.assign("CURSORUP", KeyMode.UP, onKeyUp, "u");
			main.keyInputManager.assign("CURSORDOWN", KeyMode.UP, onKeyUp, "d");
			main.keyInputManager.assign("CURSORLEFT", KeyMode.UP, onKeyUp, "l");
			main.keyInputManager.assign("CURSORRIGHT", KeyMode.UP, onKeyUp, "r");
			
			var music:Sound = getResource("music");
			_audioManager.playSound(music, AudioManager.MAX_LOOPS, 0.7);
			
			_racetrackSystem.start();
		}
		
		
		/**
		 * @inheritDoc
		 */
		override public function update():void
		{
			super.update();
		}
		
		
		/**
		 * @inheritDoc
		 */
		override public function reset():void
		{
			super.reset();
			if (_racetrackSystem) _racetrackSystem.reset();
		}
		
		
		/**
		 * @inheritDoc
		 */
		override public function stop():void
		{
			super.stop();
			main.gameLoop.stop();
		}
		
		
		/**
		 * @inheritDoc
		 */
		override public function dispose():void
		{
			super.dispose();
			if (_racetrackSystem) _racetrackSystem.dispose();
			_render2D.dispose();
		}
		
		
		// -----------------------------------------------------------------------------------------
		// Accessors
		// -----------------------------------------------------------------------------------------
		
		/**
		 * @inheritDoc
		 */
		override protected function get unload():Boolean
		{
			return true;
		}
		
		
		// -----------------------------------------------------------------------------------------
		// Callback Handlers
		// -----------------------------------------------------------------------------------------
		
		/**
		 * @inheritDoc
		 */
		override protected function onStageResize():void
		{
			super.onStageResize();
		}
		
		
		/**
		 * @private
		 */
		private function onEnterFrame():void
		{
			_racetrackSystem.updateTimer();
		}
		
		
		/**
		 * @private
		 */
		private function onTick():void
		{
			_racetrackSystem.tick();
		}
		
		
		/**
		 * @private
		 */
		private function onRender(ticks:uint, ms:uint, fps:uint):void
		{
			_racetrackSystem.render();
			_render2D.render();
		}
		
		
		/**
		 * @private
		 */
		private function onKeyDown(key:String):void
		{
			if (!_racetrackSystem) return;
			switch (key)
			{
				case "u":
					_racetrackSystem.isAccelerating = true;
					break;
				case "d":
					_racetrackSystem.isBraking = true;
					break;
				case "l":
					_racetrackSystem.isSteeringLeft = true;
					break;
				case "r":
					_racetrackSystem.isSteeringRight = true;
					break;
				case "space":
					_racetrackSystem.jump();
					break;
			}
		}
		
		
		/**
		 * @private
		 */
		private function onKeyUp(key:String):void
		{
			if (!_racetrackSystem) return;
			switch (key)
			{
				case "u":
					_racetrackSystem.isAccelerating = false;
					break;
				case "d":
					_racetrackSystem.isBraking = false;
					break;
				case "l":
					_racetrackSystem.isSteeringLeft = false;
					break;
				case "r":
					_racetrackSystem.isSteeringRight = false;
					break;
			}
		}
		
		
		private function onRTPlaySound(soundID:String):void
		{
			var sound:Sound = _sounds[soundID];
			if (sound) _audioManager.playSound(sound);
		}
		
		
		private function onRTChangeScore(score:int):void
		{
			Log.trace("Adding score: " + score, this);
		}
		
		
		private function onRTLap(lap:uint, lapTime:uint, fastest:Boolean):void
		{
			var time:Number = lapTime / 1000;
			Log.trace("Lap Nr. " + lap + " (time: " + time + ", fastest: " + fastest + ")", this);
		}
		
		
		// -----------------------------------------------------------------------------------------
		// Private Methods
		// -----------------------------------------------------------------------------------------
		/**
		 * @inheritDoc
		 */
		override protected function setup():void
		{
			super.setup();
			
			_audioManager = main.moduleManager.getModule(AudioManager.defaultID);
			
			_width = main.stage.stageWidth;
			_height = main.stage.stageHeight;
			_render2D = screenManager.render2D;
			_render2D.antiAliasing = 0;
		}


		/**
		 * @inheritDoc
		 */
		override protected function registerResources():void
		{
			registerResource("racetrackLevels");
			registerResource("sounds");
			registerResource("music");
		}
		
		
		/**
		 * @inheritDoc
		 */
		override protected function createChildren():void
		{
			/* Prepare sounds. */
			_sounds = new Dictionary();
			_sounds["checkpointSound"] = getResource("soundCheckpoint");
			_sounds["ringCollectSound"] = getResource("soundRing");
			
			_rootView = new RacingView();
			_render2D.rootView = _rootView;
			
			_racetrackFactory = new RacetrackFactory("racetrackLevels");
			_racetrack = _racetrackFactory.createRacetrack("demoLevel");
			
			_racetrackSystem = new RacetrackSystem(_width, _height, _racetrack);
			_racetrackSystem.renderCanvas = _rootView.renderCanvas;
			
			_rootView.racetrackSystem = _racetrackSystem;
		}
		
		
		/**
		 * @inheritDoc
		 */
		override protected function registerChildren():void
		{
		}


		/**
		 * @inheritDoc
		 */
		override protected function addChildren():void
		{
		}


		/**
		 * @inheritDoc
		 */
		override protected function addListeners():void
		{
			main.gameLoop.enterFrameSignal.add(onEnterFrame);
			main.gameLoop.tickSignal.add(onTick);
			main.gameLoop.renderSignal.add(onRender);
			_racetrackSystem.playSoundSignal.add(onRTPlaySound);
			_racetrackSystem.changeScoreSignal.add(onRTChangeScore);
			_racetrackSystem.lapSignal.add(onRTLap);
		}
		
		
		/**
		 * @inheritDoc
		 */
		override protected function removeListeners():void
		{
			main.gameLoop.enterFrameSignal.remove(onEnterFrame);
			main.gameLoop.tickSignal.remove(onTick);
			main.gameLoop.renderSignal.remove(onRender);
			_racetrackSystem.playSoundSignal.remove(onRTPlaySound);
			_racetrackSystem.changeScoreSignal.remove(onRTChangeScore);
			_racetrackSystem.lapSignal.remove(onRTLap);
		}


		/**
		 * @inheritDoc
		 */
		override protected function executeBeforeStart():void
		{
			main.statsMonitor.toggle();
			reset();
			_render2D.start();
			main.gameLoop.start();
		}


		/**
		 * @inheritDoc
		 */
		override protected function updateDisplayText():void
		{
		}


		/**
		 * @inheritDoc
		 */
		override protected function layoutChildren():void
		{
		}
	}
}
