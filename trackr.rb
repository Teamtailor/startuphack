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

  def track!(site, uid, location)
    time = Time.now.to_i
    sanitize!(site)

    @redis.zadd site, time, uid

    expire_in = 60 * 60 # one hour
    visitors = recent_visitors(site).size
    @redis.setex site_history(site, interval(time)), expire_in, visitors
    @redis.setex site_url(site, location), expire_in, visitors
    true
  end

  def recent_visitors(site)
    sanitize!(site)
    min_score = Time.now.to_i - 6 # Just 6 seconds!!! ZOMG! REALTIME!
    max_score = Time.now.to_i

    @redis.zrangebyscore(site, min_score, max_score)
  end

  def history(site)
    sanitize!(site)
    t1 = Time.now
    t1 = Time.new(t1.year, t1.month, t1.day, t1.hour - 1, t1.min, t1.sec - (t1.sec % 5)).to_i
    t2 = Time.now.to_i
    keys = []
    (t1..t2).step(5) do |key|
      keys << site_history(site, key)
    end
    values = @redis.mget(*keys)
    sort_result(keys, values)
  end

  def top_urls(site)
    sanitize!(site)
    keys = @redis.keys(site_url(site, "*"))
    puts "keys: #{keys.inspect}"
    values = @redis.mget(*keys)
    sort_result(keys, values)
  end

  private
  def sort_result(keys, values)
    keys.map{|key| key.split(":").last }.zip(values.map(&:to_i)).sort do |a, b|
      b.first <=> a.first
    end
  end

  def site_history(site, time)
    "#{site}:history:#{time}"
  end

  def site_url(site, url)
    "#{site}:url:#{url}"
  end

  def sanitize!(site)
    site.gsub!(".", "_")
  end

  def interval(time)
    time - (time % 5)
  end
end

