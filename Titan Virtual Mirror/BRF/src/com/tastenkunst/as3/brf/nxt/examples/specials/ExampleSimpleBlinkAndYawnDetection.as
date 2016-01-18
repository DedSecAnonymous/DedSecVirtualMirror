package com.tastenkunst.as3.brf.nxt.examples.specials {
	import com.tastenkunst.as3.brf.nxt.BRFFaceShape;
	import com.tastenkunst.as3.brf.nxt.BRFState;
	import com.tastenkunst.as3.brf.nxt.examples.ExampleFaceTracking;
	import com.tastenkunst.as3.brf.nxt.utils.DrawingUtils;

	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;

	/**
	 * This is a simple eye blink and yawn class.
	 * 
	 * Everytime you blink, the yellow circle will be visible.
	 * The wider open your mouth is, the greener the red circle gets.
	 * 
	 * @author Marcel Klammer, Tastenkunst GmbH, 2015
	 */
	public class ExampleSimpleBlinkAndYawnDetection extends ExampleFaceTracking {
		
		public var _circleRed : Sprite;
		public var _circleGreen : Sprite;
		public var _circleYellow : Sprite;
		
		public var _oldFaceShapeVertices : Vector.<Number>;
		public var _timeOut : int = -1;
		
		/**
		 * We use the Rectangles that are preselected in ExampleBase.
		 */
		public function ExampleSimpleBlinkAndYawnDetection(
				cameraResolution : Rectangle = null,
				brfResolution : Rectangle = null,
				brfRoi : Rectangle = null,
				faceDetectionRoi : Rectangle = null,
				screenRect : Rectangle = null,
				maskContainer : Boolean = true,
				webcamInput : Boolean = true) {

			_oldFaceShapeVertices = new Vector.<Number>();
			
			super(cameraResolution, brfResolution, brfRoi, 
				faceDetectionRoi, screenRect, maskContainer, webcamInput);
		}
		
		/**
		 * When BRF is ready, we can set its params and BRFMode.
		 * 
		 * In this example we want to do face tracking, 
		 * so we set tracking mode to BRFMode.FACE_TRACKING.
		 */
		override public function onReadyBRF(event : Event) : void {
			super.onReadyBRF(event);
			
			_circleRed = new Sprite();
			_circleGreen = new Sprite();
			_circleYellow = new Sprite();
			
			_circleRed.graphics.beginFill(0xff0000);
			_circleRed.graphics.drawCircle(550, 400, 50);
			_circleRed.graphics.endFill();
			
			_circleGreen.graphics.beginFill(0x00ff00);
			_circleGreen.graphics.drawCircle(550, 400, 50);
			_circleGreen.graphics.endFill();
			_circleGreen.alpha = 0.0;
			
			_circleYellow.graphics.beginFill(0xffff00);
			_circleYellow.graphics.drawCircle(550, 300, 50);
			_circleYellow.graphics.endFill();
			_circleYellow.alpha = 0.1;
			
			addChild(_circleRed);
			addChild(_circleGreen);
			addChild(_circleYellow);
		}
		
		/**
		 * We don't need to overwrite the updateInput and updateBRF, but we
		 * need to draw the results for BRFMode.FACE_TRACKING.
		 */
		override public function updateGUI() : void {
			
			_draw.clear();
			
			// Get the current BRFState and faceShape.
			var state : String = _brfManager.state;
			var faceShape : BRFFaceShape = _brfManager.faceShape;
			
			// Draw BRFs region of interest, that got analysed:
			DrawingUtils.drawRect(_draw, _brfRoi, false, 1.0, 0xacfeff, 1.0);
	
			if(state == BRFState.FACE_DETECTION) {
				// Last update was face detection only, 
				// draw the face detection roi and lastDetectedFace:
				DrawingUtils.drawRect(_draw, _faceDetectionRoi);//, false, 1, 0xffff00, 1);
				
				var rect : Rectangle = _brfManager.lastDetectedFace;
				if(rect != null && rect.width != 0) {
					DrawingUtils.drawRect(_draw, rect, false, 1.0, 0xff7900, 1.0);
				}
			} else if(state == BRFState.FACE_TRACKING_START || state == BRFState.FACE_TRACKING) {
				// The found face rectangle got analysed in detail
				// draw the faceShape and its bounds:
				//DrawingUtils.drawTriangles(_draw, faceShape.faceShapeVertices, faceShape.faceShapeTriangles);
				DrawingUtils.drawTrianglesAsPoints(_draw, faceShape.faceShapeVertices);
				DrawingUtils.drawRect(_draw, faceShape.bounds);
				
				
				// Simple yawn detection
				
				var eyeDist : Number = Math.sqrt(
					(faceShape.points[36].x - faceShape.points[31].x) * (faceShape.points[36].x - faceShape.points[31].x) + 
					(faceShape.points[36].y - faceShape.points[31].y) * (faceShape.points[36].y - faceShape.points[31].y));
					
				var mouthDist : Number = Math.sqrt(
					(faceShape.points[57].x - faceShape.points[51].x) * (faceShape.points[57].x - faceShape.points[51].x) + 
					(faceShape.points[57].y - faceShape.points[51].y) * (faceShape.points[57].y - faceShape.points[51].y));
				
				var fac : Number = mouthDist / eyeDist;
				
				fac -= 0.35;
				
				if(fac < 0) fac = 0;
				
				fac *= 2.0;
				
				if(fac > 1.0) fac = 1.0;
			
				_circleGreen.alpha = fac;


				// simple blink detection
			
				if(_oldFaceShapeVertices.length == 0) storeFaceShapeVertices(faceShape.faceShapeVertices);
					
				var i : int = 27;
				var l : int = 27 + 5;
				var yLE : Number = 0;
				
				for(; i < l; i++) {
					yLE += faceShape.faceShapeVertices[i * 2 + 1] - _oldFaceShapeVertices[i * 2 + 1];
				}
				
				yLE /= 5;
				
				i = 32;
				l = 32 + 5;
				
				var yRE : Number = 0;
				
				for(; i < l; i++) {
					yRE += faceShape.faceShapeVertices[i * 2 + 1] - _oldFaceShapeVertices[i * 2 + 1];
				}
				
				yRE /= 5;
				
				var yN : Number = 0;
	
				yN += faceShape.faceShapeVertices[37 * 2 + 1] - _oldFaceShapeVertices[37 * 2 + 1];
				yN += faceShape.faceShapeVertices[45 * 2 + 1] - _oldFaceShapeVertices[45 * 2 + 1];			
				yN /= 2;
				
				var distLE : Number = yLE;
				var distRE : Number = yRE;
				var distN : Number = yN;
				
				var blinkRatio : Number = Math.abs((distLE + distRE) / distN); 
				
				trace("br: " + blinkRatio.toFixed(1) + " " + distLE.toFixed(1) + " " + distRE.toFixed(1));
				
				if((blinkRatio > 5 && (distLE > 0.3 || distRE > 0.3))) {
					blink();
				}
				
				storeFaceShapeVertices(faceShape.faceShapeVertices);
			}
		}

		private function blink() : void {
			_circleYellow.alpha = 1.0;
			
			if(_timeOut > -1) {
				clearTimeout(_timeOut);
			}
			
			_timeOut = setTimeout(resetBlink, 150);
		}

		private function resetBlink() : void {
			_circleYellow.alpha = 0.1;
		}

		private function storeFaceShapeVertices(faceShapeVertices : Vector.<Number>) : void {
			var i : int = 0;
			var l : int = faceShapeVertices.length;
			
			for(; i < l; i++) {
				_oldFaceShapeVertices[i] = faceShapeVertices[i]; 
			}
		}
	}
}