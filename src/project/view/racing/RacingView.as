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
package view.racing
{
	import tetragon.BuildType;
	import tetragon.systems.racetrack.RacetrackSystem;
	import tetragon.view.display.rendercanvas.GPURenderCanvas;
	import tetragon.view.render2d.display.Rect2D;
	import tetragon.view.render2d.display.View2D;
	import tetragon.view.render2d.events.TouchEvent2D;
	import tetragon.view.render2d.touch.Touch2D;
	import tetragon.view.render2d.touch.TouchPhase2D;
	
	
	/**
	 * @author hexagon
	 */
	public class RacingView extends View2D
	{
		// -----------------------------------------------------------------------------------------
		// Properties
		// -----------------------------------------------------------------------------------------
		
		private var _renderCanvas:GPURenderCanvas;
		private var _rectL:Rect2D;
		private var _rectR:Rect2D;
		
		private var _racetrackSystem:RacetrackSystem;
		
		
		// -----------------------------------------------------------------------------------------
		// Public Methods
		// -----------------------------------------------------------------------------------------
		
		
		// -----------------------------------------------------------------------------------------
		// Accessors
		// -----------------------------------------------------------------------------------------
		
		public function get renderCanvas():GPURenderCanvas
		{
			return _renderCanvas;
		}
		
		
		public function get racetrackSystem():RacetrackSystem
		{
			return _racetrackSystem;
		}
		public function set racetrackSystem(v:RacetrackSystem):void
		{
			_racetrackSystem = v;
		}
		
		
		// -----------------------------------------------------------------------------------------
		// Callback Handlers
		// -----------------------------------------------------------------------------------------
		
		private function onTouch(e:TouchEvent2D):void
		{
			if (!_racetrackSystem) return;
			
			_racetrackSystem.isAccelerating = true;
			
			var touch:Touch2D = e.getTouch(stage);
			if (!touch || !touch.target) return;
			var target:String = (touch.target as Rect2D).name;
			
			if (touch.phase == TouchPhase2D.BEGAN)
			{
				if (target == "left")
				{
					_racetrackSystem.isSteeringLeft = true;
					_racetrackSystem.isSteeringRight = false;
				}
				else if (target == "right")
				{
					_racetrackSystem.isSteeringLeft = false;
					_racetrackSystem.isSteeringRight = true;
				}
			}
			else if (touch.phase == TouchPhase2D.ENDED)
			{
				_racetrackSystem.isSteeringLeft = false;
				_racetrackSystem.isSteeringRight = false;
			}
		}
		
		
		// -----------------------------------------------------------------------------------------
		// Private Methods
		// -----------------------------------------------------------------------------------------
		
		/**
		 * @inheritDoc
		 */
		override protected function setup():void
		{
			_renderCanvas = new GPURenderCanvas(stageWidth, stageHeight);
			addChild(_renderCanvas);
			
			if (main.appInfo.buildType == BuildType.IOS
				|| main.appInfo.buildType == BuildType.ANDROID)
			{
				_rectL = new Rect2D(300, refHeight, 0xFF00FF);
				_rectL.name = "left";
				_rectL.alpha = 0.0;
				_rectL.x = 0;
				_rectL.y = 0;
				_rectL.addEventListener(TouchEvent2D.TOUCH, onTouch);
				_rectR = new Rect2D(300, refHeight, 0xFF00FF);
				_rectR.name = "right";
				_rectR.alpha = 0.0;
				_rectR.x = refWidth - _rectR.width;
				_rectR.y = 0;
				_rectR.addEventListener(TouchEvent2D.TOUCH, onTouch);
				addChild(_rectL);
				addChild(_rectR);
			}
		}
		
		
		/**
		 * @inheritDoc
		 */
		override protected function executeBeforeRender():void
		{
		}
	}
}
