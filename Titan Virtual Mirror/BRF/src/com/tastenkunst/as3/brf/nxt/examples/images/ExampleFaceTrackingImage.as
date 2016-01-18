package com.tastenkunst.as3.brf.nxt.examples.images {
	import com.tastenkunst.as3.brf.nxt.BRFFaceShape;
	import com.tastenkunst.as3.brf.nxt.BRFMode;
	import com.tastenkunst.as3.brf.nxt.BRFState;
	import com.tastenkunst.as3.brf.nxt.examples.ExampleBase;
	import com.tastenkunst.as3.brf.nxt.utils.DrawingUtils;

	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.SecurityErrorEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	import flash.utils.setTimeout;

	/**
	 * v3.0.10: Added a new method: _brfManager.updateByEyes(...);
	 * It takes the BitmapData, left and right eye position and numOfUpdates.
	 * This method skips face detection and starts FaceShape Tracking based
	 * on the eyes. The only thing you have to do: click on the eyes.
	 * 
	 * This works better than the automatic face detection, but again:
	 * Getting a correct face shape from a single image is a bit of a lucky shot.
	 * 
	 * @author Marcel Klammer, Tastenkunst GmbH, 2014
	 */
	public class ExampleFaceTrackingImage extends ExampleBase {
		
		// Some images of some nice guys ;)
		public var _imageURLs : Array = [
			"media/images/brf_example_image_marcel.jpg",
			"media/images/brf_example_image_chris.jpg"
		];
		public var _images : Vector.<Loader> = new Vector.<Loader>();
		public var _image : Loader;
		
		public var _leftEye : Point;
		public var _rightEye : Point;

		/**
		 * BRF should be initialized only once. That's why we will need
		 * to create a square BitmapData to work on to get horizontal and
		 * vertical images analysed correctly.
		 */
		public function ExampleFaceTrackingImage(
				cameraResolution : Rectangle = null,
				brfResolution : Rectangle = null,
				brfRoi : Rectangle = null,
				faceDetectionRoi : Rectangle = null,
				screenRect : Rectangle = null,
				maskContainer : Boolean = true,
				webcamInput : Boolean = false) {
			
			// That will change based on the input image size.
			cameraResolution	= cameraResolution	|| new Rectangle(0, 0, 640, 480);
			// Squared.
			brfResolution		= brfResolution		|| new Rectangle(0, 0, 480, 480);
			// Analyse it all.
			brfRoi				= brfRoi			|| new Rectangle(0, 0, 480, 480);
			// Analyse it all.
			faceDetectionRoi	= faceDetectionRoi	|| new Rectangle(0, 0, 480, 480);
			// Show it all.
			screenRect			= screenRect		|| new Rectangle(0, 0, 640, 640);
			
			// Load the images and store them.
			
			var i : int = 0;
			var l : int = _imageURLs.length;
			var loader : Loader;
			
			while(i < l) {
				loader = new Loader();
				loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, function(e : Event) : void {trace("security error");});
				loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function(e : Event) : void {trace("io error");});
				loader.load(new URLRequest(_imageURLs[i]));
				
				_images.push(loader);
				++i;
			}
			_image = _images[_images.length - 1];
			
			super(cameraResolution, brfResolution, brfRoi, 
				faceDetectionRoi, screenRect, maskContainer, webcamInput);
		}
		
		/**
		 * We are working with single image in this example.
		 * So no need for a Camera or Video.
		 */
		override public function init() : void {
			initGUI();
			initBRF();
			//initCamera();
		}
		
		/**
		 * We need to add the eye markers, 2 simple orange points.
		 * Just click on the eyes to set them.
		 */
		override public function initGUI() : void {
			super.initGUI();
			
			_clickArea.buttonMode = true;
			_clickArea.useHandCursor = true;
			_clickArea.mouseChildren = false;
			
			_leftEye = new Point(-1, -1);
			_rightEye = new Point(-1, -1);
		}
		
		/**
		 * When BRF is ready, we can set its params and BRFMode.
		 * 
		 * In this example we want to do face tracking, 
		 * so we set tracking mode to BRFMode.FACE_TRACKING.
		 */
		override public function onReadyBRF(event : Event) : void {
			
			// Set the basic face detection parameters.
			_brfManager.setFaceDetectionVars(4.0, 1.0, 30.0, 0.04, 12, false);
			_brfManager.setFaceDetectionROI(
					_faceDetectionRoi.x, _faceDetectionRoi.y, 
					_faceDetectionRoi.width, _faceDetectionRoi.height);
					
			// Set the face tracking parameters. 0 for the less strickt reset behavior.
			_brfManager.setFaceTrackingVars(80, 500, 0);
			
			// We don't need CandideShape tracking here.
			// (Only if you want to build your own 3D engine single image example.)
			_brfManager.candideEnabled = false;
			_brfManager.candideActionUnitsEnabled = false;
			
			_brfManager.mode = BRFMode.FACE_TRACKING;
			
			// Change the input image.
			changeImage();
			
			// Don't add an ENTER_FRAME listener here.
			//super.onReadyBRF(event);
		}

		/**
		 * Just to demonstrate how to switch images, you can change them by click. 
		 */
		public function changeImage(event : MouseEvent = null) : void {
			
			_draw.clear();
			
			// Remove click listener until we are finished with the current image.
			_clickArea.removeEventListener(MouseEvent.CLICK, changeImage);
			
			// Remove old image and reset its size.
			if(_container.contains(_image)) {
				_image.x = 0.0;
				_image.y = 0.0;
				_image.scaleX = 1.0;
				_image.scaleY = 1.0;
				_container.removeChild(_image);
			}
			
			// Get next index and image.
			var i : int = _images.indexOf(_image) + 1;
			
			if(i >= _images.length) {
				i = 0;
			}
			
			_image = _images[i];
			
			// Add it in the container.
			_container.addChildAt(_image, 0);
			
			// Update input size to get the correct results.
			// true:  update _screenRect also to view the whole image
			// false: don't update _screenRect.
			updateCameraResolution(_image.width, _image.height, true);
			
			// Set the image like the video to match screenRect.
			_image.transform.matrix = _videoToScreenMatrix.clone();
			
			_clickArea.addEventListener(MouseEvent.CLICK, onClickedDots);
		}
		
		/**
		 * After switching the image, click on the eyes to start the tracking.
		 */
		public function onClickedDots(event : MouseEvent) : void {
			var x : int = event.localX;
			var y : int = event.localY;
			
			if(_leftEye.x == -1) {
				_leftEye.x = x;
				_leftEye.y = y;
				
				DrawingUtils.drawPoint(_draw, _leftEye, 5, false, 0xff7900, 1.0);
			} else if(_rightEye.x == -1) {
				_rightEye.x = x;
				_rightEye.y = y;	
				
				DrawingUtils.drawPoint(_draw, _rightEye, 5, false, 0xff7900, 1.0);
				
				_clickArea.removeEventListener(MouseEvent.CLICK, onClickedDots);
				
				// That timeout is just to see the set marker first.
				setTimeout(update, 100);
			}
		}
		
		/**
		 * Instead of the _video we need to fill the image into BRF.
		 */
		override public function updateInput() : void {
			_brfBmd.draw(_image, _videoToBRFMatrix);
		}

		/**
		 * And BRF needs to skip face detection and use updateByEyes
		 * instead of update.
		 */
		override public function updateBRF() : void {
			_brfManager.updateByEyes(_brfBmd, _leftEye, _rightEye, 35);
		}

		/**
		 * Now draw the results for BRFMode.FACE_TRACKING.
		 */
		override public function updateGUI() : void {
			
			_draw.clear();
			
			DrawingUtils.drawPoint(_draw, _leftEye, 5, false, 0xff7900, 1.0);
			DrawingUtils.drawPoint(_draw, _rightEye, 5, false, 0xff7900, 1.0);

			// Get the current BRFState and faceShape.
			var state : String = _brfManager.state;
			var faceShape : BRFFaceShape = _brfManager.faceShape;
			var rect : Rectangle = _brfManager.lastDetectedFace;

			// Draw BRFs region of interest, that got analysed:
			DrawingUtils.drawRect(_draw, _brfRoi, false, 1.0, 0xacfeff, 1.0);
			
			if(state == BRFState.FACE_DETECTION) {
				// Draw the face detection roi.
				DrawingUtils.drawRect(_draw, _faceDetectionRoi);//, false, 1, 0xffff00, 1);
				
				// Draw all found face regions:
				DrawingUtils.drawRects(_draw, _brfManager.lastDetectedFaces);
				
				// And draw the one result, that got calculated from all the lastDetectedFaces.
				if(rect != null && rect.width != 0) {
					DrawingUtils.drawRect(_draw, rect, false, 1.0, 0xff7900, 1.0);
				}
			} else if(state == BRFState.FACE_TRACKING_START || state == BRFState.FACE_TRACKING) {
				// Draw the morphed face shape and its bounds.
				DrawingUtils.drawTrianglesAsPoints(_draw, faceShape.faceShapeVertices);
				DrawingUtils.drawRect(_draw, faceShape.bounds);
				
				// And draw the one result, that got calculated from leftEye, rightEye
				if(rect != null && rect.width != 0) {
					DrawingUtils.drawRect(_draw, rect, false, 1.0, 0xff7900, 1.0);
				}
			}
			
			// Reset the points.
			_leftEye.x = -1.0;
			_leftEye.y = -1.0;
			_rightEye.x = -1.0;
			_rightEye.y = -1.0;
			
			_clickArea.addEventListener(MouseEvent.CLICK, changeImage);
		}
	}
}