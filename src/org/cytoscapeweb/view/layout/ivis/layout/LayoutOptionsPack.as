package org.cytoscapeweb.view.layout.ivis.layout
{
	import org.cytoscapeweb.view.layout.ivis.layout.cose.CoSEConstants;
	import org.cytoscapeweb.view.layout.ivis.layout.fd.FDLayoutConstants;

//import java.io.Serializable;

//import org.ivis.layout.cose.CoSEConstants;
//import org.ivis.layout.fd.FDLayoutConstants;
//import org.ivis.layout.avsdf.AVSDFConstants;
//import org.ivis.layout.cise.CiSEConstants;
//import org.ivis.layout.sgym.SgymConstants;
//import org.ivis.layout.spring.SpringConstants;



/**
 * This method gathers the user-customizable layout options in a package
 *
 * @author Cihan Kucukkececi
 * @author Ugur Dogrusoz
 *
 * Copyright: i-Vis Research Group, Bilkent University, 2007 - present
 */
public class LayoutOptionsPack /*implements Serializable*/
{
	private static var instance:LayoutOptionsPack;

	private var general:GeneralOptions;
	private var coSE:CoSEOptions;
	/*
	private var cluster:Cluster;
	private var ciSE:CiSE;
	private var avsdf:AVSDF;
	private var spring:Spring;
	private var sgym:Sgym;
	*/
	
	/*
	public class General
	{
		private var layoutQuality:int; // proof, default, draft
		private var animationDuringLayout:Boolean; // T-F
		private var animationOnLayout:Boolean; // T-F
		private var animationPeriod:int; // 0-100
		private var incremental:Boolean; // T-F
		private var createBendsAsNeeded:Boolean; // T-F
		private var uniformLeafNodeSizes:Boolean; // T-F

		public function getLayoutQuality():int {
			return layoutQuality;
		}

		public function setLayoutQuality(quality:int):void {
			this.layoutQuality = quality;
		}

		public function isAnimationDuringLayout():Boolean {
			return animationDuringLayout;
		}

		public function setAnimationDuringLayout(animationDuringLayout:Boolean):void {
			this.animationDuringLayout = animationDuringLayout;
		}

		public function isAnimationOnLayout():Boolean {
			return animationOnLayout;
		}

		public function setAnimationOnLayout(animationOnLayout:Boolean):void {
			this.animationOnLayout = animationOnLayout;
		}

		public function getAnimationPeriod():int {
			return animationPeriod;
		}

		public function setAnimationPeriod(animationPeriod:int):void {
			this.animationPeriod = animationPeriod;
		}

		public function isIncremental():Boolean {
			return incremental;
		}

		public function setIncremental(incremental:Boolean):void {
			this.incremental = incremental;
		}

		public function isCreateBendsAsNeeded():Boolean {
			return createBendsAsNeeded;
		}

		public function setCreateBendsAsNeeded(createBendsAsNeeded:Boolean):void {
			this.createBendsAsNeeded = createBendsAsNeeded;
		}

		public function isUniformLeafNodeSizes():Boolean {
			return uniformLeafNodeSizes;
		}
		
		public function setUniformLeafNodeSizes(uniformLeafNodeSizes:Boolean):void {
			this.uniformLeafNodeSizes = uniformLeafNodeSizes;
		}
	}

	public class CoSE
	{
		private var idealEdgeLength:int; // any positive int
		private var springStrength:int; // 0-100
		private var repulsionStrength:int; // 0-100
		private var smartRepulsionRangeCalc:Boolean; // T-F
		private var gravityStrength:int; // 0-100
		private var compoundGravityStrength:int; // 0-100
		private var gravityRange:int; // 0-100
		private var compoundGravityRange:int; // 0-100
		private var smartEdgeLengthCalc:Boolean; // T-F
		private var multiLevelScaling:Boolean; // T-F
		
		public function getIdealEdgeLength():int {
			return idealEdgeLength;
		}

		public function setIdealEdgeLength(idealEdgeLength:int):void {
			this.idealEdgeLength = idealEdgeLength;
		}

		public function getSpringStrength():int {
			return springStrength;
		}

		public function setSpringStrength(springStrength:int):void {
			this.springStrength = springStrength;
		}

		public function getRepulsionStrength():int {
			return repulsionStrength;
		}

		public function setRepulsionStrength(repulsionStrength:int):void {
			this.repulsionStrength = repulsionStrength;
		}

		public function getGravityStrength():int {
			return gravityStrength;
		}

		public function setGravityStrength(gravityStrength:int):void {
			this.gravityStrength = gravityStrength;
		}

		public function getCompoundGravityStrength():int {
			return compoundGravityStrength;
		}

		public function setCompoundGravityStrength(compoundGravityStrength:int):void {
			this.compoundGravityStrength = compoundGravityStrength;
		}
		
		public function getGravityRange():int {
			return gravityRange;
		}

		public function setGravityRange(gravityRange:int):void {
			this.gravityRange = gravityRange;
		}

		public function getCompoundGravityRange():int {
			return compoundGravityRange;
		}

		public function setCompoundGravityRange(compoundGravityRange:int):void {
			this.compoundGravityRange = compoundGravityRange;
		}

		public function isSmartEdgeLengthCalc():Boolean {
			return smartEdgeLengthCalc;
		}

		public function setSmartEdgeLengthCalc(smartEdgeLengthCalc:Boolean):void {
			this.smartEdgeLengthCalc = smartEdgeLengthCalc;
		}

		public function isMultiLevelScaling():Boolean {
			return multiLevelScaling;
		}

		public function setMultiLevelScaling(multiLevelScaling:Boolean):void {
			this.multiLevelScaling = multiLevelScaling;
		}

		public function setSmartRepulsionRangeCalc(smartRepulsionRangeCalc:Boolean):void {
			this.smartRepulsionRangeCalc = smartRepulsionRangeCalc;
		}

		public function isSmartRepulsionRangeCalc():Boolean {
			return smartRepulsionRangeCalc;
		}
	}

	public class Cluster
	{
		private var idealEdgeLength:int; // any positive int
		private var clusterSeperation:int; // 0-100
		private var clusterGravityStrength:int; // 0-100

		public function getClusterSeperation():int {
			return clusterSeperation;
		}

		public function setClusterSeperation(clusterSeperation:int):void {
			this.clusterSeperation = clusterSeperation;
		}

		public function getIdealEdgeLength():int {
			return idealEdgeLength;
		}

		public function setIdealEdgeLength(idealEdgeLength:int):void {
			this.idealEdgeLength = idealEdgeLength;
		}

		public function getClusterGravityStrength():int {
			return clusterGravityStrength;
		}

		public function setClusterGravityStrength(clusterGravityStrength:int):void {
			this.clusterGravityStrength = clusterGravityStrength;
		}
	}

	public class CiSE
	{
		var nodeSeparation:int;
		var desiredEdgeLength:int;
		var interClusterEdgeLengthFactor:int;
		var allowNodesInsideCircle:Boolean;
		var maxRatioOfNodesInsideCircle:Number;

		public function getNodeSeparation():int {
			return nodeSeparation;
		}

		public function setNodeSeparation(nodeSeparation:int):void {
			this.nodeSeparation = nodeSeparation;
		}

		public function getDesiredEdgeLength():int {
			return desiredEdgeLength;
		}

		public function setDesiredEdgeLength(desiredEdgeLength:int):void {
			this.desiredEdgeLength = desiredEdgeLength;
		}

		public function getInterClusterEdgeLengthFactor():int {
			return interClusterEdgeLengthFactor;
		}

		public function setInterClusterEdgeLengthFactor(icelf:int):void {
			this.interClusterEdgeLengthFactor = icelf;
		}
		
		public function isAllowNodesInsideCircle():Boolean {
			return allowNodesInsideCircle;
		}

		public function setAllowNodesInsideCircle(allowNodesInsideCircle:Boolean):void {
			this.allowNodesInsideCircle = allowNodesInsideCircle;
		}

		public function getMaxRatioOfNodesInsideCircle():Number {
			return maxRatioOfNodesInsideCircle;
		}

		public function setMaxRatioOfNodesInsideCircle(ratio:Number):void {
			this.maxRatioOfNodesInsideCircle = ratio;
		}
	}

	public class AVSDF
	{
		var nodeSeparation:int;

		public function getNodeSeparation():int {
			return nodeSeparation;
		}

		public function setNodeSeparation(nodeSeparation:int):void {
			this.nodeSeparation = nodeSeparation;
		}
	}

	public class Spring
	{
		var nodeDistanceRestLength:int;
		var disconnectedNodeDistanceSpringRestLength:int;

		public function getNodeDistanceRestLength():int {
			return nodeDistanceRestLength;
		}

		public function setNodeDistanceRestLength(nodeDistanceRestLength:int):void {
			this.nodeDistanceRestLength = nodeDistanceRestLength;
		}

		public function getDisconnectedNodeDistanceSpringRestLength():int {
			return disconnectedNodeDistanceSpringRestLength;
		}

		public function setDisconnectedNodeDistanceSpringRestLength(
			disconnectedNodeDistanceSpringRestLength:int):void {
			this.disconnectedNodeDistanceSpringRestLength
				= disconnectedNodeDistanceSpringRestLength;
		}
	}

	public class Sgym
	{
		var horizontalSpacing:int;
		var verticalSpacing:int;
		var vertical:Boolean;

		public function getHorizontalSpacing():int {
			return horizontalSpacing;
		}

		public function setHorizontalSpacing(horizontalSpacing:int):void {
			this.horizontalSpacing = horizontalSpacing;
		}

		public function getVerticalSpacing():int {
			return verticalSpacing;
		}

		public function setVerticalSpacing(verticalSpacing:int):void {
			this.verticalSpacing = verticalSpacing;
		}

		public function isVertical():Boolean {
			return vertical;
		}

		public function setVertical(vertical:Boolean):void {
			this.vertical = vertical;
		}
	}
	*/
	
	public function LayoutOptionsPack()
	{
		this.general = new GeneralOptions();
		this.coSE = new CoSEOptions();
		/*
		this.cluster = new Cluster();
		this.ciSE = new CiSE();
		this.avsdf = new AVSDF();
		this.spring = new Spring();
		this.sgym = new Sgym();
		*/
		setDefaultLayoutProperties();
	}

	public function setDefaultLayoutProperties():void
	{
		general.setAnimationPeriod(50);
		general.setAnimationDuringLayout(
			LayoutConstants.DEFAULT_ANIMATION_DURING_LAYOUT);
		general.setAnimationOnLayout(
			LayoutConstants.DEFAULT_ANIMATION_ON_LAYOUT);
		general.setLayoutQuality(LayoutConstants.DEFAULT_QUALITY);
		general.setIncremental(LayoutConstants.DEFAULT_INCREMENTAL);
		general.setCreateBendsAsNeeded(
			LayoutConstants.DEFAULT_CREATE_BENDS_AS_NEEDED);
		general.setUniformLeafNodeSizes(
			LayoutConstants.DEFAULT_UNIFORM_LEAF_NODE_SIZES);

		coSE.setIdealEdgeLength(FDLayoutConstants.DEFAULT_EDGE_LENGTH);
		coSE.setSmartEdgeLengthCalc(
			CoSEConstants.DEFAULT_USE_SMART_IDEAL_EDGE_LENGTH_CALCULATION);
		coSE.setMultiLevelScaling(CoSEConstants.DEFAULT_USE_MULTI_LEVEL_SCALING);
		coSE.setSmartRepulsionRangeCalc(
			FDLayoutConstants.DEFAULT_USE_SMART_REPULSION_RANGE_CALCULATION);
		coSE.setSpringStrength(50);
		coSE.setRepulsionStrength(50);
		coSE.setGravityStrength(50);
		coSE.setCompoundGravityStrength(50);
		coSE.setGravityRange(50);
		coSE.setCompoundGravityRange(50);

		/*
		ciSE.setNodeSeparation(CiSEConstants.DEFAULT_NODE_SEPARATION);
		ciSE.setDesiredEdgeLength(CiSEConstants.DEFAULT_EDGE_LENGTH);
		ciSE.setInterClusterEdgeLengthFactor(50);
		ciSE.setAllowNodesInsideCircle(
			CiSEConstants.DEFAULT_ALLOW_NODES_INSIDE_CIRCLE);
		ciSE.setMaxRatioOfNodesInsideCircle(
			CiSEConstants.DEFAULT_MAX_RATIO_OF_NODES_INSIDE_CIRCLE);

		avsdf.setNodeSeparation(AVSDFConstants.DEFAULT_NODE_SEPARATION);

		cluster.setIdealEdgeLength(CoSEConstants.DEFAULT_EDGE_LENGTH);
		cluster.setClusterSeperation(50);
		cluster.setClusterGravityStrength(50);

		spring.setDisconnectedNodeDistanceSpringRestLength(int(SpringConstants.DEFAULT_DISCONNECTED_NODE_DISTANCE_SPRING_REST_LENGTH));
		spring.setNodeDistanceRestLength(int(SpringConstants.DEFAULT_NODE_DISTANCE_REST_LENGTH_CONSTANT));

		sgym.setHorizontalSpacing(SgymConstants.DEFAULT_HORIZONTAL_SPACING);
		sgym.setVerticalSpacing(SgymConstants.DEFAULT_VERTICAL_SPACING);
		sgym.setVertical(SgymConstants.DEFAULT_VERTICAL);
		*/
	}

	public static function getInstance():LayoutOptionsPack
	{
		if (instance == null)
		{
			instance = new LayoutOptionsPack();
		}

		return instance;
	}

	public function getCoSE():CoSEOptions {
		return coSE;
	}

	public function getGeneral():GeneralOptions {
		return general;
	}

	/*
	public function getSgym():Sgym {
		return sgym;
	}
	
	public function getSpring():Spring {
		return spring;
	}

	public function getCluster():Cluster {
		return cluster;
	}

	public function getCiSE():CiSE {
		return ciSE;
	}

	public function getAVSDF():AVSDF {
		return avsdf;
	}
	*/
	
}
}