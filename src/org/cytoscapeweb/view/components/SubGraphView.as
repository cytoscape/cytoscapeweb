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
    import flare.animate.Sequence;
    import flare.animate.Transition;
    import flare.animate.TransitionEvent;
    import flare.animate.Transitioner;
    import flare.display.DirtySprite;
    import flare.display.TextSprite;
    import flare.util.Orientation;
    import flare.util.Property;
    import flare.vis.Visualization;
    import flare.vis.controls.TooltipControl;
    import flare.vis.data.Data;
    import flare.vis.data.DataList;
    import flare.vis.data.DataSprite;
    import flare.vis.data.EdgeSprite;
    import flare.vis.data.NodeSprite;
    import flare.vis.events.TooltipEvent;
    import flare.vis.events.VisualizationEvent;
    import flare.vis.operator.layout.CircleLayout;
    import flare.vis.operator.layout.Layout;
    import flare.vis.operator.layout.NodeLinkTreeLayout;
    import flare.vis.operator.layout.RadialTreeLayout;
    
    import flash.display.DisplayObject;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.text.TextField;
    
    import org.cytoscapeweb.model.data.ConfigVO;
    import org.cytoscapeweb.model.data.VisualStyleVO;
    import org.cytoscapeweb.util.Edges;
    import org.cytoscapeweb.util.GraphUtils;
    import org.cytoscapeweb.util.Groups;
    import org.cytoscapeweb.util.Labels;
    import org.cytoscapeweb.util.Layouts;
    import org.cytoscapeweb.util.Nodes;
    import org.cytoscapeweb.util.Utils;
    import org.cytoscapeweb.util.VisualProperties;
    import org.cytoscapeweb.view.layout.ForceDirectedLayout;
    import org.cytoscapeweb.view.layout.PresetLayout;
    import org.cytoscapeweb.view.render.Labeler;
    

    public class SubGraphView extends Visualization {
        
        // ========[ CONSTANTS ]====================================================================
        
        // ========[ PRIVATE PROPERTIES ]===========================================================
        
        private var _layouts:Object;
        private var _currentLayout:Layout;
        private var _style:VisualStyleVO;
        private var _config:ConfigVO;
        private var _nodeLabeler:Labeler;
        private var _edgeLabeler:Labeler;
        private var _tooltipControl:TooltipControl;
        private var _initialWidth:Number;
        private var _initialHeight:Number;
        private var _nodePoints:Object;
        
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
        public override function set bounds(r:Rectangle):void {
            super.bounds = r;
            _initialWidth = r.width;
            _initialHeight = r.height;
        }

        // ========[ CONSTRUCTOR ]==================================================================

        public function SubGraphView(data:Data, config:ConfigVO, style:VisualStyleVO) {
        	super(data);
        	this._config = config;
       
            // Visual Style:
            // --------------------------------------------------------------------------
            applyVisualStyle(style);

            // Tooltips:
            // --------------------------------------------------------------------------
            controls.add(tooltipControl);
            
            // --------------------------------------------------------------------------
            // Avoiding the bug that makes the edges separate from the nodes:
            // (seems to be caused by a Flash/Flex integration problem - see:
            // http://sourceforge.net/forum/forum.php?thread_id=2190163&forum_id=757572)
            addEventListener(VisualizationEvent.UPDATE, function ():void{ DirtySprite.renderDirty(); });
        }
        
        // ========[ PUBLIC METHODS ]===============================================================

        public function applyVisualStyle(style:VisualStyleVO):void {
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
            edgeLabeler.cacheText = false;
            edgeLabeler.textMode = TextSprite.DEVICE;

            edgeLabeler.fontName = Labels.labelFontName;
            edgeLabeler.fontColor = Labels.labelFontColor;
            edgeLabeler.fontSize = Labels.labelFontSize;
            edgeLabeler.fontWeight = Labels.labelFontWeight;
            edgeLabeler.fontStyle = Labels.labelFontStyle;
            edgeLabeler.filters = Labels.filters;
            edgeLabeler.textFunction = Labels.text;
            
            // Without this the font styles would not change:
            data.visit(function(d:DataSprite):Boolean {
                var lb:TextSprite = d.props.label;
                if (lb != null) {
                    if (d is NodeSprite) lb.applyFormat(nodeLabeler.textFormat);
                    else if (d is EdgeSprite) lb.applyFormat(edgeLabeler.textFormat);
                }
                return false;
            });

            updateLabels();

            // Tooltips:
            // ---------------------------------------------------------
            tooltipControl.showDelay = _style.getValue(VisualProperties.TOOLTIP_DELAY) as Number;
            
            DirtySprite.renderDirty();
        }

        public function applyLayout(name:String):Transition {
            continuousUpdates = false;
            
            // If the previous layout is ForceDirected, we need to set the nodes' particles and the
            // edges' springs to null, otherwise the layout may not render very well when it is
            // applied again (e.g. by using the "Recompute Layout" feature). 
            if (_currentLayout is ForceDirectedLayout) {
	            for each (var n:NodeSprite in data.nodes)
	               n.props.particle = null;
	            for each (var e:EdgeSprite in data.edges)
	               e.props.spring = null;
            }

            if (_currentLayout != null)
                operators.remove(_currentLayout);

            _currentLayout = layouts[name];
            
            if (_currentLayout is PresetLayout)
                PresetLayout(_currentLayout).points = _config.nodesPoints;
            
            // The layout must be enabled in order to allow a layout change:
            _currentLayout.enabled = true;
            operators.add(_currentLayout);

            if (_currentLayout is ForceDirectedLayout) {
                // First set random positions to nodes:
                data.nodes.visit(function(n:NodeSprite):void {
                    n.x = Math.random() * width;
                    n.y = Math.random() * height;          
                });
            }

            var seq:Sequence = new Sequence();
            var trans:Transitioner = update(0.1);
            seq.add(trans);

            seq.addEventListener(TransitionEvent.START, function(evt:TransitionEvent):void {
            	evt.currentTarget.removeEventListener(evt.type, arguments.callee);

                if (_currentLayout is ForceDirectedLayout)
                    ForceDirectedLayout(_currentLayout).enforceBounds = false;
            });
            
            seq.addEventListener(TransitionEvent.END, function(evt:TransitionEvent):void {
                evt.currentTarget.removeEventListener(evt.type, arguments.callee);

                if (_currentLayout is ForceDirectedLayout)
                    operateForceDirectedLayout();

                if (!(_currentLayout is PresetLayout))
                    realignGraph();
                
                // After new layout is rendered, disable it so users can drag the nodes:
                _currentLayout.enabled = false;
                DirtySprite.renderDirty();
                
                updateLabels();
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

        public function getRealBounds():Rectangle {
            // It's necessary to operate labeler first, so each label's text sprite is well placed!
            if (_config.nodeLabelsVisible) nodeLabeler.operate();

            var bounds:Rectangle = new Rectangle();
            var minX:Number = Number.POSITIVE_INFINITY, minY:Number = Number.POSITIVE_INFINITY;
            var maxX:Number = Number.NEGATIVE_INFINITY, maxY:Number = Number.NEGATIVE_INFINITY;

            // First, consider the NODES bounds:
            for each (var n:NodeSprite in data.nodes) {
                // The node size (its shape must have the same height and width; e.g. a circle)
                var ns:Number = n.height;
                // Verify MIN and MAX x/y again:
                minX = Math.min(minX, (n.x - ns/2));
                minY = Math.min(minY, (n.y - ns/2));
                maxX = Math.max(maxX, (n.x + ns/2));
                maxY = Math.max(maxY, (n.y + ns/2));
                
                // Consider the LABELS bounds, too:
                var lbl:TextSprite = n.props.label;
                if (_config.nodeLabelsVisible && lbl != null) {
                	// The alignment values are done by the text field, not the label...
                	var fld:TextField = lbl.textField;
                    minX = Math.min(minX, lbl.x + fld.x);
                    maxX = Math.max(maxX, (lbl.x + lbl.width + fld.x));
                    minY = Math.min(minY, lbl.y + fld.y);
                    maxY = Math.max(maxY, (lbl.y + lbl.height + fld.y));
                }
            }
            
            // Then consider the edges bezier control points too, 
            // because curved edges may get out of bounds:
            for each (var e:EdgeSprite in data.edges) e.render();
            if (_config.edgeLabelsVisible) edgeLabeler.operate();
            
            for each (e in data.edges) {
                // Edge LABELS first, to avoid checking edges that are already inside the bounds:
                lbl = e.props.label;
                if (_config.edgeLabelsVisible && lbl != null) {
                    fld = lbl.textField;
                    minX = Math.min(minX, lbl.x + fld.x);
                    maxX = Math.max(maxX, (lbl.x + lbl.width + fld.x));
                    minY = Math.min(minY, lbl.y + fld.y);
                    maxY = Math.max(maxY, (lbl.y + lbl.height + fld.y));
                }
                
                if (e.props.$points != null && e.props.$points.curve != null) {
                	var c:Point = e.props.$points.curve;
                	if (c.x < minX || c.y < minY || c.x > maxX || c.y > maxY) {
	                    var p1:Point = e.props.$points.start;
	                    var p2:Point = e.props.$points.end;
	                    // Alwasys check a few points along the bezier curve to see
	                    // if any of them is out of the bounds:
	                    var fractions:Array = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9];
	                    for each (var f:Number in fractions) {
		                    var mp:Point = Utils.bezierPoint(p1, p2, c, f);
		                    minX = Math.min(minX, mp.x);
		                    maxX = Math.max(maxX, mp.x);
		                    minY = Math.min(minY, mp.y);
		                    maxY = Math.max(maxY, mp.y);
		            	}
	                }
                }
            }
            
            const PAD:Number = 2;
            bounds.x = minX - PAD;
            bounds.y = minY - PAD;
            bounds.width = maxX - bounds.x + PAD;
            bounds.height = maxY - bounds.y + PAD;
            
            return bounds;
        }
        
        public function showDragRectangle():void {
            var b:Rectangle = getRealBounds();
            
            // Draw the border:
            graphics.lineStyle(1, 0xccccee, 0.7); 
            graphics.moveTo(b.x, b.y);
            graphics.lineTo(b.x + b.width, b.y);
            graphics.lineTo(b.x + b.width, b.y + b.height);
            graphics.lineTo(b.x, b.y + b.height);
            graphics.lineTo(b.x, b.y);
            // Fill with a transparent color:
            graphics.beginFill(_style.getValue(VisualProperties.BACKGROUND_COLOR) as uint, 0.6);
            graphics.drawRect(b.x, b.y, b.width, b.height);
            
            // Bring the subgraph to front:
            GraphUtils.bringToFront(this);
        }
        
        public function hideDragRectangle():void {
            graphics.clear();
        }
        
        public function highlightSelectedNode(n:NodeSprite):void {
        	if (n != null) {
        	    n.fillColor = Nodes.fillColor(n);
        	    n.lineWidth = Nodes.selectionLineWidth(n);
        	    n.lineColor = Nodes.lineColor(n);
        		n.alpha = Nodes.selectionAlpha(n);
        		n.filters = Nodes.filters(n, true);
        		DirtySprite.renderDirty();
        	}
        }
        
        public function highlightSelectedEdge(e:EdgeSprite):void {
        	if (e != null) {
         	    e.lineWidth = Edges.lineWidth(e);
                e.lineColor = Edges.lineColor(e);
                e.props.sourceArrowColor = Edges.sourceArrowColor(e);
                e.props.targetArrowColor = Edges.targetArrowColor(e);
                e.alpha = Edges.alpha(e);
                e.filters = Edges.filters(e);
                DirtySprite.renderDirty();
        	}
        }

        public function resetAll():void {
            resetAllEdges();
            resetAllNodes();
        }
        
        public function resetAllNodes():void {
            // If no nodes list was provided, we get all the nodes:
            var nodes:DataList = data.nodes;
            
            // Restore node properties:
            //     Note: It is better to set only the properties that are necessary.
            //     I tried data.nodes.setProperties(nodeProperties), but some nodes blinks when
            //     rolling over/out
            nodes.setProperty("lineWidth", Nodes.lineWidth);
            nodes.setProperty("fillColor", Nodes.fillColor);
            nodes.setProperty("lineColor", Nodes.lineColor);
            nodes.setProperty("alpha", Nodes.alpha);
            nodes.setProperty("filters", Nodes.filters);
            DirtySprite.renderDirty();
        }
        
        public function resetAllEdges():void {
        	data.edges.setProperties(Edges.properties);
        	DirtySprite.renderDirty();
        }
        
        public function resetDataSprite(ds:DataSprite):void {
            if (ds is NodeSprite) resetNode(NodeSprite(ds));
            else if (ds is EdgeSprite) resetEdge(EdgeSprite(ds));
        }
        
        public function resetNode(n:NodeSprite):void {
            if (n != null) {
                n.size = Nodes.size(n);
                n.fillColor = Nodes.fillColor(n);
                n.lineWidth = Nodes.lineWidth(n);
                n.lineColor = Nodes.lineColor(n);
                n.alpha = Nodes.alpha(n);  
                n.shape = Nodes.shape(n);
                n.filters = Nodes.filters(n);
            }
        }
        
        public function resetEdge(e:EdgeSprite):void {
            if (e != null) {
                e.shape = Edges.shape(e);
                e.lineWidth = Edges.lineWidth(e);
                e.lineColor = Edges.lineColor(e);
                e.props.sourceArrowColor = Edges.sourceArrowColor(e);
                e.props.targetArrowColor = Edges.targetArrowColor(e);
                e.alpha = Edges.alpha(e);  
                e.arrowType = Edges.targetArrowShape(e);
                e.props.curvature = Edges.curvature(e);
                e.filters = Edges.filters(e);
            }
        }
        
        // ========[ PRIVATE METHODS ]==============================================================
        
        /**
         * This method builds a collection of layout operators and node
         * and edge settings to be applied in the demo.
         */
        private function get layouts():Object {
        	if (_layouts == null) {
        		_layouts = new Object();

                // ---------------------------------------------------------------------------------
        		// FORCE DIRECTED:
        		// ---------------------------------------------------------------------------------
        		var fdl:ForceDirectedLayout = new ForceDirectedLayout(true, 5, null);
        		fdl.layoutBounds = new Rectangle(bounds.x, bounds.y, _initialWidth, _initialHeight),
                fdl.ticksPerIteration = 1.5,
                fdl.simulation.dragForce.drag = 0.4;
                fdl.simulation.nbodyForce.gravitation = Math.min(-100, -50000/data.nodes.length);
                fdl.simulation.nbodyForce.minDistance = 1;
                fdl.simulation.nbodyForce.maxDistance = 5000;
                fdl.defaultParticleMass = 2;
                fdl.defaultSpringTension = 0.1;
                
                var diagonal:Number = Math.sqrt(_initialWidth*_initialWidth + _initialHeight*_initialHeight);
                var desiredLength:Number = diagonal/8 + Math.pow(data.edges.length/data.nodes.length, 2)*0.3;
                fdl.defaultSpringLength = Math.min(200, desiredLength);

                _layouts[Layouts.FORCE_DIRECTED] = fdl;

                // ---------------------------------------------------------------------------------
	            // CIRCLE LAYOUT:
                // ---------------------------------------------------------------------------------
	            var cl:CircleLayout = new CircleLayout(null, null, false);
                cl.angleWidth = -2 * Math.PI;
                cl.padding = 0;

                _layouts[Layouts.CIRCLE] = cl;

                // ---------------------------------------------------------------------------------
                // CIRCLE TREE LAYOUT:
                // ---------------------------------------------------------------------------------
	            var ctl:CircleLayout = new CircleLayout(null, null, true);
                ctl.angleWidth = -2 * Math.PI;
                ctl.padding = 0;

                _layouts[Layouts.CIRCLE_TREE] = ctl;

                // ---------------------------------------------------------------------------------
                // RADIAL TREE LAYOUT:
                // ---------------------------------------------------------------------------------
                var rtl:RadialTreeLayout = new RadialTreeLayout(60, false);
                rtl.angleWidth = -2 * Math.PI;

                _layouts[Layouts.RADIAL] = rtl;

                // ---------------------------------------------------------------------------------
                // TREE LAYOUT:
                // ---------------------------------------------------------------------------------
                var nltl:NodeLinkTreeLayout = new NodeLinkTreeLayout(Orientation.TOP_TO_BOTTOM, 50, 30, 5);
                nltl.layoutAnchor = new Point(0, -2 * height/5);
                
                _layouts[Layouts.TREE] = nltl;
                
                // ---------------------------------------------------------------------------------
                // PRESET LAYOUT:
                // ---------------------------------------------------------------------------------
                var psl:PresetLayout = new PresetLayout(_config.nodesPoints);
                
                _layouts[Layouts.PRESET] = psl;
            }

            return _layouts;
        }
        
        private function operateForceDirectedLayout():void {
            var fdl:ForceDirectedLayout = ForceDirectedLayout(_currentLayout);
            var start:Date = new Date();
            
            const RUN_TIMES_1:int = 20;
            const RUN_TIMES_2:int = 10 + RUN_TIMES_1;
            const MAX_TIMES:int = 120;
            
            // Always operate the layout a few times first:
            for (var count:int = 0; count < RUN_TIMES_1; count++) fdl.operate();
            
            //Then operate the layout until it's stable:
            storeInitialNodePoints();
            var fdlTuned:Boolean = false;
            
            do {
                fdl.operate();
                
                if (count >= RUN_TIMES_2) {
                    // Start tuning the Layout, because it's hard to make the
                    // layout stable with the current values:
                    var m:Number = fdl.defaultParticleMass;
                    var t:Number = fdl.defaultSpringTension;
                    var d:Number = fdl.simulation.dragForce.drag;
                    var g:Number = fdl.simulation.nbodyForce.gravitation;
                    var l:Number = fdl.defaultSpringLength;
                    
                    m = fdl.defaultParticleMass = Math.max(1, m*0.9);
                    t = fdl.defaultSpringTension = Math.max(0.01, t*0.8);
                    d = fdl.simulation.dragForce.drag = Math.max(1, d*1.2);
                    g = fdl.simulation.nbodyForce.gravitation = Math.min(-100, g*0.8);
                    l = fdl.defaultSpringLength = Math.min(260, l*1.05);
                    
                    trace("\t% Tuning ForceDirectedLayout ["+count+"] Grav="+g+" Tens="+t+" Drag="+d+" Mass="+m+" Length="+l);
                    
                    fdl.operate();
                    count++;
                    fdlTuned = true;
                }
            } while (!isLayoutStable() && count++ < MAX_TIMES);
            
            var elapsed:Number = new Date().time - start.time;
            trace("% >> ForceDirectedLayout runned "+count+"x for "+elapsed/1000+" seconds.");
            
            // Reset layout parameter values:
            if (fdlTuned) _layouts = null;
        }
        
        private function isLayoutStable():Boolean {
            var stable:Boolean = true;
            var nodes:DataList = data.nodes;
            
            for each (var n:NodeSprite in nodes) {
                var p1:Point = _nodePoints[n.data.id];
                var p2:Point = new Point(n.x, n.y);
                _nodePoints[n.data.id] = p2;
                
                var d:Number = Point.distance(p1, p2);
                if (d > 40) stable = false;
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
        
        private function formatTooltipAttribute(attrName:String, attrValue:*, level:int=0):String {
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
