require 'sinatra/async'
require_relative 'trackr'

class App < Sinatra::Base
  register Sinatra::Async

  TRACKR = Trackr.new

  aget '/' do
    sites = TRACKR.sites
    sites_str = sites.map do |site|
      "<li><a href='/stats/#{site}'>#{site.to_s}</a></li>"
    end

    body <<-BODY
      <h1>Trackr</h1>
      <p>
        To track a user: /track/mynewsdesk_com/123
      </p>
      <p>
        To get stats: /stats/mynewsdesk_com
      </p>
      <h2>Current sites</h2>
      <ul>
        #{sites_str.join}
      </ul>
    BODY
  end

  aget '/track/:site/:uid' do
    site = params[:site]
    uid = params[:uid]

    site, uid, value = TRACKR.track!(site, uid)

    body "stored #{value} for user #{uid} in site #{site}"
  end

  aget '/stats/:site' do
    site = params[:site]

    body <<-BODY
      <h1>#{site}</h1>
      <ul>
        <li>
          Totals visitors (since last Redis restart): #{TRACKR.total_visitors(site)}
        </li>
        <li>
          Visitors last 5 minutes: #{TRACKR.recent_visitors(site)}
        </li>
      </ul>
    BODY
  end
end
