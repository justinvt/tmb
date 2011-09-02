
module TM
  class Bundles

    @@search_file = File.join(TM::SettingsDirectory, TM::SearchDB)

    attr_accessor :response, :results, :search_url, :search_terms, :full_set

      def self.searchdb_file
        @@search_file
      end

      def self.searchdb?
        File.exists?(searchdb_file) && ( JSON.parse( File.read(@@search_file) ) rescue [] ).size > 0
      end

      def initialize(search_terms=nil)
        @search_terms = search_terms
        @full_set = nil
        @results = []
      end

      def search_db(new_entries=nil)
        FileUtils.mkdir TM::BundleDirectory unless File.exist?(TM::BundleDirectory)
        f = File.open(self.class.searchdb_file,File::RDWR|File::CREAT)
        file_contents = f.read
        if new_entries
          entries = file_contents.length < 2 ? [] : JSON.parse(f.read)
          all_entries = [new_entries, entries].flatten.uniq
          to_file = JSON.generate(all_entries)
          f.puts to_file
        else
           all_entries = file_contents.length < 2 ? [] : JSON.parse(f.read)
        end
        f.close
        return all_entries
      end

      def self.handle_connection_error(e, url)
        error         = e.class.name.split("::")
        exception     = error[-1]
        lib           = error[0]
        lib           = lib == exception ? "OpenURI"  : lib
        host          = URI.parse(url).host
        error_message =   case exception
                            when "SocketError" : socket_error(e,url)
                            when "HTTPError"   : http_error(e,url)
                          end
        puts error_message.
            gsub(/#URL/,url).
            gsub(/#LIB/,lib).
            gsub(/#MESSAGE/,e.message).
            gsub(/#EXCEPTION/,exception).
            gsub(/#HOST/,host)
        exit 0
      end

      def self.socket_error(e, url)
        <<-eos

          #LIB is raising a #EXCEPTION: \033[0m#{e.message}\033[0m

          Either \033[1m#HOST\033[0m is currently unavailable or your internet connection is down.

          (We were trying to access \033[1m#URL\033[0m)

        eos
      end

      def self.http_code_messages
        {
          "404" => "the page you're attempting to access doesn't exist"
        }
      end

      def self.http_error(e, url)
        <<-eos

          #LIB is raising an #EXCEPTION: \033[1m#MESSAGE\033[0m

          That means #{http_code_messages[e.message.match(/\d{3}/).to_s]}

          (We were trying to access \033[1m#URL\033[0m)

        eos
      end

      def search_description(terms=@search_terms)
        "Searching for \033[1m#{terms.to_a.join(', ')}\033[0m"
      end

      def put_search_description
        puts "\n" + search_description + "\n"
      end


      def short_result(result)
        {:description => result["description"], :repo => git_repo(result) }
      end

      def sample_response
        '{"repositories": [{"name": "haml", "username": "justin"}]}'
      end

      def get_search_pages(url, page_range=1)
        puts "Getting a list of repositories from Github...\nThis will take a while but should only happen once...ever"
        result_set =  []
        page_range.times do |i|
         page = i + 1
         full_url = url + "?start_page=#{page}"
         puts "Reading page #{full_url}"
         begin
            res = open(full_url).read
          rescue => e
            self.class.handle_connection_error(e,search_url)
          end
          json_res = JSON.parse(res)
          repos = json_res["repositories"] || []
          #puts repos.map{|r| r["name"]}.join(",")
          puts "#{repos.size} more repositories found, #{result_set.size} total #{i==page_range ? '' : '(still searching...)'}"
          if repos.size > 0
            result_set << repos
            result_set = result_set.flatten.uniq

          else
            puts "End of results"
            break
          end
        end
        result_set
      end

      def search(search_terms = @search_terms, options={})

        bundle_suffix = ["textmate"]
        bundle_identifier = /bundle|tmbundle|textmate/
        options[:additive] ||= true
        # Don't add tmbundle term if its already in the users search
        regex_terms = Regexp.new(search_terms.to_a.select{|s| s.length > 1 }.join("|"))
        actual_search_terms = search_terms.nil? ? bundle_suffix : [ search_terms ]
        formatted_terms = actual_search_terms.flatten.compact.uniq.join(' ')
        search_url="http://github.com/api/v2/json/repos/search/#{URI.escape(formatted_terms)}"
        #puts "Searching for #{formatted_terms}"
        if search_terms.nil? && @full_set.nil?
          #puts "Getting full set"
          @full_set = get_search_pages(search_url, 20)
          puts "#{@full_set.size} Repositories found"
          search_db(@full_set)
          @full_set.each_with_index do |r,i|
            @full_set[i]["search_terms"] = r.values_at("username", "name", "description").join
          end
          @results = @full_set
        else
         # puts "Searching for matching results for #{search_terms.to_a.join(',')}..."
          @results = @results.to_a.select{|r| r["search_terms"] =~  regex_terms}
        end
        @results = @results.uniq
        current_results = search_terms.nil? ? @full_set : @results
        return current_results.uniq
      end

      def search_local(terms)
        unless File.exist?(self.class.searchdb_file)
          f = File.open(self.class.searchdb_file,File::RDWR|File::CREAT)
          f.close
        end
        @results = @full_set =  JSON.parse( File.read(@@search_file) ) rescue []
        puts "#{@full_set.size} local results"
        @full_set.each_with_index do |r,i|
          @full_set[i]["search_terms"] = r.values_at("username", "name", "description").join
        end
        @search_terms = terms
        search(terms)
      end


      def display_results(res=nil)
        res ||= results
        to_display = res || search(search_terms)
        to_display.sort{|a,b| a["name"].downcase <=> b["name"].downcase }.map{|r| TM::Bundle.new(r).to_s }.join("\n\n")
      end

      def bash_install_script_from_repo(repo)
        <<-eos
          bundle_dir="/Library/Application Support/TextMate/Bundles"
          mkdir -p "$bundle_dir"
          file_name=$(echo -e #{repo} | grep -o -P "[-\w\.]+$")
          bundle_name=$(echo -e $file_name |  sed -E -e 's/\.[a-zA-Z0-9]+$//g' -e 's/\.tmbundle//g')
          dest=$bundle_dir/$bundle_name.tmbundle
          rm -Rf "$dest"
          git clone #{repo} "$dest"
          osascript -e 'tell app "TextMate" to reload bundles'
        eos
      end

      def install(repo)
        puts repo
        if repo.match(/^(http|git|https):.*\.git$/)
          matching_repo = TM::Bundle.new([], :repo => repo)
        elsif repo.match(/^(http|ftp|https):.*\.(zip|gz|tar.gz|bz2|tar.bz2)$/)
          matching_repo = TM::Bundle.new([], :repo => repo)
        else
          matching_repo = TM::Bundle.new(search(repo).first)
        end
        install_output = matching_repo.install
        puts install_output
      end

  end
end