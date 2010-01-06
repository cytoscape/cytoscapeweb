================================================================================
LICENSE AGREEMENT AND DISCLAIMER
================================================================================

Cytoscape Web is a collaborative effort of the Cytoscape Consortium.  
It is available at http://www.cytoscape.org and provided to all users 
free of charge.

Users of Cytoscape Web must first agree to the license agreement 
provided in the file "LICENSE.txt".

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

================================================================================
INSTALLATION AND USAGE
================================================================================

-- TODO --

================================================================================
PROJECT SETUP ON ECLIPSE
================================================================================
Requires: Flex Builder 3 or Eclipse + Flex Builder 3 plugin

1. Checkout the project from SVN as a Flex project.

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

