package com.tastenkunst.as3.brf.nxt.examples.specials {
	import flash.events.MouseEvent;
	import com.tastenkunst.as3.brf.nxt.BRFFaceShape;
	import com.tastenkunst.as3.brf.nxt.BRFMode;
	import com.tastenkunst.as3.brf.nxt.BRFState;
	import com.tastenkunst.as3.brf.nxt.examples.ExampleFaceTracking;
	import com.tastenkunst.as3.brf.nxt.utils.DrawingUtils;

	import flash.events.Event;
	import flash.geom.Rectangle;

	/**
	 * This subclass of ExampleFaceTracking shows how to set custom resolutions.
	 * And it let's you click to visualize the single face tracking steps.
	 * 
	 * We want to use a 720p camera, also show that 720p video on screen,
	 * but BRF will operate on a 640x480 BitmapData and limit the area it
	 * uses from that image to an even smaller chunk.
	 * 
	 * (And please, don't hide the BRF logo. If you need a 
	 * version without logo, just email us. Thanks!)
	 * 
	 * @author Marcel Klammer, Tastenkunst GmbH, 2014
	 */
	public class ExampleComponentFlow extends ExampleFaceTracking {
		
		public function ExampleComponentFlow() {
			
			// 720p camera resolution + 520x400 BRF roi + 320x320 face detection roi + 720p screenRect
			super(
				new Rectangle(   0,   0, 1280, 720),	// Camera resolution
				new Rectangle(   0,   0,  640, 480),	// BRF BitmapData size
				new Rectangle(  60,  40,  520, 400),	// BRF region of interest within BRF BitmapData size
				new Rectangle( 160,  80,  320, 320),	// BRF face detection region of interest within BRF BitmapData size
				new Rectangle(   0,   0, 1280, 720),	// Shown video screen rectangle
				true,									// Mask the video to exactly match the screenRect area.
				true									// true for webcam input, false for single image input
			);
			
			// All other methods, params etc will be set in and taken from ExampleFaceTracking.
			
			// If you have black areas in your video, your camera may much likely not
			// support a 1280x720 resolution. You can try 1280x960 (which is the same
			// aspect ratio as 640x480)
			// If that's not working either, you might want to use the default 640x480
			// or get a better camera?
			
//			super(
//				new Rectangle(   0,   0, 1280, 960),	// Camera resolution
//				new Rectangle(   0,   0,  640, 480),	// BRF BitmapData size
//				new Rectangle(  60,  40,  520, 400),	// BRF region of interest within BRF BitmapData size
//				new Rectangle( 160, 160,  320, 320),	// BRF face detection region of interest within BRF BitmapData size
//				new Rectangle(   0,   0, 1280, 960),	// Shown video screen rectangle
//				true,									// Mask the video to exactly match the screenRect area.
//				true									// true for webcam input, false for single image input
//			);
		}
		
		override public function initGUI() : void {
			super.initGUI();
			
			_clickArea.buttonMode = true;
			_clickArea.useHandCursor = true;
			_clickArea.mouseChildren = false;
		}
		
		/**
		 * When BRF is ready, we can set its params and BRFMode.
		 * 
		 * In this example we want to do face detection and face tracking, 
		 * so we set tracking mode to BRFMode.FACE_DETECTION first.
		 */
		override public function onReadyBRF(event : Event) : void {

			_brfManager.setFaceDetectionVars(5.0, 1.0, 14.0, 0.06, 6, false);
			_brfManager.setFaceDetectionROI(_faceDetectionRoi.x, _faceDetectionRoi.y, 
					_faceDetectionRoi.width, _faceDetectionRoi.height);
			_brfManager.setFaceTrackingVars(80, 500);
			_brfManager.candideEnabled = false;
			_brfManager.candideActionUnitsEnabled = false;
			
			// We cycle through the modes and states and start with face detection.
			_brfManager.mode = BRFMode.FACE_DETECTION;
			
			_clickArea.addEventListener(MouseEvent.CLICK, onClicked);

			super.onReadyBRF(event);
		}

		/**
		 * Clicking on the webcam image will change the BRFMode to demonstrate 
		 * the different steps BRF walks through.
		 */
		private function onClicked(event : MouseEvent) : void {
			if(_brfManager.mode == BRFMode.FACE_DETECTION) {
				_brfManager.mode = BRFMode.FACE_TRACKING;
				_brfManager.candideEnabled = false;
				_brfManager.candideActionUnitsEnabled = false;
			} else if(_brfManager.candideEnabled == false) {
				_brfManager.candideEnabled = true;
				_brfManager.candideActionUnitsEnabled = true;
			} else {
				_brfManager.mode = BRFMode.FACE_DETECTION;	
			}
		}
		
		/**
		 * We don't need to overwrite the updateInput and updateBRF, but we
		 * need to draw the results for every BRFMode.
		 */
		override public function updateGUI() : void {
			
			_draw.clear();
			
			var state : String = _brfManager.state;
			var faceShape : BRFFaceShape = _brfManager.faceShape;
			var rect : Rectangle = _brfManager.lastDetectedFace;
			
			DrawingUtils.drawRect(_draw, _brfRoi, false, 1.0, 0xacfeff, 1.0);
	
			if(state == BRFState.FACE_DETECTION) {
				DrawingUtils.drawRect(_draw, _faceDetectionRoi);//, false, 1, 0xffff00, 1);
				DrawingUtils.drawRects(_draw, _brfManager.lastDetectedFaces);
				
				if(rect != null && rect.width != 0) {
					DrawingUtils.drawRect(_draw, rect, false, 5.0, 0xff7900, 1.0);
				}
			} else if(state == BRFState.FACE_TRACKING_START || state == BRFState.FACE_TRACKING) {
				if(!_brfManager.candideEnabled) {
					DrawingUtils.drawTriangles(_draw, faceShape.faceShapeVertices, faceShape.faceShapeTriangles);
					DrawingUtils.drawTrianglesAsPoints(_draw, faceShape.faceShapeVertices);
					DrawingUtils.drawRect(_draw, faceShape.bounds);
				} else {
					 if(state == BRFState.FACE_TRACKING_START) {
						DrawingUtils.drawTriangles(_draw, faceShape.faceShapeVertices, faceShape.faceShapeTriangles);
						DrawingUtils.drawTrianglesAsPoints(_draw, faceShape.faceShapeVertices);
						DrawingUtils.drawRect(_draw, faceShape.bounds);
					} else if(state == BRFState.FACE_TRACKING) {
						DrawingUtils.drawTriangles(_draw, faceShape.candideShapeVertices, faceShape.candideShapeTriangles);
						DrawingUtils.drawTrianglesAsPoints(_draw, faceShape.candideShapeVertices);
					}
				}
			}
		}
	}
}
