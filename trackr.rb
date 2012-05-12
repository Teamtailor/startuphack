require 'uri'
require 'redis'

class Trackr
  # attr_accessor :redis, :site, :uid
  def initialize(env = ENV['RACK_ENV'])
    if env == "production"
      uri = URI.parse(ENV["REDISTOGO_URL"])
      @redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
    else
      @redis = Redis.new
    end
  end

  def sites
    @redis.keys "*"
  end

  def track!(site, uid)
    value = Time.now.to_i
    sanitize!(site)

    @redis.zadd site, value, uid
    [site, uid, value]
  end

  def total_visitors(site)
    @redis.zcard(site)
  end

  def recent_visitors(site)
    min_score = Time.now.to_i - (60 * 5) # 5 minutes ago
    max_score = Time.now.to_i

    @redis.zrangebyscore(site, min_score, max_score)
  end

  private
  def sanitize!(site)
    site.gsub!(".", "_")
  end
end
