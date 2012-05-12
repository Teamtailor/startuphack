require 'sinatra/async'
require 'uri'
require 'redis'

class App < Sinatra::Base
  register Sinatra::Async

  if ENV['RACK_ENV'] == "production"
    uri = URI.parse(ENV["REDISTOGO_URL"])
    REDIS = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
  else
    REDIS = Redis.new
  end

  aget '/' do
    body <<-BODY
      <h1>Trackr</h1>
      <p>
        To track a user: /track/mynewsdesk_com/123
      </p>
      <p>
        To get stats: /stats/mynewsdesk_com
      </p>
    BODY
  end

  aget '/track/:site/:uid' do
    time = Time.now
    site = params[:site].gsub(".", "_")
    uid = params[:uid]

    REDIS.zadd site, time.to_i, uid
    body "stored #{time.to_i} for user #{uid} in site #{site}"
  end

  aget '/stats/:site' do
    site = params[:site]
    min_score = Time.now.to_i - (60 * 5) # 5 minutes ago
    max_score = Time.now.to_i

    total_visitors = REDIS.zcard(site)
    recent_visitors = REDIS.zrangebyscore(site, min_score, max_score)

    body <<-BODY
      <h1>#{site}</h1>
      <ul>
        <li>
          Totals visitors (since last Redis restart): #{total_visitors}
        </li>
        <li>
          Visitors last 5 minutes: #{recent_visitors}
        </li>
      </ul>
    BODY
  end
end
