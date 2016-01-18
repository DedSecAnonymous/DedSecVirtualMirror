package com.tastenkunst.as3.brf.nxt.examples.images {
	import com.tastenkunst.as3.brf.nxt.BRFMode;
	import com.tastenkunst.as3.brf.nxt.BRFState;
	import com.tastenkunst.as3.brf.nxt.examples.ExampleBase;
	import com.tastenkunst.as3.brf.nxt.utils.DrawingUtils;

	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.SecurityErrorEvent;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;

	/**
	 * Automatic face detection on a single image.
	 *
	 * This is a bit of a lucky shot. There is no moving or changing face,
	 * which would be much easier to find.
	 * 
	 * So face detection can fail on a still image and even if
	 * the face detection finds a face, it is likely, that the face shape
	 * morphes into something, that's just wrong.
	 * 
	 * Anyway. The automatic face detection works by altering the 
	 * params until a face was detected (might fail though).
	 * 
	 * @author Marcel Klammer, Tastenkunst GmbH, 2014
	 */
	public class ExampleFaceDetectionImage extends ExampleBase {
		
		// Some images of some nice guys ;)
		public var _imageURLs : Array = [
			"media/images/brf_example_image_marcel.jpg",
			"media/images/brf_example_image_chris.jpg"
		];
		public var _images : Vector.<Loader> = new Vector.<Loader>();
		public var _image : Loader;

		/**
		 * BRF should be initialized only once. That's why we will need
		 * to create a square BitmapData to work on to get horizontal and
		 * vertical images analysed correctly.
		 */
		public function ExampleFaceDetectionImage(
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
		
		override public function initGUI() : void {
			super.initGUI();
			
			_clickArea.buttonMode = true;
			_clickArea.useHandCursor = true;
			_clickArea.mouseChildren = false;
		}
		
		/**
		 * When BRF is ready, we can set its params and BRFMode.
		 * 
		 * In this example we want to do just face detection, a simple rectangle
		 * around a found face, so we set tracking mode to BRFMode.FACE_DETECTION.
		 */
		override public function onReadyBRF(event : Event) : void {
			
			// Set the basic face detection parameters.
			_brfManager.setFaceDetectionVars(4.0, 1.0, 30.0, 0.04, 12, false);
			_brfManager.setFaceDetectionROI(
					_faceDetectionRoi.x, _faceDetectionRoi.y, 
					_faceDetectionRoi.width, _faceDetectionRoi.height
			);
			_brfManager.mode = BRFMode.FACE_DETECTION;
			
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
			
			// Start auto detection on that new image.
			autoDetect();
		}

		/**
		 * Try to auto detect a face in a single image.
		 */
		public function autoDetect() : void {
			
			// Draw the image.
			updateInput();
			
			// Now we go through the image several times with different settings
			// to eventually find a face in it.
			
			var foundFace : Boolean = false;
			var baseScale : Number = 4.0;			// Start with 4.0 and increase it by 0.05 up to 5.0.
			var scaleIncrement : Number = 1.0;		// Make bigger steps, but decrease stepsize by 0.1, if nothing was found.
			
//			for(; baseScale < 5.0 && !foundFace; baseScale += 0.05) {
				
				scaleIncrement = 1.0;
				
				for(; scaleIncrement >= 0.1 && !foundFace; scaleIncrement -= 0.2) {
			
					_brfManager.setFaceDetectionVars(baseScale, scaleIncrement, 30.0, 0.04, 12, false);
					
					updateBRF();
					
					var rect : Rectangle = _brfManager.lastDetectedFace;
					if(rect != null && rect.width != 0) {
						foundFace = true;
						trace("face detected: ", baseScale, scaleIncrement);
					}
				}
//			}
			
			// Draw the results.
			updateGUI();
			
			// Add the click listener again to switch to the next image.
			_clickArea.addEventListener(MouseEvent.CLICK, changeImage);
		}
		
		/**
		 * Instead of the _video we need to fill the image into BRF.
		 */
		override public function updateInput() : void {
			_brfBmd.draw(_image, _videoToBRFMatrix);
		}
		
		/**
		 * Now draw the results for BRFMode.FACE_DETECTION.
		 */
		override public function updateGUI() : void {
			
			_draw.clear();
			
			// Get the current BRFState.
			var state : String = _brfManager.state;
			var rect : Rectangle = _brfManager.lastDetectedFace;

			// Draw BRFs region of interest, that got analysed:
			DrawingUtils.drawRect(_draw, _brfRoi, false, 1.0, 0xacfeff, 1.0);
	
			if(state == BRFState.FACE_DETECTION) {
				// Draw the face detection roi.
				DrawingUtils.drawRect(_draw, _faceDetectionRoi, false, 1.0, 0xffff00, 1.0);
				
				// Draw all found face regions:
				DrawingUtils.drawRects(_draw, _brfManager.lastDetectedFaces);
				
				// And draw the one result, that got calculated from all the lastDetectedFaces.
				
				if(rect != null && rect.width != 0) {
					DrawingUtils.drawRect(_draw, rect, false, 3.0, 0xff7900, 1.0);
				}
			}
		}
	}
}