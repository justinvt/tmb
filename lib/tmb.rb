require 'rubygems'
require 'json'
require 'open-uri'
require 'uri'
require 'yaml'

module TMB

  ROOT = File.expand_path( File.join( File.dirname(__FILE__), ".."))

  class << self

    def require_lib(*paths)
      paths.each do |path|
        path = File.join([ ROOT, "lib", "tmb", path.to_s + ".rb" ].flatten)
        require path
      end
    end

  end

end

TMB.require_lib(:bundle, :bundles, :commands)