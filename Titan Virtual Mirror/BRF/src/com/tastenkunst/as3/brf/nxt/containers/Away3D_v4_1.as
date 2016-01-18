package com.tastenkunst.as3.brf.nxt.containers {
	import away3d.cameras.Camera3D;
	import away3d.cameras.lenses.PerspectiveLens;
	import away3d.containers.ObjectContainer3D;
	import away3d.containers.Scene3D;
	import away3d.containers.View3D;
	import away3d.entities.Mesh;
	import away3d.events.AssetEvent;
	import away3d.events.Stage3DEvent;
	import away3d.library.assets.AssetType;
	import away3d.loaders.Loader3D;
	import away3d.loaders.parsers.Parsers;
	import away3d.materials.OcclusionMaterial;
	import away3d.materials.TextureMaterial;
	import away3d.primitives.PlaneGeometry;
	import away3d.textures.BRFVideoTexture;

	import com.tastenkunst.as3.brf.nxt.BRFFaceShape;

	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.geom.Vector3D;
	import flash.net.URLRequest;
	import flash.utils.Dictionary;

	/**
	 * An Away3D container, that lets you choose a model
	 * and places that 3D model on your face.
	 * 
	 * @author Marcel Klammer, Tastenkunst GmbH, 2014
	 */
	public class Away3D_v4_1 extends Sprite {
		
		public static const TO_DEGREE : Number = 180 / Math.PI;
		
		public var _scene3D : Scene3D;
		public var _view3D : View3D;

		public var _camera3D : Camera3D;
		public var _fieldOfView : Number;
		
		public var _baseNode : ObjectContainer3D;
		public var _holder : ObjectContainer3D;

		public var _occlusion : ObjectContainer3D;
		public var _occlusionNode : ObjectContainer3D;
		public var _occlusionMaterial : OcclusionMaterial;

		public var _videoPlane : Mesh;
		public var _videoPlaneTexture : BRFVideoTexture;
		public var _videoPlaneMaterial : TextureMaterial;
		public var _videoData : BitmapData;
			
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
		
		public function Away3D_v4_1() {				
		}
		
		public function init(viewport : Rectangle, cameraResolution : Rectangle, 
				brfResolution : Rectangle, screenRect : Rectangle) : void {
			_viewport = viewport;
			_cameraResolution = cameraResolution;
			_brfResolution = brfResolution;
			_screenRect = screenRect;
			
			_viewportToScreenFactor = _viewport.width / _screenRect.width;
			_viewportToScreenFactor = _viewport.width / _screenRect.width;
			
			_fieldOfView = 42.4; //36.95 - 1280x720 --- 42.4 - 640x480 --- 54.0 - 480x640 
			_planeFactor = 8.0;
			_modelFactor = 4.0;
			
			_planeZ = 233.3333333 * _fieldOfView;
			_modelZ = _planeZ * (_modelFactor / _planeFactor);
			
			//Enable all file formats. So we don't need to care about obj, dae, awd etc.
			Parsers.enableAllBundled();
			
			_scene3D = new Scene3D();
			
			_camera3D = new Camera3D(new PerspectiveLens(_fieldOfView));
			_camera3D.lens.far = 200000.0;
			_camera3D.lens.near = 1.0;
			_camera3D.position = new Vector3D(0, 0, 0);
			_camera3D.lookAt(new Vector3D(0, 0, 500));
			
			_view3D = new View3D(_scene3D, _camera3D);
			_view3D.antiAlias = 4;
			
			_view3D.x = _viewport.x; 
			_view3D.y = _viewport.y;
			_view3D.width = _viewport.width; 
			_view3D.height = _viewport.height;
			
			addChild(_view3D);
		
			//make the occlusion head visible with new OcclusionMaterial(false);
			//or _occlusionMaterial.occlude = false; //maybe a toggle
			_occlusionMaterial = new OcclusionMaterial();
			
			_baseNode = new ObjectContainer3D();
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
			
			_baseNode.moveTo(x, y, z);
			_baseNode.scaleX = s;
			_baseNode.scaleY = s;
			_baseNode.scaleZ = s;
			_baseNode.rotateTo(rx, ry, rz);
			_baseNode.visible = true;
			
			// If occlusion is active, we set the head the same way.
			if(_occlusion != null) {
				_occlusion.moveTo(x, y, z);
				_occlusion.scaleX = s;
				_occlusion.scaleY = s;
				_occlusion.scaleZ = s;
				_occlusion.rotateTo(rx, ry, rz);
			}
			
			if(_videoPlaneTexture) {
				_videoPlaneTexture.update();
				_view3D.render();
			}
		}

		public function idle() : void {
			_baseNode.visible = false;
			
			if(_videoPlaneTexture) {
				_videoPlaneTexture.update();
				_view3D.render();
			}
		}

		public function set model(model : String) : void {
			if(_model != null) {				
				_baseNode.removeChild(_holder);
				_models[_model] = _holder;
				_model = null;
			}
			_holder = null;
			if(model != null) {
				var holderOld : ObjectContainer3D = _models[model];
				
				if(holderOld != null) {
					_holder = holderOld;					
					_baseNode.addChild(_holder);
				} else {
					_holder = new ObjectContainer3D();
					_baseNode.addChild(_holder);
					var l : Loader3D = new Loader3D();
					//We have to offset that model a little bit
					//if you use your own models, just realign it for your needs
					//don't forget the occlusion head, see aboth
					l.load(new URLRequest(model));
					_holder.addChild(l);
				}
			}			
			_model = model;
		}
		
		public function initOcclusion(url : String) : void {
			var l : Loader3D = new Loader3D();
			l.addEventListener(AssetEvent.ASSET_COMPLETE, onCompleteOcclusion);
			l.load(new URLRequest(url));
		}
		
		public function onCompleteOcclusion(event : Event) : void {
			var assetEvent : AssetEvent = event as AssetEvent;
			if (assetEvent.asset.assetType == AssetType.MESH) {
				var mesh : Mesh = (assetEvent.asset as Mesh);
				mesh.material = _occlusionMaterial;
			
				_occlusionNode = new ObjectContainer3D();
				_occlusionNode.addChild(mesh);
				
				_view3D.scene.addChild(_occlusionNode);
				
				_occlusion = _occlusionNode;
			}
		}

		public function getScreenshot() : BitmapData {
			var bmd : BitmapData = new BitmapData(_view3D.width, _view3D.height);
			
			_view3D.renderer.queueSnapshot(bmd);
			_view3D.render();
			
			return bmd;
		}
		
		public function initVideoPlane(bitmapData : BitmapData) : void {
			_videoData = bitmapData;
			
			if(_view3D.stage3DProxy.context3D) {
				_initVideoPlane();
			} else {
				_view3D.stage3DProxy.addEventListener(Stage3DEvent.CONTEXT3D_CREATED, _initVideoPlane);
			}
		}

		private function _initVideoPlane(event : Stage3DEvent = null) : void {
			// We need to wait for the context to be initialized, otherwise the Plane will 
			// not be scaled correctly.
			_videoPlaneTexture = new BRFVideoTexture(_videoData, _view3D.stage3DProxy.context3D);
			_videoPlaneMaterial = new TextureMaterial(_videoPlaneTexture, false, false, false);
			_videoPlane = new Mesh(new PlaneGeometry(
				_screenRect.width  * _planeFactor, 
				_screenRect.height * _planeFactor, 
				5, 5, false, true), _videoPlaneMaterial);

			var x : Number = -((_view3D.width  - _screenRect.width)  * 0.5 - _screenRect.x) * _planeFactor;
			var y : Number =  ((_view3D.height - _screenRect.height) * 0.5 - _screenRect.y) * _planeFactor;
			var z : Number = _planeZ;

			_videoPlane.moveTo(x, y, z);
			_scene3D.addChild(_videoPlane);
		}
	}
}
