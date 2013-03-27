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
	import tetragon.data.racetrack.constants.RTTriggerActions;
	import tetragon.data.racetrack.constants.RTTriggerTypes;
	import tetragon.data.racetrack.proto.RTObject;
	import tetragon.data.racetrack.proto.RTObjectImageSequence;
	import tetragon.data.racetrack.proto.RTTrigger;
	import tetragon.data.racetrack.vo.RTCar;
	import tetragon.data.racetrack.vo.RTColorSet;
	import tetragon.data.racetrack.vo.RTEntity;
	import tetragon.data.racetrack.vo.RTPoint;
	import tetragon.data.racetrack.vo.RTSegment;
	import tetragon.signals.RTChangeBonusSignal;
	import tetragon.signals.RTChangeScoreSignal;
	import tetragon.signals.RTChangeTimeSignal;
	import tetragon.signals.RTLapSignal;
	import tetragon.signals.RTPlaySoundSignal;
	import tetragon.systems.ISystem;
	import tetragon.view.render.canvas.IRenderCanvas;
	import tetragon.view.render2d.display.Image2D;
	import tetragon.view.render2d.extensions.scrollimage.ScrollImage2D;
	import tetragon.view.render2d.extensions.scrollimage.ScrollTile2D;

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
		
		private var _playerOffsetY:Number;
		private var _playerJumpHeight:Number;
		private var _playerWidth:Number;
		
		private var _startPosition:Number;
		private var _position:Number;			// current camera Z position (add playerZ to get player's absolute Z position)
		private var _prevPosition:Number;
		private var _speed:Number;				// current speed
		private var _speedPercent:Number;
		
		private var _progress:uint;
		private var _currentLap:uint;
		private var _startTime:uint;
		private var _currentLapTime:uint;		// current lap time
		private var _lastLapTime:uint;			// last lap time
		private var _fastestLapTime:uint;
		
		private var _allowControls:Boolean;
		private var _isAccelerating:Boolean;
		private var _isBraking:Boolean;
		private var _isSteeringLeft:Boolean;
		private var _isSteeringRight:Boolean;
		private var _isJump:Boolean;
		private var _isFall:Boolean;
		
		private var _started:Boolean;
		
		/* Racetrack properties */
		private var _roadWidth:int;
		private var _segmentLength:int;
		private var _trackLength:int;
		private var _lanes:int;
		private var _hazeDensity:int;
		private var _hazeColor:uint;
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
		
		
		// -----------------------------------------------------------------------------------------
		// Signals
		// -----------------------------------------------------------------------------------------
		
		private var _playSoundSignal:RTPlaySoundSignal;
		private var _changeScoreSignal:RTChangeScoreSignal;
		private var _changeBonusSignal:RTChangeBonusSignal;
		private var _changeTimeSignal:RTChangeTimeSignal;
		private var _lapSignal:RTLapSignal;
		
		
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
		}
		
		
		/**
		 * @inheritDoc
		 */
		public function reset():void
		{
			stop();
			
			_playerOffsetY = -1.0;
			
			_resolution = 1.6; // _bufferHeight / _bufferHeight;
			_startPosition = 0;
			_position = 0;
			_prevPosition = -1;
			_speed = 0;
			_widthHalf = _width * 0.5;
			_heightHalf = _height * 0.5;
			_bgScrollOffset = 0.0;
			
			_progress = 0;
			_currentLap = 1;
			_startTime = 0;
			_currentLapTime = 0;
			_lastLapTime = 0;
			_fastestLapTime = 0;
			
			_allowControls = true;
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
			
			_speedPercent = _speed / _maxSpeed;
			var i:int, playerSegment:RTSegment = findSegment(_position + _playerZ);
			
			updateCars(_dt, playerSegment, _playerWidth);
			
			_startPosition = _position;
			_position = increase(_position, _dt * _speed, _trackLength);
			
			/* Handle player interaction. */
			if (_allowControls)
			{
				processPlayerControls(playerSegment);
			}
			
			/* Check if the segment the player is on has any triggers. */
			if (playerSegment.triggersNum > 0)
			{
				processSegmentTriggers(playerSegment);
			}
			
			/* Check if player drives onto off-road area. */
			if ((_playerX < -1) || (_playerX > 1))
			{
				if (_speed > _offRoadLimit)
				{
					_speed = accel(_speed, _offRoadDecel, _dt);
				}
			}
			
			/* Check player collisions with other entities. */
			if (playerSegment.entitiesNum > 0)
			{
				processEntityCollisions(playerSegment);
			}
			
			/* Check player collision with opponents. */
			for (i = 0; i < playerSegment.cars.length; i++)
			{
				var car:RTCar = playerSegment.cars[i];
				if (_speed > car.speed)
				{
					var carWidth:Number = car.entity.width * (_objectScale * car.entity.scale);
					if (overlap(_playerX, _playerWidth, car.offset, carWidth, 0.8))
					{
						_speed = car.speed * (car.speed / _speed);
						_position = increase(car.z, -_playerZ, _trackLength);
						break;
					}
				}
			}
			
			_playerX = limit(_playerX, -3, 3);		// Don't ever let it go too far out of bounds
			_speed = limit(_speed, 0, _maxSpeed);	// or exceed maxSpeed.
			
			/* Increase move counter only if the player is moving. */
			if (_prevSegment != playerSegment)
			{
				++_progress;
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
				op:RTCar,
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
				seg.haze = 1 / (Math.pow(2.718281828459045, ((i / _drawDistance) * (i / _drawDistance) * _hazeDensity)));
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
					op = seg.cars[j];
					entity = op.entity;
					spriteScale = interpolate(seg.point1.screen.scale, seg.point2.screen.scale, op.percent);
					spriteX = interpolate(seg.point1.screen.x, seg.point2.screen.x, op.percent) + (spriteScale * op.offset * _roadWidth * _widthHalf);
					spriteY = interpolate(seg.point1.screen.y, seg.point2.screen.y, op.percent);
					renderEntity(op.entity, null, spriteScale, spriteX, spriteY, -0.5, -1, seg.clip, seg.haze);
				}

				/* Render other objects. */
				if (seg.entities)
				{
					for (j = 0; j < seg.entities.length; j++)
					{
						entity = seg.entities[j];
						if (!entity.enabled) continue;
						
						spriteScale = seg.point1.screen.scale;
						spriteX = seg.point1.screen.x + (spriteScale * entity.offset * _roadWidth * _widthHalf);
						spriteY = seg.point1.screen.y;
						renderEntity(entity, null, spriteScale, spriteX, spriteY, (entity.offset < 0 ? -1 : 0), -1, seg.clip, seg.haze);
					}
				}
				
				/* Render the player sprite. */
				if (seg == playerSegment)
				{
					/* Calculate player sprite bouncing depending on speed percentage. */
					var jitter:Number = _racetrack.playerJitter ? (1.5 * Math.random() * (_speed / _maxSpeed) * _resolution) * randomChoice([-1, 1]) : 0.0;
					var steering:int = _speed * (_isSteeringLeft ? -1 : _isSteeringRight ? 1 : 0);
					var updown:Number = playerSegment.point2.world.y - playerSegment.point1.world.y;
					var seqID:String;
					
					if (steering < 0)
					{
						seqID = (updown > 0) ? "leftUphill" : "left";
					}
					else if (steering > 0)
					{
						seqID = (updown > 0) ? "rightUphill" : "right";
					}
					else
					{
						seqID = (updown > 0) ? "straightUphill" : "straight";
					}

					renderEntity(_racetrack.player,
						seqID,
						_cameraDepth / _playerZ,
						_widthHalf,
						(_heightHalf - (_cameraDepth / _playerZ * interpolate(playerSegment.point1.camera.y, playerSegment.point2.camera.y, playerPercent) * _heightHalf)) + jitter,
						-0.5,
						_playerOffsetY);
				}
			}
			
			_renderCanvas.complete();
		}
		
		
		public function jump():void
		{
			if (_isJump || _speed == 0) return;
			_playerJumpHeight = -(_speedPercent * 1.8);
			_isFall = false;
			_isJump = true;
		}
		
		
		/**
		 * @inheritDoc
		 */
		public function dispose():void
		{
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
			
			_drawDistance = _racetrack.drawDistance;
			_roadWidth = _racetrack.roadWidth;
			_segmentLength = _racetrack.segmentLength;
			_trackLength = _racetrack.trackLength;
			_lanes = _racetrack.lanes;
			_hazeDensity = _racetrack.hazeDensity;
			_hazeColor = _racetrack.hazeColor;
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
			_carsNum = _cars.length;
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
		
		
		public function get isAccelerating():Boolean
		{
			return _isAccelerating;
		}
		public function set isAccelerating(v:Boolean):void
		{
			_isAccelerating = v;
		}
		
		
		public function get isBraking():Boolean
		{
			return _isBraking;
		}
		public function set isBraking(v:Boolean):void
		{
			_isBraking = v;
		}
		
		
		public function get isSteeringLeft():Boolean
		{
			return _isSteeringLeft;
		}
		public function set isSteeringLeft(v:Boolean):void
		{
			_isSteeringLeft = v;
		}
		
		
		public function get isSteeringRight():Boolean
		{
			return _isSteeringRight;
		}
		public function set isSteeringRight(v:Boolean):void
		{
			_isSteeringRight = v;
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
		
		
		public function get lapSignal():RTLapSignal
		{
			if (!_lapSignal) _lapSignal = new RTLapSignal();
			return _lapSignal;
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
		private function updateCars(dt:Number, playerSegment:RTSegment, playerW:Number):void
		{
			var i:int,
				car:RTCar,
				oldSegment:RTSegment,
				newSegment:RTSegment;
			
			for (i = 0; i < _carsNum; i++)
			{
				car = _cars[i];
				oldSegment = findSegment(car.z);
				car.offset = car.offset + updateCarOffset(car, oldSegment, playerSegment, playerW);
				car.z = increase(car.z, dt * car.speed, _trackLength);
				car.percent = percentRemaining(car.z, _segmentLength);
				// useful for interpolation during rendering phase
				newSegment = findSegment(car.z);

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
				carW:Number = car.entity.width * _objectScale;
			
			/* Optimization: dont bother steering around other cars when 'out of sight'
			 * of the player. */
			if ((carSegment.index - playerSegment.index) > _drawDistance) return 0;

			for (i = 1; i < lookahead; i++)
			{
				segment = _segments[(carSegment.index + i) % _segments.length];

				/* Car drive-around player AI */
				if ((segment === playerSegment) && (car.speed > _speed) && (overlap(_playerX, playerW, car.offset, carW, 1.2)))
				{
					if (_playerX > 0.5) dir = -1;
					else if (_playerX < -0.5) dir = 1;
					else dir = (car.offset > _playerX) ? 1 : -1;
					// The closer the cars (smaller i) and the greater the speed ratio,
					// the larger the offset.
					return dir * 1 / i * (car.speed - _speed) / _maxSpeed;
				}

				/* Car drive-around other car AI */
				for (j = 0; j < segment.cars.length; j++)
				{
					otherCar = segment.cars[j];
					otherCarW = otherCar.entity.width * _objectScale;
					if ((car.speed > otherCar.speed) && overlap(car.offset, carW, otherCar.offset, otherCarW, 1.2))
					{
						if (otherCar.offset > 0.5) dir = -1;
						else if (otherCar.offset < -0.5) dir = 1;
						else dir = (car.offset > otherCar.offset) ? 1 : -1;
						return dir * 1 / i * (car.speed - otherCar.speed) / _maxSpeed;
					}
				}
			}

			// if no cars ahead, but car has somehow ended up off road, then steer back on.
			if (car.offset < -0.9) return 0.1;
			else if (car.offset > 0.9) return -0.1;
			else return 0;
		}
		
		
		/**
		 * @private
		 */
		private function processPlayerControls(segment:RTSegment):void
		{
			if (_isJump)
			{
				if (_playerOffsetY <= _playerJumpHeight)
				{
					_isJump = false;
					_isFall = true;
				}
				else
				{
					_playerOffsetY -= (1.1 - _speedPercent) * 0.36;
				}
			}
			else if (_isFall)
			{
				if (_playerOffsetY < -1.0)
				{
					_playerOffsetY += (1.1 - _speedPercent) * 0.36;
				}
				else
				{
					_playerOffsetY = -1.0;
					_isFall = false;
				}
			}
			else
			{
				var dx:Number = _dt * 2 * _speedPercent;
				/* Update left/right steering. */
				if (_isSteeringLeft) _playerX = _playerX - dx;
				else if (_isSteeringRight) _playerX = _playerX + dx;
				
				_playerX = _playerX - (dx * _speedPercent * segment.curve * _centrifugal);
				
				/* Update acceleration & decceleration. */
				if (_isAccelerating) _speed = accel(_speed, _acceleration, _dt);
				else if (_isBraking) _speed = accel(_speed, _braking, _dt);
				else _speed = accel(_speed, _deceleration, _dt);
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
				var w:Number = e.width * (_objectScale * e.scale);
				
				if (overlap(_playerX, _playerWidth, e.offset + (w * 0.5) * (e.offset > 0 ? 1 : -1), w))
				{
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
						_speed = _maxSpeed / 5;
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
						_speed = _maxSpeed / hardness;
						/* Stop in front of sprite (at front of segment). */
						if (hardness >= 100)
						{
							/* Determines how quick player can steer away from obstacle after being stopped. */
							_speed = _maxSpeed / 5;
							_position = increase(segment.point1.world.z, -_playerZ, _trackLength);
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
				case RTTriggerActions.CHANGE_OBJECT_STATE:
					var targetObjectID:String = trigger.arguments[0];
					var targetObject:RTObject = _racetrack.objects[targetObjectID];
					var targetStateID:String = trigger.arguments[1];
					duration = trigger.arguments[2];
					switchObjectState(targetObject, targetStateID, duration);
					break;
				case RTTriggerActions.DISABLE_PLAYER:
					duration = trigger.arguments[0];
					disablePlayer(duration);
					break;
			}
		}
		
		
		// -----------------------------------------------------------------------------------------
		// Object Trigger Actions
		// -----------------------------------------------------------------------------------------
		
		/**
		 * @private
		 */
		private function switchObjectState(object:RTObject, stateID:String, duration:Number):void
		{
			var success:int = object.switchToState(stateID, duration);
			if (success == 1)
			{
			}
		}
		
		
		/**
		 * @private
		 */
		private function disablePlayer(duration:Number):void
		{
			_allowControls = false;
			if (duration > 0.0)
			{
				Interval.setTimeOut(duration * 1000, function():void
				{
					_allowControls = true;
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
			_renderCanvas.drawRect(0, y2, _width, y1 - y2, colorSet.offroad, _hazeColor, hazeAlpha);
			
			/* Draw the road segment. */
			_renderCanvas.drawQuad(x1 - w1 - r1, y1, x1 - w1, y1, x2 - w2, y2, x2 - w2 - r2, y2, colorSet.rumble, _hazeColor, hazeAlpha);
			_renderCanvas.drawQuad(x1 + w1 + r1, y1, x1 + w1, y1, x2 + w2, y2, x2 + w2 + r2, y2, colorSet.rumble, _hazeColor, hazeAlpha);
			_renderCanvas.drawQuad(x1 - w1, y1, x1 + w1, y1, x2 + w2, y2, x2 - w2, y2, colorSet.road, _hazeColor, hazeAlpha);

			/* Draw lane strips. */
			if (colorSet.lane > 0)
			{
				var l1:Number = calcLaneMarkerWidth(w1),
				l2:Number = calcLaneMarkerWidth(w2),
				lw1:Number = w1 * 2 / _lanes,
				lw2:Number = w2 * 2 / _lanes,
				lx1:Number = x1 - w1 + lw1,
				lx2:Number = x2 - w2 + lw2;

				for (var lane:int = 1 ;lane < _lanes; lx1 += lw1, lx2 += lw2, lane++)
				{
					_renderCanvas.drawQuad(lx1 - l1 / 2, y1, lx1 + l1 / 2, y1, lx2 + l2 / 2, y2, lx2 - l2 / 2, y2, colorSet.lane, _hazeColor, hazeAlpha);
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
		private function renderEntity(entity:RTEntity, sequenceID:String, scale:Number,
			destX:Number, destY:Number, offsetX:Number = 0.0, offsetY:Number = 0.0,
			clipY:Number = 0.0, hazeAlpha:Number = 1.0):void
		{
			if (!entity.object.image) return;
			
			var image:Image2D = entity.object.image;
			// TODO Remove and add handling of object state here!
			if (sequenceID)
			{
				var seq:RTObjectImageSequence = entity.object.sequences[sequenceID];
				if (seq)
				{
					image = seq.movieClip;
				}
			}
			
			scale *= entity.scale;
			
			/* Scale for projection AND relative to roadWidth. */
			var destW:Number = (image.width * scale * _widthHalf) * (_objectScale * _roadWidth);
			var destH:Number = (image.height * scale * _widthHalf) * (_objectScale * _roadWidth);
			
			destX = destX + (destW * offsetX);
			destY = destY + (destH * offsetY);

			var clipH:int = clipY ? mathMax(0, destY + destH - clipY) : 0;

			if (clipH < int(destH))
			{
				_renderCanvas.drawImage(image, destX, destY, destW, destH - clipH,
					(destW / image.width), _hazeColor, hazeAlpha);
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


		private function accel(v:Number, accel:Number, dt:Number):Number
		{
			return v + (accel * dt);
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
