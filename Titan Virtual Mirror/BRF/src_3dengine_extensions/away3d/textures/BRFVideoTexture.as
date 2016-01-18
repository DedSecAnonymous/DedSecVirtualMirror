package away3d.textures {
	import away3d.tools.utils.TextureUtils;

	import flash.display.BitmapData;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.RectangleTexture;
	import flash.display3D.textures.Texture;
	import flash.display3D.textures.TextureBase;
	import flash.geom.Matrix;
	
	/**
	 * Inspired by the forum post of shin10 in the Away3D Forums (http://away3d.com/forum/viewthread/3733/)
	 */
	public class BRFVideoTexture extends Texture2DBase {
		
		private static var _npotSupported : int = -1;
		
		private var _bitmapData : BitmapData;
		private var _bitmapDataPOT : BitmapData;
		private var _sizePOT : uint;
		private var _matrixPOT : Matrix;
		
		private var _createdTexture : *;
		private var _createdRectangleTexture : *;

		public function BRFVideoTexture(bitmapData : BitmapData, context3D : Context3D) {
			super();
			
			_npotSupported = context3D.hasOwnProperty("createRectangleTexture") ? 1 : 0;
			
			this.bitmapData = bitmapData;
		}
		
		public function update() : void {
			// invalidateContent creates a completely new Texture, 
			// which is not needed, we can reuse to upload new content!
			if(!_createdTexture && !_createdRectangleTexture) return;
			if(_npotSupported == 0) {
				_bitmapDataPOT.draw(_bitmapData, _matrixPOT, null, null, null, true);
				Texture(_createdTexture).uploadFromBitmapData(_bitmapDataPOT, 0);
			} else if(_npotSupported == 1) {
				RectangleTexture(_createdRectangleTexture).uploadFromBitmapData(_bitmapData);
			}
		}
		
		public function get bitmapData() : BitmapData {
			return _bitmapData;
		}
		
		public function set bitmapData(value : BitmapData) : void {
			if(value == _bitmapData) {
				return;
			}
			
			if(_npotSupported == 1) {
				invalidateContent();
				setSize(value.width, value.height);
			} else {
				_sizePOT = TextureUtils.getBestPowerOf2(value.width > value.height ? value.width : value.height) >> 1;
				_bitmapDataPOT = new BitmapData(_sizePOT, _sizePOT, false, 0xff0000);
				
				_matrixPOT = new Matrix();
				_matrixPOT.scale(_sizePOT / value.width, _sizePOT / value.height);
				
				invalidateContent();
				setSize(_sizePOT, _sizePOT);
			}
			
			_bitmapData = value;
		}
		
		override protected function createTexture(context : Context3D) : TextureBase {
			if(_npotSupported) {
				_createdRectangleTexture = context["createRectangleTexture"](_bitmapData.width, _bitmapData.height, Context3DTextureFormat.BGRA, true);	
				return _createdRectangleTexture as TextureBase;
			} else {
				_createdTexture = context.createTexture(_sizePOT, _sizePOT, Context3DTextureFormat.BGRA, true);
				return _createdTexture;
			}
		}

		override protected function uploadContent(texture : TextureBase) : void {
			// We do that in update.
		}
		
		override public function dispose() : void {
			super.dispose();
			
			if(_bitmapDataPOT) {
				_bitmapDataPOT.dispose();
				_bitmapDataPOT = null;
			}
			
			_matrixPOT = null;
			_createdRectangleTexture = null;
			_createdTexture = null;
		}
	}
}
