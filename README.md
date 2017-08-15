# install_ca
An installation script for a basic installation of CollectiveAccess (currently Linux-only)


This script will install and configure all the files and software dependancies need to run a Linux-based webserver for the current versions of CollectiveAccess Providence 1 and Pawtucket 2. This process may take a long time, and will use a LOT (several gigabytes; we're installing and updating a lot of packages) of internet. You may want to get a book. And unlimited internet.

<b><font>PLEASE NOTE THAT THIS SCRIPT IS PROVIDED COMPLETELY AS-IS, WITH ABSOLUTELY NO GUARANTEES EXPRESSED OR IMPLIED.</font></b>

Specifically, this script will install and configure the following: 
<ul><li>All currently-available updates for the Linux kernel and pre-installed packages 
<li>Apache 2 webserver \n -- php 7.0 with all the nescessary supporting packages
<li>The image- and document-handling packages GraphicsMagick, GMagick, GhostScript, DCraw, LibreOffice, Poppler-Utils (PdfToText), MediaInfo, WkHtmlToText, OpenCTM, PdfMiner, and ExifTool 
<li>[IF SELECTED with -f flag] The audio- and video-handling package ffmpeg (which has to be built), along with its numerous dependancies 
<li>The database server MySQL (or MariaDB, depending on which OS you are running)
<li>The current version of CollectiveAccess Providence 1 
<li>The current version of CollectiveAccess Pawtucket 2
</ul>
Beyond that, this script assumes the following: 
<ul><li>There is nothing installed on this server already
<li>That you are currently logged in as the user under which you want to install things 
<li>That you are running this script as sudo 
<li>That you are running this script in a terminal window, rather than at the command prompt (causes some text do disappear)
</ul>

<b>If any of this is not true, ABORT NOW or risk bricking your computer.</b>

<h2>Running This Script</h2>

To run this script, open a terminal and run the following two lines:
<table border=1>
<tr><th><code>git clone https://github.com/ChrisLitfin/install_ca
  sudo bash install_ca/install_ca.sh -f</code>
</table>

<h2>Operating System Compatibility</h2>

This Script has been tested successfully on the following Operating Systems and Architectures:
<ul>
  <li><b>Linux-based</b>
  <ul>
    <li>Debian and Debian-derived
    <ul>
      <li>Debian ("Vanilla")
      <ul>
        <li>Debian 8 jessie: i386, amd64
        <li>Debian 9 stretch: i386, amd64
      </ul>
      <li>Ubuntu
        <ul>
          <li>Ubuntu 16.04 LTS: i386, amd64
        </ul>
      <li>LinuxMint Debian Edition
        <ul>
          <li>LinuxMint Debian Edition 2 betsy: i386, amd64
        </ul>
      <li>Raspbian
        <ul>
          <li> Raspbian 9 stretch: armhf
        </ul>
      </ul>
    </ul>
  </ul>
 </ul>
 
Other Operating System/Architecture combinations may or may not work as well. Operating Systems not on this list will throw an "Unknown OS" error and abort. If you want to try something that is not on the list, see "Adding New Operating Systems" below. (Most architectures should work, provided that the appropriate packages are available.)
 
<b>The following Operating System/Architecture combinations are known not to work (reason in brackets):</b>
<ul>
  <li>Raspbioan 8 jessie: armhf (lack of a good source for php7-* packages, among others)
</ul>


<h2>Adding New Operating Systems</h2>
What operating system is being used will affect how the script runs, e. g. which repos are used, what package installer to use, etc. This script uses the getOSInfo() function to figure all that stuff out.
In order to determine what operating system is used, the function calls lsb_release -si to get the $OSdist (e.g. Debiabn, Ubuntu, etc.) and then lsb_release -sc to get the $OSname (e.g. jessie, stretch, etc.). (lsb_release is part of the Linux Standard Base and is included with most modern Linuxes.) 
The function then fires $OSdist and $OSname through a bunch of nested case statements to determine what options to set. The options are described below:
<table border=1>
  <caption>install_ca OS-Specific Options</caption>
  <tr><th>Option variable<th>Type<th>Description
  <tr><th>$use_dotdeb<th>boolean (1/0)<th>Adds the dotdeb repo, usually to get php7.0-* packages for older OSes.
  <tr><th>$use_debmm<th>boolean (1/0)<th>Adds the deb-multimedia repo, to get multimedia packages.
  <tr><th>$installString<th>String<th>Dtermines what to prefix the various "install" commands with (i.e. what package manager to use, and with what options.
</table>
    
If you want to add a new OS, run the lsb_release commands shown above and see what you get, then add to the case statements accordingly. <b>IMPORTANT:</b> Note that you MUST specify an $installString for each $OSdist, and that each case statement must have a * case that calls unknownOS so that thes script aborts if the OS is not on the list. A guide to working with bash case statements can be found here: <a href=http://tldp.org/LDP/Bash-Beginners-Guide/html/sect_07_03.html>tldp.org Using Case Statements - Bash</a>
