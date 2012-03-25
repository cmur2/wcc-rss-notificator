
Gem::Specification.new do |s|
	s.name		= "wcc-rss-notificator"
	s.version	= "0.1.0"
	s.summary	= "RSS feed notificator plugin for wcc"
	s.author	= "Christian Nicolai"
	s.email		= "chrnicolai@gmail.com"
	s.homepage	= "https://github.com/cmur2/wcc-rss-notificator"
	s.rubyforge_project = "wcc-rss-notificator"
	
	s.files = [
		"assets/template.d/rss-content.html.erb",
		"assets/template.d/rss-title.plain.erb",
		"lib/wcc-rss-notificator.rb",
		"README.md"
	]
	
	s.require_paths = ["lib"]
end
