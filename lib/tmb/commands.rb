module TM

  class Commands

    def self.commands
      self.methods - [ Class.methods, "commands", "run"].flatten
    end

    def self.run(args)
      FileUtils.mkdir_p TM::SettingsDirectory unless File.exist?(TM::SettingsDirectory)
      #`mkdir -p #{TM::SettingsDirectory}`
      `touch #{TM::Bundles.searchdb_file}`
      if args[0].nil?
        help
        return 
      end
      tm_command   = args[0].to_sym
      unless self.respond_to?(tm_command)
        puts "Bad command: #{tm_command}\n\nTMB only understands: #{self.commands.join(', ')}\n\n|  Args: #{args.inspect}"
        exit 1
      else
       # puts ["Running TMB", tm_command].join(": ")
        self.send(tm_command, args)
      end

    end

    def self.uninstall(args)
      results = TM::Bundle.select(args[1])
      if results.size > 1
        puts "\nYou are trying to uninstall multiple bundles.  Select the bundle you wish to remove: \n\n"
        results.each_with_index do |r,i|
          puts "#{(i+1)}) #{r}"
        end
        print "\n\nMake your selection: "
        selection = STDIN.gets.chomp
        result = results[selection.to_i - 1]
      elsif results.size == 1
        result = results.first
      else
        puts "There are no bundles matching #{args[1].bold}"
        remaining = TM::Bundle.installed_bundle_titles
        if remaining.size > 0
          puts "Here are the bundles installed to #{TM::BundleDirectory.bold}:\n\n"
          self.list
        else
          puts "The bundle directory appears to be completely empty."
        end
        exit 1
      end
      bundle_name = File.basename(result)
      bundle_title = bundle_name.gsub(/\.tmbundle$/,'').bold
      puts "\nThis will uninstall the #{bundle_title} bundle."
      puts "\nThis can't be undone, aside from reinstalling #{bundle_title} with\n\n    #{TM::App} install #{bundle_title}\n\n"
      print "Are you sure you want to continue? (Y/n): "
      confirm = STDIN.gets.chomp
      confirm_string = "Y"
      if confirm == confirm_string
        removed = TM::Bundle.uninstall(result)
        puts "#{bundle_title} uninstalled successfully." if removed
        remaining = TM::Bundle.installed_bundle_titles
        if remaining.size > 0
          puts "\nHere are the remaining bundles:\n\n"
          self.list
        else
          puts "There are now no remaining bundles."
        end
      else
        puts "\nExiting uninstall (we were looking for #{confirm_string.bold} as a response, and you typed #{confirm.bold})..."
        puts "The #{bundle_title} bundle remains active."
      end
    end

    def self.list(args=nil)
      TM::Bundle.installed.each do |bundle|
        puts File.basename(bundle).gsub(/\.tmbundle$/,'').ljust(40).bold + " (#{File.basename(bundle)})"
      end
      #TM::Bundle.list
    end

    def self.search_remote(args)
      searcher     = TM::Bundles.new
      search_terms = args[1..-1]
      searcher.search
      search_terms.to_a.each{|term| searcher.search(term) }
      puts "\n" + searcher.search_description(search_terms) + "\n\n" + searcher.display_results + "\n\n"
    end

    def self.search_local(args)
      explain = <<-eos

   Searching your local database of textmate bundles.
   To update your listing of bundles do:

     #{"tmb updatedb".bold}

   or to search remote listings & update your local listing:

     #{"tmb search_remote <search terms>".bold}


eos


      puts explain
      searcher     = TM::Bundles.new
      search_terms = args[1..-1]
      searcher.search_local(search_terms)
      puts "\n" + searcher.search_description(search_terms) + "\n\n" + searcher.display_results + "\n\n"
    end

    def self.updatedb(args=nil)
      args ||= ["test"]
      self.search_remote(args)
    end

    def self.search(args)
      TM::Bundles.searchdb? ? self.search_local(args) : self.search_remote(args)
    end

    def self.local(args=nil)
      puts File.read(TM::Bundles.searchdb_file)
    end
    
    def self.update(args)
      bundle_name = args[1]
      repo = TM::Bundle.db[bundle_name]["url"] rescue nil
      if repo.nil?
        puts "OOPS!!!!  There is no record of installing #{bundle_name}, so updating won't work at this point.\n\n"
        puts "Running a normal install instead and you may overwrite the existing version if we find one..."
        self.install(args)
      else
        TM::Bundle.new( nil, :repo => repo, :bundle_name => bundle_name ).install(false)
      end
    end

    def self.install(args)
      if args[1] =~ /^(https|git):\S*\.git$/
        TM::Bundle.new( {}, :repo => args[1] ).install
        exit 0
      end
      searcher     = TM::Bundles.new
      search_terms = args[1..-1]
      updatedb unless TM::Bundles.searchdb?
      results = searcher.search_local(args[1])
      if results.size == 0
        puts "No matches found"
      elsif results.size == 1
        TM::Bundle.new(results.first).install
      else
        puts "\nYour installation attempt found multiple bundles.  Which of the following repositories would you like to install?\n\n"
        bundles = results.map{|r| TM::Bundle.new(r)}.sort{|a,b| b.popularity <=> a.popularity }
        bundles.each_with_index do |b,i|
          puts b.as_selection(i) + (i==0 ? " (default)" : "").bold
        end
        print "\nMake your selection (hit enter to choose default #{bundles.first.name.bold}): "
        selection = STDIN.gets.chomp
        selection = 1 if selection.nil? or selection == ""
        result = results[selection.to_i - 1]
        puts "\nYou chose #{selection}: #{result['name']}...\n\n"
        bundle = TM::Bundle.new(result)
        bundle.install
        puts "Bundle installed to #{bundle.destination}"
      end
    end

    def self.reload(args=nil)
      IO.popen("osascript -e 'tell app \"TextMate\" to reload bundles'").read
    end

    def self.info(args=nil)
      puts TM::Bundle.info
    end

    def self.help(args=nil)
      puts TM::Help
    end

  end

end


