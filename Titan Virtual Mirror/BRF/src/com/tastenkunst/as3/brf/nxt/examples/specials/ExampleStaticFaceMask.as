package com.tastenkunst.as3.brf.nxt.examples.specials {
	import com.tastenkunst.as3.brf.nxt.BRFFaceShape;
	import com.tastenkunst.as3.brf.nxt.BRFMode;
	import com.tastenkunst.as3.brf.nxt.BRFState;
	import com.tastenkunst.as3.brf.nxt.examples.ExampleBase;
	import com.tastenkunst.as3.brf.nxt.utils.DrawingUtils;

	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;

	/**
	 * Uses super class ExampleBase to init BRF, Camera and GUI.
	 * 
	 * Sets tracking mode BRFMode.FACE_TRACKING and its params.
	 * Does update the candide properties (see onReadyBRF).
	 * 
	 * What it does: Click on the webcam image to set the
	 * currently visible face shape fixed. Than keep
	 * on moving to see, how the textures in that fixed
	 * shape are filled with the currently visible webcam image.
	 * 
	 * (And please, don't hide the BRF logo. If you need a 
	 * version without logo, just email us. Thanks!)
	 * 
	 * @author Marcel Klammer, Tastenkunst GmbH, 2014
	 */
	public class ExampleStaticFaceMask extends ExampleBase {
		
		/**
		 * Switch to candide, if you want
		 */
		public var _useCandide : Boolean = true;
		
		public var _candideVertices : Vector.<Number>;
		public var _faceShapeVertices : Vector.<Number>;
		
		public var _drawSpriteFrontal : Sprite;
		public var _drawFrontal : Graphics;
		public var _drawSpriteFrontalTexture : Sprite;
		public var _drawFrontalTexture : Graphics;
		
		/**
		 * We use the Rectangles that are preselected in ExampleBase.
		 */
		public function ExampleStaticFaceMask(
				cameraResolution : Rectangle = null,
				brfResolution : Rectangle = null,
				brfRoi : Rectangle = null,
				faceDetectionRoi : Rectangle = null,
				screenRect : Rectangle = null,
				maskContainer : Boolean = false,
				webcamInput : Boolean = true) {

			super(cameraResolution, brfResolution, brfRoi, 
				faceDetectionRoi, screenRect, maskContainer, webcamInput);
		}
		
		/**
		 * Add some more elements to draw the right site and the fixed shape. 
		 */
		override public function initGUI() : void {
			super.initGUI();
						
			_drawSpriteFrontalTexture = new Sprite();
			_drawSpriteFrontalTexture.x = 640;
			_drawSpriteFrontalTexture.scaleX = _drawSprite.scaleX;
			_drawSpriteFrontalTexture.scaleY = _drawSprite.scaleY;
			_drawFrontalTexture = _drawSpriteFrontalTexture.graphics;
			
			_drawSpriteFrontal = new Sprite();
			_drawSpriteFrontal.x = 640;
			_drawSpriteFrontal.scaleX = _drawSprite.scaleX;
			_drawSpriteFrontal.scaleY = _drawSprite.scaleY;
			_drawFrontal = _drawSpriteFrontal.graphics;
			
			_container.addChild(_drawSpriteFrontalTexture);
			_container.addChild(_drawSpriteFrontal);
		}

		/**
		 * When BRF is ready, we can set its params and BRFMode.
		 * 
		 * In this example we want to do face tracking, 
		 * so we set tracking mode to BRFMode.FACE_TRACKING.
		 */
		override public function onReadyBRF(event : Event) : void {

			_brfManager.setFaceDetectionVars(5.0, 1.0, 14.0, 0.06, 6, false);
			_brfManager.setFaceDetectionROI(_faceDetectionRoi.x, _faceDetectionRoi.y, 
					_faceDetectionRoi.width, _faceDetectionRoi.height);
			_brfManager.setFaceTrackingVars(80, 500, 1);
			_brfManager.candideEnabled = _useCandide;
			_brfManager.candideActionUnitsEnabled = _useCandide;
			
			_brfManager.mode = BRFMode.FACE_TRACKING;

			super.onReadyBRF(event);			
		}
		
		/**
		 * After a click, the texture of the current webcam image 
		 * will be drawn into a fixes face shape.
		 */
		override public function updateGUI() : void {
			
			_draw.clear();
			
			// Get the current BRFState and faceShape.
			var state : String = _brfManager.state;
			var faceShape : BRFFaceShape = _brfManager.faceShape;
			
			// Draw BRFs region of interest, that got analysed:
			DrawingUtils.drawRect(_draw, _brfRoi, false, 2, 0xacfeff, 1.0);
			
			var canClick : Boolean = false;
	
			if(state == BRFState.FACE_DETECTION) {
				DrawingUtils.drawRect(_draw, _faceDetectionRoi, false, 1, 0xffff00, 1);
				
				var rect : Rectangle = _brfManager.lastDetectedFace;
				if(rect != null && rect.width != 0) {
					DrawingUtils.drawRect(_draw, rect, false, 1, 0xff7900, 1);
				}
			} else if(state == BRFState.FACE_TRACKING_START) {
				DrawingUtils.drawTriangles(_draw, faceShape.faceShapeVertices, faceShape.faceShapeTriangles);
			} else if(state == BRFState.FACE_TRACKING) {
				if(_useCandide) {
					DrawingUtils.drawTriangles(_draw, faceShape.candideShapeVertices, faceShape.candideShapeTriangles);
				} else {
					DrawingUtils.drawTriangles(_draw, faceShape.faceShapeVertices, faceShape.faceShapeTriangles);
				}
				canClick = true;
			}
			
			// Clicking on the webcam image is only allowed, when the face tracking is at work.
			if(canClick) {
				if(!_clickArea.hasEventListener(MouseEvent.CLICK)) {
					_clickArea.buttonMode = true;
					_clickArea.useHandCursor = true;
					_clickArea.mouseChildren = false;
					_clickArea.addEventListener(MouseEvent.CLICK, onClicked);
				}
			} else {
				_clickArea.useHandCursor = false;
				_clickArea.removeEventListener(MouseEvent.CLICK, onClicked);
			}
			
			// Draw the fixes shape.
			_drawFrontalTexture.clear();
			
			var uvData : Vector.<Number>;
			var i : int = 0;
			var l : int;
			
			if(_candideVertices != null) {
				_drawFrontalTexture.beginBitmapFill(_brfBmd);
				
				uvData = faceShape.candideShapeVertices.concat();
				
				for(l = uvData.length; i < l; i+=2) {
					uvData[i] /= _brfBmd.width;
					uvData[i+1] /= _brfBmd.height;
				}
				
				_drawFrontalTexture.drawTriangles(_candideVertices, faceShape.candideShapeTriangles, uvData);
				_drawFrontalTexture.endFill();
			} else if(_faceShapeVertices != null) {
				_drawFrontalTexture.beginBitmapFill(_brfBmd);
				
				uvData = faceShape.faceShapeVertices.concat();
				
				for(l = uvData.length; i < l; i+=2) {
					uvData[i] /= _brfBmd.width;
					uvData[i+1] /= _brfBmd.height;
				}
				
				_drawFrontalTexture.drawTriangles(_faceShapeVertices, faceShape.faceShapeTriangles, uvData);
				_drawFrontalTexture.endFill();
			}
		}

		private function onClicked(event : MouseEvent) : void {
			_drawFrontal.clear();
				
			if(_useCandide) {
				_candideVertices = _brfManager.faceShape.candideShapeVertices.concat();
				
				DrawingUtils.drawTriangles(_drawFrontal, _candideVertices, _brfManager.faceShape.candideShapeTriangles);
				DrawingUtils.drawTrianglesAsPoints(_drawFrontal, _candideVertices);
			} else {
				_faceShapeVertices = _brfManager.faceShape.faceShapeVertices.concat();
				
				DrawingUtils.drawTriangles(_drawFrontal, _faceShapeVertices, _brfManager.faceShape.faceShapeTriangles);
				DrawingUtils.drawTrianglesAsPoints(_drawFrontal, _faceShapeVertices);
			}
			
			_drawSpriteFrontal.alpha = 0.2;
		}
	}
}