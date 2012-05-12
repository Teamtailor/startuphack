require 'uri'
require 'redis'

class Trackr
  def initialize(env = ENV['RACK_ENV'])
    if env == "production"
      uri = URI.parse(ENV["REDISTOGO_URL"])
      @redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
    else
      @redis = Redis.new
    end
  end

  def track!(site, uid)
    time = Time.now.to_i
    sanitize!(site)

    @redis.zadd site, time, uid

    expire_in = 60 * 60 # one hour
    @redis.setex site_history(site, interval(time)), expire_in, recent_visitors(site).size
    [site, uid, time]
  end

  def recent_visitors(site)
    min_score = Time.now.to_i - 6 # Just 6 seconds!!! ZOMG! REALTIME!
    max_score = Time.now.to_i

    @redis.zrangebyscore(site, min_score, max_score)
  end

  def history(site)
    keys = @redis.keys(site_history(site, "*"))
    values = @redis.mget(*keys)
    keys.map do |key|
      {key.split(":").last.to_i => values[keys.index(key)].to_i}
    end
  end

  private
  def site_history(site, time)
    "#{site}:history:#{time}"
  end

  def sanitize!(site)
    site.gsub!(".", "_")
  end

  def interval(time)
    time - (time % 5)
  end
end

