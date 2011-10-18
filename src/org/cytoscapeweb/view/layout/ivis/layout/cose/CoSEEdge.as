package org.cytoscapeweb.view.layout.ivis.layout.cose
{
	import org.cytoscapeweb.view.layout.ivis.layout.fd.FDLayoutEdge;


/**
 * This class implements CoSE specific data and functionality for edges.
 *
 * @author Erhan Giral
 * @author Ugur Dogrusoz
 * @author Cihan Kucukkececi
 *
 * Copyright: i-Vis Research Group, Bilkent University, 2007 - present
 */
public class CoSEEdge extends FDLayoutEdge
{
// -----------------------------------------------------------------------------
// Section: Instance variables
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// Section: Constructors and initializations
// -----------------------------------------------------------------------------
	/*
	 * Constructor
	 */
	public function CoSEEdge(source:CoSENode,
		target:CoSENode,
		vEdge:*/*vEdge:Object*/)
	{
		super(source, target, vEdge);
	}

// -----------------------------------------------------------------------------
// Section: Remaining methods
// -----------------------------------------------------------------------------
}
}