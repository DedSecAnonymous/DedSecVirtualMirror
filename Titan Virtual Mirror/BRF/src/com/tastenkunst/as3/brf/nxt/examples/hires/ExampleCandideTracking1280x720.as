package com.tastenkunst.as3.brf.nxt.examples.hires {
	import com.tastenkunst.as3.brf.nxt.examples.ExampleCandideTracking;

	import flash.geom.Rectangle;

	/**
	 * This subclass of ExampleCandideTracking shows how to set custom resolutions.
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
	public class ExampleCandideTracking1280x720 extends ExampleCandideTracking {
		
		public function ExampleCandideTracking1280x720() {
		
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
			
			// All other methods, params etc will be set in and taken from ExampleCandideTracking.
			
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
	}
}
