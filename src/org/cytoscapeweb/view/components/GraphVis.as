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
package org.cytoscapeweb.view.components {
    import com.senocular.drawing.DashedLine;
    
    import flare.animate.Sequence;
    import flare.animate.Transition;
    import flare.animate.TransitionEvent;
    import flare.animate.Transitioner;
    import flare.display.DirtySprite;
    import flare.display.TextSprite;
    import flare.util.Orientation;
    import flare.util.Property;
    import flare.util.Shapes;
    import flare.vis.Visualization;
    import flare.vis.controls.TooltipControl;
    import flare.vis.data.Data;
    import flare.vis.data.DataList;
    import flare.vis.data.DataSprite;
    import flare.vis.data.EdgeSprite;
    import flare.vis.data.NodeSprite;
    import flare.vis.data.Tree;
    import flare.vis.events.DataEvent;
    import flare.vis.events.TooltipEvent;
    import flare.vis.events.VisualizationEvent;
    import flare.vis.operator.layout.Layout;
    
    import flash.display.DisplayObject;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.getTimer;
    
    import org.cytoscapeweb.model.data.ConfigVO;
    import org.cytoscapeweb.model.data.VisualStyleVO;
    import org.cytoscapeweb.model.methods.error;
    import org.cytoscapeweb.util.Edges;
    import org.cytoscapeweb.util.GraphUtils;
    import org.cytoscapeweb.util.Groups;
    import org.cytoscapeweb.util.Labels;
    import org.cytoscapeweb.util.Layouts;
    import org.cytoscapeweb.util.Nodes;
    import org.cytoscapeweb.util.Utils;
    import org.cytoscapeweb.util.VisualProperties;
    import org.cytoscapeweb.util.methods.$each;
    import org.cytoscapeweb.view.layout.CircleLayout;
    import org.cytoscapeweb.view.layout.ForceDirectedLayout;
    import org.cytoscapeweb.view.layout.NodeLinkTreeLayout;
    import org.cytoscapeweb.view.layout.PresetLayout;
    import org.cytoscapeweb.view.layout.RadialTreeLayout;
    import org.cytoscapeweb.view.layout.physics.Simulation;
    import org.cytoscapeweb.view.render.Labeler;
    

    public class GraphVis extends Visualization {
        
        // ========[ CONSTANTS ]====================================================================
        
        // ========[ PRIVATE PROPERTIES ]===========================================================
        
        private var _data:Data;
        private var _layoutName:String;
        private var _style:VisualStyleVO;
        private var _config:ConfigVO;
        private var _nodeLabeler:Labeler;
        private var _edgeLabeler:Labeler;
        private var _tooltipControl:TooltipControl;
        private var _initialWidth:Number;
        private var _initialHeight:Number;
        private var _nodePoints:Object;
        private var _dragRect:Rectangle;
        
        private var _dataList:Array = [/*flare.vis.data.Data*/];
        private var _appliedLayouts:Array = [/*flare.vis.operator.layout.Layout*/];
        
        private function get tooltipControl():TooltipControl {
            if (_tooltipControl == null) {
                var filter:Function = function(d:DisplayObject):Boolean {  
                    var show:Boolean = _config.nodeTooltipsEnabled && 
                                       _config.edgeTooltipsEnabled && 
                                       d is DataSprite;
                    show = show || (_config.nodeTooltipsEnabled && d is NodeSprite);
                    show = show || (_config.edgeTooltipsEnabled && d is EdgeSprite);
                    return show;
                };
            	_tooltipControl = new TooltipControl(filter, null, onTooltipShow);
            }
            
            return _tooltipControl;
        }
        
        // ========[ PUBLIC PROPERTIES ]============================================================
        
        public function get nodeLabeler():Labeler {
            if (_nodeLabeler == null) {
                _nodeLabeler = new Labeler(null, Data.NODES);
            }
            return _nodeLabeler;
        }
        
        public function get edgeLabeler():Labeler {
            if (_edgeLabeler == null) {
                _edgeLabeler = new Labeler(null, Data.EDGES);
            }
            return _edgeLabeler;
        }
        
        /** @inheritDoc */
        override public  function set bounds(r:Rectangle):void {
            super.bounds = r;
            _initialWidth = r.width;
            _initialHeight = r.height;
        }
        
        /** @inheritDoc */
        override public function get tree():Tree { return data.tree; }
        
        /** @inheritDoc */
        override public function get data():Data { return _data; }
        
        /** @inheritDoc */
        override public function set data(d:Data):void {
            if (_data != null) {
                _data.visit(marks.removeChild);
                _data.removeEventListener(DataEvent.ADD, dataAdded);
                _data.removeEventListener(DataEvent.REMOVE, dataRemoved);
            }
            _data = d;
            if (_data != null) {
                var edges:DataList = _data.edges;
                $each(edges, function(i:uint, e:EdgeSprite):void {
                    marks.addChild(e);
                });
                
                var nodes:DataList = _data.nodes;
                $each(nodes, function(i:uint, n:NodeSprite):void {
                    marks.addChild(n);
                });

                _data.addEventListener(DataEvent.ADD, dataAdded);
                _data.addEventListener(DataEvent.REMOVE, dataRemoved);
            }
        }

        // ========[ CONSTRUCTOR ]==================================================================

        public function GraphVis(data:Data, config:ConfigVO) {
        	super(data);
        	_config = config;
        	separateDisconnected();
        	
            // Tooltips:
            // --------------------------------------------------------------------------
            controls.add(tooltipControl);
            
            // --------------------------------------------------------------------------
            // Avoiding the bug that makes the edges separate from the nodes:
            // (seems to be caused by a Flash/Flex integration problem - see:
            // http://sourceforge.net/forum/forum.php?thread_id=2190163&forum_id=757572)
            // I've been noticing this issue on Linux only...
            if (Utils.isLinux()) {
                addEventListener(VisualizationEvent.UPDATE, 
                                 function ():void{ DirtySprite.renderDirty(); });
            }
        }
        
        // ========[ PUBLIC METHODS ]===============================================================

        public function applyVisualStyle(style:VisualStyleVO):void {
            var firstTime:Boolean = this._style == null;
            this._style = style;
            
            // Nodes & Edges properties:
            // ---------------------------------------------------------
            data.nodes.setProperties(Nodes.properties);
            data.edges.setProperties(Edges.properties);
            
            // Node labels:
            // ---------------------------------------------------------
            nodeLabeler.cacheText = false;
            nodeLabeler.textMode = TextSprite.DEVICE;

            nodeLabeler.fontName = Labels.labelFontName;
            nodeLabeler.fontColor = Labels.labelFontColor;
            nodeLabeler.fontSize = Labels.labelFontSize;
            nodeLabeler.fontWeight = Labels.labelFontWeight;
            nodeLabeler.fontStyle = Labels.labelFontStyle;
            nodeLabeler.hAnchor = Labels.labelHAnchor;
            nodeLabeler.vAnchor = Labels.labelVAnchor;
            nodeLabeler.xOffsetFunc = Labels.labelXOffset;
            nodeLabeler.yOffsetFunc = Labels.labelYOffset;
            nodeLabeler.filters = Labels.filters;
            nodeLabeler.textFunction = Labels.text;
            
            // Edge labels:
            // ---------------------------------------------------------
            edgeLabeler.textMode = TextSprite.DEVICE;

            edgeLabeler.fontName = Labels.labelFontName;
            edgeLabeler.fontColor = Labels.labelFontColor;
            edgeLabeler.fontSize = Labels.labelFontSize;
            edgeLabeler.fontWeight = Labels.labelFontWeight;
            edgeLabeler.fontStyle = Labels.labelFontStyle;
            edgeLabeler.filters = Labels.filters;
            edgeLabeler.textFunction = Labels.text;

            if (!firstTime) {
                if (_config.nodeLabelsVisible) updateLabels(Data.NODES);
                if (_config.edgeLabelsVisible) updateLabels(Data.EDGES);
            }

            // Tooltips:
            // ---------------------------------------------------------
            tooltipControl.showDelay = _style.getValue(VisualProperties.TOOLTIP_DELAY) as Number;
        }

        public function applyLayout(name:String):Transition {
            continuousUpdates = false;

            // Remove previous layouts:
            if (_appliedLayouts.length > 0) {
                for (var k:String in _appliedLayouts) {
                    operators.remove(_appliedLayouts[k]);
                }
                _appliedLayouts = [];
            }

            _layoutName = name;
            var layout:Layout, fdl:ForceDirectedLayout;
            
            if (name === Layouts.PRESET) {
                layout = createLayout(name, data);
                PresetLayout(layout).points = _config.nodesPoints;
                _appliedLayouts.push(layout);
            } else {
                if (name === Layouts.FORCE_DIRECTED) {
                    // If the previous layout is ForceDirected, we need to set the nodes' particles and
                    // the edges' springs to null, otherwise the layout may not render very well
                    // when it is applied again.
                    data.nodes.visit(function(n:NodeSprite):void {
                        n.props.particle = null;
                        // It is also important to set random positions to nodes:
                        n.x = Math.random() * _initialWidth;
                        n.y = Math.random() * _initialHeight;
                    });
                    data.edges.visit(function(e:EdgeSprite):void {
                       e.props.spring = null;
                    });
                    fdl = ForceDirectedLayout(createLayout(name, data));
                    _appliedLayouts.push(fdl);
                } else {
                    // Create one layout for each disconnected component:
                    for (var i:uint = 0; i < _dataList.length; i++) {
                        var d:Data = _dataList[i];
                        if (d.nodes.length > 1) {
                            var rect:Rectangle = GraphUtils.calculateGraphDimension(d.nodes, name, _style); 
                            var root:NodeSprite = d.nodes[0];
                            
                            layout = createLayout(name, d, rect, root);
                            _appliedLayouts.push(layout);
                        }
                    }
                }    
            }
            
            // The layouts must be enabled in order to allow a layout change:
            for each (layout in _appliedLayouts) {
                layout.enabled = true;
                operators.add(layout);
            }

            var seq:Sequence = new Sequence();
            var trans:Transitioner = update(0.1);
            seq.add(trans);

            seq.addEventListener(TransitionEvent.START, function(evt:TransitionEvent):void {
            	evt.currentTarget.removeEventListener(evt.type, arguments.callee);
                if (fdl != null) fdl.enforceBounds = false;
            });
            
            seq.addEventListener(TransitionEvent.END, function(evt:TransitionEvent):void {
                evt.currentTarget.removeEventListener(evt.type, arguments.callee);

                if (fdl != null) operateForceDirectedLayout(fdl);

                if (_layoutName != Layouts.PRESET)
                    realignGraph();
                
                // After new layout is rendered, disable it so users can drag the nodes:
                for each (layout in _appliedLayouts) {
                    layout.enabled = false;
                }
                DirtySprite.renderDirty();
                
                updateLabels();

                if (_dataList != null && _dataList.length > 0) {
                    GraphUtils.repackDisconnected(_dataList,
                                                  Math.max(_initialWidth, stage.stageWidth),
                                                  !_config.nodeLabelsVisible,
                                                  !_config.edgeLabelsVisible);
                }
            });

            return seq;
        }
        
        public function updateLabels(group:String=null):void {
            if (group == null) {
                updateLabels(Groups.NODES);
                updateLabels(Groups.EDGES);
            } else {
                var visible:Boolean;
                var labeler:Labeler;
    
                if (group === Groups.NODES) {
                    visible = _config.nodeLabelsVisible;
                    labeler = nodeLabeler;
                } else {
                    visible = _config.edgeLabelsVisible && !_config.edgesMerged;
                    labeler = edgeLabeler;
                }
                
                labeler.enabled = visible;
                operators.remove(labeler);
               
                if (visible) {
                    labeler.cacheText = false;
                    operators.add(labeler);
                    labeler.operate();
                    labeler.cacheText = true;
                }
            
                // We still need to hide the labels if the node or edge is invisible:
                showLabels(visible, group);
            }
            
            DirtySprite.renderDirty();
        }
        
        public function showLabels(visible:Boolean, group:String=null):void {
            var labels:Property = Property.$("props.label");
                
            data.visit(function(ds:DataSprite):Boolean {
                var lb:TextSprite = labels.getValue(ds);
                if (lb != null) lb.visible = visible && ds.visible;
                return false;
            }, group);
        }

        public function separateDisconnected():void {
            _dataList = GraphUtils.separateDisconnected(data);
        }
        
        public function getDisconnectedData(ds:DataSprite):Data {
            if (_dataList != null) {
                for each (var d:Data in _dataList) {
                    if (d.contains(ds)) return d;
                }
            }
            return data;
        }
        
        public function getRealBounds(d:Data=null):Rectangle {
            if (d == null) d = data;
            
            // It's necessary to operate labeler first, so each label's text sprite is well placed!
            if (_config.nodeLabelsVisible) nodeLabeler.operate();

            // Then render edges and operate their labels:
            $each(d.edges, function(i:uint, e:EdgeSprite):void {
                 if (e.shape != Shapes.LINE) e.render();
            });
            if (_config.edgeLabelsVisible) edgeLabeler.operate();

            var bounds:Rectangle = GraphUtils.getBounds(d, !_config.nodeLabelsVisible, !_config.edgeLabelsVisible);
            
            return bounds;
        }
        
        public function updateDragRectangle(...delta):void {
            if (_dragRect != null) {
                var b:Rectangle = _dragRect;
                if (delta.length > 1) {
                    b.x += delta[0];
                    b.y += delta[1];
                }
                graphics.clear();
                
                // Draw the border:
                graphics.lineStyle(_config.visualStyle.getValue(VisualProperties.SELECTION_LINE_WIDTH),
                                   _config.visualStyle.getValue(VisualProperties.SELECTION_LINE_COLOR),
                                   _config.visualStyle.getValue(VisualProperties.SELECTION_LINE_ALPHA));
                
                var dash:DashedLine = new DashedLine(this, 1, 4);
                
                dash.moveTo(b.x, b.y);
                dash.lineTo(b.x + b.width, b.y);
                dash.lineTo(b.x + b.width, b.y + b.height);
                dash.lineTo(b.x, b.y + b.height);
                dash.lineTo(b.x, b.y);
            }
        }
        
        public function showDragRectangle(ds:DataSprite):void {
            var d:Data = getDisconnectedData(ds);
            _dragRect = getRealBounds(d);
            updateDragRectangle();
        }
        
        public function hideDragRectangle():void {
            if (_dragRect != null) {
                _dragRect = null;
                graphics.clear();
            }
        }
        
        // ========[ PRIVATE METHODS ]==============================================================
        
        /**
         * This method builds a collection of layout operators and node
         * and edge settings to be applied in the demo.
         */
        private function createLayout(name:String,
                                      d:Data,
                                      layoutBounds:Rectangle=null,
                                      layoutRoot:DataSprite=null):Layout {
        	var layout:Layout;
        	
        	if (layoutBounds == null)
        	   layoutBounds = new Rectangle(bounds.x, bounds.y, _initialWidth, _initialHeight);

            if (name === Layouts.FORCE_DIRECTED) {
                var el:uint = data.edges.length;
                
        		var fdl:ForceDirectedLayout = new ForceDirectedLayout(true, 5, new Simulation());
                fdl.ticksPerIteration = 1.5,
                fdl.simulation.dragForce.drag = 0.4;
                fdl.simulation.nbodyForce.gravitation = -1000;
                fdl.simulation.nbodyForce.minDistance = 1;
                fdl.simulation.nbodyForce.maxDistance = 10000;
                fdl.defaultParticleMass = 3;
                fdl.defaultSpringTension = 0.1;

                var desiredLength:Number = 60 + (el > 0 ? 2*Math.log(el) : 0);
                fdl.defaultSpringLength = Math.min(200, desiredLength);

                var tension:Function = fdl.tension;
                fdl.tension = function(e:EdgeSprite):Number {
                    var t:Number = 0;
                    if (!GraphUtils.isFilteredOut(e))
                        t = Math.max(0.01, tension(e));
                    return t;
                };

                trace("[FORCE_DIRECTED] Grav="+fdl.simulation.nbodyForce.gravitation+
                                      " Tens="+fdl.defaultSpringTension+
                                      " Drag="+fdl.simulation.dragForce.drag+
                                      " Mass="+fdl.defaultParticleMass+
                                      " Length="+fdl.defaultSpringLength);

                layout = fdl;
            } else if (name === Layouts.CIRCLE) {
	            var cl:CircleLayout = new CircleLayout(null, null, false, d);
                cl.angleWidth = -2 * Math.PI;
                cl.padding = 0;

                layout = cl;
            } else if (name === Layouts.CIRCLE_TREE) {
	            var ctl:CircleLayout = new CircleLayout(null, null, true, d);
                ctl.angleWidth = -2 * Math.PI;
                ctl.padding = 0;
                
                layoutBounds.height = Math.max(200, layoutBounds.height);
                layoutBounds.width = Math.max(200, layoutBounds.width);

                layout = ctl;
            } else if (name === Layouts.RADIAL) {
                var r:Number = Math.max(60, _initialWidth/8);
                var rtl:RadialTreeLayout = new RadialTreeLayout(r, true, false, d);
                rtl.angleWidth = -2 * Math.PI;
                
                layout = rtl;
            } else if (name === Layouts.TREE) {
                var nltl:NodeLinkTreeLayout = new NodeLinkTreeLayout(Orientation.TOP_TO_BOTTOM, 50, 30, 5, d);
                nltl.layoutAnchor = new Point(0, -2 * height/5);
                
                layout = nltl;
            } else if (name === Layouts.PRESET) {
                var psl:PresetLayout = new PresetLayout(_config.nodesPoints);
                
                layout = psl;
            }
            
            layout.layoutBounds = layoutBounds;
            layout.layoutRoot = layoutRoot;

            return layout;
        }
        
        private function operateForceDirectedLayout(fdl:ForceDirectedLayout):void {
            var startTime:int = getTimer();
            
            const MIN_COUNT:uint = 20;
            const MAX_COUNT:uint = 80;
            const MAX_TIME:uint = 60000;
            var count:uint = 0, stableCount:uint = 0;
            
            try {
                // Always operate the layout a few times first:
                while (count++ < MIN_COUNT  && (getTimer()-startTime < MAX_TIME)) {
                    fdl.operate();
                }
                
                // Then operate the layout until it's stable:
                var reset:Boolean = false;
                storeInitialNodePoints();
                var stable:Boolean = false;
                const MAX_M:Number = 1, MAX_D:Number = 1, MAX_L:Number = 240;
           
                while ( !stable &&  (getTimer()-startTime < MAX_TIME) ) {
                    fdl.operate();
                    count++;
                    
                    stable = stable || isLayoutStable();
                    
                    if (!stable) {
                        // Start tuning the Layout, because it's hard to make the
                        // layout stable with the current values:
                        var m:Number = fdl.defaultParticleMass;          
                        var d:Number = fdl.simulation.dragForce.drag;
                        var l:Number = fdl.defaultSpringLength;
                        var g:Number = fdl.simulation.nbodyForce.gravitation;
                        var t:Number = fdl.defaultSpringTension;
                        
                        m = fdl.defaultParticleMass = Math.max(MAX_M, m*0.9);
                        d = fdl.simulation.dragForce.drag = Math.min(MAX_D, d*1.1);
                        l = fdl.defaultSpringLength = Math.min(MAX_L, l*1.1);
    
                        if (m === MAX_M && d === MAX_D && l === MAX_L) {
                            // It has not worked so far, so decrease gravity/tension and do not verify anymore:
                            g = fdl.simulation.nbodyForce.gravitation = -10;
                            //t = fdl.defaultSpringTension = Math.max(0.05, t/2);
                            stable = true;
                        }
                        
                        trace("\t% Stabilizing ForceDirectedLayout ["+count+"] Grav="+g+" Tens="+t+" Drag="+d+" Mass="+m+" Length="+l);
                        reset = true;
                        
                        fdl.operate();
                        count++;
                    } else {
                        // Just consider the layout stable:
                        stable = true;
                        break;
                    }
                }
            } catch (err:Error) {
                if (err.errorID === 1502 || err.errorID === 1503)
                    trace("[ visit ] Timeout at iteration " + count + ": " + err.getStackTrace());
                else
                    error("Error operating ForceDirected Layout: "+err.message, err.errorID, err.name, err.getStackTrace());
            }
            
            var elapsed:Number = getTimer() - startTime;
            trace("% >> ForceDirectedLayout runned "+count+"x for "+elapsed/1000+" seconds.");
        }
        
        private function isLayoutStable():Boolean {
            var stable:Boolean = true;
            var nodes:DataList = data.nodes;
            
            if (nodes.length > 1) {
                for each (var n:NodeSprite in nodes) {
                    var p1:Point = _nodePoints[n.data.id];
                    var p2:Point = new Point(n.x, n.y);
                    _nodePoints[n.data.id] = p2;
                    
                    var d:Number = Point.distance(p1, p2);
                    if (d > 40) stable = false;
                }
            }
            
            return stable;
        }
        
        private function storeInitialNodePoints():void {
            _nodePoints = {};
            for each (var n:NodeSprite in data.nodes) {
                _nodePoints[n.data.id] = new Point(n.x, n.y);
            }
        }
        
        /**
         * Reposition all nodes, if they are dislocated,
         * aligning their "real" bounds with its sprite's UP and LEFT edges.
         */ 
        private function realignGraph():void {
        	// Get the rectangle where the graph is positioned:
        	var rb:Rectangle = getRealBounds();
        	// Get the shift value (graph position - original sprite bounds):
        	var shiftX:Number = rb.x - 0;
            var shiftY:Number = rb.y - 0;
        	
        	// Reposition all the nodes,
        	// aligning the graph with the up and letf borders of this sprite:
        	for each (var n:NodeSprite in data.nodes) {
                n.x -= shiftX;
                n.y -= shiftY;
            }
        }
        
        private function onTooltipShow(e:TooltipEvent):void {
            var target:Object = e.object;
            var tooltip:TextSprite = TextSprite(e.tooltip);
            
            if (target is EdgeSprite) {
                formatEdgeTooltip(EdgeSprite(target), tooltip);
            } else {
                formatNodeTooltip(NodeSprite(target), tooltip);
            }
        }
        
        private function formatEdgeTooltip(edge:EdgeSprite, tooltip:TextSprite):void {
            var data:Object = edge.data;

            var font:String = _style.getValue(VisualProperties.EDGE_TOOLTIP_FONT, data);
            var color:uint = _style.getValue(VisualProperties.EDGE_TOOLTIP_COLOR, data);
            var size:Number = _style.getValue(VisualProperties.EDGE_TOOLTIP_FONT_SIZE, data);
            var template:String;
            
            if (edge.props.$merged && _style.hasVisualProperty(VisualProperties.EDGE_TOOLTIP_TEXT_MERGE)) {
                template = _style.getValue(VisualProperties.EDGE_TOOLTIP_TEXT_MERGE, data);
            } else {
                template = _style.getValue(VisualProperties.EDGE_TOOLTIP_TEXT, data);
            }

            tooltip.htmlText = formatTooltipContent(data, template, font, color, size);
            tooltip.textField.backgroundColor = _style.getValue(VisualProperties.EDGE_TOOLTIP_BACKGROUND_COLOR, data);
            tooltip.textField.borderColor = _style.getValue(VisualProperties.EDGE_TOOLTIP_BORDER_COLOR, data);
        }
        
        private function formatNodeTooltip(node:NodeSprite, tooltip:TextSprite):void {
            var data:Object = node.data;

            var font:String = _style.getValue(VisualProperties.NODE_TOOLTIP_FONT, data);
            var color:uint = _style.getValue(VisualProperties.NODE_TOOLTIP_COLOR, data);
            var size:Number = _style.getValue(VisualProperties.NODE_TOOLTIP_FONT_SIZE, data);
            var template:String = _style.getValue(VisualProperties.NODE_TOOLTIP_TEXT, data);
            
            tooltip.htmlText = formatTooltipContent(data, template, font, color, size);
            tooltip.textField.backgroundColor = _style.getValue(VisualProperties.NODE_TOOLTIP_BACKGROUND_COLOR, data);
            tooltip.textField.borderColor = _style.getValue(VisualProperties.NODE_TOOLTIP_BORDER_COLOR, data);
        }
        
        private function formatTooltipContent(data:Object, template:String, font:String, color:uint, size:Number):String {
            var text:String = '<font face="'+font+'" size="'+size+'" color="'+Utils.rgbColorAsString(color)+'">';

            if (template != null) {
                // Format the VizMapper text:
                text += Utils.format(template, data);
            } else {
                for (var attrName:String in data) {
                    var attrValue:* = data[attrName];
                    text += formatTooltipAttribute(attrName, attrValue);
                }
            }

            text += '</font>';

            return text;
        }
        
        private function formatTooltipAttribute(attrName:String, attrValue:*, level:uint=0):String {
            var text:String = '';
            if (attrName === "") attrName = null;

            if (attrValue == null   || attrValue is String || 
                attrValue is Number || attrValue is int    || attrValue is uint   ||
                attrValue is Date   || attrValue is Boolean) {
                
                text += '<textformat blockindent="'+(level*10)+'">';
                text += "- ";
                if (attrName != null)  text += attrName + ": ";
                if (attrValue != null) text += attrValue;
                text += "</textformat>";
                text += "<br>";
            } else {
                if (attrName != null) {
                    text += '<textformat blockindent="'+(level*10)+'">';
                    text += "- " + attrName + ":<br>";
                    text += "</textformat>";
                }
                if (attrValue is Array) {
                    for each (var v:* in attrValue)
                        text += formatTooltipAttribute(null, v, level+1);
                } else {
                    for (var k:String in attrValue)
                        text += formatTooltipAttribute(k, attrValue[k], level);
                }
            }
            
            return text;
        }
    }
}
