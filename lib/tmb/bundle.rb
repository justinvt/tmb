require 'fileutils'
module TM
  
  include FileUtils

  TextWrap = 78
  IndentSpacing = 10
  Indent    = (" " * IndentSpacing)
  Justify = 15
  Delimiter = ": "
  BundleListPrefix = "  * "
  BaseBundleDirectory = "/Library/Application Support/TextMate/Bundles"
  UserBundleDirectory = "#{ENV['HOME']}/Library/Application Support/TextMate/Bundles"
  `mkdir -p "#{TM::UserBundleDirectory}"`
  BundleDirectory = ( File.exist?(BaseBundleDirectory) && Dir.entries(BaseBundleDirectory).size >  Dir.entries(UserBundleDirectory).size ) ? BaseBundleDirectory : UserBundleDirectory
  SettingsDirectory = "#{ENV['HOME']}/.tmb"
  App = File.basename File.dirname(__FILE__)
  DB = ".tmbdb"
  SearchDB = ".searchdb"

  Help = <<-eos

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
    
  # Update bundle named 'json' if we can find it in your installation records.
  # If we can't find a record, we will attempt to run the normal installation routine
  # for the bundle name you entered.  If #{App} has degenerate records, you will still
  # have the option to overwrite the existing version during the normal install process.

  \033[1m#{App} update json\033[0m


  # Tell textmate (if it's open) to reload its bundle information,
  # and update menus & controls accordingly

  \033[1m#{App} reload\033[0m


  # Print this help information

  \033[1m#{App} help\033[0m



  eos

end


class String

  def indent(indent=TM::Indent)
    indent + self
  end

  def text_wrap(width=TM::TextWrap, indent=TM::Indent)
     self.gsub /(.{1,#{width}})(\s+|\Z)/, "\\1\n".indent(indent)
   end

  def bold
    "\033[1m" + self + "\033[0m"
  end

end

module TM

  class Bundle


    attr_accessor :result, :repository, :install_output, :before_hooks, :output

    def self.before(instance, hook, method, args={})
      instance.before_hooks[hook] = {:method => method, :args => args}
    end

    def before(hook, method, args=nil)
      self.before_hooks[hook] ||= {}
      self.before_hooks[hook] = { :method => method, :args => args }
    end

    def run_before(method)
      self.send(self.before_hooks[method][:method], self.before_hooks[method][:args]) if self.before_hooks[method]
    end

    def initialize(result=nil, options={})
      if result.nil?
        @repository = options[:repo]
        @result = {
          "name" => self.class.name_from_repo(@repository), 
          "bundle_name" => options[:bundle_name],
          "url" => @repository 
        }
      else
        @before_hooks =      @result     = result
        @repository = git_repo
      end
      #before(:git_install_script, :update_db)
    end

    def self.installed
      Dir.glob("#{BundleDirectory}/*.tmbundle").sort{|a,b| a.downcase <=> b.downcase }
    end

    def self.db_filename
      File.join(SettingsDirectory, DB)
    end
    
    def self.existing_installdb
      ( YAML.load File.read( self.db_filename ) rescue nil ) || {}
    end

    def self.db(settings=nil)
      #puts "with settings...#{settings.inspect}"
      if !File.exist?(db_filename)
        puts "DB doesn't exist (#{db_filename}).  Skipping addition of bundle to install db."
        return 
      end
      f = File.open(db_filename,File::RDWR|File::CREAT)
      unless settings.nil? or !( settings.class.name =~ /^Hash/ )
        parsed = settings.merge self.existing_installdb
        f.puts YAML::dump( parsed )
      end
      db_content = f.read
      f.close
      self.existing_installdb
    end

    def self.info
      File.read(db_filename)
    end
    
    def self.installed_bundle_filenames
      installed.map do |b|
        File.basename(b)
      end
    end
    
      def self.installed_bundle_titles
      installed.map do |b|
        TM::BundleListPrefix + File.basename(b).gsub(/\.tmbundle$/,'')
      end
    end

    def self.list
      installed.each do |b|
        puts  TM::BundleListPrefix + File.basename(b)
      end
    end

    def self.select(bundle)
      installed.select{|b| b =~ Regexp.new(bundle + ".*\.tmbundle$") }
    end

    def self.uninstall(bundle)
      if bundle.nil? || bundle == ""
        puts "We couldn't find an appropriate bundle to uninstall...Exiting"
        return 
      end
      bundle_dir = File.basename(bundle)
      #{}` rm -Rf #{ File.join(BundleDirectory, bundle_dir) }`
      FileUtils.rm_r File.join(BundleDirectory, bundle_dir)
    end

    def short_result
      {:description => result["description"], :repo => repository }
    end
    
    def self.name_from_repo(repository_url)
      repository_url.scan(/(\w\-0-9)\.git$/)
    end

    def name
      result["name"] || repository.scan(/(\w\-0-9)\.git$/)
    end

    def bundle_name
      result["bundle_name"] || name.gsub("tmbundle",'').gsub(/^[[:punct:]]+|[[:punct:]]+$/,'')
    end

    def git_repo
       "https://github.com/#{@result["username"]}/#{@result["name"]}.git"
    end

    def display_key(key, options={})
      defaults = {:ljust => Justify, :rjust => Justify, :delimiter => Delimiter, :key_prefix => "", :key_suffix => ""}
      options = defaults.merge options

      if options[:bold_key]
        options[:key_prefix] = "\033[1m" + options[:key_prefix]
        options[:key_suffix] = options[:key_suffix] +"\033[0m"
      end
      if options[:title].nil? || options[:title].strip.length == 0
        options[:title] = ""
        options[:delimiter] = ""#(" " * options[:delimiter].length)
        options[:ljust] = 0
      end
      options[:title] ||= key.to_s
      options[:key_prefix] + (options[:title].capitalize + options[:delimiter]).ljust(options[:ljust]) + options[:key_suffix]
    end

    def display_keypair(key, options={})
      defaults = {:title => key.to_s, :ljust => Justify, :rjust => Justify, :delimiter => Delimiter, :key_prefix => "", :key_suffix => "", :value_prefix => "", :value_suffix => ""}
      options = defaults.merge(options)
      if options[:bold]
        options[:bold_value] ||= true
        options[:bold_key] ||= true
      end
      if options[:bold_value]
        options[:value_prefix] = "\033[1m" + options[:value_prefix]
        options[:value_suffix] = options[:value_suffix] +"\033[0m"
      end
      [
        display_key(options[:title], options),
        options[:value_prefix] + ((options[:value] || (key.is_a?(Symbol) && self.methods.include?(key.to_s)) ? self.send(key) : @result[key.to_s]).to_s) + options[:value_suffix]
      ].compact.reject{|s| s.strip == "" }.join
    end

    def display_value(key, options={})
      display_keypair(key, options)
    end

    def extended_display(key, options={})
      #options[:indent] ||= true
      ed = display_value(key, options).to_s
      unless options[:indent] == false
        ed = ed.indent
      end
      if options[:wrap]
        ed = ed.text_wrap
      end
      if options[:newline]
        ed = ("\n" * options[:newline]) + ed
      end
      ed
    end

    def stats
      "\n" + [
        display_value(:followers, :ljust => Justify ),
        display_value(:forks, :ljust => Justify ),
        display_value(:watchers, :ljust => Justify )
      ].map{|v| v.indent(" " * (IndentSpacing + Justify))}.join("\n")
    end

    def popularity
      result["watchers"].to_i || 0
    end

    def short_stats
      "(" + ["followers", "forks", "watchers"].map{|s| result[s.to_s].to_s + " " + s.to_s}.join(", ") + ")"
    end

    def as_selection(index)
       "#{(index + 1).to_s}) #{git_repo.ljust(60)} \033[1m#{short_stats}\033[0m"
    end

    def display_map
      [
        {:v=> "name", :bold => true, :indent => true, :title => "", :value_prefix => "\e[1;32m"},
        {:v => "username", :title => "Author", :bold_value => true, :newline => 1},
        {:v => "homepage"},
        {:v => :repository, :bold_value => true},
        {:v => :stats, :delimiter => "",  :title => ""},
        {:v => "created_at", :newline => 1},
        {:v=> "description", :indent => false, :newline => 2, :title => "", :wrap => true}
        ]
    end

    def to_s
      display_map.map{|d| extended_display(d.delete(:v), d) }.join("\n") + "\n"
    end

    def destination
      File.join(BundleDirectory, "#{bundle_name}.tmbundle")
    end

    def common_install_script
      <<-eos
        bundle_dir="#{BundleDirectory}"
        mkdir -p "$bundle_dir"
        file_name=$(echo -e #{@repository} | grep -o -P "[-\w\.]+$")
        bundle_name=$(echo -e $file_name |  sed -E -e 's/\.[a-zA-Z0-9]+$//g' -e 's/\.tmbundle//g')
        dest="#{destination}"
        rm -Rf "$dest"
      eos
    end

    def git_install_script
      <<-eos
        #{common_install_script}
        git clone #{@repository} "$dest"
      eos
    end

    def bundle_reload_script
      "osascript -e 'tell app \"TextMate\" to reload bundles'"
    end

    def smart_extract_script(archive)
      <<-eos
        arch=#{archive}
        if [ -f $arch ]; then
            case $arch in
                *.tar.bz2)  tar -jxvf $arch        ;;
                *.tar.gz)   tar -zxvf $arch        ;;
                *.bz2)      bunzip2 $arch          ;;
                *.dmg)      hdiutil mount $arch    ;;
                *.gz)       gunzip $arch           ;;
                *.tar)      tar -xvf $arch         ;;
                *.tbz2)     tar -jxvf $arch        ;;
                *.tgz)      tar -zxvf $arch        ;;
                *.zip)      unzip $arch            ;;
                *.Z)        uncompress $arch       ;;
                *)          echo "'$arch' cannot be extracted/mounted via smartextract()" ;;
            esac
        else
            echo "'$arch' is not a valid file"
        fi
      eos
    end

    def archive_install_script
      <<-eos
        #{common_install_script}
        cd $bundle_dir
        if [[ -n $bundle_name ]]
        then
          rm -R "$bundle_dir/$bundle_name"*
        fi
        curl -o "$bundle_dir/$file_name" $1
        #{ smart_extract_script('$bundle_dir/$file_name')}
        bundle=$(find $bundle_dir/$bundle_name | grep -P "tmbundle$")
        if [[ -n $bundle ]]
        then
          cp -R $bundle $bundle_dir
        fi
        non_bundles=$(find $bundle_dir -d 1 | grep -v -P "tmbundle$|^\.")
        echo $non_bundles | xargs -Ixxx rm -Rf "xxx"
        cd $current
        osascript -e 'tell app "TextMate" to reload bundles'
      eos
    end

    def git_repo?
      File.exists?(File.join(destination,".git"))
    end

    def hash(digester="sha1")
      if git_repo?
        master_file = File.join(destination,".git","refs","heads","master")
        begin
          op = File.read(master_file)
        rescue => e
          puts "An error occurred while attempting to read #{master_file}...skipping\n   #{e.message}"
          `ls "#{ File.dirname(master_file) }"`
          op = ""
        end
      else
        op = IO.popen("cat `ls -F #{destination} | grep -v -E '\/$'` | #{digester} | tr '\n' ''").read
      end
      op.strip
    end

    def db_hash
      { bundle_name => {"url" => repository, "dir" => destination, "installed" => Time.now.to_s, "sha1" => hash}}
    end

    def update_db
      puts "Updating install db"
      self.class.db(db_hash)
    end

    def run_script(method)
      @output = IO.popen(self.send(method)).read
    end

    def bundle_exists?
      File.exists?(destination)
    end

    def install(prompt_on_reinstall=true)
      if bundle_exists? && prompt_on_reinstall
        puts "That bundle already appears to be installed at #{destination}.\n\nReinstall? [Yn]"
        answer = STDIN.gets.chomp
        exit if answer == "n"
      end
      puts "#{prompt_on_reinstall ? 'Installing' : 'Updating bundle'} from #{@repository}"
      run_script(:git_install_script)
      puts "Bundle installed to #{destination}.  \n\nReloading bundles..."
      run_script(:bundle_reload_script)
      puts "All done!"
      update_db
    end

  end
end

