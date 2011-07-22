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
package org.cytoscapeweb {
	import flexunit.framework.TestSuite;
	
	import org.cytoscapeweb.model.ConfigProxy;
	import org.cytoscapeweb.model.GraphProxy;
	import org.cytoscapeweb.model.converters.ExternalObjectConverterTest;
	import org.cytoscapeweb.model.converters.SIFConverterTest;
	import org.cytoscapeweb.model.converters.XGMMLConverterTest;
	import org.cytoscapeweb.model.data.ConfigVOTest;
	import org.cytoscapeweb.model.data.ContinuousVizMapperVOTest;
	import org.cytoscapeweb.model.data.DiscreteVizMapperVOTest;
	import org.cytoscapeweb.model.data.FirstNeighborsVOTest;
	import org.cytoscapeweb.model.data.InteractionVOTest;
	import org.cytoscapeweb.model.data.VisualPropertyVOTest;
	import org.cytoscapeweb.model.data.VisualStyleBypassVOTest;
	import org.cytoscapeweb.model.data.VisualStyleVOTest;
	import org.cytoscapeweb.model.data.VizMapperVOTest;
	import org.cytoscapeweb.util.UtilsTest;
	import org.cytoscapeweb.util.VisualPropertiesTest;
	import org.cytoscapeweb.view.render.ImageCacheTest;
	import org.cytoscapeweb.view.render.LabelerTest;

	public class AllTests extends TestSuite {
		
		public function AllTests() {
		    setupEnvironment();

			addTestSuite(UtilsTest);
			addTestSuite(VisualPropertiesTest);
			
			addTestSuite(InteractionVOTest);
			
			addTestSuite(VisualPropertyVOTest);
			addTestSuite(VisualStyleVOTest);
			addTestSuite(VisualStyleBypassVOTest);
			addTestSuite(ConfigVOTest);
			
			addTestSuite(VizMapperVOTest);
			addTestSuite(DiscreteVizMapperVOTest);
			addTestSuite(ContinuousVizMapperVOTest);
			
			addTestSuite(FirstNeighborsVOTest);
			
			addTestSuite(LabelerTest);
			addTestSuite(ImageCacheTest);
			
			addTestSuite(XGMMLConverterTest);
			addTestSuite(SIFConverterTest);
			addTestSuite(ExternalObjectConverterTest);
		}
		
		private function setupEnvironment():void {
		    // Pure MVC setup:
		    var facade:ApplicationFacade = ApplicationFacade.getInstance();
		    
		    // Register required model classes:
            facade.registerProxy(new ConfigProxy());
            facade.registerProxy(new GraphProxy());
		}
	}
}