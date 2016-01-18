package com.tastenkunst.as3.brf.nxt.examples.specials {
	import com.tastenkunst.as3.brf.nxt.BRFFaceShape;
	import com.tastenkunst.as3.brf.nxt.BRFState;
	import com.tastenkunst.as3.brf.nxt.examples.ExampleFaceTracking;
	import com.tastenkunst.as3.brf.nxt.utils.DrawingUtils;

	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Rectangle;

	/**
	 * This is a simple smile detection class. 
	 * 
	 * It adds a red and green circle. 
	 * The more you smile the greener the circle gets.
	 * 
	 * @author Marcel Klammer, Tastenkunst GmbH, 2015
	 */
	public class ExampleSimpleSmileDetection extends ExampleFaceTracking {
		
		public var _circleRed : Sprite;
		public var _circleGreen : Sprite;

		/**
		 * We use the Rectangles that are preselected in ExampleBase.
		 */
		public function ExampleSimpleSmileDetection(
				cameraResolution : Rectangle = null,
				brfResolution : Rectangle = null,
				brfRoi : Rectangle = null,
				faceDetectionRoi : Rectangle = null,
				screenRect : Rectangle = null,
				maskContainer : Boolean = true,
				webcamInput : Boolean = true) {
			
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
			
			_circleRed.graphics.beginFill(0xff0000);
			_circleRed.graphics.drawCircle(550, 400, 50);
			_circleRed.graphics.endFill();
			
			_circleGreen.graphics.beginFill(0x00ff00);
			_circleGreen.graphics.drawCircle(550, 400, 50);
			_circleGreen.graphics.endFill();
			_circleGreen.alpha = 0.0;
			
			addChild(_circleRed);
			addChild(_circleGreen);
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
				
				
				// Simple smile detection
				
				var leftMouthCornerX : Number = faceShape.faceShapeVertices[48 * 2];
				var leftMouthCornerY : Number = faceShape.faceShapeVertices[48 * 2 + 1];
				var rightMouthCornerX : Number = faceShape.faceShapeVertices[54 * 2];
				var rightMouthCornerY : Number = faceShape.faceShapeVertices[54 * 2 + 1];
				
				var distMouth : Number = Math.sqrt(
					(rightMouthCornerX - leftMouthCornerX) * (rightMouthCornerX - leftMouthCornerX) + 
					(rightMouthCornerY - leftMouthCornerY) * (rightMouthCornerY - leftMouthCornerY));
				
				var leftEyeCenterX : Number = faceShape.faceShapeVertices[31 * 2];
				var leftEyeCenterY : Number = faceShape.faceShapeVertices[31 * 2 + 1];
				var rightEyeCenterX : Number = faceShape.faceShapeVertices[36 * 2];
				var rightEyeCenterY : Number = faceShape.faceShapeVertices[36 * 2 + 1];
				
				var distEyes : Number = Math.sqrt(
					(rightEyeCenterX - leftEyeCenterX) * (rightEyeCenterX - leftEyeCenterX) + 
					(rightEyeCenterY - leftEyeCenterY) * (rightEyeCenterY - leftEyeCenterY));
					
				var faceSmileFactor : Number = distMouth / distEyes;
				
				if(faceSmileFactor > 1.0) faceSmileFactor = 1.0;
				if(faceSmileFactor < 0.75) faceSmileFactor = 0.75;
				
				faceSmileFactor -= 0.75;
				faceSmileFactor *= 4;
								
				_circleGreen.alpha = faceSmileFactor;
			}
		}
	}
}