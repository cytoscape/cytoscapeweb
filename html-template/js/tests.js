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
		size: { defaultValue: 12, continuousMapper: { attrName: "weight", minValue: 12, maxValue: 48 } },
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

var fneighbRes = {
		cytoweb1: { roots: ["2","3"], neighbors: ["1"], edgesLength: 4, mergedEdgesLength: 2 },
		cytoweb2: { roots: ["a01","a03"], neighbors: ["a02","a05","a04"], edgesLength: 6, mergedEdgesLength: 3 }
};

// Filters:

function nfilter(n) {
	return n.data.weight > 0.03 && n.data.weight < 0.4;
}

function efilter(e) {
	return Number(e.data.id.replace("e","")) % 2 === 0;
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
	module(moduleName);

	var _errId;
    var _onError = function(evt) {
    	_errId = evt.value.id;
    }
    vis.addListener("error", _onError);
	
	test("Initialization Parameters", function() {
        same(vis.panZoomControlVisible(), options.panZoomControlVisible, "Pan-zoom control visible?");
        same(vis.nodeLabelsVisible(),     options.nodeLabelsVisible,     "Node Labels visible?");
        same(vis.edgesMerged(),           options.edgesMerged,           "Edges merged?");
        same(vis.nodeTooltipsEnabled(),   options.nodeTooltipsEnabled,   "Node tooltips enabled?");
        same(vis.edgeTooltipsEnabled(),   options.edgeTooltipsEnabled,   "Edge tooltips enabled?");
    });
	
	test("Custom Cursors", function() {
		ok(vis.customCursorsEnabled() === true, "Custom cursors enabled by default");
		vis.customCursorsEnabled(false);
		ok(vis.customCursorsEnabled() === false, "Custom cursors disabled");
		vis.customCursorsEnabled(true);
		ok(vis.customCursorsEnabled() === true, "Custom cursors enabled again");
	});

    test("Pan-Zoom Control", function() {
        vis.panZoomControlVisible(false);
        ok(!vis.panZoomControlVisible(), "Pan-zoom control should NOT be visible");
        vis.panZoomControlVisible(true);
        ok(vis.panZoomControlVisible(), "Pan-zoom control should be visible");

        var callbackZoom = -1;
        vis.addListener("zoom", function(evt) {
        	callbackZoom = evt.value;
    	});
        
        vis.zoom(0.02322);
        same(Math.round(callbackZoom*10000)/10000, 0.0232, "Zoom out");
        same(Math.round(vis.zoom()*10000)/10000, 0.0232, "zoom() returns the correct value after zoom out.");
        vis.zoom(2.1);
        same(Math.round(callbackZoom*100)/100, 2.1, "Zoom in");
        same(Math.round(vis.zoom()*100)/100, 2.1, "zoom() returns the correct value after zoom in.");

        vis.panBy(100, 200);
        vis.zoomToFit();
        ok(callbackZoom <= 1, "Zoom to fit (value <= 1 ?):" + callbackZoom);
        same(vis.zoom(), callbackZoom, "zoom() returns the correct value after zoomToFit().");

        var zoom = callbackZoom;
        vis.panBy(320, 160);
        vis.panToCenter();
        same(callbackZoom, zoom, "Zoom value should NOT change after panning");
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
    
    test("Get Node by ID", function() {
        var expected = vis.nodes()[2];
        var n = vis.node(expected.data.id);
        ok(n != null, "Node not null");
        same(n, expected, "Got correct node");
        same(vis.node("_none_"), null, "Inexistent node");
    });
    
    test("Get Edge by ID", function() {
    	// Regular edge:
    	var expected = vis.edges()[3];
    	var e = vis.edge(expected.data.id);
    	ok (e != null, "Edge not null");
    	same(e, expected, "Got correct edge");
    	same(vis.edge("_none_"), null, "Inexistent edge");
    	// Merged edge:
    	expected = vis.mergedEdges()[2];
    	e = vis.edge(expected.data.id);
    	ok(e != null, "Merged edge not null");
    	same(e, expected, "Got correct merged edge");
    });
    
    asyncTest("Select Nodes by ID", function() {
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
    
    test("Visual Style", function() {
		vis.visualStyle(style);
    	var nodes = vis.nodes(), edges = vis.edges();
    	var s = vis.visualStyle();
    	
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

    	$.each(nodes, function(i, n) {
    		if (n.nodesCount == 0) { // ignore compound nodes
    			same(Math.round(n.opacity*100)/100, s.nodes.opacity, "Node opacity");
    			same(n.borderColor, s.nodes.borderColor, "Node borderColor");
    		}
	    });
		$.each(edges, function(i, e) {
			same(Math.round(e.opacity*100)/100, s.edges.opacity, "Edge opacity");
			same(e.color, s.edges.color, "Edge color");
		});

    });
    
    test("Visual Style--transparent nodes", function() {
    	vis.visualStyle({ 
    		global: { backgroundColor: "transparent" },
    		nodes: { color: "transparent", compoundColor: "transparent" },
    		edges: { color: "transparent" }
    	});
    	same(vis.visualStyle().global.backgroundColor, "#ffffff", "Visual Style backgroundColor color");
    	same(vis.visualStyle().nodes.color, "transparent", "Visual Style nodes color");
    	same(vis.visualStyle().edges.color, "#ffffff", "Visual Style edges color");
    	
    	var nodes = vis.nodes(), edges = vis.edges();
    	
    	$.each(nodes, function(i, n) {
    		same(n.color, "transparent", "Node color");
    	});
    	$.each(edges, function(i, e) {
    		same(e.color, "#ffffff", "Edge color");
    	});
    	
    	vis.visualStyle(style);
    });
    
    test("Get empty Visual Style Bypass", function() {
    	var bypass = vis.visualStyleBypass();
    	ok(bypass.nodes != null);
    	ok(bypass.edges != null);

    	var fail = false;
    	try {
    		for (k in bypass.nodes) throw("Bypass.nodes should be empty!");
    		for (k in bypass.edges) throw("Bypass.edges should be empty!");
    	} catch (err) { fail = true; }
    	ok(fail === false, "bypass[nodes|edges] should be empty");
    });
    
    test("Set Visual Style Bypass", function() {
    	var bypass = { nodes: {}, edges: {} };
    	var id;
    	var nodes = vis.nodes();
    	var edges = vis.edges();
    	
    	var nodeOpacity = function(id) { return (id % 2 === 0 ? 0.9 : 0.1); };
    	var edgeOpacity = function(id) { return (id % 2 === 0 ? 0.5 : 0); };
    	var nodeColor = "#345678";
    	var edgeWidth = 4;
    	
    	$.each(nodes, function(i, n) {
    		var o = nodeOpacity(n.data.id);
    		if (n.nodesCount > 0) {
    			bypass.nodes[n.data.id] = { compoundOpacity: o, compoundColor: nodeColor };
    		} else {
    			bypass.nodes[n.data.id] = { opacity: o, color: nodeColor };
    		}
    	});
    	$.each(edges, function(i, e) {
    		var o = edgeOpacity(e.data.id);
    		bypass.edges[e.data.id] = { opacity: o, width: edgeWidth };
    	});
    	
    	// Just to test special characters as part of ID's:
    	// Note: Any UNICODE character except " or \ or control character
    	bypass.nodes["_=5.@1/4-4+9,0;'3:a?*&^%$#!`~<>{}[]"] = { color: "#000000" };
    	vis.visualStyleBypass(bypass);

    	var bp = vis.visualStyleBypass();
    	same (bp, bypass);
    	
    	nodes = vis.nodes();
    	edges = vis.edges();
    	
    	$.each(nodes, function(i, n) {
    		var expected = nodeOpacity(n.data.id);
    		same(Math.round(n.opacity*100)/100, expected);
    		same(n.color, nodeColor);
    		var opacityAttr = n.nodesCount > 0 ? "compoundOpacity" : "opacity";
    		same(bp.nodes[n.data.id][opacityAttr], expected);
    		var colorAttr = n.nodesCount > 0 ? "compoundColor" : "color";
    		same(bp.nodes[n.data.id][colorAttr], nodeColor);
    	});
    	$.each(edges, function(i, e) {
    		var expected = edgeOpacity(e.data.id);
    		same(bp.edges[e.data.id].opacity, expected);
    		same(Math.round(e.opacity*100)/100, expected);
    		
    		same(bp.edges[e.data.id].width, edgeWidth);
    		same(e.width, edgeWidth);
    	});
    });
    
    test("Remove Visual Style Bypass", function() {
    	vis.visualStyleBypass(null);	
    	var bp = vis.visualStyleBypass();
    		
		ok(bp.nodes != null, "bypass.nodes is NOT null");
		ok(bp.edges != null, "bypass.edges is NOT null");
		
		var count = 0;
		for (var k in bp.nodes) { count++; }
		ok(count === 0, "No more nodes bypass props");
		
		var count = 0;
		for (var k in bp.edges) { count++; }
		ok(count === 0, "No more edges bypass props");
    });
    
    test("Bypass--transparent nodes", function() {
    	var n = vis.nodes()[0];
    	var e = vis.edges()[0];
    	var bypass = { nodes: {}, edges: {} };
    	bypass.nodes[n.data.id] = { color: "transparent" };
    	bypass.edges[e.data.id] = { color: "transparent" }; // should be converted to white!
    	
    	vis.visualStyleBypass(bypass);
    	
    	same(vis.visualStyleBypass().nodes[n.data.id].color, "transparent", "Visual Style nodes color");
    	same(vis.visualStyleBypass().edges[e.data.id].color, "#ffffff", "Visual Style edges color");
    	same(vis.node(n.data.id).color, "transparent", "Node color");
    	same(vis.edge(e.data.id).color, "#ffffff", "Edge color");
    	
    	vis.visualStyleBypass({});
    });
    
    asyncTest("Preset Layout", function() {
    	expect(4);
    	var points = [ { id: "1", x: 10, y: -20 },
    	               { id: "2", x: 100, y: 120 },
    	               { id: "3", x: -33, y: 20 },
    	               { id: "4", x: 10, y: -20 },
    	               { id: "5", x: 0, y: 0 } ]
    	
    	vis.addListener("layout", function(evt) {
			start();
			var elay = evt.value;
			var lay = vis.layout();
			var opt = lay.options;

			same(lay.name, "Preset", "layout name");
			same(opt.points, points, "points");
			same(opt.fitToScreen, false, "fitToScreen");
			same(elay, lay, "evt.value and layout() are the same objects");
			stop();
			
			vis.removeListener("layout");
    	});
    	
    	vis.layout({ name: 'preset', options: { points: points, fitToScreen: false } });
    });
    
    asyncTest("Layout", function() {
    	expect(6);
    	vis.addListener("layout", function(evt) {
    		start();
    		var elay = evt.value;
    		var lay = vis.layout();
    		var opt = lay.options;
    		
    		same(lay.name, "Tree", "layout name");
    		same(opt.orientation, "topToBottom", "orientation");
    		ok(opt.depthSpace > 0, "depthSpace > 0");
    		ok(opt.breadthSpace > 0, "breadthSpace > 0");
    		ok(opt.subtreeSpace > 0, "subtreeSpace > 0");
    		
    		same(elay, lay, "evt.value and layout() are the same objects");
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
	    		ok(efilter(e), "Edge '"+e.data.id+"' correctly filtered ("+j+")");
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
    	
    	// TODO: test filtering merged edges?
    	
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
	    	$.each(filtered, function(j, n) {
	    		n = vis.node(n.data.id);
	    		inNodes[n.data.id] = n;
	    		same(n.group, "nodes", "Filtered group for '"+n.data.id+"' ("+j+")");
	    		ok(n.data.weight > 0.03 && n.data.weight < 0.4, "Node '"+n.data.id+"' correctly filtered ("+j+")");
	    		ok(n.visible, "Filtered node '"+n.data.id+"' is visible ("+j+")");
	    		// When updateVisualMappers == false:
	    		if (n.nodesCount == 0) { // ignore compound nodes
	    			same(n.size, nlookup[n.data.id].size, "The node size should not change ("+n.data.id+")");
	    		}
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
    
    var isCompoundGraph = vis.parentNodes().length > 0;
    
    if (!isCompoundGraph) { // continuous mapper for node size is hard to test because parent nodes' auto size! 
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
		    	
		    	vis.removeFilter("nodes", true);
		    	stop();
	        });
	        
	        // Filter nodes and ask to update mappers:
	        vis.filter("nodes", nfilter, true);
	    });
    }
    
    test("Add Node", function() {
    	var nodes = vis.nodes();
    	var count = nodes.length;
    	var n;
    	
    	// 1. NO id and NO (x,y):
    	n = vis.addNode();
    	ok(n.data.id != null, "New node has auto-incremented ID");
    	same(n.size, style.nodes.size.continuousMapper.minValue + n.borderWidth, "Min node size");
    	same(vis.nodes().length, ++count, "New nodes length");
    	
    	// 2. Id and (x,y):
    	n = vis.addNode(30, 45, { id: "NN1", label: "New Node 1", weight: 4 }, true);
    	same(n.data.id, "NN1", "New node has correct ID");
    	same(n.data.label, "New Node 1", "New node has correct label");
    	same(Math.round(n.x), 30, "New node - x");
    	same(Math.round(n.y), 45, "New node - y");
    	ok(n.size > style.nodes.size.continuousMapper.minValue + n.borderWidth, "Node size updated");
    	same(vis.nodes().length, ++count, "New nodes length");
    });
    
    test("Add Node: accepts null number attribute", function() {
    	vis.addDataField("nodes", { name: "null_number_attr", type: "number" }); 
    	
    	var n = vis.addNode({ label: "New Node - null number", null_number_attr: null });
    	same(n.data.null_number_attr, null, "New node added: 'null_number_attr' still null");
    	
    	vis.removeElements([n], true);
    	vis.removeDataField("nodes", "null_number_attr");
    });
    
    test("Add Edge", function() {
    	var edges = vis.edges(), nodes = vis.nodes();
    	var count = edges.length;
    	var e;
    	var src = nodes[0], tgt = nodes[2];
    	
    	// 1. NO id:
    	e = vis.addEdge({ source: src.data.id, target: tgt.data.id });
    	ok(e.data.id != null, "New edge has auto-incremented ID");
    	same(e.data.source, src.data.id, "New edge source ID");
    	same(e.data.target, tgt.data.id, "New edge target ID");
    	same(vis.edges().length, ++count, "New edges length");
    	
    	// 2. Id:
    	e = vis.addEdge({ id: "NE1", label: "New Edge 1",
    		              source: src.data.id, target: tgt.data.id,
    		              weight: 2.5 }, true);
    	same(e.data.id, "NE1", "New edge has correct ID");
    	same(e.data.label, "New Edge 1", "New node has correct label");
    	same(e.data.source, src.data.id, "New edge target ID");
    	same(e.data.target, tgt.data.id, "New edge target ID");
    	same(vis.edges().length, ++count, "New edges length");
    });
    
    test("Add Edge: accepts null number attribute", function() {
    	vis.addDataField("edges", { name: "null_number_attr", type: "number" }); 
    	
    	var nodes = vis.nodes();
    	var src = nodes[0], tgt = nodes[2];
    	var e = vis.addEdge({ source: src.data.id, target: tgt.data.id, null_number_attr: null });
    	same(e.data.null_number_attr, null, "New edge added: 'null_number_attr' still null");
    	
    	vis.removeElements([e], true);
    	vis.removeDataField("edges", "null_number_attr");
    });
    
    test("Remove Edges", function() {
    	var nodes = vis.nodes(), edges = vis.edges();
    	var original = edges;
    	var edgesCount = edges.length;

    	// 1. Inexistent:
    	vis.removeElements("edges", ["_none_"], true);
    	edges = vis.edges();
    	same(edges.length, edgesCount, "Inexistent edge => no change");
    	
    	// 2. Remove one edge by ID:
    	var id = original[0].data.id;
    	vis.removeElements("edges", [id], true);

    	edges = vis.edges();
    	nodes = vis.nodes();
    	same(edges.length, edgesCount-1, "New edges length");
    	same(vis.edge(id), null, "Edge '"+id+"' deleted");
    	same(nodes.length, vis.nodes().length, "Nodes not affected");

    	// 3. Remove only one by Object:
    	vis.removeEdge(original[1]);
    	same(vis.edge(original[1].data.id), null, "Edge '"+original[1].data.id+"' deleted");
    	
    	// 4. Remove 2 edges - by object:
    	vis.removeElements("edges", [original[2], original[3]]);
    	edges = vis.edges();
    	same(edges.length, edgesCount-4, "2 more edges removed - new length");
    	same(vis.edge(original[2].data.id), null, "Edge '"+original[2].data.id+"' deleted");
    	same(vis.edge(original[3].data.id), null, "Edge '"+original[3].data.id+"' deleted");
    	
    	// 5. Remove ALL edges:
    	vis.removeElements("edges", false);
    	edges = vis.edges();
    	same(edges.length, 0, "All edges removed");
    	same(vis.mergedEdges().length, 0, "All merged edges removed");
    	same(nodes.length, vis.nodes().length, "Nodes not affected");
    	
    	// Set original edges back for the other tests:
    	$.each(original, function(i, e) { vis.addEdge(e.data, true); });
    });
    
    test("Remove Nodes", function() {
    	var nodes = vis.nodes(), edges = vis.edges(), merged = vis.mergedEdges();
    	var originalNodes = nodes, originalEdges = edges;
    	var nodesCount = nodes.length;
    	
    	// 1. Inexistent:
    	vis.removeElements("nodes", ["_none_"], true);
    	nodes = vis.nodes();
    	same(nodes.length, nodesCount, "Inexistent node => no change");
    	
    	// 2. Remove one node by ID:
    	var id = originalNodes[0].data.id;
    	vis.removeElements("nodes", [id]);
    	
    	edges = vis.edges();
    	nodes = vis.nodes();
    	same(nodes.length, nodesCount-1, "New nodes length");
    	same(vis.node(id), null, "Node '"+id+"' deleted");
    	// Edges that were linked to that node should have been removed, as well:
    	$.each(originalEdges, function(i, e) {
    		if (e.data.source === id || e.data.target === id) {
    			same(vis.edge(e.data.id), null, "Edge '"+e.data.id+"' removed along with source/target node");
    		}
    	});
    	
    	// 3. Remove only one by Object:
    	vis.removeNode(originalNodes[0]);
    	nodesCount -= 1 + originalNodes[0].nodesCount; // in case this node had children
    	same(vis.node(originalNodes[0].data.id), null, "Node '"+originalNodes[1].data.id+"' deleted");
    	
    	// 4. Remove 2 nodes - by object:
    	vis.removeElements("nodes", [originalNodes[1], originalNodes[2]]);
    	nodesCount -= 1 + originalNodes[1].nodesCount;
    	nodesCount -= 1 + originalNodes[2].nodesCount;
    	nodes = vis.nodes();
    	same(nodes.length, nodesCount, "2 more nodes removed - new length");
    	same(vis.node(originalNodes[1].data.id), null, "Node '"+originalNodes[1].data.id+"' deleted");
    	same(vis.node(originalNodes[2].data.id), null, "Node '"+originalNodes[2].data.id+"' deleted");
    	
    	// 5. Remove ALL:
    	vis.removeElements();
    	same(vis.nodes().length, 0, "All nodes removed");
    	same(vis.edges().length, 0, "All edges removed");
    	same(vis.mergedEdges().length, 0, "All merged edges removed");
    	
    	// Exporting data/image should not throw errors:
    	ok(vis.pdf().indexOf("JVBERi0xLjUKMSAwIG9iago8PC9UeXBlIC9QYWd") === 0, "PDF image");
    	ok(vis.png().indexOf("iVBORw0KGgoAAAANSUhEUgAAAA") === 0, "PNG image");
    	
    	same(vis.sif(), "", "SIF is empty");
    	
    	var xml = $(vis.graphml());
    	same(xml[0].tagName, "GRAPHML", "GraphML root tag");
    	ok(xml.find("key").length > 0, "GraphML looks correct");
    	same(xml.find("node").length, 0, "GraphML has no nodes");
    	same(xml.find("edge").length, 0, "GraphML has no edges");
    	
    	xml = $(vis.xgmml());
    	same(xml[0].tagName, "GRAPH", "XGMML root tag");
    	same(xml.find("att[name='backgroundColor']").length, 1, "XGMML has backgroundColor tag");
    	same(xml.find("node").length, 0, "XGMML has no nodes");
    	same(xml.find("edge").length, 0, "XGMML has no edges");
    	
    	// Set original nodes/edges back for the other tests:
    	$.each(originalNodes, function(i, n) { vis.addNode(n.x, n.y, n.data, true); });
    	$.each(originalEdges, function(i, e) { vis.addEdge(e.data, true); });
    });
    
    test("Update Data Attributes", function() {
    	var all, nodes = vis.nodes(), edges = vis.edges();
    	var filter = function(o) { return o.data.id % 2 === 0; };
    	var ids = [];
    	
    	// 1: Update all nodes and edges (same data):
        var data = { weight: 1 };
        vis.updateData(data);
    	
        all = vis.nodes().concat(vis.edges());
        $.each(all, function(i, el) {
    		same(el.data.weight, 1, "weight updated ("+el.data.id+")");
    	});
        
        // 2: Update more than one node and edge at once (by ID - ALL groups - same data):
        var data = { weight: 0.5, type: "new_type" };
        $.each(all, function(i, o) {
        	if (filter(o)) { ids.push(o.data.id); }
        });

        vis.updateData(ids, data);
        
        all = vis.nodes().concat(vis.edges());
        $.each(all, function(i, el) {
        	if (filter(el)) {
	    		same(el.data.weight, 0.5, "weight updated ("+el.data.id+")");
	    		same(el.data.type, "new_type", "type updated ("+el.data.id+")");
        	} else {
        		same(el.data.weight, 1, "weight NOT updated ("+el.data.id+")");
	    		ok(el.data.type != "new_type", "type NOT updated ("+el.data.id+")");
        	}
    	});
        
        // 3: Update more than one object (by ID - 1 group - same data):
        ids = ["1","3"];
        var data = { weight: 4, source: "3", target: "5", id: "999999" };
        vis.updateData("edges", ids, data);
        
        all = vis.nodes().concat(vis.edges());
        $.each(all, function(i, el) {
        	var id = el.data.id;
        	if (el.group === "edges") {
        		if (id === "1" || id === "3") {
        			same(el.data.weight, 4, "weight updated ("+el.data.id+")");
        		}
		        ok(el.data.source != "3" || el.data.target != "5", "source/target is NEVER changed for edges");
        	} else {
        		ok(el.data.weight == 0.5 || el.data.weight == 1, "weight NOT updated ("+el.data.id+")");
        	}
        	ok(el.data.id != "999999", "id is NEVER changed");
    	});
        
    	// 4: Update only one node (send the whole object):
    	var n = vis.nodes()[1];
        n.data.label = "["+n.data.label+"]";
        n.data.weight = 2;
        vis.updateData([n]);
        
        all = vis.nodes().concat(vis.edges());
        $.each(all, function(i, el) {
        	if (el.group === "nodes" && el.data.id === n.data.id) {
        		same(el.data.weight, n.data.weight, "Node weight updated ("+el.data.id+")");
        		same(el.data.label, n.data.label, "Node label updated ("+el.data.id+")");
        	} else {
        		ok(el.data.weight != n.data.weight, "Other nodes or edges weight NOT updated ("+el.data.id+")");
        		ok(el.data.label != n.data.label, "Other nodes or edges label NOT updated ("+el.data.id+")");
        	}
    	});

        // 5: Update more than one object at once (merge data):
        var n = nodes[3];
        var e = edges[4];
        n.data.weight = 0;
        n.data.label = "["+n.data.label+"]";
        e.data.weight = 0;
        e.data.type = "AAA";
        
        vis.updateData([n, e], { weight: 6 });
        
        all = vis.nodes().concat(vis.edges());
        $.each(all, function(i, el) {
        	var id = el.data.id;
        	if (el.group === "nodes" && id === n.data.id) {
        		same(el.data.label, n.data.label, "Node label updated ("+id+")");
        		same(el.data.weight, 6, "Node weight updated ("+id+")");
        	} else if (el.group === "edges" && id === e.data.id) {
        		same(el.data.type, e.data.type, "Edge type updated ("+id+")");
        		same(el.data.weight, 6, "Edge weight updated ("+id+")");
        	} else {
        		ok(el.data.weight != 6, "Other nodes or edges weight NOT updated ("+id+")");
        		ok(el.data.label != n.data.label, "Other nodes or edges label NOT updated ("+id+")");
        	}
    	});
        
        var id = nodes[0].data.id;
        
        // 6: Update a field with type 'number' to null (should work):
        vis.updateData("nodes", [id], { weight: null });
        ok(vis.node(id).data.weight === null, "Node weight should be null");
        
        // Test Errors:
        
        // 7: Update a field with type 'int' to null => ERROR:
        vis.updateData("nodes", [id], { ranking: null });
        same(_errId, "dat001", "node.data.ranking (error: int type with null value)");
        _errId = null;
        
        // 8: Update a field with type 'boolean' to null => ERROR:
        vis.updateData("nodes", [id], { special: null });
        same(_errId, "dat001", "node.data.special (error: boolean type with null value)");
        _errId = null;
    });
    
    test("Get Data Schema", function() {
    	var schema = vis.dataSchema();
    	ok(schema.nodes.length > 0, "Empty 'nodes' schema");
    	ok(schema.edges.length > 0, "Empty 'edges' schema");
    	
    	$.each(schema.nodes, function(i, df) {
    		ok(df.name != null, "name (nodes schema)");
    		ok(df.type != null, "type (nodes schema)");
    		ok(df.defValue !== undefined, "defValue (nodes schema)");
    	});
    	$.each(schema.edges, function(i, df) {
    		ok(df.name != null, "name (edges schema)");
    		ok(df.type != null, "type (edges schema)");
    		ok(df.defValue !== undefined, "defValue (edges schema)");
    	});
    });
    
    test("Add Data Field", function() {
    	var all, nodes, edges, field;
    	
    	// 1: Add new field to nodes and edges:
        field = { name: "new_attr_1", type: "string" };
        vis.addDataField(field);
    	
        all = vis.nodes().concat(vis.edges());
        $.each(all, function(i, el) {
    		same(el.data.new_attr_1, null, "New field added to all ("+el.group+" "+el.data.id+")");
    	});
        
        // 2: Add new field to nodes only:
        vis.addDataField("nodes", { name: "new_node_attr_1", type: "number", defValue: 0.234 }) 
           .addDataField("nodes", { name: "new_node_attr_2", type: "number"  })
           .addDataField("nodes", { name: "new_node_attr_3", type: "boolean", defValue: true })
           .addDataField("nodes", { name: "new_node_attr_4", type: "boolean", defValue: null  })
           .addDataField("nodes", { name: "new_node_attr_5", type: "int" })
           .addDataField("nodes", { name: "new_node_attr_6", type: "string", defValue: "DEF_VAL" })
           .addDataField("nodes", { name: "new_node_attr_7", type: "string" });

        nodes = vis.nodes();
        $.each(nodes, function(i, el) {
    		same(el.data["new_node_attr_1"], 0.234, "New field [number] added to nodes ("+el.data.id+")");
    		same(el.data["new_node_attr_2"], null, "New field [number] added to nodes ("+el.data.id+")");
    		same(el.data["new_node_attr_3"], true, "New field [boolean] added to nodes ("+el.data.id+")");
    		same(el.data["new_node_attr_4"], false, "New field [boolean] added to nodes ("+el.data.id+")");
    		same(el.data["new_node_attr_5"], 0, "New field [int] added to nodes ("+el.data.id+")");
    		same(el.data["new_node_attr_6"], "DEF_VAL", "New field [string] added to nodes ("+el.data.id+")");
    		same(el.data["new_node_attr_7"], null, "New field [string] added to nodes ("+el.data.id+")");
    	});
        edges = vis.edges();
        $.each(edges, function(i, el) {
        	same(el.data["new_node_attr_1"], undefined, "Field NOT added to edges ("+el.data.id+")");
        });
        
        // 3: Ignore duplicated field:
        field = { name: "new_attr_1", type: "string", defValue: "IGNORE IT" };
        vis.addDataField("nodes", field);
    	
        nodes = vis.nodes();
        $.each(nodes, function(i, el) {
    		same(el.data.new_attr_1, null, "Duplicated field 'new_attr_1' ignored ("+el.data.id+")");
    	});
        
        // 4: Errors:
    	var fail;
    	try {
    		vis.addDataField("nodes"); fail = true;
    	} catch (err) { fail = false; }
    	ok(fail === false, "Null 'dataField' throws exception");
    	try {
    		vis.addDataField("edges", { type: "string" }); fail = true;
    	} catch (err) { fail = false; }
    	ok(fail === false, "Null 'dataField.name' throws exception");
    	try {
    		vis.addDataField({ name: "err_attr" }); fail = true;
    	} catch (err) { fail = false; }
    	ok(fail === false, "Null 'dataField.type' throws exception");
    });
    
    test("Remove Data Field", function() {
    	var all, nodes, edges, name;

    	// 1: Remove field from nodes and edges:
    	name = "new_attr_1";
    	vis.removeDataField(name);
    	
    	all = vis.nodes().concat(vis.edges());
    	$.each(all, function(i, el) {
    		same(el.data[name], undefined, "Field "+name+"' removed from all ("+el.group+" "+el.data.id+")");
    	});
    	
    	// 2: Remove field from nodes only:
    	name = "new_node_attr_1";
    	vis.addDataField({ name: name, type: "string", defValue: "delete me!" });
    	vis.removeDataField("edges", name);
    	
    	edges = vis.edges();
    	$.each(edges, function(i, el) {
    		same(el.data[name], undefined, "Field "+name+"' removed from edges ("+el.data.id+")");
    	});
    	nodes = vis.nodes();
    	$.each(nodes, function(i, el) {
    		ok(el.data[name] !== undefined, "Field "+name+"' NOT removed from nodes ("+el.data.id+")");
    	});
    	
    	// 3: Do NOT remove non-custom fields:
    	vis.addDataField("edges", { name: "label", type: "string", defValue: "edge" });
    	
    	vis.removeDataField("id").removeDataField("label");
    	vis.removeDataField("edges", "source").removeDataField("edges", "target").removeDataField("edges", "directed");
    	
    	all = vis.nodes().concat(vis.edges());
    	$.each(all, function(i, el) {
    		ok(el.data["id"] != null, "Did NOT remove mandatory field 'id' ("+el.data.id+")");
    		ok(el.data["label"] == null, "Removed 'label' field ("+el.data.id+")");
    	});
    	edges = vis.edges();
    	$.each(edges, function(i, el) {
    		ok(el.data["source"] != null && el.data["target"] != null && el.data["directed"] != null, 
    	       "Did NOT remove edge fields 'directed', 'source' and 'target' ("+el.data.id+")");
    	});
    	
    	// 4: Errors:
    	var fail;
    	try {
    		vis.removeDataField(); fail = true;
    	} catch (err) { fail = false; }
    	ok(fail === false, "Null 'name' throws exception");
    });
    
    test("NetworkModel", function() {
    	var model = vis.networkModel();
    	var nodes = vis.nodes();
    	var edges = vis.edges();
    	var schema = vis.dataSchema();
    	
    	var nodesData = [];
    	var edgesData = [];
    	$.each(nodes, function(i, n) { nodesData.push(n.data); });
    	$.each(edges, function(i, e) { edgesData.push(e.data); });

    	same(model.dataSchema, schema, "Schema");
    	same(model.data.nodes, nodesData, "Nodes Data");
    	same(model.data.edges, edgesData, "Edges Data");
    });
    
    test("GraphML", function() {
    	var xml = $(vis.graphml());
    	var nodes = vis.nodes();
    	var edges = vis.edges();
    	var schema = vis.dataSchema();
    	var ignoredFields = 5; // id (nodes), id (edges), source, target, directed
    	var parents = vis.parentNodes();
    	
    	same(xml[0].tagName.toLowerCase(), "graphml", "<graphml> tag");
    	same(xml.find("node > graph").length, parents.length, "<graph> tag");
    	same(xml.find("key").length, (schema.nodes.length + schema.edges.length - ignoredFields), "Number <key> tags");
    	same(xml.find("node").length, nodes.length, "Number of nodes");
    	same(xml.find("edge").length, edges.length, "Number of edges");
    });
    
    test("XGMML", function() {
    	var xml = $(vis.xgmml());
    	var nodes = vis.nodes();
    	var edges = vis.edges();
    	var parents = vis.parentNodes();
    	
    	same(xml[0].tagName.toLowerCase(), "graph", "<graph> tag");
    	same(xml.find("att > graph").length, parents.length, "nested <graph> tags"); // compound graphs only
    	same(xml.find("node").length, nodes.length, "Number of nodes");
    	same(xml.find("node > graphics").length, nodes.length, "Number of node graphics");
    	same(xml.find("edge").length, edges.length, "Number of edges");
    	same(xml.find("edge > graphics").length, edges.length, "Number of edge graphics");
    });
    
    test("SIF", function() {
    	var sif = vis.sif();
    	var edges = vis.edges();
    	// Default fields:
    	$.each(edges, function(i, e) {
    		var inter = e.data.interaction ? e.data.interaction : e.data.id;
    		var line = e.data.source + "\t" + inter + "\t" + e.data.target; 
    		ok(sif.indexOf(line) > -1, "SIF (A) text should have the line: '"+line+"'");
    	});
    	// Now replace the default node and interaction fields:
    	var sif = vis.sif({ nodeAttr: "name", interactionAttr: "type" });
    	var edges = vis.edges();
    	$.each(edges, function(i, e) {
    		var src = vis.node(e.data.source).data.name;
    		var tgt = vis.node(e.data.target).data.name;
    		var line = src + "\t" + e.data.type + "\t" + tgt; 
    		ok(sif.indexOf(line) > -1, "SIF (B) text should have the line: '"+line+"'");
    	});
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
				var w = n.width * scale;
				var h = n.height * scale;
				p.x += n.x;
				p.y += n.y;
				pointer.css('left', p.x - w/2).css('top', p.y - h/2);
				pointer.css('width', w).css('height', h);
			});
    	});
    	vis.zoomToFit();
    	vis.removeListener("zoom");
		// --------------------------------------------------------
    });
    
    test("PDF", function() {
    	var base64 = vis.pdf();
    	var beginning = "JVBERi0xLjUKMSAwIG9iago8PC9UeXBlIC9QYWdlcwovS2lkcyBbMyAwIFJdCi9Db3VudCAxPj4K";

    	ok(base64.length > 9000, "PDF string has compatible length ("+base64.length+")");
    	same(base64.indexOf(beginning), 0, "PDF begins with correct chars");
    });
    
    test("SVG", function() {
    	if (!$.browser.msie) {
    		// TODO: make test work on IE
	    	var svg = $(vis.svg());
	    	var nodes = vis.nodes();
	    	var edges = vis.edges();
	
	    	same(svg.find(".cw-background").length, 1, "Background rectangle");
	    	same(svg.find(".cw-node").length, nodes.length, "Number of SVG nodes");
	    	same(svg.find(".cw-node-shape").length, nodes.length, "Number of SVG node shapes");
	    	same(svg.find(".cw-edge").length, edges.length, "Number of SVG edges");
	    	same(svg.find(".cw-edge-line").length, edges.length, "Number of SVG edge lines");
	    	
	    	// TODO: test node images
	    	// TODO: test edge arrows
    	}
    });
    
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