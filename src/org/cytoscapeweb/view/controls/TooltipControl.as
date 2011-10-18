/*
  This file is part of Cytoscape Web.
  Copyright (c) 2009, The Cytoscape Consortium (www.cytoscape.org)

  The Cytoscape Consortium is:
    - Agilent Technologies
    - Institut Pasteur
    - Institute for Systems Biology
    - Memorial Sloan-Kettering Cancer Center
    - National Center for Integrative Biomedical Informatics
    - Unilever
    - University of California San Diego
    - University of California San Francisco
    - University of Toronto

  This library is free software; you can redistribute it and/or
  modify it under the terms of the GNU Lesser General Public
  License as published by the Free Software Foundation; either
  version 2.1 of the License, or (at your option) any later version.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
  Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public
  License along with this library; if not, write to the Free Software
  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
*/
package org.cytoscapeweb.view.controls {
    import flare.animate.Tween;
    import flare.display.TextSprite;
    import flare.vis.controls.Control;
    import flare.vis.events.TooltipEvent;
    
    import flash.display.DisplayObject;
    import flash.display.DisplayObjectContainer;
    import flash.display.InteractiveObject;
    import flash.display.Stage;
    import flash.events.MouseEvent;
    import flash.events.TimerEvent;
    import flash.filters.DropShadowFilter;
    import flash.geom.Rectangle;
    import flash.text.TextFormat;
    import flash.utils.Timer;

    [Event(name="show", type="flare.vis.events.TooltipEvent")]
    [Event(name="hide", type="flare.vis.events.TooltipEvent")]
    [Event(name="update", type="flare.vis.events.TooltipEvent")]

    /**
     * Modifies original Flare's TooltipControl code, so it is possible to set diffent opacity
     * values to tooltips.
     * 
     * @see flare.vis.events.TooltipEvent
     * @see flare.display.TextSprite
     */
    public class TooltipControl extends Control {       
        private var _cur:DisplayObject;
        
        private var _showTimer:Timer;
        private var _hideTimer:Timer;
        private var _show:Boolean = false;
        private var _t:Tween;
        
        /** The tooltip delay, in milliseconds. */
        public function get showDelay():Number { return _showTimer.delay; }
        public function set showDelay(d:Number):void { _showTimer.delay = d; }
        
        /** The delay before hiding a tooltip, in milliseconds. */
        public function get hideDelay():Number { return _hideTimer.delay; }
        public function set hideDelay(d:Number):void { _hideTimer.delay = d; }
        
        /** The legal bounds for the tooltip in stage coordinates.
         *  If null (the default), the full stage bounds are used. */
        public var tipBounds:Rectangle = null;
        
        /** The x-offset from the mouse at which to place the tooltip. */
        public var xOffset:Number = 0;
        /** The y-offset from the mouse at which to place the tooltip. */
        public var yOffset:Number = 25;
        
        /** The display object presented as a tooltip. */
        public var tooltip:DisplayObject = null;
        
        /** Duration of fade animations (in seconds) for tooltip show and hide.
         *  If less than or equal to zero, no fade will be performed. */
        public var fadeDuration:Number = 0.3;
        
        /** Indicates if the tooltip should follow the mouse pointer. */
        public var followMouse:Boolean = true;
        
        // --------------------------------------------------------------------
        
        /**
         * Creates a new TooltipControl.
         * @param filter a Boolean-valued filter function indicating which
         *  items should receive tooltip handling
         */
        public function TooltipControl(filter:*=null,
            tooltip:DisplayObject=null, show:Function=null,
            update:Function=null, hide:Function=null, delay:Number=500) {
            this.filter = filter;
            _showTimer = new Timer(delay);
            _showTimer.addEventListener(TimerEvent.TIMER, onShow);
            _hideTimer = new Timer(100);
            _hideTimer.addEventListener(TimerEvent.TIMER, onHide);
            
            this.tooltip = tooltip ? tooltip : createDefaultTooltip();

            if (show != null) addEventListener(TooltipEvent.SHOW, show);
            if (update != null) addEventListener(TooltipEvent.UPDATE, update);
            if (hide != null) addEventListener(TooltipEvent.HIDE, hide);
        }
        
        /**
         * Generates a default TextSprite tooltip 
         * @return a new default tooltip object
         */
        public static function createDefaultTooltip():TextSprite {
            var fmt:TextFormat = new TextFormat("Arial", 14);
            fmt.leftMargin = 2;
            fmt.rightMargin = 2;
            
            var tip:TextSprite;
            tip = new TextSprite("", fmt);
            tip.textField.border = true;
            tip.textField.borderColor = 0;
            tip.textField.background = true;
            tip.textField.backgroundColor = 0xf5f5cc;
            tip.textField.multiline = true;
            tip.filters = [new DropShadowFilter(4,45,0,0.5)];
            return tip;
        }
        
        /**
         * Calculates the tooltip layout.
         * @param tip the tooltip object
         * @param obj the currently moused-over object
         */
        protected function layout(tip:DisplayObject, obj:DisplayObject):void {
            var s:Stage = tip.stage;
            
            if (s != null) {
                tip.x = s.mouseX + xOffset;
                tip.y = s.mouseY + yOffset;
                
                var b:Rectangle = tipBounds ? tipBounds : getStageBounds(s);
                var r:Rectangle = tip.getBounds(s);
                
                if (r.width > b.width) {
                    tip.x = b.left;
                } else if (r.left < b.left + 5) {
                    tip.x = s.mouseX + xOffset;
                } else if (r.right > b.right - 5) {
                    tip.x = s.mouseX - 2 - r.width;
                }
                if (r.height > b.height) {
                    tip.y = b.top;
                } if (r.top < b.top + 5) {
                    tip.y = s.mouseY - yOffset;
                } else if (r.bottom > b.bottom - 5) {
                    tip.y = s.mouseY - 7 - r.height;
                }
            }
        }
        
        /** @private */
        protected function fireEvent(type:String):void {
            if (hasEventListener(type)) {
                dispatchEvent(new TooltipEvent(type, _cur, tooltip));
            }
        }
        
        // --------------------------------------------------------------------
        
        /** @inheritDoc */
        public override function attach(obj:InteractiveObject):void {
            if (!(obj is DisplayObjectContainer)) {
                throw new Error("TooltipControls can only be " +
                    "attached to DisplayObjectContainers.");
            }
            super.attach(obj);
            if (obj != null) {
                obj.addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
                obj.addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
            }
        }
        
        /** @inheritDoc */
        public override function detach():InteractiveObject {
            if (_object != null) {
                _object.removeEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
                _object.removeEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
            }
            return super.detach();
        }
        
        private function onMouseOver(evt:MouseEvent):void {
            var n:DisplayObject = evt.target as DisplayObject;
            if (n==null || (_filter!=null && !_filter(n))) return;

            _cur = n;
            if (_show) {
                _hideTimer.stop();
                onShow();
            } else {
                _showTimer.start();
            }
        }
        
        private function onMouseMove(evt:MouseEvent):void {
            if (!followMouse) {
                _object.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
                return;
            }
            fireEvent(TooltipEvent.UPDATE);
            layout(tooltip, _cur);
        }
        
        private function onShow(evt:TimerEvent=null):void {
            if (_t && _t.running) _t.stop();
            _showTimer.stop();
            _show = true;

            _cur.stage.addChild(tooltip);
            fireEvent(TooltipEvent.SHOW);
            layout(tooltip, _cur);
            
            if (fadeDuration <= 0) {
                tooltip.visible = true;
            } else {
                _t = new Tween(tooltip, fadeDuration, { alpha: tooltip.alpha, visible: true });
                _t.play();
            }
            if (followMouse)
                _object.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
        }
        
        private function onHide(evt:TimerEvent=null):void {
            _hideTimer.stop();
            fireEvent(TooltipEvent.HIDE);
            if (fadeDuration <= 0) {
                tooltip.alpha = 0;
                tooltip.visible = false;
                if (tooltip.parent)
                    tooltip.parent.removeChild(tooltip);
            } else {
                _t = new Tween(tooltip, fadeDuration,
                        {alpha: 0, visible: false}, true);
                _t.play();
            }
            _show = false;
            _cur = null;
        }
        
        private function onMouseOut(evt:MouseEvent):void {
            _showTimer.stop();
            if (_cur == null) return;
            _object.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
            if (_show) _hideTimer.start();
        }
        
        // --------------------------------------------------------------------
        
        private static function getStageBounds(stage:Stage):Rectangle {
            return new Rectangle(0, 0, stage.stageWidth, stage.stageHeight);
        }
    }
}
