module JekyllFeed
  class FeedConfig
    attr_accessor :name # so far unused - just for identification
    attr_accessor :path
    attr_accessor :filter
  end

  class Generator < Jekyll::Generator
    safe true
    priority :lowest

    # Main plugin action, called by Jekyll-core
    def generate(site)
      @site = site
      feed_configs.each do |feed_config|
        next if file_exists?(feed_config.path)
        @site.pages << content_for_file(feed_config, feed_source_path)
      end
    end

    private

    # Matches all whitespace that follows
    #   1. A '>', which closes an XML tag or
    #   2. A '}', which closes a Liquid tag
    # We will strip all of this whitespace to minify the template
    MINIFY_REGEX = %r!(?<=>|})\s+!

    # Path to feed from config, or feed.xml for default
    def feed_configs
      return ["feed.xml"] unless @site.config["feeds"]

      feeds = []
      @site.config["feeds"].each do |name, config|
        next unless config["path"]

        feed = FeedConfig.new
        feed.path = config["path"]
        
        if config["filter"]
          feed.filter = config["filter"]
        end

        feeds << feed
      end

      feeds
    end

    # Path to feed.xml template file
    def feed_source_path
      File.expand_path "./feed.xml", File.dirname(__FILE__)
    end

    # Checks if a file already exists in the site source
    def file_exists?(file_path)
      if @site.respond_to?(:in_source_dir)
        File.exist? @site.in_source_dir(file_path)
      else
        File.exist? Jekyll.sanitized_path(@site.source, file_path)
      end
    end

    # Generates contents for a file
    def content_for_file(feed_config, file_source_path)
      file = PageWithoutAFile.new(@site, File.dirname(__FILE__), "", feed_config.path)
      file.content = File.read(file_source_path).gsub(MINIFY_REGEX, "")
      file.data["layout"] = nil
      file.data["sitemap"] = false
      file.data["xsl"] = file_exists?("feed.xslt.xml")
      file.data["post_filter"] = feed_config.filter
      file.output
      file
    end
  end
end
