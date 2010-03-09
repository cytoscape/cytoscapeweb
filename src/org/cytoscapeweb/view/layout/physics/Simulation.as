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
package org.cytoscapeweb.view.layout.physics {
    import flare.physics.IForce;
    import flare.physics.Particle;
    import flare.physics.Simulation;
    import flare.physics.Spring;
    
    import org.cytoscapeweb.util.methods.$each;
    

    /**
     * This is the same Flare Simulation, slightly modified to avoid timeout exceptions 
     * on large graphs
     * 
     * @see flare.physics.Simulation
     */
    public class Simulation extends flare.physics.Simulation {

        // ========[ PROTECTED PROPERTIES ]=========================================================

        protected var forces:Array = []; // Only because the superclass property is private :-(

        // ========[ CONSTRUCTOR ]==================================================================

        public function Simulation(gx:Number=0, gy:Number=0, drag:Number=0.1, attraction:Number=-5) {
            super(gx, gy, drag, attraction);
            forces.push(gravityForce);
            forces.push(nbodyForce);
            forces.push(dragForce);
            forces.push(springForce);
        }
        
        // ========[ PUBLIC METHODS ]===============================================================
        
        /** @inheritDoc */
        override public function addForce(force:IForce):void {
            if (force != null) {
                super.addForce(force);
                forces.push(force);
            }
        }
        
        /** @inheritDoc */
        override public function tick(dt:Number=1):void {   
            var p:Particle, ax:Number, ay:Number;
            var dt1:Number = dt/2, dt2:Number = dt*dt/2;

            // remove springs connected to dead particles
            $each(springs, function(i:uint, s:Spring):void {
                if (s.die || s.p1.die || s.p2.die) {
                    s.p1.degree--;
                    s.p2.degree--;
                    reclaimSpring(s);
                    springs.splice(i, 1);
                }
            }, true);

            // remove springs connected to dead particles
            $each(springs, function(i:uint, s:Spring):void {
                if (s.die || s.p1.die || s.p2.die) {
                    s.p1.degree--;
                    s.p2.degree--;
                    reclaimSpring(s);
                    springs.splice(i, 1);
                }
            }, true);
        
            // update particles using Verlet integration
            $each(particles, function(i:uint, p:Particle):void {
                p.age += dt;
                if (p.die) { // remove dead particles
                    reclaimParticle(p);
                    particles.splice(i, 1);
                } else if (p.fixed) {
                    p.vx = p.vy = 0;
                } else {
                    ax = p.fx / p.mass; ay = p.fy / p.mass;
                    p.x  += p.vx*dt + ax*dt2;
                    p.y  += p.vy*dt + ay*dt2;
                    p._vx = p.vx + ax*dt1;
                    p._vy = p.vy + ay*dt1;
                }
            }, true);

            // evaluate the forces
            eval();
            
            // update particle velocities
            $each(particles, function(i:uint, p:Particle):void {
                if (!p.fixed) {
                    ax = dt1 / p.mass;
                    p.vx = p._vx + p.fx * ax;
                    p.vy = p._vy + p.fy * ax;
                }
            });
            
            // enfore bounds
            if (bounds) enforceBounds();
        }
        
        /** @inheritDoc */
        override public function eval():void {
            var i:uint, p:Particle, length:uint, finished:Boolean = false;
            var sim:flare.physics.Simulation = this;
            
            // reset forces
            $each(particles, function(i:uint, p:Particle):void {
                p.fx = p.fy = 0;
            });
            // collect forces
            $each(forces, function(i:uint, f:IForce):void {
                f.apply(sim);
            });
        }
        
        // ========[ PROTECTED METHODS ]============================================================

        protected function enforceBounds():void {
            var minX:Number = bounds.x;
            var maxX:Number = bounds.x + bounds.width;
            var minY:Number = bounds.y;
            var maxY:Number = bounds.y + bounds.height;
            
            $each(particles, function(i:uint, p:Particle):void {
                if (p.x < minX) {
                    p.x = minX; p.vx = 0;
                } else if (p.x > maxX) {
                    p.x = maxX; p.vx = 0;
                }
                if (p.y < minY) {
                    p.y = minY; p.vy = 0;
                }
                else if (p.y > maxY) {
                    p.y = maxY; p.vy = 0;
                }
            });
        }

    }
}