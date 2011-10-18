package org.cytoscapeweb.view.layout.ivis.layout.cose
{
	import org.cytoscapeweb.view.layout.ivis.layout.LGraph;
	import org.cytoscapeweb.view.layout.ivis.layout.LGraphManager;


/**
 * This class implements CoSE specific data and functionality for graphs.
 *
 * @author Erhan Giral
 * @author Ugur Dogrusoz
 * @author Cihan Kucukkececi
 *
 * Copyright: i-Vis Research Group, Bilkent University, 2007 - present
 */
public class CoSEGraph extends LGraph
{
// -----------------------------------------------------------------------------
// Section: Constructors and initialization
// -----------------------------------------------------------------------------
	/*
	 * Constructor
	 */
	public function CoSEGraph(parent:CoSENode,
		graphMgr:LGraphManager,
		vGraph:*/*vGraph:Object*/)
	{
		super(parent, graphMgr, vGraph);
	}

	// !!!Currently empty and useless class!!!
}
}