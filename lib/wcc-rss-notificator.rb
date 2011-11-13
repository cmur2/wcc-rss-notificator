
require 'rss/maker'
require 'socket' # only for getting hostname
require 'yaml'

class RSSNotificator
	@@tpl = {}
	@@shutdown_hooks = []
	
	# TODO: can we hook into --clean?
	
	def initialize(opts)
		@dirty = false
		if opts.is_a?(Hash)
			@file = opts['file'] || WCC::Conf.file("atom.xml")
			@db_name = opts['db_name']
			@num_keep = opts['num_keep'] || 1000
			@feed = {}
			if opts['feed'].is_a?(Hash)
				@feed = {
					:title => opts['feed']['title'] || "wcc Updates Feed - #{Socket.gethostname}",
					:subtitle => opts['feed']['subtitle'] || "The newest changes to your watched sites.",
					:link => opts['feed']['link'],
					:alt_link => opts['feed']['alternate_link'],
					:id => opts['feed']['id']
				}
			end
			if @feed[:id].nil?
				raise ArgumentError, "Missing atom feed ID!"
			end
			if @db_name.nil?
				raise ArgumentError, "Missing db name for atom feed!"
			end
		else
			raise ArgumentError, "No options given for 'rss:' way of a recipient! Need at least db name and feed id."
		end
		@@shutdown_hooks << self
	end
	
	def get_feeddb
		if @feeddb.nil?
			feeddb_file = WCC::Conf.file("feed-db-#{@db_name}.yml")
			WCC.logger.debug "Loading feed-db '#{@db_name}' from file '#{feeddb_file}'"
			if not File.exists?(feeddb_file)
				WCC.logger.warn "Feed-db '#{@db_name}' does not exist, will create it on save in '#{feeddb_file}'"
				@feeddb = {'feed' => []}
			else
				# may be false if file is empty
				@feeddb = YAML.load_file(feeddb_file)
				if not @feeddb.is_a?(Hash)
					WCC.logger.warn "Feed-db '#{@db_name}' is corrupt, will overwrite it on save"
					@feeddb = {'feed' => []}
				end
			end
		end
		@feeddb
	end
	
	def notify!(data)
		title = self.class.get_tpl(:title, 'rss-title.plain.erb').result(binding)
		# remove trailing whitespace introduced by template
		title.strip!
		content = self.class.get_tpl(:content, 'rss-content.html.erb').result(binding)
		id = "#{@feed['id']}item/#{Time.now.to_f}"
		
		# append entries to class variable (not thread safe)
		@dirty = true
		feed = get_feeddb['feed']
		feed.insert 0, {
			'title' => title,
			#'description' => '', # summary
			'content' => content,
			'link' => data.site.uri.to_s,
			'id' => id,
			'updated' => Time.now.to_s
		}
	end
	
	def shut_down
		return unless @dirty
		
		WCC.logger.debug "Writing feed-db '#{@db_name}' to file"
		
		feeddb_file = WCC::Conf.file("feed-db-#{@db_name}.yml")
		feeddb = get_feeddb
		# auto-purge
		feeddb['feed'] = feeddb['feed'].slice(0, @num_keep)
		File.open(feeddb_file, 'w+') do |f| YAML.dump(feeddb, f) end
		
		WCC.logger.info "Generating feed '#{@file}'..."
		
		content = RSS::Maker.make('atom') do |m|
			m.channel.title = @feed[:title]
			m.channel.subtitle = @feed[:subtitle]
			m.channel.author = "web change checker (aka wcc) #{WCC::VERSION}"
			if not @feed[:link].nil?
				m.channel.links.new_link do |li|
					li.rel = "self"
					li.type = "application/atom+xml"
					li.href = @feed[:link]
				end
			end
			if not @feed[:alternate_link].nil?
				m.channel.links.new_link do |li|
					li.rel = "alternate"
					li.type = "text/html"
					li.href = @feed[:alternate_link]
				end
			end
			m.channel.id = @feed[:id]
			m.channel.updated = Time.now.to_s
			m.items.do_sort = true # sort items by date
			
			# feeddb-hash to atom
			feeddb['feed'].each do |e|
				m.items.new_item do |i|
					i.title = e['title']
					#i.description = e['description']
					i.content.content = e['content']
					i.content.type = "html"
					i.author = "wcc"
					if not e['link'].nil?
						i.links.new_link do |li|
							li.rel = "alternate"
							li.type = "text/html"
							li.href = e['link']
						end
					end
					i.id = e['id']
					i.updated = e['updated']
				end
			end
		end
		
		File.open(@file, 'w+') do |f| f.write(content.to_s) end
	end
	
	def self.parse_conf(conf); {} end
	
	def self.shut_down
		@@shutdown_hooks.each do |s| s.shut_down end
	end

	def self.get_tpl(id, name)
		if @@tpl[id].nil?
			@@tpl[id] = WCC::Prog.load_template(name)
			if @@tpl[id].nil?
				src_path = Pathname.new(__FILE__) + "../../assets/template.d/#{name}"
				t = File.open(src_path, 'r') { |f| f.read }
				WCC::Prog.save_template(name, t)
				# retry load
				@@tpl[id] = WCC::Prog.load_template(name)
			end
			if @@tpl[id].nil?
				@@tpl[id] = ERB.new("ERROR LOADING TEMPLATE '#{name}'!", 0, "<>")
			end
		end
		@@tpl[id]
	end
end

WCC::Notificators.map "rss", RSSNotificator
