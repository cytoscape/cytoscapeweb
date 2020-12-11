Cytoscape Web
=============

Flash-based graph visualization tool which can be integrated in HTML via its
Javascript API (http://cytoscapeweb.cytoscape.org).

This project has been replaced by [Cytoscape.js](https://js.cytoscape.org/) and is no longer active.


LICENSE AGREEMENT AND DISCLAIMER
--------------------------------------------------------------------------------

Cytoscape Web is developed as part of the Cytoscape project, by members of the
Cytoscape Consortium.  
It is available at http://www.cytoscape.org and provided to all users
free of charge under the Lesser GNU Public License (LGPL).

Users of Cytoscape Web must first agree to the license agreement
provided in the file "LICENSE.txt".

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


WEBSITE
--------------------------------------------------------------------------------

Visit our Website at http://cytoscapeweb.cytoscape.org/


INSTALLATION AND USAGE
--------------------------------------------------------------------------------

1. Copy all the files from js/min/ and swf/ to your project folder.

2. Create an HTML file in the same folder and reference the copied JavaScript
   files:

        <head>
            <script type="text/javascript" src="AC_OETags.min.js"></script>
            <script type="text/javascript" src="json2.min.js"></script>
            <script type="text/javascript" src="cytoscapeweb.min.js"></script>
        </head>
        
3. Add a div or another HTML container and give it an ID (Cytoscape Web will
   replace its contents with the rendered graph):

        <body>
            <div id="cytoscapeweb" style="width:600px;height:400px;"></div>
        </body>
   
4. Write JavaScript code to initialize and start Cytoscape Web:

        <script type="text/javascript">
            // network data could alternatively be grabbed via ajax
            var xml = '\
            <graphml>\
              <graph>\
                <node id="1"/>\
                <node id="2"/>\
                <edge target="1" source="2"/>\
              </graph>\
            </graphml>\
            ';
            
            // init and draw
            var vis = new org.cytoscapeweb.Visualization("cytoscapeweb");
            vis.draw({ network: xml });
        </script>


To see other examples and the API documentation, visit 
http://cytoscapeweb.cytoscape.org/documentation


SOURCE CODE
--------------------------------------------------------------------------------

- You can get the Cytoscape Web source code at
  https://github.com/cytoscape/cytoscapeweb

- After you download the project, you can use Flex Builder or Apache Ant to build it.


PROJECT SETUP ON FLEX BUILDER
--------------------------------------------------------------------------------

This option requires Adobe's Flex Builder 3 (or the Flex Builder plugin for
Eclipse).
It is not free, but you can download a 60-day trial from:

    http://www.adobe.com/products/flex.

The Cytoscape Web development team uses Eclipse with the Flex Builder plugin.

1. Checkout the project from SVN or import it as a Flex project.

2. Setup the Flex Build Path:
   * Main source folder:            src
   * Output folder:                 bin
   * Source Path (Add Folder):      src-test
   * Library Path (Add SWC Folder): lib

3. Add this line to Flex's "additional compiler arguments":
   -locale en_US -source-path=assets/locale/{locale}
   
4. Set the Flex Applications:
   * src/CytoscapeWeb.mxml (default)
   * src/TestRunner.mxml

5. Before running Cytoscape Web with the test page, you need to minify some
   JavaScript files. We provided an Ant task for that.
   One option is to manually execute the "js minify" Ant task after the
   ActionScript code is compiled by the Flex Builder.
   But if you are using Eclipse with the Flex Builder plugin, it might be
   more convenient to let Eclipse do it automatically after each build.
   To allow that, just follow these steps:
   
   5.1. Open the project Properties panel and select "Builders".
   
   5.2. Click "New..." and choose "Ant Builder".
   
   5.3. Give it a name (e.g. "JS Minify"), and enter the following parameters:
   
          - Main tab:
          
            Buildfile:        ${workspace_loc:/cytoscapeweb/build.xml}
            Base direectory:  ${workspace_loc:/cytoscapeweb}
            
          - Targets tab:
          
            Manual Build: js minify
            Auto Build:   js minify
            
    5.4. Click "Apply" and "OK".
    
    Now, every time the project is built by the Eclipse Flex Builder plugin, 
    it will also minify the required JavaScript files.

6. To test Cytoscape Web, just right-click src/CytoscapeWeb.mxml and choose:
   
   Run As >> Flex Application
   
   The first time it will open CytoscapeWeb.html in your default browser, but
   it will not work. To fix it, right-click CytoscapeWeb.mxml again and select:
   
   Run As >> Run Configurations...
   
   Then, under "URL or path to launch", uncheck "Use defaults" and replace
   "CytoscapeWeb.html" by "tests.html" (on Debug, Profile and Run). Now you can
   run CytoscapeWeb.mxml again.


BUILDING WITH ANT
--------------------------------------------------------------------------------

If you do not have Flex Builder, you still can build the project with Apache
Ant:

1. Download and install Apache Ant. Installation instructions are available at:
   
   http://ant.apache.org/manual/install.html.

2. Download and install the Flex SDK from:

   http://www.adobe.com/cfusion/entitlement/index.cfm?e=flex3sdk
   
3. After installing the Flex SDK, create a file called "local.properties" in the
   root folder of the Cytoscape Web project (the one that contains "build.xml").
   Open the created properties file with any text editor and add the FLEX_HOME
   path, which is the location where you just installed the Flex SDK.
   Example:
   
   FLEX_HOME=/Library/flex_sdk_3.5/

2. To build Cytoscape Web, open the terminal, go to the project folder and type:

   ant build

3. To test it, just open bin/tests.html in a web browser. It will probably not
   work if you are doing that directly from the file system, because of the
   Flash Player security settings. You can change it by going to this web page:
   
   http://www.macromedia.com/support/documentation/en/flashplayer/help/settings_manager04.html
   
   Just open "Edit locations...", select "Add location...", and add the folder
   that contains the Cytoscape Web project. Now you can open bin/tests.html
   again.
   
   If you run Cytoscape Web from a Web server, there are no such security
   issues.


LINKING BACK TO US
--------------------------------------------------------------------------------
If you use Cytoscape Web, please link us back.
We appreciate it, because that helps us keep Cytoscape Web development funded.
Feel free to link to us however you choose or use one of the examples below:

<a href="http://cytoscapeweb.cytoscape.org/">
    <img src="http://cytoscapeweb.cytoscape.org/img/logos/cw_s.png" alt="Cytoscape Web"/>
</a>

<a href="http://cytoscapeweb.cytoscape.org/">
    <img src="http://cytoscapeweb.cytoscape.org/img/logos/cw.png" alt="Cytoscape Web"/>
</a>



Third-Party Licenses
--------------------------------------------------------------------------------

Flare:

	Copyright (c) 2007 Regents of the University of California.
	  All rights reserved.

	  Redistribution and use in source and binary forms, with or without
	  modification, are permitted provided that the following conditions
	  are met:

	  1. Redistributions of source code must retain the above copyright
	  notice, this list of conditions and the following disclaimer.

	  2. Redistributions in binary form must reproduce the above copyright
	  notice, this list of conditions and the following disclaimer in the
	  documentation and/or other materials provided with the distribution.

	  3.  Neither the name of the University nor the names of its contributors
	  may be used to endorse or promote products derived from this software
	  without specific prior written permission.

	  THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
	  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
	  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
	  ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
	  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
	  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
	  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
	  HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
	  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
	  OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
	  SUCH DAMAGE.


PureMVC:

    PureMVC MultiCore Framework for Java (Ported) - Copyright © 2008-2010 Anthony Quinault
    PureMVC - Copyright © 2006-2012 Futurescale, Inc.

    All rights reserved.

    Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
        Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
        Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
        Neither the name of Futurescale, Inc., PureMVC.org, nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.



AlivePDF (MIT License):

	Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
