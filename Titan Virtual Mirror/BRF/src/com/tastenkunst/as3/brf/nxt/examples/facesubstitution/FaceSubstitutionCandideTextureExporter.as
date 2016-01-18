package com.tastenkunst.as3.brf.nxt.examples.facesubstitution {
	import com.adobe.images.PNGEncoder;
	import com.tastenkunst.as3.brf.nxt.BRFFaceShape;
	import com.tastenkunst.as3.brf.nxt.BRFState;
	import com.tastenkunst.as3.brf.nxt.utils.DrawingUtils;

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.SecurityErrorEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.FileReference;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.setTimeout;

	/**
	 * This is an exporter for textures and their UV data from BRF results.
	 * These textures and UV data can be used in the FaceSubstitutionViewer
	 * to overlay a persons face with another face.
	 * 
	 * You need to add your images to the _imageURLs Array.
	 * 
	 * Once the app loaded all images, you will need to click on the eyes of the face.
	 * This will start BRF. If the result doesn't look correct, click again to reset
	 * the results, choose slightly different points around the eyes to start BRF again.
	 * 
	 * Once a face shape looks correct, click generate to test your face overlay.
	 * You can now export both files (texture.png and uv_data.txt).
	 * 
	 * @author Marcel Klammer, Tastenkunst GmbH, 2015
	 */
	public class FaceSubstitutionCandideTextureExporter extends FaceSubstitutionCandideViewer {
		
		// Add your urls to your images here.
		public var _imageURLs : Array = [
			"media/images/brf_example_image_marcel.jpg",
			"media/images/brf_example_image_chris.jpg"
		];
		public var _images : Vector.<Loader> = new Vector.<Loader>();
		public var _image : Loader;
		public var _numLoadedImages : int = 0;
		
		public var _leftEye : Point;
		public var _rightEye : Point;
		public var _origin : Point;
		public var _candideBounds : Rectangle;
		
		public var _imageSrc : Bitmap;
		public var _textureBounds : Rectangle;
		
		public var _mode : int = 0;
		
		public var _btSwitchImage : Button;
		public var _btGenerate : Button;
		public var _btExportTexture : Button;
		public var _btExportUVData : Button;
		
		/**
		 * Let's use square BRF BitmapData to get the whole center of the loaded image covered.
		 * Make sure, that your loaded images contain a face in the center of your image. Otherwise
		 * BRF will not be able to process it.
		 */
		public function FaceSubstitutionCandideTextureExporter() {

			var cameraResolution : Rectangle	= new Rectangle(0, 0, 640, 480);
			var brfResolution : Rectangle		= new Rectangle(0, 0, 480, 480);
			var brfRoi : Rectangle				= new Rectangle(0, 0, 480, 480);
			var faceDetectionRoi : Rectangle	= new Rectangle(0, 0, 480, 480);
			var screenRect : Rectangle			= new Rectangle(0, 0, 640, 640);
			
			super(cameraResolution, brfResolution, brfRoi, 
				faceDetectionRoi, screenRect, false, false);
		}
		
		/**
		 * No need for a camera for the start.
		 */
		override public function init() : void {
			initGUI();
			initBRF();
			//initCamera();
		}

		/**
		 * BRF is ready. Now load all images and check with they all got loaded.
		 */
		override public function onReadyBRF(event : Event) : void {
			super.onReadyBRF(event);
						
			removeDrawSpriteMask();
			removeEventListener(Event.ENTER_FRAME, update);
			
			// Load the images and store them.
			
			var i : int = 0;
			var l : int = _imageURLs.length;
			var loader : Loader;
			
			for(; i < l; i++) {
				loader = new Loader();
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onComplete);
				loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, function(e : Event) : void {trace("security error");});
				loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function(e : Event) : void {trace("io error");});
				loader.load(new URLRequest(_imageURLs[i]));
				
				_images.push(loader);
			}
			
			_image = _images[0];
		}

		/**
		 * When all images had been we generate the UI and choose the first image.
		 */
		public function onComplete(event : Event) : void {
			_numLoadedImages++;
			
			if(_numLoadedImages == _images.length) {
				_clickArea.buttonMode = true;
				_clickArea.useHandCursor = true;
				_clickArea.mouseChildren = false;
				
				_leftEye = new Point(-1, -1);
				_rightEye = new Point(-1, -1);
				_origin = new Point(0, 0);
				_candideBounds = new Rectangle();
			
				_btSwitchImage =	createButton("next image", 240, 5, onClickedNextImage); 
				_btGenerate =		createButton("generate and test mask", 240, 35, onClickedGenerate); 
				_btExportTexture =	createButton("export texture", 240, 65, onClickedExportTexture); 
				_btExportUVData =	createButton("export uv data", 240, 95, onClickedExportUVData); 
				
				changeImage(_image.content as Bitmap);
			}
		}
		
		/**
		 * Changes to a new image. Resets the old image if necessary.
		 */
		public function changeImage(image : Bitmap) : void {
			_mode = 0;
			
			mirrored = false;
			
			_draw.clear();
			
			removeEventListener(Event.ENTER_FRAME, update);
			
			// Remove click listener until we are finished with the current image.
			
			_clickArea.removeEventListener(MouseEvent.CLICK, changeImage);
			
			// Remove old image and reset its size.
			if(_imageSrc != null) {
				_imageSrc.x = 0.0;
				_imageSrc.y = 0.0;
				_imageSrc.scaleX = 1.0;
				_imageSrc.scaleY = 1.0;
				
				if(_container.contains(_imageSrc)) {
					_container.removeChild(_imageSrc);
				}
			}
			
			if(_container.contains(_video)) {
				_container.removeChild(_video);
			}
			
			_imageSrc = image;
			removeDrawSpriteMask();
			_container.addChild(_drawSprite);
			
			// Add it in the container.
			_container.addChildAt(_imageSrc, 0);
			
			// Update input size to get the correct results.
			// true:  update _screenRect also to view the whole image
			// false: don't update _screenRect.
			updateCameraResolution(_imageSrc.width, _imageSrc.height, true);
			
			// Set the image like the video to match screenRect.
			_imageSrc.transform.matrix = _videoToScreenMatrix.clone();
			
			_clickArea.addEventListener(MouseEvent.CLICK, onClickedDots);
		}
		
		/**
		 * BRF needs the position of the eyes to start. You will need to mark the eyes of the face. 
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
		 * There are two modes. 0 is for the loaded image and the other is for 
		 * using the webcam to try the overlay.
		 */
		override public function updateInput() : void {
			if(_mode == 0) {
				_brfBmd.draw(_imageSrc, _videoToBRFMatrix);
			} else {
				super.updateInput();
			}
		}
		
		override public function updateBRF() : void {
			if(_mode == 0) {
				_brfManager.updateByEyes(_brfBmd, _leftEye, _rightEye, 35);
			} else {
				super.updateBRF();
			}
		}
		
		/**
		 * See FaceSubstitutionViewer to see how the overlay is drawn.
		 */
		override public function updateGUI() : void {
			
			removeDrawSpriteMask();
			
			if(_mode == 0) {
				_draw.clear();
				
				DrawingUtils.drawRect(_draw, _brfRoi, false, 1.0, 0xacfeff, 1.0);
				
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
//					DrawingUtils.drawTrianglesAsPoints(_draw, faceShape.faceShapeVertices);
//					DrawingUtils.drawRect(_draw, faceShape.bounds);
					
					// And draw the one result, that got calculated from leftEye, rightEye
//					if(rect != null && rect.width != 0) {
//						DrawingUtils.drawRect(_draw, rect, false, 1.0, 0xff7900, 1.0);
//					}
					
					DrawingUtils.drawTriangles(_draw, faceShape.candideShapeVertices, faceShape.candideShapeTriangles);
					DrawingUtils.drawTrianglesAsPoints(_draw, faceShape.candideShapeVertices);
					
//					drawIndices(faceShape.candideShapeVertices);
				}
				
				// Reset the points.
				_leftEye.x = -1.0;
				_leftEye.y = -1.0;
				_rightEye.x = -1.0;
				_rightEye.y = -1.0;
				
				_clickArea.addEventListener(MouseEvent.CLICK, onClickedReset);
				
			} else {
				super.updateGUI();
			}
		}

		/**
		 * If you want to see the indices of the candide shape, you can draw them with
		 * this function. The indices are a bit messy, but that's the Candide 3 model itself.
		 */
		public function drawIndices(candideShapeVertices : Vector.<Number>) : void {
			_drawSprite.removeChildren();
			
			var i : int = 0;
			var l : int = candideShapeVertices.length;
			
			for(; i < l; i += 2) {
				var x : Number = candideShapeVertices[i];
				var y : Number = candideShapeVertices[i + 1];
				
				var bt : Button = createButton("" + (i/2), x, y, null, 30);
				bt.scaleX = 0.25;
				bt.scaleY = 0.25;
				bt.alpha = 0.5;
				_drawSprite.addChild(bt);
			}
			
			// ZOOM IN A BIT:
//			_container.scaleX = 6.5;
//			_container.scaleY = 6.5;
//			_container.x -= 2000;
//			_container.y -= 1500;
			
			_container.scaleX = 2.5;
			_container.scaleY = 2.5;
			_container.x -= 400;
			_container.y -= 150;
		}

		private function onClickedReset(event : MouseEvent) : void {
			_clickArea.removeEventListener(MouseEvent.CLICK, onClickedReset);
			
			_draw.clear();
			
			changeImage(_imageSrc);
		}

		/**
		 * Texture and UV data generation.
		 */
		public function generateTextureAndUVData() : void {
			
			// The face has a certain bounds. This rect must be recalculated to
			// match the input image scale again and add some border pixels.
			
			var faceShape : BRFFaceShape = _brfManager.faceShape;
			
			_textureBounds = getCandideBounds(faceShape.candideShapeVertices);
			
			_textureBounds.x = 		int(_textureBounds.x		* _drawSprite.scaleX - 0.5) + _drawSprite.x - 5;
			_textureBounds.y =		int(_textureBounds.y		* _drawSprite.scaleY - 0.5) + _drawSprite.y - 5;
			_textureBounds.width =	int(_textureBounds.width	* _drawSprite.scaleX + 0.5) + 10; 
			_textureBounds.height =	int(_textureBounds.height	* _drawSprite.scaleY + 0.5) + 10; 
			
			_texture = new BitmapData(_textureBounds.width, _textureBounds.height, false, 0x000000);
			_texture.copyPixels(_imageSrc.bitmapData, _textureBounds, _origin);			
			
			// The UV data must also be rescaled.
			
			_uvData = faceShape.candideShapeVertices.concat();
			
			var i : int = 0;
			var l : int = _uvData.length;
			
			for(; i < l; i+=2) {
				_uvData[i]		= (_uvData[i]     * _drawSprite.scaleX + _drawSprite.x - _textureBounds.x) / _textureBounds.width;
				_uvData[i + 1]	= (_uvData[i + 1] * _drawSprite.scaleY + _drawSprite.y - _textureBounds.y) / _textureBounds.height;
			}
		}

		private function getCandideBounds(candideShapeVertices : Vector.<Number>) : Rectangle {
			
			var minX : Number = Number.MAX_VALUE;
			var minY : Number = Number.MAX_VALUE;
			var maxX : Number = Number.MIN_VALUE;
			var maxY : Number = Number.MIN_VALUE;
			
			var i : int = 0;
			var l : int = candideShapeVertices.length;
			
			for(; i < l; i += 2) {
				var x : Number = candideShapeVertices[i];
				var y : Number = candideShapeVertices[i + 1];
				
				if(x < minX) minX = x;
				if(x > maxX) maxX = x;
				if(y < minY) minY = y;
				if(y > maxY) maxY = y;
			}
			
			_candideBounds.x = minX;
			_candideBounds.y = minY;
			_candideBounds.width = maxX - minX;
			_candideBounds.height = maxY - minY;
			
			return _candideBounds;
		}

		/**
		 * Switch from image to webcam mode.
		 */
		public function tryTexture() : void {
			_mode = 1;
			
			_brfManager.reset();
			
			if(_imageSrc != null) {
				_imageSrc.x = 0.0;
				_imageSrc.y = 0.0;
				_imageSrc.scaleX = 1.0;
				_imageSrc.scaleY = 1.0;
				
				if(_container.contains(_imageSrc)) {
					_container.removeChild(_imageSrc);
				}
			}
			
			_container.addChildAt(_video, 0);
			
			_screenRect.x = 0;
			_screenRect.y = 0;
			_screenRect.width = 1280;
			_screenRect.height = 720;
			
			_cameraResolution.x = 0;
			_cameraResolution.y = 0;
			_cameraResolution.width = 1280;
			_cameraResolution.height = 720;
			
			initCamera();
			mirrored = true;
			
			setTimeout(start, 1000);
		}

		public function start() : void {
			addEventListener(Event.ENTER_FRAME, update);
		}
		
		/**
		 * Switch to the next image in the Array.
		 */
		public function onClickedNextImage(event : Event) : void {
			var i : int = _images.indexOf(_image);
			
			if(i >= 0) {
				i++;
				
				if(i >= _images.length) {
					i = 0;
				}
				
				_image = _images[i];
				changeImage(_image.content as Bitmap);
			}	
		}
		
		public function onClickedGenerate(event : Event) : void {
			generateTextureAndUVData();
			tryTexture();
		}
		
		public function onClickedExportTexture(event : Event) : void {
			var texture : ByteArray = PNGEncoder.encode(_texture);
			var fr : FileReference = new FileReference();
			fr.save(texture, "texture.png");
		}
		
		public function onClickedExportUVData(event : Event) : void {
			var fr : FileReference = new FileReference();
			fr.save(_uvData.toString(), "uv.txt");
		}

		public function createButton(label : String, x : int, y : int, f : Function, w : int = 200) : Button {
			var bt : Button = new Button(w);
			bt.x = x;
			bt.y = y;
			bt.setLabel(label);
			f && bt.addEventListener(MouseEvent.CLICK, f);
			addChild(bt);
			return bt;
		}
	}
}