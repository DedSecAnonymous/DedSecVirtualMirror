// forked from Saqoosha's Fire
package com.tastenkunst.as3.brf.nxt.examples.flare3d.firebeard {
	import com.adobe.images.PNGEncoder;

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BitmapDataChannel;
	import flash.display.BlendMode;
	import flash.display.DisplayObject;
	import flash.display.PixelSnapping;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.BlurFilter;
	import flash.filters.ColorMatrixFilter;
	import flash.filters.ConvolutionFilter;
	import flash.geom.Point;
	import flash.net.FileReference;
	import flash.utils.ByteArray;
	
	public class FireBeardRenderer extends Sprite {
			
		public var size : int = 256;  
			
		[Embed(source="assets/fire-color.png")]
		public var BMD_FIRE_COLOR : Class;
		public var _bmdColor : BitmapData;

		[Embed(source="assets/beard_eyes.png")]
		public var BMD_BEARD_AREA : Class;
		public var _bmdBeard : BitmapData;
		
		[Embed(source="assets/face_area.png")]
		public var BMD_FACE_AREA : Class;
		public var _bmdFace : BitmapData;
		
		public var _textureFire : BitmapData;
        public var _canvas : Sprite;
		
        public static const ZERO_POINT : Point = new Point();
        public static const ANCHOR_POINT : Point = new Point(128, 256);
        
        public var _currentFireColor:int;
        
        public var _grey:BitmapData;
        public var _spread:ConvolutionFilter;
        public var _cooling:BitmapData;
        public var _cooling2:BitmapData;
        public var _color:ColorMatrixFilter;
        public var _offset:Array;
        public var _fire:BitmapData;
        public var _palette:Array;
		public var _zeroArray : Array;
		public var _result : Bitmap;
		
		public var _blurFilter : BlurFilter = new BlurFilter(8, 8, 2);
		private var _emitterFaceArea : DisplayObject;
		private var _emitterBeardEyes : DisplayObject;

		public function FireBeardRenderer() {
			init();
		}

		private function init() : void {
            _bmdColor = (new BMD_FIRE_COLOR()).bitmapData;
            _bmdBeard = (new BMD_BEARD_AREA()).bitmapData;
            _bmdFace = (new BMD_FACE_AREA()).bitmapData;

			_textureFire = new BitmapData(size*2, size*2, true, 0x00000000);
			_result = new Bitmap(_textureFire);
			
			_canvas = new Sprite();
			_emitterFaceArea = createEmitter(_bmdFace, 1.0, 0, 0);
			_emitterFaceArea.alpha = 0.04;
			_canvas.addChild(_emitterFaceArea);
			
			_emitterBeardEyes = createEmitter(_bmdBeard, 1.0, 0, 0);
			_emitterBeardEyes.alpha = 0.6;
			_canvas.addChild(_emitterBeardEyes);
			
			_grey = new BitmapData(size, size, true, 0xffffffff);
            _spread = new ConvolutionFilter(3, 3, [0, 1, 0,  1, 1, 1,  0, 1, 0], 5);
            _cooling = new BitmapData(size, size, false, 0x000000);
            _cooling2 = new BitmapData(size, size, false, 0x000000);
            _offset = [new Point(), new Point()];
            _fire = new BitmapData(size, size, false, 0xffffff);
			
			_cooling.perlinNoise(10, 10, 2, 982374, false, false, 0, true, _offset);

			createCooling(0.16);
			createPalette(_currentFireColor = 0);
			
			_cooling.perlinNoise(10, 10, 2, 982374, false, false, 0, true, _offset);
			addEventListener(Event.ENTER_FRAME, update);
		}

		public function onClicked(event : MouseEvent = null) : void {
			var texture : ByteArray = PNGEncoder.encode(_result.bitmapData);
			var fr : FileReference = new FileReference();
			fr.save(texture, "texture.png");
		}

		public function createEmitter(bmd : BitmapData, scale : Number = 1.0, centerOffsetX : Number = 0, centerOffsetY : Number = 0) : DisplayObject {
			var bm : Bitmap = new Bitmap(bmd, PixelSnapping.AUTO, true);
			
			bm.scaleX = scale;
			bm.scaleY = scale;
			bm.x = (size - bm.width) * 0.5 + centerOffsetX;
			bm.y = (size - bm.height) * 0.5 + centerOffsetY;
			
			return bm;
		}
        
        public function createCooling(a:Number):void {
            _color = new ColorMatrixFilter([
                a, 0, 0, 0, 0,
                0, a, 0, 0, 0,
                0, 0, a, 0, 0,
                0, 0, 0, 1, 0
            ]);
        }
		
		public function createPalette(idx:int):void {
            _palette = [];
            _zeroArray = [];
			
            for(var i : int = 0; i < 256; i++) {
                _palette.push(_bmdColor.getPixel(i, idx * 32));
                _zeroArray.push(0);
            }
        }
		
		public function update(e : Event):void {
			_grey.draw(_canvas);
            _grey.applyFilter(_grey, _grey.rect, ZERO_POINT, _spread);
			
			_cooling.perlinNoise(10, 10, 2, 982374, false, false, 0, true, _offset);
			
			_offset[0].x += 1;
            _offset[1].y += 4;//4
            _cooling2.applyFilter(_cooling, _cooling.rect, ZERO_POINT, _color);
            _grey.draw(_cooling2, null, null, BlendMode.SUBTRACT, null, true);
            _grey.scroll(0, -1);
            _fire.paletteMap(_grey, _grey.rect, ZERO_POINT, _palette, _zeroArray, _zeroArray, _zeroArray);
			
			_result.bitmapData.copyPixels(_fire, _fire.rect, ANCHOR_POINT);
			_result.bitmapData.copyChannel(_fire, _fire.rect, ANCHOR_POINT, BitmapDataChannel.RED, BitmapDataChannel.ALPHA);
		}
    }
}