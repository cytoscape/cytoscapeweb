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
	import flare.vis.data.Data;
	import flare.vis.data.EdgeSprite;
	import flare.vis.data.NodeSprite;
	import flare.vis.operator.layout.ForceDirectedLayout;
	

	/**
	 * This is the same Flare layout, slightly modified to create springs for merged edges only,
	 * which improves the performance for graphs that have multiple edges linking the
	 * same pair of nodes.
	 * 
	 * @see flare.vis.operator.layout.ForceDirectedLayout
	 */
	public class ForceDirectedLayout extends flare.vis.operator.layout.ForceDirectedLayout {

        // ========[ PRIVATE PROPERTIES ]===========================================================

		private var _gen:uint = 0;
		private var _damping:Number = 0.1;

        // ========[ CONSTRUCTOR ]==================================================================

		/**
		 * Creates a new ForceDirectedLayout.
		 * @param iterations the number of iterations to run the simulation
		 *  per invocation
		 * @param sim the physics simulation to use for the layout. If null
		 *  (the default), default simulation settings will be used
		 */
		public function ForceDirectedLayout(enforceBounds:Boolean=false, 
			                                iterations:int=1, sim:Simulation=null) {
			super(enforceBounds, iterations, sim);
		}
		
		// ========[ PROTECTED PROPERTIES ]=========================================================
		
		/** @inheritDoc */
		protected override function layout():void {
			++_gen; // update generation counter
			init(); // populate simulation

			// run simulation
			simulation.bounds = enforceBounds ? layoutBounds : null;
			var iter:int = iterations;
			var ticks:int = ticksPerIteration;

			for (var i:uint=0; i<iter; ++i) {
				simulation.tick(ticks);
			}

			visualization.data.nodes.visit(update); // update positions
			updateEdgePoints(_t);
		}

		/** @inheritDoc */
		protected override function init():void {
			var data:Data = visualization.data, o:Object;
			var p:Particle, s:Spring, n:NodeSprite, e:EdgeSprite;
			var sim:Simulation = simulation;

			// initialize all simulation entries
			for each (n in data.nodes) {
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
			}
			for each (e in data.edges) {
				if (e.props.$merged) {
					s = e.props.spring;
					if (s == null) {
						var l:Number = defaultSpringLength;
						var t:Number = defaultSpringTension;
						var d:Number = _damping;
						e.props.spring = (s = sim.addSpring(
							e.source.props.particle, e.target.props.particle, l, t, d));
					}
	
					s.tag = _gen;
				}
			}
			// set up simulation parameters
			// this needs to be kept separate from the above initialization
			// to ensure all simulation items are created first
			if (mass != null) {
				for each (n in data.nodes) {
					p = n.props.particle;
					p.mass = mass(n);
				}
			}
			for each (e in data.edges) {
				if (e.props.$merged) {
					s = e.props.spring;
					if (restLength != null)
						s.restLength = restLength(e);
					if (tension != null)
						s.tension = tension(e);
					if (damping != null)
						s.damping = damping(e);
				}
			}
			// clean-up unused items
			for each (p in sim.particles)
				if (p.tag != _gen) p.kill();
			for each (s in sim.springs)
				if (s.tag != _gen) s.kill();
		}
	}
}