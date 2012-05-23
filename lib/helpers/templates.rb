require 'open-uri'
require 'helpers'
module HelpersTemplates
  include Ditty

  def post_contents post
    return "" if post.nil? or post.body.nil?
    markdown post.body
  end

  def time_display post
    return "" if post.nil? or post.created_at.nil?
    action = (post.created_at == post.updated_at ? "Created" : "Updated")
    mt = post.updated_at
    nt = Time.now
    if nt.to_i > mt.to_i+(60*60*24)
      "<span class='header_time'>#{action} on #{mt.strftime("%B %d, %Y")}</span>"
    else
      "<span class='header_time'>#{action} at #{mt.strftime("%r")}</span>"
    end
  end

  def post_tags post
    (Ditty::Tag.where( :post_id => post.id ).map { |t| t.tag }).compact.sort.join(" ")
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
    return "<a href='/archive/#{path}'>#{name}</a>" 
  end

  def archive_items
    collection = Ditty::Post.all(:order => :created_at.desc)
    archive = {}
    # TODO: there has to be a better way
    collection.each do |item| 
      date = item.created_at
      archive[date.year] = {} unless archive.has_key? date.year
      archive[date.year][date.month] = [] unless archive[date.year].has_key? date.month
      archive[date.year][date.month].push item
    end
    archive
  end

  def archive_nav_list 
    archive = archive_items
    markup = ""
    markup << %{ <ul class="nav_list"> }
    archive.each_key do |year|
      markup << %{ <li class="nav_item"><b>#{archive_link(year)}</b></li> }
      markup << %{ <ul class="nav_sub_list"> }
      archive[year].each_key do |month|
        markup << %{ <li class="nav_item">#{ archive_link(year, month) }</li> }
      end
      markup << %{ </ul> }
      markup << %{ </li> }
    end
    markup << %{ </ul> }
    markup
  end

  def archive_list archive=nil
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
    markup
  end

  def post_link post, use_title=false
    return "" if post.nil? or post.id.blank?
    link = if use_title
             linkify_title(post_title(post)) 
           else
             post.id.to_s
           end
    "<a href='/post/#{link}'>#{post_title(post)}</a>"
  end
    
  def months
    %w{ january february march april may june july august september october november december }
  end

  def latest n=25
    Ditty::Post.all(:order => :created_at.desc)[0..n-1]
  end

  def linkify_title title
    URI::encode title
  end

  def delinkify_title title
    URI::decode title
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
