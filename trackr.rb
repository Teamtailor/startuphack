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
    time = Time.now.to_i
    sanitize!(site)

    @redis.zadd site, time, uid
    @redis.zadd site_history(site), interval(time), recent_visitors(site).size
    [site, uid, time]
  end

  def total_visitors(site)
    @redis.zcard(site)
  end

  def recent_visitors(site)
    min_score = Time.now.to_i - 6 # Just 6 seconds!!! ZOMG! REALTIME!
    max_score = Time.now.to_i

    @redis.zrangebyscore(site, min_score, max_score)
  end

  private
  def site_history(site)
    site + ":history"
  end

  def sanitize!(site)
    site.gsub!(".", "_")
  end

  def interval(time)
    time - (time % 5)
  end
end
