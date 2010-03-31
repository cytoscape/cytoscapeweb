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

var style = {
	global: {
	    backgroundColor: "#ffffdf"
	},
	nodes: {
		shape: "RECTANGLE",
		opacity: 0.75,
		size: { defaultValue: 12, continuousMapper: { attrName: "weight", minValue: 12, maxValue: 36 } },
		borderColor: "#333333",
		borderWidth: 4,
		selectionBorderColor: "#ff0000",
		selectionColor: "#ffff00",
		selectionLineWidth: 2,
		selectionGlowOpacity: 0,
		hoverGlowOpacity: 0
	},
	edges: {
		color: "#000066",
		width: { defaultValue: 1, continuousMapper: { attrName: "weight", minValue: 1, maxValue: 4 } },
		mergeWidth: { defaultValue: 1, continuousMapper: { attrName: "sum:weight", minValue: 1, maxValue: 4 } },
		opacity: 0.88
	}
};

function setCallbacks(vis) {
	vis.$callbacks = {};

	vis.addListener("zoom", function(evt) {
		vis.$callbacks["zoom"] = evt.value;
	});
	vis.addListener("layout", function(evt) {
		vis.$callbacks["layout"] = evt.layout;
	});
}

var fneighbRes = {
		cytoweb1: { roots: ["2","3"], neighbors: ["1"], edgesLength: 4, mergedEdgesLength: 2 },
		cytoweb2: { roots: ["a01","a03"], neighbors: ["a02","a05","a04"], edgesLength: 6, mergedEdgesLength: 3 }
};

// Filters:

function nfilter(n) {
	return n.data.weight > 0.03 && n.data.weight < 0.4;
}

function efilter(e) {
	return e.data.id % 2 === 0;
}

// Tests:

function runJSTests(vis) {
	test("Event Listeners", function() {
		ok(!vis.hasListener("nodes", "click"), "Does not have nodes::click listener yet");

		var onNodeClick1 = function (evt) { };
		var onNodeClick2 = function (evt) { };
		var onEdgeClick = function (evt) { };
		var onZoom1 = function (evt) { };
		var onZoom2 = function (evt) { };

		// Add listeners:
		ok(vis._listeners==null || vis._listeners.nodes.click.length===0, "nodes::click NOT added yet");
		var ret = vis.addListener("click", "nodes", onNodeClick1);
		ok(ret instanceof org.cytoscapeweb.Visualization, "addListener() returned the Viualization instance.");
		same(vis._listeners.nodes.click.length, 1, "nodes::click added");
		ok(vis.hasListener("click", "nodes"), "Has nodes::click");
		ok(!vis.hasListener("click", "edges"), "Has NO edges::click");
		ok(!vis.hasListener("mouseover", "nodes"), "Has NO nodes::mouseover");

		vis.addListener("click", "nodes", onNodeClick1);
		same(vis._listeners.nodes.click.length, 1, "nodes::click NOT added again");

		ok(vis._listeners.edges==null || vis._listeners.edges.click.length===0, "edges::click NOT added yet");
		vis.addListener("click", "edges", onEdgeClick);
		same(vis._listeners.edges.click.length, 1, "edges::click added");
		ok(vis.hasListener("click", "edges"), "Has edges::click");
		ok(vis.hasListener("click", "nodes"), "Still has nodes::click");

		vis.addListener("mouseOver", "edges", function (evt) { });
		vis.addListener("mouseOut", "edges", function (evt) { });
		ok(vis.hasListener("mouseover", "edges"), "Has edges::mouseOver");
		ok(vis.hasListener("mouseout", "edges"), "Has edges::mouseOut");

		vis.addListener("zoom", onZoom1);
		ok(vis.hasListener("zoom"), "none:zoom added");
		same(vis._listeners.none.zoom.length, 1, "Number of none:zoom");

		// Remove listener:
		ret = vis.removeListener("click", "edges", onEdgeClick);
		ok(ret instanceof org.cytoscapeweb.Visualization, "removeListener() returned the Viualization instance.");
		same(vis._listeners.edges.click.length, 0, "edges::click removed");
		vis.removeListener("zoom", onZoom1);
		same(vis._listeners.none.zoom.length, 0, "none:zoom removed");
		ok(!vis.hasListener("click", "edges"), "Has NO edges::click");
		ok(!vis.hasListener("zoom"), "Has NO none:zoom (A)");
		ok(!vis.hasListener("zoom", "none"), "Has NO none:zoom (B)");
		ok(vis.hasListener("click", "nodes"), "Still has nodes::click");
		ok(vis.hasListener("mouseover", "edges"), "Still has edges::mouseOver");
		ok(vis.hasListener("mouseout", "edges"), "Still has edges::mouseOut");

		vis.addListener("zoom", onZoom1);
		same(vis._listeners.nodes.click.length, 1, "Number of none:zoom");

		// Remove when more than one function for the same event:
		vis.addListener("click", "nodes", onNodeClick2);
		same(vis._listeners.nodes.click.length, 2, "Number of nodes::click");

		vis.removeListener("click", "nodes", onNodeClick1);
		same(vis._listeners.nodes.click.length, 1, "Number of nodes::click");

		vis.removeListener("click", "nodes", onNodeClick1);
		same(vis._listeners.nodes.click.length, 1, "Number of nodes::click");

		// Remove all functions from one listener (with group):
		vis.addListener("click", "nodes", onNodeClick1);
		vis.addListener("click", "nodes", onNodeClick2);
		same(vis._listeners.nodes.click.length, 2, "Number of nodes::click");
		vis.removeListener("click", "nodes");
		same(vis._listeners.nodes.click, undefined, "nodes::click removed (BOTH)");

		// Remove all functions from one listener (NO group):
		vis.addListener("zoom", onZoom1);
		vis.addListener("zoom", onZoom2);
		same(vis._listeners.none.zoom.length, 2, "Number of none:zoom");
		vis.removeListener("zoom");
		same(vis._listeners.none.zoom, undefined, "none:zoom removed (BOTH)");
	});
}

function runGraphTests(moduleName, vis, options) {
	setCallbacks(vis);
	module(moduleName);

	test("Initialization Parameters", function() {
        same(vis.panZoomControlVisible(), options.panZoomControlVisible, "Pan-zoom control visible?");
        same(vis.nodeLabelsVisible(),     options.nodeLabelsVisible,     "Node Labels visible?");
        same(vis.edgesMerged(),           options.edgesMerged,           "Edges merged?");
        same(vis.nodeTooltipsEnabled(),   options.nodeTooltipsEnabled,   "Node tooltips enabled?");
        same(vis.edgeTooltipsEnabled(),   options.edgeTooltipsEnabled,   "Edge tooltips enabled?");
    });

    test("Pan-Zoom Control", function() {
        vis.panZoomControlVisible(false);
        ok(!vis.panZoomControlVisible(), "Pan-zoom control should NOT be visible");
        vis.panZoomControlVisible(true);
        ok(vis.panZoomControlVisible(), "Pan-zoom control should be visible");

        vis.zoom(0.02322);
        same(Math.round(vis.$callbacks.zoom*10000)/10000, 0.0232, "Zoom out");
        same(Math.round(vis.zoom()*10000)/10000, 0.0232, "zoom() returns the correct value after zoom out.");
        vis.zoom(2.1);
        same(Math.round(vis.$callbacks.zoom*100)/100, 2.1, "Zoom in");
        same(Math.round(vis.zoom()*100)/100, 2.1, "zoom() returns the correct value after zoom in.");

        vis.panBy(100, 200);
        vis.zoomToFit();
        ok(vis.$callbacks.zoom <= 1, "Zoom to fit (value <= 1 ?):" + vis.$callbacks.zoom);
        same(vis.zoom(), vis.$callbacks.zoom, "zoom() returns the correct value after zoomToFit().");

        var zoom = vis.$callbacks.zoom;
        vis.panBy(320, 160);
        vis.panToCenter();
        same(vis.$callbacks.zoom, zoom, "Zoom value should NOT change after panning");
        same(vis.zoom(), zoom, "zoom() returns the correct value again.");
    });

    test("Tooltips", function() {
        vis.nodeTooltipsEnabled(false);
        ok(!vis.nodeTooltipsEnabled(), "Node tooltips should NOT be enabled");
        vis.nodeTooltipsEnabled(true);
        ok(vis.nodeTooltipsEnabled(), "Node tooltips should be enabled again");

        vis.edgeTooltipsEnabled(false);
        ok(!vis.edgeTooltipsEnabled(), "Edge tooltips should NOT be enabled");
        vis.edgeTooltipsEnabled(true);
        ok(vis.edgeTooltipsEnabled(), "Edge tooltips should be enabled again");
    });

    test("Labels", function() {
        vis.nodeLabelsVisible(false);
        ok(!vis.nodeLabelsVisible(), "Node Labels should NOT be visible");
        vis.nodeLabelsVisible(true);
        ok(vis.nodeLabelsVisible(), "Node Labels should be visible again");
        vis.edgeLabelsVisible(false);
        ok(!vis.edgeLabelsVisible(), "Edge Labels should NOT be visible");
        vis.edgeLabelsVisible(true);
        ok(vis.edgeLabelsVisible(), "Edge Labels should be visible again");

    });

    test("Nodes", function() {
        var nodes = vis.nodes();
        same(nodes.length, 5, "Number of nodes" );
    });

    test("Edges", function() {
    	vis.edgesMerged(false);
    	vis.edgesMerged(true);
        ok(vis.edgesMerged(), "Edges should be merged");
        vis.edgesMerged(false);
        ok(!vis.edgesMerged(), "Edges should NOT be merged");

    	// Must return only regular non-merged edges:
        var edges = vis.edges();
        same(edges.length, 7, "Number of edges" );
        $.each(edges, function(i, e) {
        	ok(!e.merged, "Edge ["+e.data.id+"] is NOT merged.");
        });
        // Must return only merged ones:
        var merged = vis.mergedEdges();
        $.each(merged, function(i, e) {
        	ok(e.merged, "Edge ["+e.data.id+"] is merged.");
        	var ee = e.edges;
        	ok(ee.length > 0, "Merged Edge ["+e.data.id+"] has regular edges.");
        	
        	$.each(ee, function(i, e) {
        		ok(!e.merged, "Regular Edge ["+e.data.id+"] is NOT merged.");
        	});
        });
    });
    
    asyncTest("Select Nodes by ID", function() {
    	expect(6);
    	var nodes = vis.nodes();
    	var sel = [nodes[0].data.id, nodes[1].data.id];
    	
    	vis.addListener("select", "nodes", function(evt) {
    		start();
    		vis.removeListener("select", "nodes");

    		same(evt.target.length, 2, "Number of selected nodes from callback");
            same(vis.selected("nodes").length, 2, "Number of selected nodes");

            for (var i=0; i < evt.target.length; i++) {
            	var n = evt.target[i];
            	ok(n.group === "nodes", "Selected element '"+n.data.id+"' is a node.");
            	ok(sel.contains(n.data.id), "Selected node '"+n.data.id+"' returned by callback");
            }
            vis.deselect("nodes"); // Always deselect all to avoid interfering with other tests!
        	stop();
    	});
    	
    	vis.select("nodes", sel);
    });
    
    asyncTest("Deselect Nodes by ID", function() {
    	expect(4);
    	var nodes = vis.nodes();
    	var sel = [nodes[0].data.id, nodes[1].data.id];
    	
    	vis.addListener("select", "nodes", function(evt) {
    		vis.removeListener("select", "nodes");
    		vis.deselect("nodes", [sel[0]]);
    	});
    	vis.addListener("deselect", "nodes", function(evt) {
    		start();
    		vis.removeListener("deselect", "nodes");
    		
            same(evt.target.length, 1, "Number of deselected nodes from callback");
            same(vis.selected("nodes").length, 1, "Number of selected nodes after deselecting one");
            same(evt.target[0].data.id, sel[0], "The deselected node is right");
            same(vis.selected("nodes")[0].data.id, sel[1], "The selected node is right");

    		vis.deselect("nodes"); // Always deselect all to avoid interfering with other tests!
    		stop();
    	});
    	
    	vis.select("nodes", sel);
    });
    
    asyncTest("Select Edges by ID and Object", function() {
    	expect(4);
    	var edges = vis.edges();
    	var sel = [edges[0].data.id, edges[1], edges[2].data.id];
    	
    	// This one should not be selected twice:
    	vis.select("edges", [sel[0]]);
    	
    	vis.addListener("select", "edges", function(evt) {
    		start();
    		vis.removeListener("select", "edges");

    		// One edge is already selected, so it shoul return only 2 new selected edges:
    		same(evt.target.length, 2, "Number of new selected edges from callback");
            same(vis.selected("edges").length, 3, "Total number of selected edges");

            for (var i=0; i < evt.target.length; i++) {
            	var e = evt.target[i];
            	ok(e.group === "edges", "Selected element '"+e.data.id+"' is an edge.");
            }
            vis.deselect("edges"); // Always deselect all to avoid interfering with other tests!
        	stop();
    	});
    	
    	vis.select("edges", sel);
    });
    
    asyncTest("Deselect Edges by Object", function() {
    	expect(3);
    	var edges = vis.edges();
    	var sel = [edges[0].data.id, edges[1], edges[2].data.id];
    	
    	vis.addListener("select", "edges", function(evt) {
    		vis.removeListener("select", "edges");
    		vis.deselect("edges", [sel[0], sel[2]]);
    	});
    	vis.addListener("deselect", "edges", function(evt) {
    		start();
    		vis.removeListener("deselect", "edges");
    		
            same(evt.target.length, 2, "Number of deselected edges from callback");
            same(vis.selected("edges").length, 1, "Number of selected edges after deselecting two");
            same(vis.selected("edges")[0].data.id, sel[1].data.id, "The selected edge is right");

    		vis.deselect("edges"); // Always deselect all to avoid interfering with other tests!
    		stop();
    	});
    	
    	vis.select("edges", sel);
    });
    
    asyncTest("Select some nodes and edges altogether", function() {
        expect(9);
    	var nodes = vis.nodes();
        var edges = vis.edges();
        var sel = [edges[0], nodes[1], edges[2]];
        var tested = 0;
        start();

        // Should call all the following listeners:
        vis.addListener("select", "nodes", function(evt) {
    		vis.removeListener("select", "nodes");

    		same(evt.target.length, 1, "Number of selected nodes from callback");
            same(vis.selected("nodes").length, 1, "Number of selected nodes");

        	var n = evt.target[0];
        	ok(n.group === "nodes", "Selected element '"+n.data.id+"' is a node.");
        	same(n.data.id, nodes[1].data.id, "Selected node is correct");
        	
        	tested++;
            if (tested === 3) { stop(); vis.deselect(); }
    	});
        vis.addListener("select", "edges", function(evt) {
        	vis.removeListener("select", "edges");
        	
        	same(evt.target.length, 2, "Number of selected edges from callback");
        	same(vis.selected("edges").length, 2, "Number of selected edges");
        	
        	for (var i=0; i < evt.target.length; i++) {
            	var e = evt.target[i];
            	ok(e.group === "edges", "Selected element '"+e.data.id+"' is an edge.");
        	}
        	
        	tested++;
            if (tested === 3) { stop(); vis.deselect(); }
        });
        vis.addListener("select", function(evt) {
        	vis.removeListener("select");
        	
        	same(evt.target.length, 3, "Number of selected items from callback");

        	tested++;
            if (tested === 3) { stop(); vis.deselect(); }
        });
    	
    	vis.select(sel);
    });
    
    test("Select: ignore invalid", function() {
    	vis.addListener("select", "nodes", function(evt) {
    		ok(false, "This assertion should not run!");
    	});
    	vis.select([]);
    	vis.select(["423432432", "abcdef", "", null, undefined]);
    	vis.select("invalid", []);
    	//vis.select("invalid"); // TODO: should it default to "none" or be ignored?
    	same(vis.selected().length, 0, "No element was selected");
    	vis.removeListener("select", "nodes");
    });
    
    asyncTest("Select All Nodes", function() {
    	expect(2);
    	var nodes = vis.nodes();
    	vis.addListener("select", "nodes", function(evt) {
    		start();
    		vis.removeListener("deselect", "nodes");
    		same(evt.target.length, nodes.length, "Number of selected nodes from callback");
    		same(vis.selected("nodes").length, nodes.length, "Number of selected nodes");
    		vis.deselect("nodes"); // Always deselect all to avoid interfering with other tests!
    		stop();
    	});
    	vis.select("nodes");
    });
    
    asyncTest("Deselect All Nodes", function() {
    	expect(2);
    	var nodes = vis.nodes();
    	vis.addListener("select", "nodes", function(evt) {
    		vis.removeListener("select", "nodes");
    		vis.deselect("nodes");
    	});
    	vis.addListener("deselect", "nodes", function(evt) {
    		start();
    		vis.removeListener("deselect", "nodes");
        	same(evt.target.length, nodes.length, "Deselected nodes returned by callback");
        	same(vis.selected("nodes").length, 0, "Number of selected nodes after deselect");
    		stop();
    	});
    	vis.select("nodes");
    });
    
    asyncTest("Select All Edges", function() {
    	expect(2);
    	var edges = vis.edges();
    	vis.addListener("select", "edges", function(evt) {
    		start();
    		vis.removeListener("select", "edges");
    		same(evt.target.length, edges.length, "Number of selected edges from callback");
    		same(vis.selected("edges").length, edges.length, "Number of selected edges");
    		vis.deselect("edges"); // Always deselect all to avoid interfering with other tests!
    		stop();
    	});
    	vis.select("edges");
    });
    
    asyncTest("Deselect All Edges", function() {
    	expect(2);
    	var edges = vis.edges();
    	vis.addListener("select", "edges", function(evt) {
    		vis.removeListener("select", "edges");
    		vis.deselect("edges");
    	});
    	vis.addListener("deselect", "edges", function(evt) {
    		start();
    		vis.removeListener("deselect", "edges");
    		same(evt.target.length, edges.length, "Deselected edges returned by callback");
    		same(vis.selected("edges").length, 0, "Number of selected edges after deselect");
    		stop();
    	});
    	vis.select("edges");
    });
	
	// TODO: select merged edges
	// TODO: select regular edges when they are merged and vice-versa
	// TODO: select filtered edges when they are merged and when they aren't
    
    asyncTest("Visual Style", function() {
        expect(14);
    	vis.addListener("visualstyle", function(evt) {
        	start();
        	vis.removeListener("visualstyle");
        	var s = evt.value;
        	same(s.global.backgroundColor, style.global.backgroundColor);
        	same(s.nodes.shape, style.nodes.shape);
        	same(s.nodes.opacity, style.nodes.opacity);
        	same(s.nodes.borderColor, style.nodes.borderColor);
        	same(s.nodes.size.defaultValue, style.nodes.size.defaultValue);
        	same(s.nodes.size.continuousMapper.attrName, style.nodes.size.continuousMapper.attrName);
        	same(s.nodes.size.continuousMapper.minValue, style.nodes.size.continuousMapper.minValue);
        	same(s.nodes.size.continuousMapper.maxValue, style.nodes.size.continuousMapper.maxValue);
        	same(s.edges.color, style.edges.color);
        	same(s.edges.opacity, style.edges.opacity);
        	same(s.edges.width.defaultValue, style.edges.width.defaultValue);
        	same(s.edges.width.continuousMapper.attrName, style.edges.width.continuousMapper.attrName);
        	same(s.edges.width.continuousMapper.minValue, style.edges.width.continuousMapper.minValue);
        	same(s.edges.width.continuousMapper.maxValue, style.edges.width.continuousMapper.maxValue);
        	stop();
        });
    	
    	vis.visualStyle(style);
    });
    
    asyncTest("Set Visual Style Bypass", function() {
    	var bypass = { nodes: {}, edges: {} };
    	var id;
    	var nodes = vis.nodes();
    	var edges = vis.edges();
    	
    	expect(4 * (nodes.length + edges.length));
    	
    	var nodeOpacity = function(id) { return (id % 2 === 0 ? 0.9 : 0.1); };
    	var edgeOpacity = function(id) { return (id % 2 === 0 ? 0.5 : 0); };
    	var nodeColor = "#345678";
    	var edgeWidth = 4;

		$.each(nodes, function(i, n) {
			var o = nodeOpacity(n.data.id);
			bypass.nodes[n.data.id] = { opacity: o, color: nodeColor };
	    });
		$.each(edges, function(i, e) {
			var o = edgeOpacity(e.data.id);
			bypass.edges[e.data.id] = { opacity: o, width: edgeWidth };
		});
		
    	vis.addListener("visualstyle", function(evt) {
    		start();
    		vis.removeListener("visualstyle");
    		var bp = evt.value;
    		
    		nodes = vis.nodes();
    		edges = vis.edges();
    		
    		$.each(nodes, function(i, n) {
    			var expected = nodeOpacity(n.data.id);
    			same(bp.nodes[n.data.id].opacity, expected);
    			same(Math.round(n.opacity*100)/100, expected);
    			
    			same(bp.nodes[n.data.id].color, nodeColor);
    			same(n.color, nodeColor);
    	    });
    		$.each(edges, function(i, e) {
    			var expected = edgeOpacity(e.data.id);
    			same(bp.edges[e.data.id].opacity, expected);
    			same(Math.round(e.opacity*100)/100, expected);
    			
    			same(bp.edges[e.data.id].width, edgeWidth);
    			same(e.width, edgeWidth);
    		});
    		stop();
    	});
    	
    	vis.visualStyleBypass(bypass);
    });
    
    asyncTest("Remove Visual Style Bypass", function() {
    	expect(4);
    	
    	vis.addListener("visualstyle", function(evt) {
    		start();
    		vis.removeListener("visualstyle");
    		var bp = evt.value;
    		
    		ok(bp.nodes != null, "bypass.nodes is NOT null");
    		ok(bp.edges != null, "bypass.edges is NOT null");
    		
    		var count = 0;
    		for (var k in bp.nodes) { count++; }
    		ok(count === 0, "No more nodes bypass props");
    		
    		var count = 0;
    		for (var k in bp.edges) { count++; }
    		ok(count === 0, "No more edges bypass props");
    		
    		stop();
    	});
    	
    	vis.visualStyleBypass(null);
    });
    
    asyncTest("Layout", function() {
    	expect(2);
    	vis.addListener("layout", function(evt) {
			start();
			same("Tree", evt.value, "evt.value layout");
			same("Tree", vis.layout(), "layout()");
			stop();
			
			vis.removeListener("layout");
    	});
    	
    	vis.layout('  TREE '); // It should trim and be case insensitive!
    });
    
    test("Filter", function() {
    	// Before filtering:
    	var nlookup = { /*id=>node*/ }, elookup = { /*id=>edge*/ };
    	// Filtered in elements maps:
    	var inNodes = { /*id=>node*/ }, inEdges = { /*id=>edge*/ };
    	// Array of filtered elements:
    	var feList, fnList, fAllList;
    	// Counter for nodes/edges:
    	var ce = 0, cn = 0;
    	
    	// Create nodes and edges map:
    	var nodes = vis.nodes();
    	$.each(nodes, function(i, n) {
    		nlookup[n.data.id] = n;
    	});
    	var edges = vis.edges();
    	$.each(edges, function(i, e) {
    		elookup[e.data.id] = e;
    	});
    	
    	//Add Listeners:
    	vis.addListener("filter", "edges", function(evt) {
    		feList = evt.target;
    	});
    	vis.addListener("filter", "nodes", function(evt) {
    		fnList = evt.target;
    	});
    	vis.addListener("filter", function(evt) {
    		fAllList = evt.target;
    	});
    	
    	// --- FILTER BY GROUP ---
    	
    	// EDGES:
    	// Filter:
    	vis.filter("edges", function(e){
    		same(e.group, "edges", "Filtering edge '"+e.data.id+"'");
    		ce++;
    		return efilter(e);
    	});
    	// Check:
    	edges = vis.edges();
    	same(ce, edges.length, "Filter function received all edges");
    	same(feList.length, Math.floor(edges.length/2), "Filtered correct number of edges");
    	// Listeners for "edges" & "none" should get the same results:
    	$.each([feList, fAllList], function(i, filtered) {
	    	$.each(filtered, function(j, e) {
	    		inEdges[e.data.id] = e;
	    		same(e.group, "edges", "Filtered group for '"+e.data.id+"' ("+j+")");
	    		ok(e.data.id % 2 === 0, "Edge '"+e.data.id+"' correctly filtered ("+j+")");
	    		ok(e.visible, "Filtered edge '"+e.data.id+"' is visible ("+j+")");
	    		// When updateVisualMappers == false:
	    		same(e.width, elookup[e.data.id].width, "The edge width should not change ("+e.data.id+")");
	    	});
    	});
    	same(fnList, undefined, "Listener for 'nodes' was not called when filtering edges");
    	$.each(edges, function(i, e) {
    		if (!inEdges[e.data.id]) {
    			ok(!e.visible, "Filtered-out edge '"+e.data.id+"' is INVISIBLE");
    		}
    	});
    	
    	// TODO: what happens when filtering merged edges?
    	
    	// NODES:
    	// Filter:
    	vis.filter("nodes", function(n){
    		same(n.group, "nodes", "Filtering node '"+n.data.id+"'");
    		cn++;
    		return nfilter(n);
    	});
    	// Check:
    	nodes = vis.nodes();
    	same(cn, nodes.length, "Filter function received all nodes");
    	same(fnList.length, 3, "Filtered correct number of nodes");
    	// Listeners for "nodes" & "none" should get the same results:
    	$.each([fnList, fAllList], function(i, filtered) {
	    	$.each(fnList, function(j, n) {
	    		inNodes[n.data.id] = n;
	    		same(n.group, "nodes", "Filtered group for '"+n.data.id+"' ("+j+")");
	    		ok(n.data.weight > 0.03 && n.data.weight < 0.4, "Node '"+n.data.id+"' correctly filtered ("+j+")");
	    		ok(n.visible, "Filtered node '"+n.data.id+"' is visible ("+j+")");
	    		// When updateVisualMappers == false:
	    		same(n.size, nlookup[n.data.id].size, "The node size should not change ("+n.data.id+")");
	    	});
    	});
    	$.each(nodes, function(i, n) {
    		if (!inNodes[n.data.id]) {
    			ok(!n.visible, "Filtered-out node '"+n.data.id+"' is INVISIBLE");
    		}
    	});
    	// Edges from filtered-out nodes must be invisible, too:
    	edges = vis.edges();
    	$.each(edges, function(i, e) {
    		if (!inNodes[e.data.source] || !inNodes[e.data.target]) {
    			ok(!e.visible, "Edge '"+e.data.id+"' from filtered-out node is INVISIBLE, too");
    		}
    	});

    	// --- REMOVE FILTER ---
    	
    	// EDGES:
    	vis.removeFilter("edges");
    	same(feList, null, "Edge Filter removed");
    	edges = vis.edges();
    	$.each(edges, function(i, e) {
    		if (!inNodes[e.data.source] || !inNodes[e.data.target]) {
    			ok(!e.visible, "Edge '"+e.data.id+"' from filtered-out node is still INVISIBLE after edge filter is removed");
    		} else {
    			ok(e.visible, "Edge '"+e.data.id+"' from filtered-in node is visible after edge filter is removed");
    		}
    	});
    	
    	// NODES:
    	vis.removeFilter("nodes");
    	same(fnList, null, "Node Filter removed");
    	nodes = vis.nodes();
    	$.each(nodes, function(i, n) {
    		ok(n.visible, "Node '"+n.data.id+"' is visible");
    	});
    	edges = vis.edges();
    	$.each(edges, function(i, e) {
    		ok(e.visible, "Edge '"+e.data.id+"' is visible");
    	});
    	
    	// --- FILTER NODES/EDGES altogether ---

    	ce = 0;
    	cn = 0;
    	vis.filter(function(item){
    		if (item.group === 'edges') { ce++; } else if (item.group === 'nodes') { cn++; }
    		return efilter(item);
    	});
    	same(cn, nodes.length, "Filter function received all nodes (filter by 'none')");
    	same(ce, edges.length, "Filter function received all edges (filter by 'none')");
    	nodes = vis.nodes();
    	edges = vis.edges();
    	same(fnList.length, Math.floor(nodes.length/2), "Listener for 'nodes' still working when filtering by 'none'");
    	same(feList.length, Math.floor(edges.length/2), "Listener for 'edges' still working when filtering by 'none'");
    	same(fAllList.length, Math.floor(nodes.length/2)+Math.floor(edges.length/2), "Filtered correct number of nodes and edges with 'none'");
    	
    	// --- REMOVE FILTER AGAIN ---
    	vis.removeFilter();
    	same(fnList, null, "Return of listener for 'nodes' after removing filter by 'none'");
    	same(feList, null, "Return of listener for 'edges' after removing filter by 'none'");
    	same(fAllList, null, "Return of listener for 'none' after removing filter by 'none'");
    });
    
    asyncTest("Filter nodes and update mappers automatically", function() {
    	expect(2);
    	
    	vis.addListener("filter", "nodes", function(evt) {
        	start();
        	vis.removeListener("filter", "nodes");

        	var maxVal = -1, minVal = 999999;
        	var larger, smaller;

	    	$.each(evt.target, function(i, n) {
	    		var size = n.size - n.borderWidth;
	    		if (size > maxVal) {
	    			larger = n;
	    			maxVal = size;
	    		} else if (size < minVal) {
	    			smaller = n;
	    			minVal = size;
	    		}
	    	});

        	same(minVal, style.nodes.size.continuousMapper.minValue, "The node "+smaller.data.id+" should be smaller now");
	    	same(maxVal, style.nodes.size.continuousMapper.maxValue, "The node "+larger.data.id+" should be bigger now");
	    	
	    	vis.removeFilter("nodes");
	    	stop();
        });
        
        // Filter nodes and ask to update mappers:
        vis.filter("nodes", nfilter, true);
    });
    
    test("PNG", function() {
    	vis.zoom(Math.random()*2);
    	vis.panBy(Math.random()*-1000, Math.random()*1000);
    	
    	var base64 = vis.png();
    	ok(typeof base64 === 'string', "PNG returned as string");
    	ok(base64.length > 0, "PNG string not empty");
    	$("#image_"+vis.containerId).html('<img src="data:image/png;base64,'+base64+'"/>');
    	
		// Visual test of node coordinates - align divs with nodes:
		// --------------------------------------------------------
    	vis.addListener("zoom", function(evt) {
			var nodes = vis.nodes();
			$.each(nodes, function(i, n) {
				var pointer = $('<div class="pointer"></div>');
				$("body").append(pointer);
				
				var p = $("#"+vis.containerId).coordinates();
				var scale = vis.zoom();
				var size = n.size * scale;
				p.x += n.x;
				p.y += n.y;
				pointer.css('left', p.x - size/2).css('top', p.y - size/2);
				pointer.css('width', size).css('height', size);
			});
    	});
    	vis.zoomToFit();
    	vis.removeListener("zoom");
		// --------------------------------------------------------
    });
    
    test("PDF", function() {
    	var base64 = vis.pdf();
    	ok(typeof base64 === 'string', "PDF returned as string");
    	ok(base64.length > 0, "PDF string not empty");
    });
    
    test("SIF", function() {
    	var sif = vis.sif();
    	var edges = vis.edges();
    	$.each(edges, function(i, e) {
    		var inter = e.data.interaction ? e.data.interaction : e.data.id;
    		var line = e.data.source + "\t" + inter + "\t" + e.data.target; 
    		ok(sif.indexOf(line) > -1, "SIF text should have the line: '"+line+"'");
    	});
    	// Now replace the default interaction field:
    	var sif = vis.sif("type");
    	var edges = vis.edges();
    	$.each(edges, function(i, e) {
    		var line = e.data.source + "\t" + e.data.type + "\t" + e.data.target; 
    		ok(sif.indexOf(line) > -1, "SIF text should have the line: '"+line+"'");
    	});
    });
    
    // TODO: test graphml(), xgmml()
    // TODO: test selection styles
    // TODO: text context menu methods
}

//#################################################################################
// Get the XY coordinates of any DOM element
//#################################################################################
jQuery.fn.coordinates = function() {
	var left = 0;
	var top = 0;
	var obj = this;
	if (obj.offsetParent) {
		do {
			left = left + obj.attr('offsetLeft');
			top = top + obj.attr('offsetTop');
			obj = obj.offsetParent();
		} while (obj.attr('tagName') != 'BODY');
	}
	return { x: left, y: top };
}

//#################################################################################
//To allow Internet Explorer and older browsers to use Array.indexOf()
//#################################################################################
//This prototype is provided by the Mozilla foundation and
//is distributed under the MIT license.
//http://www.ibiblio.org/pub/Linux/LICENSES/mit.license
if (!Array.prototype.indexOf) {
	Array.prototype.indexOf = function(elt /*, from*/) {
		var len = this.length;
		var from = Number(arguments[1]) || 0;
		from = (from < 0) ? Math.ceil(from) : Math.floor(from);
		if (from < 0) from += len;
	  	for (; from < len; from++) {
	  		if (from in this && this[from] === elt) return from;
	  	}
	  	return -1;
	};
}
if (!Array.prototype.contains) {
	Array.prototype.contains = function(elt) {
	  	return this.indexOf(elt) != -1;
	};
}
//#################################################################################