package org.cytoscapeweb.view.layout.ivis.layout
{
	public class GeneralOptions
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
}