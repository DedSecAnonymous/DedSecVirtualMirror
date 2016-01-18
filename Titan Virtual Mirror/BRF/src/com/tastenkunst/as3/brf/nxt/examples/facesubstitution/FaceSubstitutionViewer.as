package com.tastenkunst.as3.brf.nxt.examples.facesubstitution {
	import com.tastenkunst.as3.brf.nxt.BRFFaceShape;
	import com.tastenkunst.as3.brf.nxt.BRFMode;
	import com.tastenkunst.as3.brf.nxt.BRFState;
	import com.tastenkunst.as3.brf.nxt.examples.ExampleBase;
	import com.tastenkunst.as3.brf.nxt.utils.DrawingUtils;

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.filters.BitmapFilterQuality;
	import flash.filters.BlurFilter;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	/**
	 * A viewer class for textures and their UV data.
	 * 
	 * If you don't need smoothed edges, most of the stuff can be removed as
	 * it is just a drawTriangles call.
	 * 
	 * So drawing the outlinge and mouth into a blurred mask results in
	 * smoothed edges.
	 * 
	 * @author Marcel Klammer, Tastenkunst GmbH, 2015
	 */
	public class FaceSubstitutionViewer extends ExampleBase {
		
		[Embed(source="assets/texture_marcel_v3.png")]
		public var IMAGE : Class;
		
		[Embed(source="assets/uv_marcel_v3.txt", mimeType="application/octet-stream")]
		public var UVDATA : Class;
		
		// The chosen texture and its UV data.
		public var _texture : BitmapData;
		public var _uvData : Vector.<Number>;
		
		// Helpers for drawing a smoothing mask for the texture.
		public const _outlinePoints : Vector.<Point> = new Vector.<Point>(21, true);
		public const _mouthHolePoints : Vector.<Point> = new Vector.<Point>(12, true);
		
		// We need to draw the smoothing mask, so thats done with these helpers.
		public var _drawSpriteMask : Sprite;
		public var _drawMask : Graphics;
		
		public function FaceSubstitutionViewer(
				cameraResolution : Rectangle = null,
				brfResolution : Rectangle = null,
				brfRoi : Rectangle = null,
				faceDetectionRoi : Rectangle = null,
				screenRect : Rectangle = null,
				maskContainer : Boolean = true,
				webcamInput : Boolean = true) {
			
			if(stage != null) {
				setTexture((new IMAGE() as Bitmap).bitmapData, Vector.<Number>((new UVDATA()).toString().split(",")));
			} else {
				setTexture(null, null);
			}
			
			super(cameraResolution, brfResolution, brfRoi, 
				faceDetectionRoi, screenRect, maskContainer, webcamInput);
		}
		
		override public function onReadyBRF(event : Event) : void {
			_brfManager.setFaceDetectionVars(6.0, 0.5, 12.0, 0.06, 12, false);
			_brfManager.setFaceDetectionROI(
					_faceDetectionRoi.x, _faceDetectionRoi.y, 
					_faceDetectionRoi.width, _faceDetectionRoi.height);
			_brfManager.setFaceTrackingVars(80, 500, 1);
			_brfManager.candideEnabled = false;
			_brfManager.candideActionUnitsEnabled = false;
			_brfManager.mode = BRFMode.FACE_TRACKING;
			
			_drawSpriteMask = new Sprite();
			_drawSpriteMask.filters = [new BlurFilter(8, 8, BitmapFilterQuality.HIGH)];
			_drawSpriteMask.scaleX = _drawSprite.scaleX;
			_drawSpriteMask.scaleY = _drawSprite.scaleY;
			_drawSpriteMask.x = _drawSprite.x;
			_drawSpriteMask.y = _drawSprite.y;
			_drawMask = _drawSpriteMask.graphics;

			_drawSpriteMask.cacheAsBitmap = true;
			_drawSprite.cacheAsBitmap = true;
			removeDrawSpriteMask();
			
			_container.addChild(_drawSpriteMask);
			
			// mouth outer edge
			var i : int = 48;
			var l : int = 60;
			var k : int = 0;
			
			for(; i < l; i++, k++) {
				_mouthHolePoints[k] = _brfManager.faceShape.points[i];
			}
			
			// outer line of face shape
			for(i = 0, l = _outlinePoints.length; i < l; i++) {
				_outlinePoints[i] = new Point();
			}
			
			super.onReadyBRF(event);
		}

		override public function updateGUI() : void {
			
			_draw.clear();
			
			// Get the current BRFState and faceShape.
			var state : String = _brfManager.state;
			var faceShape : BRFFaceShape = _brfManager.faceShape;
			
			// Draw BRFs region of interest, that got analysed:
			DrawingUtils.drawRect(_draw, _brfRoi, false, 1.0, 0xacfeff, 1.0);
			
			removeDrawSpriteMask();
				
			if(state == BRFState.FACE_DETECTION) {
				// Last update was face detection only, 
				// draw the face detection roi and lastDetectedFace:
				DrawingUtils.drawRect(_draw, _faceDetectionRoi);//, false, 1, 0xffff00, 1);
				
				// Draw all found face regions:
				DrawingUtils.drawRects(_draw, _brfManager.lastDetectedFaces);
				
				var rect : Rectangle = _brfManager.lastDetectedFace;
				if(rect != null && rect.width != 0) {
					DrawingUtils.drawRect(_draw, rect, false, 1.0, 0xff7900, 1.0);
				}
			} else if(state == BRFState.FACE_TRACKING_START || state == BRFState.FACE_TRACKING) {
				
				if(_texture == null) {
					// The found face rectangle got analysed in detail
					// draw the faceShape and its bounds:
					DrawingUtils.drawTriangles(_draw, faceShape.faceShapeVertices, faceShape.faceShapeTriangles);
					DrawingUtils.drawTrianglesAsPoints(_draw, faceShape.faceShapeVertices);
					DrawingUtils.drawRect(_draw, faceShape.bounds);
				} else {
					// Drawing the chosen texture.
					DrawingUtils.drawTrianglesWithTexture(_draw, faceShape.faceShapeVertices, faceShape.faceShapeTriangles, _texture, _uvData);
					
					// You might want to smooth the edges.
					
					// Setting the outline of the face
					calculateFaceOutline();
					
					// Drawing the outline of the face for the blurred mask
					drawBlurredMask();
				}
			}
		}

		public function removeDrawSpriteMask() : void {
			_drawSprite.mask = null;
			_drawSpriteMask.visible = false;
		}

		public function addDrawSpriteMask() : void {
			_drawSpriteMask.visible = true;
			_drawSprite.mask = _drawSpriteMask;
		}

		public function drawBlurredMask() : void {
			var i : int = 1;
			var l : int = _outlinePoints.length;
			
			_drawMask.clear();
			_drawMask.beginFill(0xff0000, 0.7);
			_drawMask.moveTo(_outlinePoints[0].x, _outlinePoints[0].y);
			for(; i < l; i++) {
				_drawMask.lineTo(_outlinePoints[i].x, _outlinePoints[i].y);					
			}
			_drawMask.lineTo(_outlinePoints[0].x, _outlinePoints[0].y);
			
			// and drawing the mouth whole into the blurry mask
			i = 1;
			l = _mouthHolePoints.length;
			
			_drawMask.moveTo(_mouthHolePoints[0].x, _mouthHolePoints[0].y);
			for(; i < l; i++) {
				_drawMask.lineTo(_mouthHolePoints[i].x, _mouthHolePoints[i].y);
			}
			_drawMask.lineTo(_mouthHolePoints[0].x, _mouthHolePoints[0].y);
			_drawMask.endFill();
			
			_drawSpriteMask.x = _drawSprite.x;
			_drawSpriteMask.y = _drawSprite.y;
			_drawSpriteMask.scaleX = _drawSprite.scaleX;
			_drawSpriteMask.scaleY = _drawSprite.scaleY;
			
			addDrawSpriteMask();
		}

		public function calculateFaceOutline() : void {
			var shapePoints : Vector.<Point> = _brfManager.faceShape.points;
			var center : Point = shapePoints[67];
			var tmpPointShape : Point;
			var tmpPointOutline : Point;
			var fac : Number = 0.04;
			var i : int = 0;
			var l : int = 18;

			for (i = 0; i < l; i++) {
				tmpPointShape = shapePoints[i];
				tmpPointOutline = _outlinePoints[i];
				tmpPointOutline.x = tmpPointShape.x + (center.x - tmpPointShape.x) * fac;
				tmpPointOutline.y = tmpPointShape.y + (center.y - tmpPointShape.y) * fac;
			}
			var k : int = 23;
			l = _outlinePoints.length;
			for (; i < l; i++, k--) {
				tmpPointShape = shapePoints[k];
				tmpPointOutline = _outlinePoints[i];
				tmpPointOutline.x = tmpPointShape.x + (center.x - tmpPointShape.x) * fac;
				tmpPointOutline.y = tmpPointShape.y + (center.y - tmpPointShape.y) * fac;
			}
		}

		public function setTexture(texture : BitmapData, uvData : Vector.<Number>) : void {
			_texture = texture;
			_uvData = uvData;
		}
	}
}