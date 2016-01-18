package com.tastenkunst.as3.brf.nxt.examples.flare3d.firebeard {
	import flare.basic.Scene3D;
	import flare.core.Camera3D;
	import flare.core.Light3D;
	import flare.core.Mesh3D;
	import flare.core.Pivot3D;
	import flare.core.Texture3D;
	import flare.materials.Shader3D;
	import flare.materials.filters.TextureMapFilter;
	import flare.primitives.Plane;

	import com.tastenkunst.as3.brf.nxt.BRFFaceShape;

	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;

	/**
	 * A Flare3D container, that lets you choose a model
	 * and places that 3D model on your face.
	 * 
	 * @author Marcel Klammer, Tastenkunst GmbH, 2014
	 */
	public class Flare3DFireBeard extends Sprite {
		
		public static const TO_DEGREE : Number = 180 / Math.PI;
		
		public var _scene3D : Scene3D;
		public var _light3D : Light3D;

		public var _camera3D : Camera3D;
		public var _fieldOfView : Number;

		public var _baseNode : Pivot3D;
		public var _holder : Pivot3D;

		public var _occlusion : Pivot3D;
		public var _occlusionNode : Pivot3D;
		
		public var _videoPlane : Plane;
		public var _videoPlaneTexture : Texture3D;
		public var _videoPlaneMaterial : Shader3D;
		
		public var _viewportToScreenFactor : Number;
		public var _planeFactor : Number;
		public var _planeZ : Number;

		public var _modelFactor : Number;
		public var _modelZoom : Number;
		public var _modelZ : Number;
		
		public var _model : String;
		public var _models : Dictionary = new Dictionary();
		
		public var _viewport : Rectangle;
		public var _screenRect : Rectangle;
		public var _brfResolution : Rectangle;
		public var _cameraResolution : Rectangle;
		private var _fireBmd : BitmapData;
		private var _fireTexture : Texture3D;
		private var _fireTextureMapFilter : TextureMapFilter;
		private var _fireRenderer : FireBeardRenderer;

		public function Flare3DFireBeard() {
		}
		
		/**
		 * Input your rectangles here to setup Flare3D. 
		 * The viewport can be any size. The screenRect will place the video plane and the 3D model
		 * will automatically be places on the right position on that video plane.
		 * Don't change the calculations, just put 3d models in.
		 * See the ExampleFlare3D.
		 */
		public function init(viewport : Rectangle, cameraResolution : Rectangle, 
				brfResolution : Rectangle, screenRect : Rectangle) : void {
			_viewport = viewport;
			_cameraResolution = cameraResolution;
			_brfResolution = brfResolution;
			_screenRect = screenRect;
			
			_viewportToScreenFactor = _viewport.width / _screenRect.width;
			_viewportToScreenFactor = _viewport.width / _screenRect.width;
		
			_fieldOfView = 48.6;
			_planeFactor = 8.0;
			_modelFactor = 4.0;
			
			_planeZ = 233.3333333 * _fieldOfView;
			_modelZ = _planeZ * (_modelFactor / _planeFactor);
			
			_scene3D = new Scene3D(this);
			_scene3D.setViewport(_viewport.x, _viewport.y, 
					_viewport.width, _viewport.height, 2);
			_scene3D.antialias = 2;
			_scene3D.allowImportSettings = false;
			_scene3D.pause();
			
			_camera3D = new Camera3D();
			_camera3D.parent = null;
			_camera3D.far = 200000;
			_camera3D.near = 10.0;
			_camera3D.fieldOfView = _fieldOfView;
			_camera3D.setPosition(0, 0, 0);
			_camera3D.lookAt(0, 0, 500);
			
			_scene3D.camera = _camera3D;
			
			_occlusionNode = new Pivot3D(); 
			_occlusionNode.name = "_occlusionNode";
			_scene3D.addChild(_occlusionNode);
			
			_baseNode = new Pivot3D(); 
			_baseNode.name = "_baseNode";
			_scene3D.addChild(_baseNode);
			
			var brfRatio : Number    = _brfResolution.width / _brfResolution.height;
			var videoRatio : Number  = _cameraResolution.width / _cameraResolution.height;
			var screenRatio : Number = _screenRect.width / _screenRect.height;
			var zoomBRFToVideo : Number = 1.0;
			var zoomBRFToScreen : Number = 1.0;
			var zoomScreenToVideo : Number = 1.0;
			var zoomViewportToCamera : Number = (_cameraResolution.width / _viewport.width) * (1280.0 / _cameraResolution.width);
			
			if(brfRatio <= videoRatio) {
				zoomBRFToVideo = _cameraResolution.height / _brfResolution.height;
			} else {
				zoomBRFToVideo = _cameraResolution.width / _brfResolution.width;			
			}
			if(brfRatio <= screenRatio) {
				zoomBRFToScreen = _screenRect.height / _brfResolution.height;
			} else {
				zoomBRFToScreen = _screenRect.width / _brfResolution.width;				
			}
			if(screenRatio <= videoRatio) {
				zoomScreenToVideo = _cameraResolution.height / _screenRect.height;
			} else {
				zoomScreenToVideo = _cameraResolution.width / _screenRect.width;				
			}
			
			_planeFactor = 8.0 * zoomViewportToCamera;
			_modelFactor = 4.0 * zoomViewportToCamera;
			_modelZoom = zoomBRFToVideo / zoomScreenToVideo;

			idle();
		}

		public function update(faceShape : BRFFaceShape) : void {
			if(!_videoPlane) return;
					
			var s : Number = (faceShape.scale / 180) * _modelFactor * _modelZoom;
			var x : Number = _videoPlane.x / _planeFactor * _modelFactor;
			var y : Number = _videoPlane.y / _planeFactor * _modelFactor;
			var z : Number = _modelZ;
				
			x += (faceShape.translationX - (_brfResolution.width  * 0.5)) * _modelFactor * _modelZoom;
			y -= (faceShape.translationY - (_brfResolution.height * 0.5)) * _modelFactor * _modelZoom;
						
			var rx : Number = faceShape.rotationX * TO_DEGREE;
			var ry : Number = -faceShape.rotationY * TO_DEGREE;
			var rz : Number = -faceShape.rotationZ * TO_DEGREE;
			
			var rya : Number = ry < 0 ? -ry : ry;
			ry = ry * (rya / 36);
			
			ry += x * 0.0095;
			rx -= y * 0.01;
			rz += y * 0.0026;
			
			_baseNode.setPosition(x, y, z);
			_baseNode.setScale(s, s, s);
			_baseNode.setRotation(rx, ry, rz);
			_baseNode.show();
			
			// If occlusion is active, we set the head the same way.
			if(_occlusion != null) {
				_occlusion.setPosition(x, y, z);
				s*=0.01;
				_occlusion.setScale(s, s, s);
				_occlusion.setRotation(rx, ry, rz);
			}
			
			if(_videoPlaneTexture) {
				_videoPlaneTexture.uploadTexture();
				setTexture();
			}
		}

		public function idle() : void {
			_baseNode.hide();
			
			if(_videoPlaneTexture) {
				_videoPlaneTexture.uploadTexture();			
			}
		}
		
		public function set model(model : String) : void {
			_scene3D.pause();
			if(_model != null) {				
				_baseNode.removeChild(_holder);
				_models[_model] = _holder;
				_model = null;
			}
			_holder = null;
			if(model != null) {
				var holderOld : Pivot3D = _models[model];
				
				if(holderOld != null) {
					_holder = holderOld;
					_baseNode.addChild(_holder);
					_scene3D.resume();
				} else {
					_holder = new Pivot3D(); 
					_holder.name = "_holder_"+model;
					_baseNode.addChild(_holder);
					
					_scene3D.addEventListener(Scene3D.COMPLETE_EVENT, onCompleteLoading);
					_scene3D.addChildFromFile(model, _holder);
				}
			}			
			_model = model;
		}
		
		public function onCompleteLoading(e : Event) : void {
			_scene3D.removeEventListener(Scene3D.COMPLETE_EVENT, onCompleteLoading);
			_scene3D.camera = _camera3D;
			_scene3D.resume();
			
			var facePlane : Mesh3D = _holder.getChildByName("_facePlane") as Mesh3D;
			var mat : Shader3D = facePlane.getMaterialByName("green") as Shader3D;
			
			_fireBmd = new BitmapData(512, 512, true, 0x00000000);
			_fireTexture = new Texture3D(_fireBmd, true);
			_fireTexture.mipMode = Texture3D.MIP_NONE;
			_fireTexture.loaded = true;
			_fireTexture.upload(_scene3D);
			
			_fireTextureMapFilter = new TextureMapFilter(_fireTexture);

			mat.filters = [
				_fireTextureMapFilter
			];
			
			_fireRenderer = new FireBeardRenderer();
			stage.addChild(_fireRenderer);
		}
		
		public function setTexture() : void {
			if(_fireBmd != null) {
				_fireBmd.fillRect(_fireBmd.rect, 0x0);
				
				//_fireBmd.copyPixels(_fireRenderer._textureFire, _fireRenderer._textureFire.rect, new Point(128, 128));
				_fireBmd.draw(_fireRenderer._textureFire, new Matrix(0.75*2, 0, 0, 1.25*2, -128, -512-178-75), null, null, null, true);
				_fireTexture.uploadTexture();
				
			}
		}
		// You have more GPU power to spent? Then let's hide the glasses bows behind a invisible head! 
		// (or any other object behind any other invisible object)
		public function initOcclusion(url : String) : void {
			_scene3D.addEventListener(Scene3D.COMPLETE_EVENT, onCompleteOcclusion);
			_scene3D.addChildFromFile(url, _occlusionNode);
		}
		// We extract the occlusion object and remove it from the scene
		// the _scene3D gets a render event and handles drawing semi-automatically
		public function onCompleteOcclusion(event : Event) : void {
			_scene3D.removeEventListener(Scene3D.COMPLETE_EVENT, onCompleteOcclusion);
			
			_occlusion = _occlusionNode;
			
			if(_occlusion != null) {
				_occlusion.parent = null;
				_occlusion.upload(_scene3D);
			}			
			
			_scene3D.addEventListener(Scene3D.RENDER_EVENT, onRender);
			_scene3D.resume();
		}
		/** need a screenshot of the scene? */
		public function getScreenshot() : BitmapData {
			var bmd : BitmapData = new BitmapData(
					_scene3D.viewPort.width, _scene3D.viewPort.height);
			
			_scene3D.context.clear();
			
			onRender();
			
			_scene3D.render();
			_scene3D.context.drawToBitmapData(bmd);
			
			return bmd;
		}
		//the occlusion magic goes here
		private function onRender(event : Event = null) : void {
			//first: draw the video plane in the background
			_videoPlane.draw();
			//if there is an occlusion object, ...
			if(_occlusion != null) {
				//... write it to the buffer, but hide all coming polys behind it
				_scene3D.context.setColorMask(false, false, false, false);
				_occlusion.draw();
				_scene3D.context.setColorMask(true, true, true, true);
			}
			//all objects, that where not drawn here, will be drawn by Flare3D automatically
		}
		//Stage3D is not transparent. We need to create a video plane and map the video bitmapdata to it.
		public function initVideoPlane(bitmapData : BitmapData) : void {
			_videoPlaneTexture = new Texture3D(bitmapData, true);
			_videoPlaneTexture.mipMode = Texture3D.MIP_NONE;
			_videoPlaneTexture.loaded = true;
			_videoPlaneTexture.upload(_scene3D);
			
			_videoPlaneMaterial = new Shader3D("_videoPlaneMaterial", [new TextureMapFilter(_videoPlaneTexture)], false);
			_videoPlaneMaterial.twoSided = true;
			_videoPlaneMaterial.build();
			
			_videoPlane = new Plane("_videoPlane", 
				_screenRect.width  * _planeFactor,
				_screenRect.height * _planeFactor,
				10, _videoPlaneMaterial, "+xy");
			_scene3D.addChild(_videoPlane);

			var x : Number = -((_scene3D.viewPort.width  - _screenRect.width)  * 0.5 - _screenRect.x) * _planeFactor;
			var y : Number =  ((_scene3D.viewPort.height - _screenRect.height) * 0.5 - _screenRect.y) * _planeFactor;
			var z : Number = _planeZ;

			_videoPlane.setPosition(x, y, z);
		}
	}
}
		