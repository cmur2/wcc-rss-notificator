wcc-rss-notificator
===================

This adds Atom feed support to [wcc](https://github.com/cmur2/wcc) encapsuled
in a separate gem.

Note: Currently there is only one feed for all users/recipients.

What you need to add to your conf.yml:

	conf:
	  [...]
	  # feed of all entries
	  rss:
	    # mandatory option - Note that this is *NOT* your feed's
	    # url or something, this should be just an unique identifier:
	    feed_id: http://www.example.com/my-feed/
	    # optional options
	    #feed_link: # this now should be the feed's url
	    #feed_title: Your cool feed
	    #feed_subtitle: About things
	    # wcc need write permission on this file/directory:
	    #file: <cache.d>/atom.xml
	    # wcc will keep the N newest entries in your feed
	    #num_keep: 1000
	
	recipients:
	  [...]
	  - me:
	    [...]
	    # write updates to Atom feed
	    - rss
