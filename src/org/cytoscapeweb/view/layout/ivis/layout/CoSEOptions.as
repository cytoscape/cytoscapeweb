package org.cytoscapeweb.view.layout.ivis.layout
{
	public class CoSEOptions
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
}