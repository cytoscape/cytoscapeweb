package org.cytoscapeweb.view.layout.ivis.layout
{
/**
 * This class maintains the constants used by the layout package.
 *
 * @author: Ugur Dogrusoz
 *
 * Copyright: i-Vis Research Group, Bilkent University, 2007 - present
 */
public class LayoutConstants
{
// -----------------------------------------------------------------------------
// Section: General user options
// -----------------------------------------------------------------------------
	/**
	 * Layout Quality
	 */
	public static const PROOF_QUALITY:int= 0;
	public static const DEFAULT_QUALITY:int= 1;
	public static const DRAFT_QUALITY:int= 2;

	/**
	 * Default parameters
	 */
	public static const DEFAULT_CREATE_BENDS_AS_NEEDED:Boolean= false;
	public static const DEFAULT_INCREMENTAL:Boolean= false;
	public static const DEFAULT_ANIMATION_ON_LAYOUT:Boolean= true;
	public static const DEFAULT_ANIMATION_DURING_LAYOUT:Boolean= false;
	public static const DEFAULT_ANIMATION_PERIOD:int= 50;
	public static const DEFAULT_UNIFORM_LEAF_NODE_SIZES:Boolean= false;

// -----------------------------------------------------------------------------
// Section: General other constants
// -----------------------------------------------------------------------------
	/*
	 * Margins of a graph to be applied on bouding rectangle of its contents. We
	 * assume margins on all four sides to be uniform.
	 */
	public static var GRAPH_MARGIN_SIZE:int= 10;

	/*
	 * The height of the label of a compound. We assume the label of a compound
	 * node is placed at the bottom with a dynamic width same as the compound
	 * itself.
	 */
	public static const LABEL_HEIGHT:int= 20;

	/*
	 * Additional margins that we maintain as safety buffer for node-node
	 * overlaps. Compound node labels as well as graph margins are handled
	 * separately!
	 */
	public static const COMPOUND_NODE_MARGIN:int= 5;

	/*
	 * Default dimension of a non-compound node.
	 */
	public static const SIMPLE_NODE_SIZE:int= 40;	

	/*
	 * Default dimension of a non-compound node.
	 */
	public static const SIMPLE_NODE_HALF_SIZE:int= SIMPLE_NODE_SIZE / 2;	

	/*
	 * Empty compound node size. When a compound node is empty, its both
	 * dimensions should be of this value.
	 */
	public static const EMPTY_COMPOUND_NODE_SIZE:int= 40;	

	/*
	 * Minimum length that an edge should take during layout
	 */
	public static const MIN_EDGE_LENGTH:int= 1;

	/*
	 * World boundaries that layout operates on
	 */
	public static const WORLD_BOUNDARY:int= 1000000;

	/*
	 * World boundaries that random positioning can be performed with
	 */
	public static const INITIAL_WORLD_BOUNDARY:int= WORLD_BOUNDARY / 1000;

	/*
	 * Coordinates of the world center
	 */
	public static const WORLD_CENTER_X:int= 1200;
	public static const WORLD_CENTER_Y:int= 900;
}
}