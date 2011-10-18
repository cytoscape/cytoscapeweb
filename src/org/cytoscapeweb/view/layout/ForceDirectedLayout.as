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
package org.cytoscapeweb.view.layout {
    import flare.physics.Particle;
    import flare.physics.Simulation;
    import flare.physics.Spring;
    import flare.util.Maths;
    import flare.vis.data.DataList;
    import flare.vis.data.EdgeSprite;
    import flare.vis.data.NodeSprite;
    import flare.vis.operator.layout.ForceDirectedLayout;
    
    import flash.geom.Point;
    import flash.utils.getTimer;
    
    import mx.utils.StringUtil;
    
    import org.cytoscapeweb.util.GraphUtils;
    import org.cytoscapeweb.util.Groups;
    import org.cytoscapeweb.util.methods.$each;
    

    /**
     * This is the same Flare layout, slightly modified to create springs for merged edges only,
     * which improves the performance for graphs that have multiple edges linking the
     * same pair of nodes.
     * 
     * @see flare.vis.operator.layout.ForceDirectedLayout
     */
    public class ForceDirectedLayout extends flare.vis.operator.layout.ForceDirectedLayout {

        // ========[ CONSTANTS ]====================================================================
        
        public static const NORMALIZED_WEIGHT:String = "linear";
        public static const INV_NORMALIZED_WEIGHT:String = "invlinear";
        public static const LOG_WEIGHT:String = "log";
        
        protected static const MIN_SPRING_WEIGHT:Number = 0.1;
        protected static const MAX_SPRING_WEIGHT:Number = 0.9;
        
        // ========[ PRIVATE PROPERTIES ]===========================================================

        private var _gen:uint = 0;
        private var _damping:Number = 0.1;
        private var _maxTime:uint;
        
        private var _weightAttr:String;
        private var _weightNormalization:String;
        private var _weighted:Boolean;
        private var _minWeight:Number;
        private var _maxWeight:Number;
        
        private var _eLengths:/*edge_id->length*/Object;

        // ========[ PUBLIC PROPERTIES ]===========================================================

        public var autoStabilize:Boolean;

        public function get maxTime():uint { return _maxTime; }
        public function set maxTime(v:uint):void { _maxTime = Math.max(500, v); }
        
        /** The name of the edge attribute that contains the weights. */
        public function get weightAttr():String { return _weightAttr; }
        public function get weightNormalization():String { return _weightNormalization; }
        public function get weighted():Boolean { return _weighted; }
        
        /** The minimum edge weight to consider, if the layout is set to be weighted. */
        public function get minWeight():Number { return _minWeight; }
        public function set minWeight(min:Number):void { _minWeight = min; }
        
        /** The maximum edge weight to consider, if the layout is set to be weighted */
        public function get maxWeight():Number { return _maxWeight; }
        public function set maxWeight(max:Number):void { _maxWeight = max; }
        
        public function get edges():DataList {
            return visualization.data.group(Groups.MERGED_EDGES);
        }

        // ========[ CONSTRUCTOR ]==================================================================

        /**
         * Creates a new ForceDirectedLayout.
         * @param iterations the number of iterations to run the simulation
         *                   per invocation.
         * @param maxTime the maximum time to run the simulation, in milliseconds. The minimum value is 500.
         * @param autoStabilize the maximum time to run the simulation, in milliseconds. The minimum value is 500.
         * @param sim the physics simulation to use for the layout. If null
         *            (the default), default simulation settings will be used
         */
        public function ForceDirectedLayout(enforceBounds:Boolean=false,
                                            iterations:uint=1,
                                            maxTime:uint=60000,
                                            autoStabilize:Boolean=true,
                                            sim:Simulation=null,
                                            edgeWeightAttr:String=null,
                                            edgeWeightNormalization:String=null) {
            super(enforceBounds, iterations, sim);
            this.maxTime = maxTime;
            this.autoStabilize = autoStabilize;
            _weightAttr = StringUtil.trim(edgeWeightAttr);
            _weightNormalization = StringUtil.trim(edgeWeightNormalization).toLocaleLowerCase();
            _weighted = _weightAttr != "";
            _eLengths = null;
            
            this.restLength = function(e:EdgeSprite):Number {
                var rl:Number = defaultSpringLength;
                var sw:Number = e.props.springWeight;
                
                if (weighted && !isNaN(sw)) {
                    switch (edgeWeightNormalization) {
                        case INV_NORMALIZED_WEIGHT:
                            rl /= (MIN_SPRING_WEIGHT + MAX_SPRING_WEIGHT - sw); break;
                        default:
                            if (sw !== 0) rl /= sw;
                    }
                }
                return Math.max(1, rl);
            }
            
            this.tension = function(e:EdgeSprite):Number {
                var t:Number = 0;
                
                if (!GraphUtils.isFilteredOut(e)) {
                    var s:Spring = Spring(e.props.spring);
                    var n:Number = Math.max(s.p1.degree, s.p2.degree);
                    t = defaultSpringTension / Math.sqrt(n);
                    t = Math.max(0.01, t);
                }
                
                return t;
            };
        }
        
        // ========[ PROTECTED PROPERTIES ]=========================================================
        
        /** @inheritDoc */
        protected override function layout():void {
            ++_gen; // update generation counter
            init(); // populate simulation

            // run simulation
            simulation.bounds = enforceBounds ? layoutBounds : null;
            var ticks:int = ticksPerIteration;
            var t1:uint = getTimer();

            $each(iterations, function(i:uint, o:*):Boolean {
                if (getTimer() - t1 < maxTime) {
                    simulation.tick(ticks);
                    return false;
                }
                return true;
            });

            // stabilize
            if (autoStabilize) stabilize(t1);
            
            // update positions
            $each(visualization.data.nodes, function(i:uint, n:NodeSprite):void {
                update(n);
            });
            updateEdgePoints(_t);
        }
        
        protected function stabilize(t1:uint):void {
            var sim:Simulation = simulation;
            
            var stable:Boolean = false;
            var ticks:int = ticksPerIteration;
            var count:uint = 0;
            const MIN_M:int = 1, MAX_D:Number = 0.8, MAX_L:int = 240, MIN_T:Number = 0.05, MAX_G:int = -100;

            while ( !stable &&  (getTimer() - t1 < maxTime) ) {
                for (var i:int = 0; i < 10; i++) sim.tick(ticks);
                stable = stable || isStable();
                
                if (!stable) {
                    // Start tuning the Layout, because it's hard to make the
                    // layout stable with the current values:
                    var m:Number = defaultParticleMass;          
                    var d:Number = sim.dragForce.drag;
                    var l:Number = defaultSpringLength;
                    var g:Number = sim.nbodyForce.gravitation;
                    var t:Number = defaultSpringTension;
                    
                    m = defaultParticleMass = Math.max(MIN_M, m*0.98);
                    d = sim.dragForce.drag = Math.min(MAX_D, d*1.01);
                    l = defaultSpringLength = Math.min(MAX_L, l*1.04);
                    g = sim.nbodyForce.gravitation = Math.min(MAX_G, g*0.98);
                    t = defaultSpringTension = Math.max(MIN_T, t*0.9);

                    $each(edges, function(i:uint, e:EdgeSprite):void {
                        var s:Spring = e.props.spring;
                        s.restLength = restLength(e);
                        s.tension = tension(e);
                    });
                    $each(visualization.data.nodes, function(i:uint, n:NodeSprite):void {
                        var p:Particle = n.props.particle;
                        p.mass = mass(n);
                    });
                    
                    trace("\t% Stabilizing ForceDirectedLayout ["+(++count)+"] Grav="+g+" Tens="+t+" Drag="+d+" Mass="+m+" Length="+l);
                } else {
                    // Just consider the layout stable:
                    stable = true;
                    break;
                }
            }
        }
        
        /**
         * Just compare the particle positions between iterations. If at least one of them
         * has moved too much, it returns false;
         */
        protected function isStable():Boolean {
            var stable:Boolean = true;
            var sim:Simulation = simulation;
            var edges:DataList = this.edges;
            var s:Spring;

            // Store initial particle points (coordinates):
            if (_eLengths == null) {
                _eLengths = {};
                $each(edges, function(i:uint, e:EdgeSprite):void {
                    s = e.props.spring;
                    _eLengths[e] = 0;
                });
            }

            $each(edges, function(i:uint, e:EdgeSprite):void {
                s = e.props.spring;
                var d1:Number = _eLengths[e];
                var p1:Point = new Point(s.p1.x, s.p1.y);
                var p2:Point = new Point(s.p2.x, s.p2.y);
                var d2:Number = Point.distance(p1, p2);
                _eLengths[e] = d2;

                stable = stable && !(e.source !== e.target && d1 === 0) && Math.abs(d2-d1) < 80;
            });
              
            return stable;
        }

        /** @inheritDoc */
        protected override function init():void {
            var o:Object;
            var p:Particle, s:Spring, n:NodeSprite, e:EdgeSprite;
            var sim:Simulation = simulation;
            var length:uint, i:uint;
            var finished:Boolean = false;
            var edges:DataList = this.edges;
            var nodes:DataList = visualization.data.nodes;

            // initialize all simulation entries
            $each(nodes, function(i:uint, n:NodeSprite):void {
                p = n.props.particle;
                o = _t.$(n);

                if (p == null) {
                    var m:Number = mass(n);
                    n.props.particle = (p = sim.addParticle(m, o.x, o.y));
                    p.fixed = o.fixed;
                } else {
                    p.x = o.x;
                    p.y = o.y;
                    p.fixed = o.fixed;
                }
                p.tag = _gen;
            });
            
            // Minimum and maximum weight values for the current edges set:
            var computeMin:Boolean = isNaN(minWeight); // User didn't set the min weight
            var computeMax:Boolean = isNaN(maxWeight);
            
            if (computeMin) minWeight = Number.POSITIVE_INFINITY;
            if (computeMax) maxWeight = Number.NEGATIVE_INFINITY;
            var ew:Number;
            
            $each(edges, function(i:uint, e:EdgeSprite):void {
                s = e.props.spring;
                if (s == null) {
                    var l:Number = defaultSpringLength;
                    var t:Number = defaultSpringTension;
                    var d:Number = _damping;
                    s = Spring(sim.addSpring(e.source.props.particle, e.target.props.particle, l, t, d));
                    e.props.spring = s;
                }

                s.tag = _gen;
                
                if (weighted && !GraphUtils.isFilteredOut(e)) {
                    // Get min and max weights - filtered-in edges only!
                    ew = e.data[weightAttr];
                    if (computeMin) minWeight = Math.min(ew, minWeight);
                    if (computeMax) maxWeight = Math.max(ew, maxWeight);
                }
            });
            
            if (weightNormalization === LOG_WEIGHT) {
                minWeight = Math.log(minWeight);
                maxWeight = Math.log(maxWeight);
            }
            
            // set up simulation parameters
            // this needs to be kept separate from the above initialization
            // to ensure all simulation items are created first
            if (mass != null) {
                $each(nodes, function(i:uint, n:NodeSprite):void {
                    p = n.props.particle;
                    p.mass = mass(n);
                });
            }

            var mediumSpringWeight:Number = (MAX_SPRING_WEIGHT - MIN_SPRING_WEIGHT) / 2;

            $each(edges, function(i:uint, e:EdgeSprite):void {
                s = e.props.spring;
                var sw:Number;
                
                if (weighted) {
                    ew = e.data[weightAttr];
                    if (weightNormalization === LOG_WEIGHT) ew = Math.log(ew);

                    // Normalize min and max weights for better visual results (always between 0 and 1):
                    if (minWeight === maxWeight) {
                        sw = mediumSpringWeight;
                    } else if (ew < minWeight) {
                        sw = MIN_SPRING_WEIGHT;
                    } else if (ew > maxWeight) {
                        sw = MAX_SPRING_WEIGHT;
                    } else {
                        var f:Number = Maths.invLinearInterp(ew, minWeight, maxWeight);
                        sw = Maths.linearInterp(f, MIN_SPRING_WEIGHT, MAX_SPRING_WEIGHT);
                    }
                }

                e.props.springWeight = sw;
                
                if (restLength != null)
                    s.restLength = restLength(e);
                if (tension != null)
                    s.tension = tension(e);
                if (damping != null)
                    s.damping = damping(e);
            });

            // clean-up unused items
            $each(sim.particles, function(i:uint, p:Particle):void {
                if (p.tag != _gen) p.kill();
            });
            $each(sim.springs, function(i:uint, s:Spring):void {
                if (s.tag != _gen) s.kill();
            });
        }
    }
}
