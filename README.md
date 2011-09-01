Installation & usage
----------------------------

<pre>
<code>
gem install tmb
tmb search javascript
tmb install javascript-jquery // (or some other result you found from the search - we'll let you pick if there are name conflicts)
</code>
</pre>

Note: If you get an error about some file or dir not existing the first time you use this gem, firstly let me know about it, but is probably because you've never installed a textmate bundle before and you dont have a bundle directory.  It is also possible that we have't created the tmb db files during installation.  On OSX, open up the terminal and run the following to try to work around those problems temporarily...

<pre>
<code>
mkdir -p "~/Library/Application Support/Textmate/Bundles"
mkdir -p ~/.tmb
touch ~/.tmb/.searchdb
</code>
</pre>

Things should run smoothly at that point.  Like I said, let me know if things break for you...I've been trying to fix that bug for a while now.