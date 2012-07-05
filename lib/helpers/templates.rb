require 'open-uri'
require 'tzinfo'
require 'helpers'
module Helper
  module Templates
    def post_contents post
      return "" if post.nil? or post.body.nil?
      markdown post.body
    end

    def time_display post
      return "" if post.nil? or post.created_at.nil?
      post_time = post.created_at.utc
      begin
        time_zone = TZInfo::Timezone.get(settings.timezone) 
        zone_time = time_zone.utc_to_local(post_time)
      rescue
        logger.info "Timezone Error (#{settings.timezone})!"
        zone_time = post_time
      end
      if Time.now.utc.to_i > post_time.to_i+(60*60*24)
        "<span class='header_time'>Created on #{zone_time.strftime("%B %d, %Y")}</span>"
      else
        "<span class='header_time'>Created at #{zone_time.strftime("%r")}</span>"
      end
    end

    def post_tags post
      unless $tags and $tags[:expires].to_i > Time.now.to_i-(5*60*1000)
        logger.info "tags: miss" 
        $tags = { :tags => (Tag.where( :post_id => post.id ).cache.map { |t| t.tag }).compact.sort.join(" "),
                  :expires => Time.now }
      else
        logger.debug "tags: hit"
      end
      return $tags[:tags]
    end

    def post_title post
      return "" if post.nil?
      post.title
    end

    def archive_link year, month=nil
      if month.nil?
        path = year.to_s
        name = path
      else
        path  = "#{year}/#{"%02d" % month}"
        name  = months[month.to_i-1].capitalize
      end
      return name if request.path_info =~ Regexp.new(Regexp.escape(path)+"(\/?)$")
      return "<a href='/#{path}'>#{name}</a>" 
    end

    def post_tag_string tags
      (tags.map { |t| t.name }).join(", ")
    end

    def archive_items
      unless $archive and $archive[:expires].to_i > Time.now.to_i-(5*60*1000) 
        logger.info "archive: miss"
        collection = Post.all.desc(:created_at).cache
        archive = {}
        # TODO: there has to be a better way
        collection.each do |item| 
          date = item.created_at
          archive[date.year] = {} unless archive.has_key? date.year
          archive[date.year][date.month] = [] unless archive[date.year].has_key? date.month
          archive[date.year][date.month].push item
        end
        $archive = { :archive => archive, :expires => Time.now }
      else
        logger.debug "archive: hit"
      end
      return $archive[:archive]
    end

    def archive_list archive=nil
      unless $markup and $markup[:expires].to_i > Time.now.to_i-(5*60*1000)
        logger.info "markup: miss"
        archive = archive_items if archive.nil?

        markup = ""
        markup << %{ <ul class="nav_list"> }

        archive.each_key do |year|
          markup << %{ <li class="nav_item"><b>#{archive_link(year)}</b></li> }
          markup << %{ <ul class="nav_sub_list"> }
          archive[year].each_key do |month|
            markup << %{ <li class="nav_item">#{ archive_link(year, month) }</li> }
            markup << %{ <ul class="nav_sub_list"> }
            archive[year][month].each do |item|
              markup << %{ <li class="nav_item">#{ post_link(item) }</li> }
            end
            markup << %{ </ul> }
            markup << %{ </li> }
          end
          markup << %{ </ul> }
          markup << %{ </li> }
        end
        markup << %{ </ul> }
        $markup = { :markup => markup, :expires => Time.now }
      else
        logger.debug "markup: hit"
      end
      return $markup[:markup]
    end

    def post_link post
      return "" if post.nil? or post.id.blank?
      "<a href='#{post.title_path}'>#{post.title}</a>"
    end
      
    def months
      %w{ january february march april may june july august september october november december }
    end

    def latest n=25
      unless $latest and $latest[:expires].to_i > Time.now.to_i-(5*60*1000) and $latest[:count] == n
        logger.info "latest: miss"
        #TODO: might be buggy when changing 'n'
        $latest = { :posts => Post.all.desc(:created_at).cache[0..n-1], :expires => Time.now, :count => n }
      else
        logger.debug "latest: hit"
      end
      return $latest[:posts]
    end

    def linkify_title title
      URI::encode title
    end

    def delinkify_title title
      URI::decode title
    end

    def set_title_from_status state, post
      if state == :preview 
        return post["title"]
      elsif post.nil? or post.title.blank?
        return settings.title
      else
        return post_title(post)
      end
    end

    def set_state_class_from_state state
      if state == :index
        return "post_index"
      else
        return "post_show"
      end
    end

    protected
    # TODO: there has to be a better way
    def collection_sort collection, date_key="created_at"
      (collection.sort_by { |item| item[date_key] })
    end
    def collection_rsort collection, date_key="created_at"
      collection_sort(collection, date_key).reverse
    end
  end
end
