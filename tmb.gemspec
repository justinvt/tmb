# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{tmb}
  s.version = "0.0.89"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Justin Thibault"]
  s.cert_chain = ["/Users/jvthibault/.gem/gem-public_cert.pem"]
  s.date = %q{2011-04-29}
  s.default_executable = %q{tmb}
  s.description = %q{tmb provides a command line interface to manage your textmate bundles, allowing you to search for new bundles on github, install them, and uninstall existing local bundles.}
  s.email = %q{jvthibault@gmail.com}
  s.executables = ["tmb"]
  s.extra_rdoc_files = ["CHANGELOG", "LICENSE", "README.md", "bin/tmb", "lib/tmb.rb", "lib/tmb/bundle.rb", "lib/tmb/bundles.rb", "lib/tmb/commands.rb"]
  s.files = ["CHANGELOG", "LICENSE", "README.md", "Rakefile", "bin/tmb", "lib/tmb.rb", "lib/tmb/bundle.rb", "lib/tmb/bundles.rb", "lib/tmb/commands.rb", "Manifest", "tmb.gemspec"]
  s.homepage = %q{http://tmb.github.com/tmb/}
  s.post_install_message = %q{
   [1mtmb[0m is a utility to search for textmate bundles, download and install
   them, all via a convenient command line interface, much like rubygems.


   Usage:
   ======================================

   # Search for bundles containing the word 'webrat' in
   # the title, description, or author's name.

   [1mtmb search webrat[0m


   # Search for bundles containing the word 'rspec' OR
   # 'cucumber' OR 'shoulda' in their title, description,
   # or author's name.

   [1mtmb search rspec cucumber shoulda[0m


   # Install a bundle containing the word rspec in its
   # search fields.  If multiple matches exist, tmb
   # will let you choose which version to install.

   [1mtmb install rspec[0m


   # List all installed bundles

   [1mtmb list[0m


   # Uninstall bundle matching 'json'.  If you type in a
   # fragment and there are multiple installed bundles that begin
   # with that fragment, tmb will let you choose which version
   # you'd like to destroy

   [1mtmb uninstall json[0m


   # Tell textmate (if it's open) to reload its bundle information,
   # and update menus & controls accordingly

   [1mtmb reload[0m


   # Print this help information

   [1mtmb help[0m

}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Tmb", "--main", "README.md"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{tmb}
  s.rubygems_version = %q{1.6.1}
  s.signing_key = %q{/Users/jvthibault/.gem/gem-private_key.pem}
  s.summary = %q{tmb - Textmate bundle utility: A utility to search, install, and uninstall textmate bundles from github}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
