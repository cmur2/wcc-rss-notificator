wcc-rss-notificator
===================

This adds Atom feed support to [wcc](https://github.com/cmur2/wcc) encapsulated
in a separate gem.

Note: Currently there is only one feed for all users/recipients.

What you need to add to your conf.yml:

	conf:
	  [...]
	  # enable rss plugin
	  rss: {}
	
	recipients:
	  [...]
	  - me:
	    [...]
	    # write updates to Atom feed
	    - rss:
	        # wcc needs write permission on this file/directory:
	        #file: <cache.d>/atom.xml
	        # mandatory option! - this allows you to use different
	        # (or same) databases for each recipient
	        db_name: me
	        # wcc will keep the N newest entries in your feed
	        #num_keep: 1000
	        feed:
	          # mandatory option! - Note that this is *NOT* your feed's
	          # url or something, this should be just an unique identifier:
	          id: http://www.example.com/my-feed/
	          #title: Your cool feed
	          #subtitle: About things
	          #link: # this now should be the feed's url
	          #alternate_link: # this may be a websites url (favicon comes from here)
