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
    import com.gskinner.utils.Rndm;
    import com.senocular.drawing.DashedLine;
    
    import flare.animate.Sequence;
    import flare.animate.Transition;
    import flare.animate.TransitionEvent;
    import flare.animate.Transitioner;
    import flare.display.DirtySprite;
    import flare.display.TextSprite;
    import flare.util.Property;
    import flare.vis.Visualization;
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
    
    import org.cytoscapeweb.model.data.ConfigVO;
    import org.cytoscapeweb.model.data.VisualStyleVO;
    import org.cytoscapeweb.model.error.CWError;
    import org.cytoscapeweb.util.CompoundNodes;
    import org.cytoscapeweb.util.Edges;
    import org.cytoscapeweb.util.GraphUtils;
    import org.cytoscapeweb.util.Groups;
    import org.cytoscapeweb.util.Labels;
    import org.cytoscapeweb.util.Layouts;
    import org.cytoscapeweb.util.Nodes;
    import org.cytoscapeweb.util.Utils;
    import org.cytoscapeweb.util.VisualProperties;
    import org.cytoscapeweb.util.methods.$each;
    import org.cytoscapeweb.view.controls.TooltipControl;
    import org.cytoscapeweb.view.layout.CircleLayout;
    import org.cytoscapeweb.view.layout.CompoundSpringEmbedder;
    import org.cytoscapeweb.view.layout.ForceDirectedLayout;
    import org.cytoscapeweb.view.layout.NodeLinkTreeLayout;
    import org.cytoscapeweb.view.layout.PresetLayout;
    import org.cytoscapeweb.view.layout.RadialTreeLayout;
    import org.cytoscapeweb.view.layout.physics.Simulation;
    import org.cytoscapeweb.view.render.Labeler;
    import org.cytoscapeweb.vis.data.CompoundNodeSprite;
    

    public class GraphVis extends Visualization {
        
        // ========[ CONSTANTS ]====================================================================
        
        // ========[ PRIVATE PROPERTIES ]===========================================================
        
        private var _data:Data;
        private var _layoutName:String;
        private var _style:VisualStyleVO;
        private var _config:ConfigVO;
        private var _nodeLabeler:Labeler;
        private var _compoundNodeLabeler:Labeler;
        private var _edgeLabeler:Labeler;
        private var _tooltipControl:TooltipControl;
        private var _initialWidth:Number;
        private var _initialHeight:Number;
        private var _dragRect:Rectangle;
        
        private var _dataList:Array = [/*flare.vis.data.Data*/];
        private var _appliedLayouts:Array = [/*flare.vis.operator.layout.Layout*/];
        
        private function get tooltipControl():TooltipControl {
            if (_tooltipControl == null) {
                var filter:Function = function(d:DisplayObject):Boolean {  
                    var show:Boolean = _config.nodeTooltipsEnabled && d is NodeSprite;
                    return show || (_config.edgeTooltipsEnabled && d is EdgeSprite);
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
        
        public function get compoundNodeLabeler():Labeler {
            if (_compoundNodeLabeler == null) {
                _compoundNodeLabeler = new Labeler(null, Groups.COMPOUND_NODES);
                //_compoundNodeLabeler = new Labeler(null, Data.NODES);
            }
            return _compoundNodeLabeler;
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

        public function refreshVisualProperties(newStyle:VisualStyleVO=null):void {
            var firstTime:Boolean = this._style == null;
            if (newStyle != null) this._style = newStyle;

            // Nodes & Edges properties:
            // ---------------------------------------------------------
            data.nodes.setProperties(Nodes.properties);
            data.group(Groups.COMPOUND_NODES).setProperties(CompoundNodes.properties);
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
            
            // Compound node labels:
            // ---------------------------------------------------------
            compoundNodeLabeler.cacheText = false;
            compoundNodeLabeler.textMode = TextSprite.DEVICE;
            
            compoundNodeLabeler.fontName = Labels.labelFontName;
            compoundNodeLabeler.fontColor = Labels.labelFontColor;
            compoundNodeLabeler.fontSize = Labels.labelFontSize;
            compoundNodeLabeler.fontWeight = Labels.labelFontWeight;
            compoundNodeLabeler.fontStyle = Labels.labelFontStyle;
            compoundNodeLabeler.hAnchor = Labels.labelHAnchor;
            compoundNodeLabeler.vAnchor = Labels.labelVAnchor;
            compoundNodeLabeler.xOffsetFunc = Labels.labelXOffset;
            compoundNodeLabeler.yOffsetFunc = Labels.labelYOffset;
            compoundNodeLabeler.filters = Labels.filters;
            compoundNodeLabeler.textFunction = Labels.text;
            
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
                if (_config.nodeLabelsVisible) {
                    updateLabels(Data.NODES);
                    updateLabels(Groups.COMPOUND_NODES);
                }
                
                if (_config.edgeLabelsVisible) {
                    updateLabels(Data.EDGES);
                }
            }

            // Tooltips:
            // ---------------------------------------------------------
            tooltipControl.showDelay = _style.getValue(VisualProperties.TOOLTIP_DELAY) as Number;
            
            // Force the rendering--might be necessary for some browsers:
            DirtySprite.renderDirty();
        }

        public function applyLayout(layoutObj:Object):Transition {
            continuousUpdates = false;

            // Remove previous layouts:
            if (_appliedLayouts.length > 0) {
                for (var k:String in _appliedLayouts) {
                    operators.remove(_appliedLayouts[k]);
                }
                _appliedLayouts = [];
            }

            _layoutName = layoutObj.name;
            
            var layout:Layout, fdl:ForceDirectedLayout;
            
            if (_layoutName === Layouts.PRESET || _layoutName === Layouts.COSE) {
                layout = createLayout(layoutObj, data);
                _appliedLayouts.push(layout);
            } else {
                if (_layoutName === Layouts.FORCE_DIRECTED) {
                    // Is there a seed?
                    var seed:* = layoutObj.options.seed;
                    var rndm:* = (seed is Number && uint(seed) > 0) ? new Rndm(uint(seed)) : Math;
                    // If the previous layout is ForceDirected, we need to set the nodes' particles and
                    // the edges' springs to null, otherwise the layout may not render very well
                    // when it is applied again.
                    data.nodes.visit(function(n:NodeSprite):void {
                        n.props.particle = null;
                        // It is also important to set random positions to nodes:
                        n.x = rndm.random() * _initialWidth;
                        n.y = rndm.random() * _initialHeight;
                    });
                    data.edges.visit(function(e:EdgeSprite):void {
                       e.props.spring = null;
                    });
                    fdl = ForceDirectedLayout(createLayout(layoutObj, data));
                    _appliedLayouts.push(fdl);
                } else {
                    // Create one layout for each disconnected component:
                    for (var i:uint = 0; i < _dataList.length; i++) {
                        var d:Data = _dataList[i];
                        if (d.nodes.length > 1) {
                            var rect:Rectangle = GraphUtils.calculateGraphDimension(d.nodes, _layoutName); 
                            var root:NodeSprite = Layouts.rootNode(d);
                            
                            layout = createLayout(layoutObj, d, rect, root);
                            _appliedLayouts.push(layout);
                        }
                    }
                }    
            }
            
            // The layouts must be enabled in order to allow a layout change:
            for each (layout in _appliedLayouts) {
                layout.enabled = false;
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

                for each (layout in _appliedLayouts) layout.operate();
                
                if (_layoutName != Layouts.PRESET) {
                    realignGraph();
                }

                DirtySprite.renderDirty();
                updateLabels();
                
                var repack:Boolean = (_layoutName !== Layouts.PRESET) &&
                                     (_layoutName !== Layouts.COSE);

                if (repack && _dataList != null && _dataList.length > 0) {
                    updateAllCompoundBounds();
                    GraphUtils.repackDisconnected(_dataList,
                                                  stage.stageWidth,
                                                  !_config.nodeLabelsVisible,
                                                  !_config.edgeLabelsVisible);
                }
                
                // update all compound bounds again after the operation
                updateAllCompoundBounds();
            });

            return seq;
        }
        
        public function updateLabels(group:String=null):void {
            if (group == null) {
                updateLabels(Groups.NODES);
                updateLabels(Groups.COMPOUND_NODES);
                updateLabels(Groups.EDGES);
            } else {
                var visible:Boolean;
                var labeler:Labeler;
    
                if (group === Groups.NODES) {
                    visible = _config.nodeLabelsVisible;
                    labeler = nodeLabeler;
                } else if (group === Groups.COMPOUND_NODES) {
                    visible = _config.nodeLabelsVisible;
                    labeler = compoundNodeLabeler;
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
                if (ds is NodeSprite && ds.props.autoSize) {
                    if (! (ds is CompoundNodeSprite && (ds as CompoundNodeSprite).nodesCount > 0)) {
                        ds.dirty();
                    }
                }
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
            if (_config.nodeLabelsVisible) {
                nodeLabeler.operate();
                compoundNodeLabeler.operate();
            }

            // Then render edges and operate their labels:
            $each(d.edges, function(i:uint, e:EdgeSprite):void {
                 e.render();
            });
            if (_config.edgeLabelsVisible) edgeLabeler.operate();

            var bounds:Rectangle = GraphUtils.getBounds(d.nodes,
                                                        d.edges,
                                                        !_config.nodeLabelsVisible,
                                                        !_config.edgeLabelsVisible);
            
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

        /**
         * Updates the bounds of the given compound node sprite using bounds of
         * its child nodes. This function does NOT recursively update bounds of
         * its child compounds, in other words the bounds of all child nodes are
         * assumed to be up-to-date. This method also updates the coordinates
         * of the given compound node sprite according to the newly calculated
         * bounds.
         * 
         * @param cns   compound node sprite
         */
        public function updateCompoundBounds(cns:CompoundNodeSprite):void {
            var ns:NodeSprite;
            var children:Data = new Data();
            var bounds:Rectangle;
            var allChildren:Array = CompoundNodes.getChildren(cns);
            
            if (allChildren.length > 0 && !cns.allChildrenInvisible()) {
                for each (ns in allChildren) {
                    children.addNode(ns);
                }
                
                // calculate&update bounds of the compound node 
                bounds = this.getRealBounds(children);
                cns.updateBounds(bounds);
            }
        }
        
        public function updateAllCompoundBounds():void {
            var cns:CompoundNodeSprite;
            
            // find all parentless compounds, and recursively update bounds
            // in a bottom-up manner.
            for each (cns in data.group(Groups.COMPOUND_NODES)) {
                if (cns.isInitialized() && cns.data.parent == null) {
                    updateAllBounds(cns);
                }
            }
        }
        
        // ========[ PRIVATE METHODS ]==============================================================
        
        /**
         * This method builds a collection of layout operators and node
         * and edge settings to be applied in the demo.
         */
        private function createLayout(obj:Object,
                                      d:Data,
                                      layoutBounds:Rectangle=null,
                                      layoutRoot:DataSprite=null):Layout {
            var layout:Layout;
            var name:String = obj.name;
            var options:Object = obj.options;
            var correction:Number;
            
            if (layoutBounds == null)
               layoutBounds = new Rectangle(bounds.x, bounds.y, _initialWidth, _initialHeight);

            if (name === Layouts.FORCE_DIRECTED) {
                var iter:uint = Math.max(1, options.iterations);
                var maxTime:uint = options.maxTime;
                var autoStab:Boolean = options.autoStabilize;
                var weightAttr:String = options.weightAttr;
                var weightNorm:String = options.weightNorm;
                var sim:Simulation = new Simulation();
                
                var fdl:ForceDirectedLayout = new ForceDirectedLayout(true, iter, maxTime, autoStab, sim, weightAttr, weightNorm);
                //fdl.ticksPerIteration = 1,
                fdl.simulation.dragForce.drag = options.drag;
                fdl.simulation.nbodyForce.gravitation = options.gravitation;
                fdl.simulation.nbodyForce.minDistance = options.minDistance;
                fdl.simulation.nbodyForce.maxDistance = options.maxDistance;
                fdl.defaultParticleMass = options.mass;
                fdl.defaultSpringTension = options.tension;
                fdl.minWeight = options.minWeight;
                fdl.maxWeight = options.maxWeight;

                var length:Number = options.restLength;
                var el:uint = data.edges.length;
                
                if (isNaN(length)) {
                    length = 60 + (el > 0 ? 2*Math.log(el) : 0);
                    length = Math.min(200, length);
                }
                fdl.defaultSpringLength = length;

                trace("[FORCE_DIRECTED] Grav="+fdl.simulation.nbodyForce.gravitation+
                                      " Tens="+fdl.defaultSpringTension+
                                      " Drag="+fdl.simulation.dragForce.drag+
                                      " Mass="+fdl.defaultParticleMass+
                                      " Length="+fdl.defaultSpringLength);

                layout = fdl;
            } else if (name === Layouts.CIRCLE) {
                var tree:Boolean = options.tree;
                
                var cl:CircleLayout = new CircleLayout(null, null, tree, d);
                cl.angleWidth = options.angleWidth * Math.PI / 180;
                
                correction = Math.max(1, Math.abs(360 / options.angleWidth));
                layoutBounds.width *= correction;
                layoutBounds.height *= correction;
                
                if (tree) {
                    layoutBounds.height = Math.max(200, layoutBounds.height);
                    layoutBounds.width = Math.max(200, layoutBounds.width);
                }
                
                cl.padding = 0;

                layout = cl;
            } else if (name === Layouts.RADIAL) {
                var r:Number = options.radius;
                if (isNaN(r)) {
                    r = Math.max(60, Math.sqrt(layoutBounds.width*layoutBounds.height)/4);
                    correction = Math.max(1, Math.abs(360 / options.angleWidth));
                    r *= correction;
                }

                var rtl:RadialTreeLayout = new RadialTreeLayout(r, true, false, d);
                rtl.angleWidth = options.angleWidth * Math.PI / 180;
                
                layout = rtl;
            } else if (name === Layouts.TREE) {
                var nltl:NodeLinkTreeLayout = new NodeLinkTreeLayout(options.orientation,
                                                                     options.depthSpace,
                                                                     options.breadthSpace,
                                                                     options.subtreeSpace,
                                                                     d);
                nltl.layoutAnchor = new Point(0, -2 * height/5);
                
                layout = nltl;
            } else if (name === Layouts.PRESET) {
                var psl:PresetLayout = new PresetLayout();
                
                var points:Array = options.points;
                if (points != null) {
                    for each (var p:Object in points) {
                        psl.addPoint(p.id, new Point(p.x * scaleX, p.y * scaleY));
                    }
                }
                
                layout = psl;
            } else if (name === Layouts.COSE) {
                // create layout
                var cose:CompoundSpringEmbedder = new CompoundSpringEmbedder();
                // set layout options
                cose.setOptions(options);
                // set current layout
                layout = cose;
            }
            
            if (layout == null) throw new CWError("Invalid layout: " + name);
            
            layout.layoutBounds = layoutBounds;
            layout.layoutRoot = layoutRoot;

            return layout;
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
            // Hide it, if no text:
            tooltip.alpha = (tooltip.text == null || tooltip.text == "") ? 0 : 1;
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
            var text:String

            if (template != null) {
                text = '<font face="'+font+'" size="'+size+'" color="'+Utils.rgbColorAsString(color)+'">';
                // Format the VizMapper text:
                text += Utils.format(template, data);
                text += '</font>';
            }

            return text;
        }
        
        private function updateAllBounds(cns:CompoundNodeSprite):void { 
            for each (var ns:NodeSprite in cns.getNodes()) {
                if (ns is CompoundNodeSprite && (ns as CompoundNodeSprite).isInitialized()) {
                    this.updateAllBounds(ns as CompoundNodeSprite);
                }
            }
            
//            this.compoundNodeLabeler.update(cns);
            this.updateCompoundBounds(cns);
            cns.render();
        }
    }
}
