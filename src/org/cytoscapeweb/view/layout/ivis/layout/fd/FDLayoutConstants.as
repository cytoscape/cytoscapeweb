package org.cytoscapeweb.view.layout.ivis.layout.fd
{
/**
 * This class maintains the constants used by force-directed layouts.
 *
 * @author: Ugur Dogrusoz
 *
 * Copyright: i-Vis Research Group, Bilkent University, 2007 - present
 */
public class FDLayoutConstants
{
// -----------------------------------------------------------------------------
// Section: user options
// -----------------------------------------------------------------------------
	/*
	 * Options potentially exposed to the user 
	 */
	public static const DEFAULT_EDGE_LENGTH:int= 50;
	public static const DEFAULT_SPRING_STRENGTH:Number= 0.45;
	public static const DEFAULT_REPULSION_STRENGTH:Number= 4500.0;
	public static const DEFAULT_GRAVITY_STRENGTH:Number= 0.015;
	public static const DEFAULT_COMPOUND_GRAVITY_STRENGTH:Number= 5.0;
	public static const DEFAULT_GRAVITY_RANGE_FACTOR:Number= 2.0;
	public static const DEFAULT_COMPOUND_GRAVITY_RANGE_FACTOR:Number= 1.5;
	public static const DEFAULT_USE_SMART_REPULSION_RANGE_CALCULATION:Boolean= true;
	
// -----------------------------------------------------------------------------
// Section: remaining constants
// -----------------------------------------------------------------------------
	
	/*
	 * Maximum amount by which a node can be moved per iteration
	 */
	public static const MAX_NODE_DISPLACEMENT_INCREMENTAL:Number= 100.0;
	public static const MAX_NODE_DISPLACEMENT:Number= 
		MAX_NODE_DISPLACEMENT_INCREMENTAL * 3;

	/*
	 * Used to determine node pairs that are too close during repulsion calcs
	 */
	public static const MIN_REPULSION_DIST:Number= DEFAULT_EDGE_LENGTH / 10.0;

	/**
	 * Number of iterations that should be done in between convergence checks
	 */
	public static const CONVERGENCE_CHECK_PERIOD:int= 100;

	/**
	 * Ideal edge length coefficient per level for intergraph edges
	 */
	public static const PER_LEVEL_IDEAL_EDGE_LENGTH_FACTOR:Number= 0.1;

	/**
	 * Minimum legth of an edge
	 */
	public static const MIN_EDGE_LENGTH:int= 1;
	
	/**
	 * Number of iterations that should be done in between grid calculations
	 */
	public static const GRID_CALCULATION_CHECK_PERIOD:int= 10;
}
}