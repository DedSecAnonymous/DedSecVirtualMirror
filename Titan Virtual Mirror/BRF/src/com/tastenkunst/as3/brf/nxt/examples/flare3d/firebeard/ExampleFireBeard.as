package com.tastenkunst.as3.brf.nxt.examples.flare3d.firebeard {
	import com.tastenkunst.as3.brf.nxt.BRFState;
	import com.tastenkunst.as3.brf.nxt.examples.ExampleCandideTracking;

	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.geom.Rectangle;
	
	/**
	 * This is a fun little experiment with face tracking + perlin noise.
	 * It generates a fire like texture for a Flare3D curved plane.
	 *  
	 * @author Marcel Klammer, Tastenkunst GmbH, 2014
	 */
	public class ExampleFireBeard extends ExampleCandideTracking {
		
		// the occlusion head model, that hides the bows of the glasses
		public var _occlusionModel : String = "media/f3d/brf_occlusion_head.zf3d";
		// first example glasses model
		public var _model1 : String = "media/f3d/facePlane.zf3d";
		// 3D scene handler
		public var _container3D : Flare3DFireBeard;
		
		// size and position of 3d viewport
		public var _viewport : Rectangle;
		
		// texture for webcam image as 3d plane
		public var _screenBmd : BitmapData;

		public function ExampleFireBeard() {
			//
			// 480p version:
			//

			// set the viewport size and position
			_viewport = new Rectangle(0, 0, 640, 480);
			
			// and the other rectangles (see ExampleBase for more information)
			super(
				new Rectangle(  0,   0,  640, 480),	// Camera resolution
				new Rectangle(  0,   0,  640, 480), // BRF BitmapData size
				new Rectangle( 80,   0,  480, 480), // BRF region of interest within BRF BitmapData size
				new Rectangle(120,  40,  400, 400), // BRF face detection region of interest within BRF BitmapData size
				new Rectangle(  0,   0,  640, 480), // Shown video screen rectangle within the 3D scene
				true, true
			);
			
//			//
//			// 720p version
//			//
//			
//			// set the viewport size and position
//			_viewport = new Rectangle(0, 0, 1280, 720);
//			
//			// and the other rectangles (see ExampleBase for more information)
//			super(
//				new Rectangle(  0,   0, 1280, 720),	// Camera resolution
//				new Rectangle(  0,   0,  640, 480), // BRF BitmapData size
//				new Rectangle(  0,   0,  640, 480), // BRF region of interest within BRF BitmapData size
//				new Rectangle(120,  40,  400, 400), // BRF face detection region of interest within BRF BitmapData size
//				new Rectangle(  0,   0, 1280, 720), // Shown video screen rectangle within the 3D scene
//				true, true
//			);
		}
		
		/**
		 * BRF is ready. Lets set the tracking mode to BRFMode.FACE_TRACKING.
		 * and init all necessary stuff for Flare3D.
		 */
		override public function onReadyBRF(event : Event) : void {
			super.onReadyBRF(event);
			
			// visible webcam image
			// on mobile: uploading large textures is slow, also drawing a video to large BitmapData is slow
			// so we make the shown video smaller in size if necessary: eg. 0.5
			var videoQuality : Number = 0.8; 
			
			_screenBmd = new BitmapData(_screenRect.width * videoQuality, _screenRect.height * videoQuality, false, 0x333333);
			_videoToScreenMatrix.scale(videoQuality, videoQuality);
			
			// the actual 3d scene handling container
			_container3D = new Flare3DFireBeard();
			addChild(_container3D);
			
			_container3D.init(_viewport, _cameraResolution, _brfResolution, _screenRect);
			_container3D.initVideoPlane(_screenBmd);
			_container3D.initOcclusion(_occlusionModel);
			
			// set the first model
			_container3D.model = _model1;
			
			// remove the video or brf bitmap, if its on stage, because Stage3D sits
			// below the display list.
			if(_container.contains(_video)) {
				_container.removeChild(_video);
			}
			_stats.visible = false;
		}
		
		/**
		 * We need to draw the webcam to the texture BitmapData.
		 */
		override public function updateInput() : void {
			super.updateInput();
			
			_screenBmd.draw(_video, _videoToScreenMatrix);
		}
		
		/**
		 * Update the 3D content, if a face shape was tracked.
		 * Otherwise hide the 3D content.
		 */
		override public function updateGUI() : void {
			_draw.clear();
			
			if(_brfManager.state == BRFState.FACE_TRACKING) {
				// We either have a result and show the 3D model,
				_container3D.update(_brfManager.faceShape); 
			} else {
				// Or we don't have a result and hide the 3D model.
				_container3D.idle();
			}
		}
	}
}