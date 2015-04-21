Cytoscape Web
=============

Flash-based graph visualization tool which can be integrated in HTML via its
Javascript API (http://cytoscapeweb.cytoscape.org).


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

- You can get the Cytoscape Web source code at https://github.com/cytoscape/cytoscapeweb


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

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
Thank you for using Cytoscape Web!
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

