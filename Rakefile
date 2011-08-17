require 'rubygems'
require 'rake'
require 'echoe'
#Echoe.new(File.basename(File.dirname(__FILE__)))

App = "tmb"
Version = "0.0.89"

Echoe.new(App, Version) do |p|
   p.name    = App
   p.version = Version
   p.author  = "Justin Thibault"
   p.email   = "jvthibault@gmail.com"
   p.bin_files = ["tmb"]

   p.install_message = <<-eos

   \033[1m#{App}\033[0m is a utility to search for textmate bundles, download and install
   them, all via a convenient command line interface, much like rubygems.


   Usage:
   ======================================

   # Search for bundles containing the word 'webrat' in
   # the title, description, or author's name.

   \033[1m#{App} search webrat\033[0m


   # Search for bundles containing the word 'rspec' OR
   # 'cucumber' OR 'shoulda' in their title, description,
   # or author's name.

   \033[1m#{App} search rspec cucumber shoulda\033[0m


   # Install a bundle containing the word rspec in its
   # search fields.  If multiple matches exist, #{App}
   # will let you choose which version to install.

   \033[1m#{App} install rspec\033[0m


   # List all installed bundles

   \033[1m#{App} list\033[0m


   # Uninstall bundle matching 'json'.  If you type in a
   # fragment and there are multiple installed bundles that begin
   # with that fragment, #{App} will let you choose which version
   # you'd like to destroy

   \033[1m#{App} uninstall json\033[0m


   # Tell textmate (if it's open) to reload its bundle information,
   # and update menus & controls accordingly

   \033[1m#{App} reload\033[0m


   # Print this help information

   \033[1m#{App} help\033[0m

   eos

   p.summary = "#{App} - Textmate bundle utility: A utility to search, install, and uninstall textmate bundles from github"
   p.description = "#{App} provides a command line interface to manage your textmate bundles, allowing" +
   " you to search for new bundles on github, install them, and uninstall existing local bundles."
 end