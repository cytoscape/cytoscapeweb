package org.cytoscapeweb.view.layout.ivis.layout.fd
{
import org.cytoscapeweb.view.layout.ivis.layout.LEdge;
import org.cytoscapeweb.view.layout.ivis.layout.LNode;


/**
 * This class implements common data and functionality for edges of all layout
 * styles that are force-directed.
 *
 * @author: Ugur Dogrusoz
 * 
 * Copyright: i-Vis Research Group, Bilkent University, 2007 - present
 */
public /*abstract*/ class FDLayoutEdge extends LEdge
{
// -----------------------------------------------------------------------------
// Section: Instance variables
// -----------------------------------------------------------------------------
	/**
	 * Desired length of this edge after layout
	 */
	public var idealLength:Number= FDLayoutConstants.DEFAULT_EDGE_LENGTH;

// -----------------------------------------------------------------------------
// Section: Constructors and initialization
// -----------------------------------------------------------------------------
	/*
	 * Constructor
	 */
	public function FDLayoutEdge(source:LNode,
		target:LNode,
		vEdge:*/*vEdge:Object*/)
	{
		super(source, target, vEdge);
	}
}
}