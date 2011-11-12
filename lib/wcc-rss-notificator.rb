
require 'rss/maker'
require 'socket' # only for getting hostname
require 'yaml'

class RSSNotificator
	@@feeddb = nil
	@@tpl = {}
	
	# TODO: can we hook into --clean?
	
	def initialize
		# TODO: maybe differentiate by file/html? by recipient
	end
	
	def notify!(data)
		title = self.class.get_tpl(:title, 'rss-title.plain.erb').result(binding)
		content = self.class.get_tpl(:content, 'rss-content.html.erb').result(binding)
		id = "#{WCC::Conf[:rss_id]}item/#{Time.now.to_f}"
		
		# append entries to class variable (not thread safe)
		feed = self.class.get_feeddb['feed']
		feed.insert 0, {
			'title' => title,
			#'description' => '', # summary
			'content' => content,
			'link' => data.site.uri.to_s,
			'id' => id,
			'updated' => Time.now.to_s
		}
	end
	
	def self.parse_conf(conf)
		if conf.is_a?(Hash)
			if conf['feed_id'].nil?
				WCC.logger.fatal "Missing rss feed ID!"
				return { :rss_id => nil }
			else
				return {
					:rss_title => conf['feed_title'] || "wcc Updates Feed - #{Socket.gethostname}",
					:rss_subtitle => conf['feed_subtitle'] || "The newest changes to your watched sites.",
					:rss_link => conf['feed_link'],
					:rss_id => conf['feed_id'],
					:rss_file => conf['file'] || WCC::Conf.file("atom.xml"),
					:rss_num_keep => conf['num_keep'] || 1000
				}
			end
		end
		# no defaults
		{}
	end
	
	def self.shut_down
		WCC.logger.info "Write feed-db to file"
		
		feeddb_file = WCC::Conf.file('feed-db.yml')
		feeddb = get_feeddb
		# auto-purge
		feeddb['feed'] = feeddb['feed'].slice(0, WCC::Conf[:rss_num_keep])
		File.open(feeddb_file, 'w+') do |f| YAML.dump(feeddb, f) end
		
		WCC.logger.info "Generate the feed"
		
		content = RSS::Maker.make('atom') do |m|
			m.channel.title = WCC::Conf[:rss_title]
			m.channel.subtitle = WCC::Conf[:rss_subtitle]
			m.channel.author = "web change checker (aka wcc) #{WCC::VERSION}"
			if not WCC::Conf[:rss_link].nil?
				m.channel.links.new_link do |li|
					li.rel = "self"
					li.type = "application/atom+xml"
					li.href = WCC::Conf[:rss_link]
				end
			end
			m.channel.id = WCC::Conf[:rss_id]
			m.channel.updated = Time.now.to_s
			m.items.do_sort = true # sort items by date
			
			# feeddb-hash to atom
			feeddb['feed'].each do |e|
				m.items.new_item do |i|
					i.title = e['title']
					#i.description = e['description']
					i.content.content = e['content']
					i.content.type = "html"
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
		
		File.open(WCC::Conf[:rss_file], 'w+') do |f| f.write(content.to_s) end
	end
	
	def self.get_feeddb
		if @@feeddb.nil?
			feeddb_file = WCC::Conf.file('feed-db.yml')
			if not File.exists?(feeddb_file)
				WCC.logger.warn "Feed-db file not found, will create one on save."
				@@feeddb = {'feed' => []}
			else
				# may be false if file is empty
				@@feeddb = YAML.load_file(feeddb_file)
				if not @@feeddb.is_a?(Hash)
					WCC.logger.warn "Feed-db is corrupt, will overwrite it on save."
					@@feeddb = {'feed' => []}
				end
			end
		end
		@@feeddb
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
