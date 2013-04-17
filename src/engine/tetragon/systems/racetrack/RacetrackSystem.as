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
	import tetragon.Main;
	import tetragon.data.racetrack.Racetrack;
	import tetragon.data.racetrack.constants.RTObjectPropertyNames;
	import tetragon.data.racetrack.constants.RTObjectTypes;
	import tetragon.data.racetrack.constants.RTPlayerDefaultStateNames;
	import tetragon.data.racetrack.constants.RTTriggerActions;
	import tetragon.data.racetrack.constants.RTTriggerTypes;
	import tetragon.data.racetrack.proto.RTObject;
	import tetragon.data.racetrack.proto.RTTrigger;
	import tetragon.data.racetrack.vo.RTCar;
	import tetragon.data.racetrack.vo.RTColorSet;
	import tetragon.data.racetrack.vo.RTEntity;
	import tetragon.data.racetrack.vo.RTPoint;
	import tetragon.data.racetrack.vo.RTSegment;
	import tetragon.debug.Log;
	import tetragon.signals.RTChangeBonusSignal;
	import tetragon.signals.RTChangeHealthSignal;
	import tetragon.signals.RTChangeScoreSignal;
	import tetragon.signals.RTChangeTimeSignal;
	import tetragon.signals.RTCheckPointSignal;
	import tetragon.signals.RTCompleteLevelSignal;
	import tetragon.signals.RTDisablePlayerSignal;
	import tetragon.signals.RTLapSignal;
	import tetragon.signals.RTPlaySoundSignal;
	import tetragon.signals.RTProgressSignal;
	import tetragon.systems.ISystem;
	import tetragon.view.render.canvas.IRenderCanvas;
	import tetragon.view.render2d.animation.Transitions2D;
	import tetragon.view.render2d.animation.Tween2D;
	import tetragon.view.render2d.display.Image2D;
	import tetragon.view.render2d.display.Rect2D;
	import tetragon.view.render2d.extensions.scrollimage.ScrollImage2D;
	import tetragon.view.render2d.extensions.scrollimage.ScrollTile2D;

	import com.hexagonstar.signals.Signal;
	import com.hexagonstar.time.Interval;

	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	
	/**
	 * @author Hexagon
	 */
	public class RacetrackSystem implements ISystem
	{
		//-----------------------------------------------------------------------------------------
		// Constants
		//-----------------------------------------------------------------------------------------
		
		public static const SYSTEM_ID:String = "racetrackSystem";
		
		
		// -----------------------------------------------------------------------------------------
		// Properties
		// -----------------------------------------------------------------------------------------
		
		private var _renderCanvas:IRenderCanvas;
		
		private var _bgScroller:ScrollImage2D;
		private var _bgScrollOffset:Number;
		private var _bgScrollPrevX:Number;
		//private var _bgScrollPrevY:Number;
		
		private var _racetrack:Racetrack;
		private var _prevSegment:RTSegment;
		private var _interval:Interval;
		
		private var _width:int;
		private var _height:int;
		private var _widthHalf:int;
		private var _heightHalf:int;
		
		private var _resolution:Number;			// scaling factor to provide resolution independence (computed)
		private var _drawDistance:int;			// number of segments to draw
		private var _bgSpeedMult:Number;
		
		private var _playerX:Number;			// player x offset from center of road (-1 to 1 to stay independent of roadWidth)
		private var _playerY:int;				// player x offset from center of road (-1 to 1 to stay independent of roadWidth)
		private var _playerZ:Number;			// player relative z distance from camera (computed)
		
		private var _playerOffsetX:Number;
		private var _playerOffsetY:Number;
		private var _playerJumpHeight:Number;
		private var _playerWidth:Number;
		private var _playerFPS:int;
		
		private var _startPosition:Number;
		private var _position:Number;			// current camera Z position (add playerZ to get player's absolute Z position)
		private var _prevPosition:Number;
		private var _playerSpeed:Number;				// current speed
		private var _playerSpeedPercent:Number;
		private var _playerSpeedCollision:Number;
		
		private var _progress:int;
		private var _progressTotal:int;
		
		private var _currentLap:uint;
		private var _startTime:uint;
		private var _currentLapTime:uint;		// current lap time
		private var _lastLapTime:uint;			// last lap time
		private var _fastestLapTime:uint;
		
		private var _enableCollision:Boolean;
		private var _enableControls:Boolean;
		private var _isAccelerating:Boolean;
		private var _isBraking:Boolean;
		private var _isSteeringLeft:Boolean;
		private var _isSteeringRight:Boolean;
		private var _isJump:Boolean;
		private var _isFall:Boolean;
		
		private var _playerEnabled:Boolean;
		private var _idleAfterCollision:Boolean;
		private var _suppressDefaultPlayerStates:Boolean;
		
		private var _started:Boolean;
		
		/* Racetrack properties */
		private var _roadWidth:int;
		private var _segmentLength:int;
		private var _trackLength:int;
		private var _lanes:int;
		private var _hazeDensity:int;
		private var _hazeColor:uint;
		private var _hazeThreshold:Number;
		private var _acceleration:Number;
		private var _deceleration:Number;
		private var _braking:Number;
		private var _offRoadDecel:Number;
		private var _offRoadLimit:Number;
		private var _centrifugal:Number;
		private var _maxSpeed:Number;
		private var _dt:Number;
		private var _fov:int;
		private var _cameraAltitude:Number;
		private var _cameraDepth:Number;
		private var _segments:Vector.<RTSegment>;
		private var _cars:Vector.<RTCar>;
		private var _carsNum:uint;
		private var _objects:Dictionary	;
		private var _objectScale:Number;
		
		private var _boundingBox:Rect2D;
		
		
		// -----------------------------------------------------------------------------------------
		// Signals
		// -----------------------------------------------------------------------------------------
		
		private var _playSoundSignal:RTPlaySoundSignal;
		private var _changeScoreSignal:RTChangeScoreSignal;
		private var _changeBonusSignal:RTChangeBonusSignal;
		private var _changeTimeSignal:RTChangeTimeSignal;
		private var _changeHealthSignal:RTChangeHealthSignal;
		private var _disablePlayerSignal:RTDisablePlayerSignal;
		private var _lapSignal:RTLapSignal;
		private var _completeLevelSignal:RTCompleteLevelSignal;
		private var _progressSignal:RTProgressSignal;
		private var _checkPointSignal:RTCheckPointSignal;
		
		
		//-----------------------------------------------------------------------------------------
		// Constructor
		//-----------------------------------------------------------------------------------------
		
		/**
		 * Creates a new instance of the class.
		 * 
		 * @param width
		 * @param height
		 * @param racetrack
		 */
		public function RacetrackSystem(width:int, height:int, racetrack:Racetrack,
			renderCanvas:IRenderCanvas = null)
		{
			Main.instance.classRegistry.registerSystem(SYSTEM_ID, this);
			
			_width = width;
			_height = height;
			_renderCanvas = renderCanvas;
			
			setup();
			
			this.racetrack = racetrack;
		}
		
		
		// -----------------------------------------------------------------------------------------
		// Public Methods
		// -----------------------------------------------------------------------------------------
		
		/**
		 * Starts the racetrack system.
		 */
		public function start():void
		{
			_started = true;
			_startTime = getTimer();
		}
		
		
		/**
		 * Stops the racetrack system.
		 */
		public function stop():void
		{
			_started = false;
			if (_interval) _interval.stop();
		}
		
		
		/**
		 * @inheritDoc
		 */
		public function reset():void
		{
			stop();
			
			_playerOffsetX = -0.5;
			_playerOffsetY = -1.0;
			_playerFPS = 12;
			
			_resolution = 1.6; // _bufferHeight / _bufferHeight;
			_startPosition = 0;
			_position = 0;
			_prevPosition = -1;
			_playerSpeed = 0;
			_playerSpeedCollision = 0;
			_widthHalf = _width * 0.5;
			_heightHalf = _height * 0.5;
			_bgScrollOffset = 0.0;
			
			_progress = 0;
			_progressTotal = _racetrack ? _racetrack.segmentsNum : 0;
			
			_currentLap = 1;
			_startTime = 0;
			_currentLapTime = 0;
			_lastLapTime = 0;
			_fastestLapTime = 0;
			
			_enableControls = true;
			_enableCollision = true;
			_playerEnabled = true;
			_suppressDefaultPlayerStates = false;
		}
		
		
		/**
		 * Switches an object to a specific state.
		 * 
		 * @param objectID
		 * @param stateID
		 * @param duration
		 * @param completeCallback
		 */
		public function setObjectState(objectID:String, stateID:String, duration:Number = 0.0,
			completeCallback:Function = null, callbackDelay:Number = 0.0):void
		{
			var object:RTObject = _racetrack.objects[objectID];
			if (!object) return;
			if (object.interval) object.interval.reset();
			changeObjectState(object, stateID, duration, completeCallback, callbackDelay);
		}
		
		
		/**
		 * Tweens the player entity horizontally on the screen. The centered offset is -0.5.
		 * An offset of -2.0 would place the player outside the screen.
		 * 
		 * @param startX
		 * @param endX
		 * @param duration
		 */
		public function tweenPlayer(startX:Number, endX:Number = -0.5, duration:Number = 1.0):void
		{
			_playerOffsetX = startX;
			var tween:Tween2D = new Tween2D(this, duration, Transitions2D.EASE_IN_OUT);
			tween.animate("playerOffsetX", endX);
			RTObject.juggler.add(tween);
			tween.onComplete = function():void
			{
				RTObject.juggler.remove(tween);
			};
		}
		
		
		public function updateTimer():void
		{
			if (!_started || _position <= _playerZ) return;
			
			/* Reached the finish line. */
			if (_currentLapTime > 0 && (_startPosition < _playerZ))
			{
				_lastLapTime = _currentLapTime;
				_startTime = _currentLapTime;
				_currentLapTime = 0;
				var fastest:Boolean = false;
				/* New fastest lap! */
				if (_lastLapTime < _fastestLapTime)
				{
					_fastestLapTime = _lastLapTime;
					fastest = true;
				}
				else
				{
				}
				
				if (_lapSignal) _lapSignal.dispatch(_currentLap, _lastLapTime, fastest);
				++_currentLap;
			}
			else
			{
				_currentLapTime = getTimer() - _startTime;
			}
		}
		
		/**
		 * Ticks the racetrack system's non-render logic.
		 */
		public function tick():void
		{
			/* only process non-render logic if system is started. */
			if (!_started) return;
			
			var i:int, playerSegment:RTSegment = findSegment(_position + _playerZ);
			
			_playerSpeedPercent = _playerSpeed / _maxSpeed;
			_startPosition = _position;
			_position = increase(_position, _dt * _playerSpeed, _trackLength);
			
			updateCars(playerSegment, _playerWidth);
			
			/* Handle player interaction. */
			if (_playerEnabled)
			{
				processPlayerControls(playerSegment);
			}
			
			/* Check if the segment the player is on has any triggers. */
			if (playerSegment.triggersNum > 0)
			{
				processSegmentTriggers(playerSegment);
			}
			
			/* Check player collisions with other entities. */
			if (playerSegment.entitiesNum > 0 && _enableCollision)
			{
				processEntityCollisions(playerSegment);
			}
			
			/* Slow down if player drives onto off-road area. */
			if ((_playerX < -1 || _playerX > 1) && _playerSpeed > _offRoadLimit)
			{
				_playerSpeed = accel(_playerSpeed, _offRoadDecel);
			}
			
			/* Check player collision with other cars. */
			for (i = 0; i < playerSegment.cars.length; i++)
			{
				var car:RTCar = playerSegment.cars[i];
				if (_playerSpeed > car.carSpeed)
				{
					var carWidth:Number = car.width * (_objectScale * car.scale);
					if (overlap(_playerX, _playerWidth, car.carOffset, carWidth, 0.8))
					{
						_playerSpeed = car.carSpeed * (car.carSpeed / _playerSpeed);
						_position = increase(car.carZ, -_playerZ, _trackLength);
						break;
					}
				}
			}
			
			_playerX = limit(_playerX, -3, 3);		// Don't ever let it go too far out of bounds
			_playerSpeed = limit(_playerSpeed, 0, _maxSpeed);	// or exceed maxSpeed.
			
			/* Increase move counter only if the player is moving. */
			if (_prevSegment != playerSegment)
			{
				++_progress;
				if (_progressSignal) _progressSignal.dispatch(_progress);
			}
			
			_prevPosition = _position;
			_prevSegment = playerSegment;
			
			/* Calculate scroll offsets for BG layers. */
			if (_bgScroller)
			{
				_bgScrollOffset = increase(_bgScrollOffset, _bgSpeedMult * playerSegment.curve * (_position - _startPosition) / _segmentLength, 1.0);
				var bgScrollX:Number = -(_bgScrollOffset * _bgScroller.layerWidth);
				if (bgScrollX != _bgScrollPrevX)
				{
					_bgScroller.tilesOffsetX = _bgScrollPrevX = bgScrollX;
				}
				// TODO Add vertical bg parallax scrolling.
				//var bgScrollY:Number = (_bgSpeedMult * _playerY);// / _bgScroller.layerHeight;
				//if (bgScrollY != _bgScrollPrevY)
				//{
				//	_bgScroller.tilesOffsetY = _bgScrollPrevY = bgScrollY;
				//}
			}
		}
		
		/**
		 * Renders the racetrack.
		 */
		public function render():void
		{
			var baseSegment:RTSegment = findSegment(_position),
				basePercent:Number = percentRemaining(_position, _segmentLength),
				playerSegment:RTSegment = findSegment(_position + _playerZ),
				playerPercent:Number = percentRemaining(_position + _playerZ, _segmentLength),
				seg:RTSegment,
				car:RTCar,
				entity:RTEntity,
				maxY:int = _height,
				x:Number = 0,
				dx:Number = -(baseSegment.curve * basePercent),
				i:int,
				j:int,
				spriteScale:Number,
				spriteX:Number,
				spriteY:Number;
			
			_playerY = interpolate(playerSegment.point1.world.y, playerSegment.point2.world.y, playerPercent);
			
			/* Render background. */
			if (_bgScroller) _renderCanvas.blit(_bgScroller, 0, 0);
			else _renderCanvas.clear();
			
			/* PHASE 1: render segments, front to back and clip far segments that have been
			 * obscured by already rendered near segments if their projected coordinates are
			 * lower than maxY. */
			for (i = 0; i < _drawDistance; i++)
			{
				seg = _segments[(baseSegment.index + i) % _segments.length];
				seg.looped = seg.index < baseSegment.index;
				/* Apply exponential haze alpha value. */
				seg.haze = 1.0 / (Math.pow(2.718281828459045, ((i / _drawDistance) * (i / _drawDistance) * _hazeDensity)));
				seg.clip = maxY;

				project(seg.point1, (_playerX * _roadWidth) - x, _playerY + _cameraAltitude, _position - (seg.looped ? _trackLength : 0));
				project(seg.point2, (_playerX * _roadWidth) - x - dx, _playerY + _cameraAltitude, _position - (seg.looped ? _trackLength : 0));

				x = x + dx;
				dx = dx + seg.curve;

				if ((seg.point1.camera.z <= _cameraDepth)			// behind us
				|| (seg.point2.screen.y >= seg.point1.screen.y)		// back face cull
				|| (seg.point2.screen.y >= maxY))					// clip by (already rendered) hill
				{
					continue;
				}
				
				renderSegment(i, seg.point1.screen.x, seg.point1.screen.y, seg.point1.screen.w, seg.point2.screen.x, seg.point2.screen.y, seg.point2.screen.w, seg.colorSet, seg.haze);
				maxY = seg.point1.screen.y;
			}

			/* PHASE 2: Back to front render the sprites. */
			for (i = (_drawDistance - 1); i > 0; i--)
			{
				seg = _segments[(baseSegment.index + i) % _segments.length];

				/* Render opponent cars. */
				for (j = 0; j < seg.cars.length; j++)
				{
					entity = car = seg.cars[j];
					spriteScale = interpolate(seg.point1.screen.scale, seg.point2.screen.scale, car.carPercent);
					spriteX = interpolate(seg.point1.screen.x, seg.point2.screen.x, car.carPercent) + (spriteScale * car.carOffset * _roadWidth * _widthHalf);
					spriteY = interpolate(seg.point1.screen.y, seg.point2.screen.y, car.carPercent);
					renderEntity(car, spriteScale, spriteX, spriteY, -0.5, -1, entity.pixelOffsetY, seg.clip, seg.haze);
				}
				
				/* Render other objects. */
				if (seg.entities)
				{
					for (j = 0; j < seg.entities.length; j++)
					{
						entity = seg.entities[j];
						if (!entity.enabled) continue;
						
						spriteScale = seg.point1.screen.scale;
						spriteX = seg.point1.screen.x + (spriteScale * entity.offsetX * _roadWidth * _widthHalf);
						spriteY = seg.point1.screen.y;
						//if (entity.type == RTObjectTypes.OBSTACLE) Debug.trace(entity.offsetX);
						//if (entity.isOffroad) offsetX = (entity.offsetX < 0 ? -1 : 0);
						//else offsetX = entity.offsetX - 0.5;
						//offsetX = entity.offsetX;
						renderEntity(entity, spriteScale, spriteX, spriteY, entity.offsetX2, -1, entity.pixelOffsetY, seg.clip, seg.haze);
					}
				}
				
				/* Render the player sprite. */
				if (seg == playerSegment)
				{
					/* Calculate player sprite bouncing depending on speed percentage. */
					var jitter:Number = _racetrack.playerJitter ? (1.5 * Math.random() * (_playerSpeed / _maxSpeed) * _resolution) * randomChoice([-1, 1]) : 0.0;
					renderEntity(_racetrack.player,
						_cameraDepth / _playerZ,
						_widthHalf,
						(_heightHalf - (_cameraDepth / _playerZ * interpolate(playerSegment.point1.camera.y, playerSegment.point2.camera.y, playerPercent) * _heightHalf)) + jitter,
						_playerOffsetX,
						_playerOffsetY,
						_racetrack.player.pixelOffsetY);
				}
			}
				
			_renderCanvas.complete();
		}
		
		
		public function jump():void
		{
			if (!_enableControls || !_playerEnabled || _isJump || _playerSpeed == 0) return;
			_playerJumpHeight = -(_playerSpeedPercent * 1.8);
			_isFall = false;
			_isJump = true;
		}
		
		
		/**
		 * @inheritDoc
		 */
		public function dispose():void
		{
			if (_racetrack) _racetrack.dispose();
			if (_bgScroller) _bgScroller.dispose();
			if (_interval) _interval.dispose();
			if (_renderCanvas) _renderCanvas.clear();
			Main.instance.classRegistry.unregisterSystem(SYSTEM_ID);
		}
		
		
		// -----------------------------------------------------------------------------------------
		// Accessors
		// -----------------------------------------------------------------------------------------
		
		/**
		 * The progress of the player's movement on the racetrack. This value increases
		 * by 1 whenever the player crosses the next racetrack segment.
		 */
		public function get progress():uint
		{
			return _progress;
		}
		
		
		/**
		 * The total progress number.
		 */
		public function get progressTotal():int
		{
			return _progressTotal;
		}
		
		
		/**
		 * The current lap. This value starts with 1 and increases whenever the player
		 * crosses the finish line.
		 */
		public function get currentLap():uint
		{
			return _currentLap;
		}
		
		
		public function get currentLapTime():uint
		{
			return _currentLapTime;
		}


		public function get lastLapTime():uint
		{
			return _lastLapTime;
		}


		public function get fastestLapTime():uint
		{
			return _fastestLapTime;
		}
		
		
		public function get width():int
		{
			return _width;
		}
		public function set width(v:int):void
		{
			_width = v;
		}
		
		
		public function get height():int
		{
			return _height;
		}
		public function set height(v:int):void
		{
			_height = v;
		}
		
		
		public function get racetrack():Racetrack
		{
			return _racetrack;
		}
		public function set racetrack(v:Racetrack):void
		{
			_racetrack = v;
			if (!_racetrack) return;
			
			_drawDistance = _racetrack.drawDistance;
			_roadWidth = _racetrack.roadWidth;
			_segmentLength = _racetrack.segmentLength;
			_trackLength = _racetrack.trackLength;
			_lanes = _racetrack.lanes;
			_hazeDensity = _racetrack.hazeDensity;
			_hazeColor = _racetrack.hazeColor;
			_hazeThreshold = _racetrack.hazeThreshold;
			_acceleration = _racetrack.acceleration;
			_deceleration = _racetrack.deceleration;
			_braking = _racetrack.braking;
			_offRoadDecel = _racetrack.offRoadDecel;
			_offRoadLimit = _racetrack.offRoadLimit;
			_centrifugal = _racetrack.centrifugal;
			_maxSpeed = _racetrack.maxSpeed;
			_dt = _racetrack.dt;
			
			_segments = _racetrack.segments;
			_cars = _racetrack.cars;
			_carsNum = _cars ? _cars.length : 0;
			_objects = _racetrack.objects;
			_objectScale = _racetrack.objectScale;
			_playerWidth = _racetrack.player.width * _objectScale;
			
			cameraAltitude = _racetrack.cameraAltitude;
			fov = _racetrack.fov;
			
			_prevSegment = findSegment(_position + _playerZ);
			
			if (_racetrack.backgroundLayers)
			{
				if (!_bgScroller)
				{
					_bgScroller = new ScrollImage2D(_width, _height);
					_bgScroller.tilesScale = _racetrack.backgroundScale;
				}
				for (var i:uint = 0; i < _racetrack.backgroundLayers.length; i++)
				{
					var layer:ScrollTile2D = _racetrack.backgroundLayers[i];
					if (!layer) continue;
					_bgScroller.addLayer(layer);
				}
			}
		}
		
		
		/**
		 * Determines the number of road segments to draw.
		 * 
		 * @default 300
		 */
		public function get drawDistance():int
		{
			return _drawDistance;
		}
		public function set drawDistance(v:int):void
		{
			_drawDistance = v;
		}
		
		
		/**
		 * Z height of camera (usable range is 500 - 5000).
		 * 
		 * @default 1000
		 */
		public function get cameraAltitude():Number
		{
			return _cameraAltitude;
		}
		public function set cameraAltitude(v:Number):void
		{
			if (v == _cameraAltitude) return;
			_cameraAltitude = v;
			calculateDerivedParameters();
		}
		
		
		/**
		 * Angle (degrees) for field of view (usable range is 80 - 140).
		 * 
		 * @default 100
		 */
		public function get fov():int
		{
			return _fov;
		}
		public function set fov(v:int):void
		{
			if (v == _fov) return;
			_fov = v;
			calculateDerivedParameters();
		}
		
		
		/**
		 * X Offset Position of the player entity.
		 */
		public function get playerOffsetX():Number
		{
			return _playerOffsetX;
		}
		public function set playerOffsetX(v:Number):void
		{
			_playerOffsetX = v;
		}
		
		
		/**
		 * The canvas onto which the racetrack is rendered.
		 */
		public function get renderCanvas():IRenderCanvas
		{
			return _renderCanvas;
		}
		public function set renderCanvas(v:IRenderCanvas):void
		{
			_renderCanvas = v;
			_renderCanvas.fillColor = _racetrack.backgroundColor;
		}
		
		
		public function get enableCollision():Boolean
		{
			return _enableCollision;
		}
		public function set enableCollision(v:Boolean):void
		{
			_enableCollision = v;
		}
		
		
		/**
		 * Determines whether player control are enabled or not.
		 */
		public function get enableControls():Boolean
		{
			return _enableControls;
		}
		public function set enableControls(v:Boolean):void
		{
			_enableControls = v;
			if (!_enableControls)
			{
				_isAccelerating = _isBraking = _isSteeringLeft = _isSteeringRight = false;
			}
		}
		
		
		public function get playerEnabled():Boolean
		{
			return _playerEnabled;
		}
		
		
		public function get isAccelerating():Boolean
		{
			return _isAccelerating;
		}
		public function set isAccelerating(v:Boolean):void
		{
			if (!_enableControls) return;
			_isAccelerating = v;
		}
		
		
		public function get isBraking():Boolean
		{
			return _isBraking;
		}
		public function set isBraking(v:Boolean):void
		{
			if (!_enableControls) return;
			_isBraking = v;
		}
		
		
		public function get isSteeringLeft():Boolean
		{
			return _isSteeringLeft;
		}
		public function set isSteeringLeft(v:Boolean):void
		{
			if (!_enableControls) return;
			_isSteeringLeft = v;
		}
		
		
		public function get isSteeringRight():Boolean
		{
			return _isSteeringRight;
		}
		public function set isSteeringRight(v:Boolean):void
		{
			if (!_enableControls) return;
			_isSteeringRight = v;
		}
		
		
		public function get playerFPS():int
		{
			return _playerFPS;
		}
		
		
		/**
		 * Speed of the player.
		 */
		public function get playerSpeed():Number
		{
			return _playerSpeed;
		}
		
		
		/**
		 * The speed of the player at the last collision occurence.
		 */
		public function get playerSpeedCollision():Number
		{
			return _playerSpeedCollision;
		}
		
		
		public function get playSoundSignal():RTPlaySoundSignal
		{
			if (!_playSoundSignal) _playSoundSignal = new RTPlaySoundSignal();
			return _playSoundSignal;
		}
		
		
		public function get changeScoreSignal():RTChangeScoreSignal
		{
			if (!_changeScoreSignal) _changeScoreSignal = new RTChangeScoreSignal();
			return _changeScoreSignal;
		}
		
		
		public function get changeBonusSignal():RTChangeBonusSignal
		{
			if (!_changeBonusSignal) _changeBonusSignal = new RTChangeBonusSignal();
			return _changeBonusSignal;
		}
		
		
		public function get changeTimeSignal():RTChangeTimeSignal
		{
			if (!_changeTimeSignal) _changeTimeSignal = new RTChangeTimeSignal();
			return _changeTimeSignal;
		}
		
		
		public function get changeHealthSignal():RTChangeHealthSignal
		{
			if (!_changeHealthSignal) _changeHealthSignal = new RTChangeHealthSignal();
			return _changeHealthSignal;
		}
		
		
		public function get disablePlayerSignal():RTDisablePlayerSignal
		{
			if (!_disablePlayerSignal) _disablePlayerSignal = new RTDisablePlayerSignal();
			return _disablePlayerSignal;
		}
		
		
		public function get lapSignal():RTLapSignal
		{
			if (!_lapSignal) _lapSignal = new RTLapSignal();
			return _lapSignal;
		}
		
		
		public function get completeLevelSignal():RTCompleteLevelSignal
		{
			if (!_completeLevelSignal) _completeLevelSignal = new RTCompleteLevelSignal();
			return _completeLevelSignal;
		}
		
		
		public function get progressSignal():RTProgressSignal
		{
			if (!_progressSignal) _progressSignal = new RTProgressSignal();
			return _progressSignal;
		}
		
		
		public function get checkPointSignal():RTCheckPointSignal
		{
			if (!_checkPointSignal) _checkPointSignal = new RTCheckPointSignal();
			return _checkPointSignal;
		}
		
		
		// -----------------------------------------------------------------------------------------
		// Private Methods
		// -----------------------------------------------------------------------------------------
		
		/**
		 * @private
		 */
		protected function setup():void
		{
			/* Set defaults. */
			_bgSpeedMult = 0.001;
			_playerX = _playerY = _playerZ = 0;
			
			_boundingBox = new Rect2D(10, 10, 0xFF00FF);
			_boundingBox.alpha = 0.4;
		}
		
		
		/**
		 * @private
		 */
		private function calculateDerivedParameters():void
		{
			if (_fov > 0 && !isNaN(_cameraAltitude))
			{
				_cameraDepth = 1 / Math.tan((_fov / 2) * Math.PI / 180);
				_playerZ = (_cameraAltitude * _cameraDepth);
			}
		}
		
		
		/**
		 * @private
		 */
		private function updateCars(playerSegment:RTSegment, playerW:Number):void
		{
			var i:int,
				car:RTCar,
				oldSegment:RTSegment,
				newSegment:RTSegment;
			
			for (i = 0; i < _carsNum; i++)
			{
				car = _cars[i];
				oldSegment = findSegment(car.carZ);
				car.carOffset = car.carOffset + updateCarOffset(car, oldSegment, playerSegment, playerW);
				car.carZ = increase(car.carZ, _dt * car.carSpeed, _trackLength);
				car.carPercent = percentRemaining(car.carZ, _segmentLength);
				// useful for interpolation during rendering phase
				newSegment = findSegment(car.carZ);

				if (oldSegment != newSegment)
				{
					var index:int = oldSegment.cars.indexOf(car);
					oldSegment.cars.splice(index, 1);
					newSegment.cars.push(car);
				}
			}
		}


		/**
		 * @private
		 */
		private function updateCarOffset(car:RTCar, carSegment:RTSegment,
			playerSegment:RTSegment, playerW:Number):Number
		{
			var i:int,
				j:int,
				dir:Number,
				segment:RTSegment,
				otherCar:RTCar,
				otherCarW:Number,
				lookahead:int = 20,
				carW:Number = car.width * _objectScale;
			
			/* Optimization: dont bother steering around other cars when 'out of sight'
			 * of the player. */
			if ((carSegment.index - playerSegment.index) > _drawDistance) return 0;

			for (i = 1; i < lookahead; i++)
			{
				segment = _segments[(carSegment.index + i) % _segments.length];

				/* Car drive-around player AI */
				if ((segment === playerSegment) && (car.carSpeed > _playerSpeed) && (overlap(_playerX, playerW, car.carOffset, carW, 1.2)))
				{
					if (_playerX > 0.5) dir = -1;
					else if (_playerX < -0.5) dir = 1;
					else dir = (car.carOffset > _playerX) ? 1 : -1;
					// The closer the cars (smaller i) and the greater the speed ratio,
					// the larger the offset.
					return dir * 1 / i * (car.carSpeed - _playerSpeed) / _maxSpeed;
				}

				/* Car drive-around other car AI */
				for (j = 0; j < segment.cars.length; j++)
				{
					otherCar = segment.cars[j];
					otherCarW = otherCar.width * _objectScale;
					if ((car.carSpeed > otherCar.carSpeed) && overlap(car.carOffset, carW, otherCar.carOffset, otherCarW, 1.2))
					{
						if (otherCar.carOffset > 0.5) dir = -1;
						else if (otherCar.carOffset < -0.5) dir = 1;
						else dir = (car.carOffset > otherCar.carOffset) ? 1 : -1;
						return dir * 1 / i * (car.carSpeed - otherCar.carSpeed) / _maxSpeed;
					}
				}
			}

			// if no cars ahead, but car has somehow ended up off road, then steer back on.
			if (car.carOffset < -0.9) return 0.1;
			else if (car.carOffset > 0.9) return -0.1;
			else return 0;
		}
		
		
		/**
		 * @private
		 */
		private function processPlayerControls(segment:RTSegment):void
		{
			var playerStateID:String;
			
			if (_isJump)
			{
				if (_playerOffsetY <= _playerJumpHeight)
				{
					_isJump = false;
					_isFall = true;
				}
				else
				{
					playerStateID = RTPlayerDefaultStateNames.JUMP;
					_playerOffsetY -= (1.1 - _playerSpeedPercent) * 0.36;
				}
			}
			else if (_isFall)
			{
				if (_playerOffsetY < -1.0)
				{
					playerStateID = RTPlayerDefaultStateNames.FALL;
					_playerOffsetY += (1.1 - _playerSpeedPercent) * 0.36;
				}
				else
				{
					_playerOffsetY = -1.0;
					_isFall = false;
				}
			}
			else
			{
				var dx:Number = _dt * 2 * _playerSpeedPercent;
				var updown:Number = segment.point2.world.y - segment.point1.world.y - 20;
				
				/* Update left/right steering. */
				if (_isSteeringLeft)
				{
					playerStateID = (updown > 0)
						? RTPlayerDefaultStateNames.MOVE_LEFT_UP
						: RTPlayerDefaultStateNames.MOVE_LEFT;
					_playerX = _playerX - dx;
				}
				else if (_isSteeringRight)
				{
					playerStateID = (updown > 0)
						? RTPlayerDefaultStateNames.MOVE_RIGHT_UP
						: RTPlayerDefaultStateNames.MOVE_RIGHT;
					_playerX = _playerX + dx;
				}
				else
				{
					playerStateID = (updown > 0)
						? RTPlayerDefaultStateNames.MOVE_FORWARD_UP
						: RTPlayerDefaultStateNames.MOVE_FORWARD;
				}
				
				_playerX = _playerX - (dx * _playerSpeedPercent * segment.curve * _centrifugal);
				
				/* Update acceleration & decceleration. */
				if (_isAccelerating)
				{
					_idleAfterCollision = false;
					_playerSpeed = accel(_playerSpeed, _acceleration);
				}
				else if (_isBraking)
				{
					_playerSpeed = accel(_playerSpeed, _braking);
				}
				else
				{
					_playerSpeed = accel(_playerSpeed, _deceleration);
				}
			}
			
			if (_playerSpeed <= 0 || _idleAfterCollision)
			{
				playerStateID = RTPlayerDefaultStateNames.IDLE;
			}
				
			if (playerStateID && !_suppressDefaultPlayerStates)
			{
				_racetrack.player.object.switchToState(playerStateID);
				if (_racetrack.playerAnimDynamicFPS)
				{
					_playerFPS = (_playerSpeed * 0.6) / 300;
					if (_playerFPS < 6) _playerFPS = 6;
					else if (_playerFPS > 20) _playerFPS = 20;
					_racetrack.player.object.changeAnimFramerate(_playerFPS);
				}
			}
		}
		
		
		/**
		 * @private
		 */
		private function processSegmentTriggers(segment:RTSegment):void
		{
			for (var i:uint = 0; i < segment.triggersNum; i++)
			{
				var trigger:RTTrigger = segment.triggers[i];
				
				/* Player is still on the same segment but trigger should not be
				 * triggered again on the same segment. */
				if (!trigger.multi && segment.index == _prevSegment.index) continue;
				processTrigger(trigger, null);
			}
		}
		
		
		/**
		 * @private
		 */
		private function processEntityCollisions(segment:RTSegment):void
		{
			for (var i:uint = 0; i < segment.entitiesNum; i++)
			{
				var e:RTEntity = segment.entities[i];
				if (!e.enabled) continue;
				
				/* Collision coords with scaled offset for onroad objects. */
				var w2:Number = (e.width * 0.5) * (_objectScale * e.scale);
				var x2:Number = e.offsetX + (w2 * 2.0) * e.offsetX3;
				
				//if (overlap(_playerX, _playerWidth, e.offsetX + (w * 0.5) * (e.offsetX > 0 ? 1 : -1), w))
				if (overlap(_playerX, _playerWidth, x2, w2, e.object.collisionGrace))
				{
					_racetrack.player.isColliding = e.isColliding = true;
					_playerSpeedCollision = _playerSpeed;
					
					/* Check the collided entity's triggers. */
					if (e.object.triggersNum > 0)
					{
						for (var j:uint = 0; j < e.object.triggersNum; j++)
						{
							var trigger:RTTrigger = e.object.triggers[j];
							if (!trigger || trigger.type != RTTriggerTypes.COLLISION) continue;
							/* Don't retrigger on same segment if not multi-trigger! */
							if (!trigger.multi && segment.index == _prevSegment.index) continue;
							processTrigger(trigger, e);
						}
					}
					
					/* Offroad-type entities should only be checked for collision if the
					 * player is actually off-road! */
					if (e.type == RTObjectTypes.OFFROAD && (_playerX < -1 || _playerX > 1))
					{
						_playerSpeed = _maxSpeed / 5;
						/* Stop in front of sprite (at front of segment). */
						_position = increase(segment.point1.world.z, -_playerZ, _trackLength);
						break;
					}
					/* On-road obstacles. */
					else if (e.type == RTObjectTypes.OBSTACLE)
					{
						var hardness:int = 100;
						if (e.object.propertiesNum > 0)
						{
							hardness = e.object.properties[RTObjectPropertyNames.OBSTACLE_HARDNESS];
						}
						_playerSpeed = _maxSpeed / hardness;
						/* Stop in front of sprite (at front of segment). */
						if (hardness >= 100)
						{
							/* Determines how quick player can steer away from obstacle after being stopped. */
							_playerSpeed = _maxSpeed / 5;
							_position = increase(segment.point1.world.z, -_playerZ, _trackLength);
							_idleAfterCollision = true;
						}
						break;
					}
					else if (e.type == RTObjectTypes.COLLECTIBLE)
					{
						/* Remove the entity from the racetrack! */
						e.enabled = false;
					}
				}
			}
		}
		
		
		/**
		 * @private
		 * 
		 * @param trigger The triggered trigger.
		 * @param entity The entity that was collided.
		 */
		private function processTrigger(trigger:RTTrigger, entity:RTEntity):void
		{
			var s:String;
			var duration:Number;
			var targetStateID:String;
			
			switch (trigger.action)
			{
				case RTTriggerActions.PLAY_SOUND:
					if (!_playSoundSignal) return;
					_playSoundSignal.dispatch(String(trigger.arguments[0]));
					break;
				case RTTriggerActions.ADD_SCORE:
					if (!_changeScoreSignal) return;
					_changeScoreSignal.dispatch(int(trigger.arguments[0]));
					break;
				case RTTriggerActions.SUBTRACT_SCORE:
					if (!_changeScoreSignal) return;
					_changeScoreSignal.dispatch(int(-(trigger.arguments[0])));
					break;
				case RTTriggerActions.ADD_BONUS:
					if (!_changeBonusSignal) return;
					s = entity ? entity.object.id : "segment";
					_changeBonusSignal.dispatch(int(trigger.arguments[0]), s);
					break;
				case RTTriggerActions.SUBTRACT_BONUS:
					if (!_changeBonusSignal) return;
					s = entity ? entity.object.id : "segment";
					_changeBonusSignal.dispatch(int(-(trigger.arguments[0])), s);
					break;
				case RTTriggerActions.ADD_TIME:
					if (!_changeTimeSignal) return;
					_changeTimeSignal.dispatch(int(trigger.arguments[0]));
					break;
				case RTTriggerActions.SUBTRACT_TIME:
					if (!_changeTimeSignal) return;
					_changeTimeSignal.dispatch(int(-(trigger.arguments[0])));
					break;
				case RTTriggerActions.ADD_HEALTH:
					if (!_changeHealthSignal) return;
					_changeHealthSignal.dispatch(Number(trigger.arguments[0]));
					break;
				case RTTriggerActions.SUBTRACT_HEALTH:
					if (!_changeHealthSignal) return;
					_changeHealthSignal.dispatch(Number(-(trigger.arguments[0])));
					break;
				case RTTriggerActions.CHANGE_OBJECT_STATE:
					var targetObjectID:String = trigger.arguments[0];
					var targetObject:RTObject = _racetrack.objects[targetObjectID];
					targetStateID = trigger.arguments[1];
					duration = trigger.arguments[2];
					changeObjectState(targetObject, targetStateID, duration);
					break;
				case RTTriggerActions.CHANGE_ENTITY_STATE:
					var targetEntityID:String = trigger.arguments[0];
					var targetEntity:RTEntity;
					if (targetEntityID == "this") targetEntity = entity;
					else targetEntity = _racetrack.entities[targetEntityID];
					targetStateID = trigger.arguments[1];
					duration = trigger.arguments[2];
					changeEntityState(targetEntity, targetStateID, duration);
					break;
				case RTTriggerActions.DISABLE_PLAYER:
					duration = trigger.arguments[0];
					disablePlayer(duration);
					if (!_disablePlayerSignal) return;
					_disablePlayerSignal.dispatch(duration);
					break;
				case RTTriggerActions.COMPLETE_LEVEL:
					if (!_completeLevelSignal) return;
					_completeLevelSignal.dispatch();
					break;
				case RTTriggerActions.STOP_PLAYER:
					_isAccelerating = _isSteeringLeft = _isSteeringRight = false;
					break;
				case RTTriggerActions.TRACK_CHECKPOINT:
					if (!_checkPointSignal) return;
					_checkPointSignal.dispatch();
					break;
				default:
					Log.warn("Unknown trigger action: " + trigger.action, this);
			}
		}
		
		
		// -----------------------------------------------------------------------------------------
		// Object Trigger Actions
		// -----------------------------------------------------------------------------------------
		
		/**
		 * @private
		 * 
		 * @param object The object of which to switch a state.
		 * @param stateID ID of the state.
		 * @param duration Duration for that the state should be switched to. If 0, the
		 *        new state will be permanent.
		 * @param completeCallback Optional callback that is invoked after the state's
		 *        anim sequence is finished. Is only for called for non-looping sequences!
		 */
		private function changeObjectState(object:RTObject, stateID:String, duration:Number,
			completeCallback:Function = null, callbackDelay:Number = 0.0):void
		{
			if (!object) return;
			
			if (completeCallback != null)
			{
				if (!object.sequenceCompleteSignal) object.sequenceCompleteSignal = new Signal();
				object.sequenceCompleteSignal.addOnce(function(obj:RTObject):void
				{
					if (callbackDelay <= 0.0) completeCallback();
					else Interval.setInterval(callbackDelay * 1000, completeCallback, 1, true);
				});
			}
			
			var success:int = object.switchToState(stateID);
			if (success == 1)
			{
				if (duration > 0.0)
				{
					if (object.isPlayer) _suppressDefaultPlayerStates = true;
					if (!object.interval) object.interval = new Interval(0, 0, null, null);
					else object.interval.reset();
					object.interval.delay = duration * 1000;
					object.interval.callBack = function():void
					{
						object.switchToState(object.defaultStateID);
						_suppressDefaultPlayerStates = false;
					};
					object.interval.start();
				}
			}
		}
		
		
		/**
		 * @private
		 */
		private function changeEntityState(entity:RTEntity, stateID:String, duration:Number,
			completeCallback:Function = null, callbackDelay:Number = 0.0):void
		{
			if (!entity) return;
			var object:RTObject = entity.object;
			
			if (completeCallback != null)
			{
				if (!object.sequenceCompleteSignal) object.sequenceCompleteSignal = new Signal();
				object.sequenceCompleteSignal.addOnce(function(obj:RTObject):void
				{
					if (callbackDelay <= 0.0) completeCallback();
					else Interval.setInterval(callbackDelay * 1000, completeCallback, 1, true);
				});
			}
		}
		
		
		/**
		 * @private
		 */
		private function disablePlayer(duration:Number):void
		{
			_playerEnabled = false;
			if (duration > 0.0)
			{
				_interval = Interval.setTimeOut(duration * 1000, function():void
				{
					_playerEnabled = true;
				}, true);
			}
		}
		
		
		// -----------------------------------------------------------------------------------------
		// Render Functions
		// -----------------------------------------------------------------------------------------
		
		/**
		 * Renders a segment.
		 * 
		 * @param x1
		 * @param y1
		 * @param w1
		 * @param x2
		 * @param y2
		 * @param w2
		 * @param color
		 * @param hazeAlpha
		 */
		private function renderSegment(nr:int, x1:int, y1:int, w1:int, x2:int, y2:int, w2:int,
			colorSet:RTColorSet, hazeAlpha:Number):void
		{
			/* Calculate rumble widths for current segment. */
			var r1:Number = calcRumbleWidth(w1), r2:Number = calcRumbleWidth(w2);
			
			/* Draw offroad area segment. */
			//if (nr % 2 == 0)
			_renderCanvas.drawRect(0, y2, _width, y1 - y2, colorSet.offroad, _hazeColor, hazeAlpha,
				_hazeThreshold);
			
			/* Draw the road segment. */
			_renderCanvas.drawQuad(x1 - w1 - r1, y1, x1 - w1, y1, x2 - w2, y2, x2 - w2 - r2, y2, colorSet.rumble, _hazeColor, hazeAlpha, _hazeThreshold);
			_renderCanvas.drawQuad(x1 + w1 + r1, y1, x1 + w1, y1, x2 + w2, y2, x2 + w2 + r2, y2, colorSet.rumble, _hazeColor, hazeAlpha, _hazeThreshold);
			_renderCanvas.drawQuad(x1 - w1, y1, x1 + w1, y1, x2 + w2, y2, x2 - w2, y2, colorSet.road, _hazeColor, hazeAlpha, _hazeThreshold);
			
			/* Draw lane strips. */
			if (colorSet.lane > 0)
			{
				var l1:Number = calcLaneMarkerWidth(w1),
				l2:Number = calcLaneMarkerWidth(w2),
				lw1:Number = w1 * 2 / _lanes,
				lw2:Number = w2 * 2 / _lanes,
				lx1:Number = x1 - w1 + lw1,
				lx2:Number = x2 - w2 + lw2;

				for (var lane:int = 1; lane < _lanes; lx1 += lw1, lx2 += lw2, lane++)
				{
					_renderCanvas.drawQuad(lx1 - l1 / 2, y1, lx1 + l1 / 2, y1, lx2 + l2 / 2, y2,
						lx2 - l2 / 2, y2, colorSet.lane, _hazeColor, hazeAlpha, _hazeThreshold);
				}
			}
		}
		
		
		/**
		 * Renders a sprite onto the render buffer.
		 * 
		 * @param sprite
		 * @param scale
		 * @param destX
		 * @param destY
		 * @param offsetX
		 * @param offsetY
		 * @param clipY
		 * @param hazeAlpha
		 */
		private function renderEntity(entity:RTEntity, scale:Number,
			destX:Number, destY:Number, offsetX:Number = 0.0, offsetY:Number = 0.0,
			pixelOffsetY:int = 0, clipY:Number = 0.0, hazeAlpha:Number = 1.0):void
		{
			if (!entity.object || !entity.object.image) return;
			
			var image:Image2D = entity.object.image;
			scale *= entity.scale;
			
			/* Scale for projection AND relative to roadWidth. */
			var destW:Number = (image.width * scale * _widthHalf) * (_objectScale * _roadWidth);
			var destH:Number = (image.height * scale * _widthHalf) * (_objectScale * _roadWidth);
			
			destX = destX + (destW * offsetX);
			destY = (destY + (destH * offsetY)) + (pixelOffsetY * scale * 1000);
			
			var clipH:int = clipY ? mathMax(0, destY + destH - clipY) : 0;

			if (clipH < int(destH))
			{
				_renderCanvas.drawImage(image, destX, destY, destW, destH - clipH,
					(destW / image.width), _hazeColor, hazeAlpha, _hazeThreshold);
				
				if (entity.isColliding)
				{
					//_renderCanvas.drawDebugRect(destX, destY, destW, destH - clipH, 0xFF0000);
					entity.isColliding = false;
				}
			}
		}
		
		
		// -----------------------------------------------------------------------------------------
		// Util Functions
		// -----------------------------------------------------------------------------------------
		
		private function findSegment(z:Number):RTSegment
		{
			return _segments[int(z / _segmentLength) % _segments.length];
		}
		
		
		private function increase(start:Number, increment:Number, max:Number):Number
		{
			var result:Number = start + increment;
			while (result >= max) result -= max;
			while (result < 0) result += max;
			return result;
		}


		private function accel(v:Number, accel:Number):Number
		{
			return v + (accel * _dt);
		}


		private function limit(value:Number, min:Number, max:Number):Number
		{
			return mathMax(min, mathMin(value, max));
		}


		private function project(p:RTPoint, cameraX:Number, cameraY:Number, cameraZ:Number):void
		{
			p.camera.x = (p.world.x || 0) - cameraX;
			p.camera.y = (p.world.y || 0) - cameraY;
			p.camera.z = (p.world.z || 0) - cameraZ;
			p.screen.scale = _cameraDepth / p.camera.z;
			p.screen.x = mathRound(_widthHalf + (p.screen.scale * p.camera.x * _widthHalf));
			p.screen.y = mathRound(_heightHalf - (p.screen.scale * p.camera.y * _heightHalf));
			p.screen.w = mathRound((p.screen.scale * _roadWidth * _widthHalf));
		}


		private function calcRumbleWidth(projectedRoadWidth:Number):Number
		{
			return projectedRoadWidth / mathMax(6, 2 * _lanes);
		}


		private function calcLaneMarkerWidth(projectedRoadWidth:Number):Number
		{
			return projectedRoadWidth / mathMax(32, 8 * _lanes);
		}


		private function interpolate(a:Number, b:Number, percent:Number):Number
		{
			return a + (b - a) * percent;
		}


		private function randomInt(min:int, max:int):int
		{
			return mathRound(interpolate(min, max, Math.random()));
		}


		private function randomChoice(a:Array):*
		{
			return a[randomInt(0, a.length - 1)];
		}
		
		
		private function percentRemaining(n:Number, total:Number):Number
		{
			return (n % total) / total;
		}


		private function overlap(x1:Number, w1:Number, x2:Number, w2:Number, percent:Number = 1.0):Boolean
		{
			var half:Number = percent * 0.5;
			/* return !((max1 < min2) || (min1 > max2)) */
			return !(((x1 + (w1 * half)) < (x2 - (w2 * half))) || ((x1 - (w1 * half)) > (x2 + (w2 * half))));
		}


		private function mathMax(a:Number, b:Number):Number
		{
			return (a > b) ? a : b;
		}


		private function mathMin(a:Number, b:Number):Number
		{
			return (a < b) ? a : b;
		}


		private function mathRound(n:Number):int
		{
			return n + (n < 0 ? -0.5 : +0.5) >> 0;
		}
	}
}
