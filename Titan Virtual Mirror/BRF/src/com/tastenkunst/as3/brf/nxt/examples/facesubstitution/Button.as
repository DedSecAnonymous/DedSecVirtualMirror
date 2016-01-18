package com.tastenkunst.as3.brf.nxt.examples.facesubstitution {
	
	import flash.text.TextFormatAlign;
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFormat;

	/**
	 * @author Marcel Klammer, Tastenkunst GmbH, 2014
	 */
	public class Button extends Sprite {
		
		private var _bg : Sprite;
		private var _tf : TextField;
		
		public function Button(w : int = 200) {
			init(w);
		}

		private function init(w : int) : void {
			buttonMode = true;
			mouseChildren = false;
			useHandCursor = true;
			
			_bg = new Sprite();
			_bg.graphics.beginFill(0xababab);
			_bg.graphics.drawRect(0, 0, w, 25);
			_bg.graphics.endFill();
			
			_tf = new TextField();
			_tf.y = 3;
			_tf.width = w;
						
			var format : TextFormat = _tf.defaultTextFormat;
			format.font = "Arial";
			format.size = 14;
			format.align = TextFormatAlign.CENTER;
			
			_tf.defaultTextFormat = format;
			
			addChild(_bg);
			addChild(_tf);
			
			setLabel("no label");
		}

		public function setLabel(label : String) : void {
			_tf.text = label;
		}
	}
}
