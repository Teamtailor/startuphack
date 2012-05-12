require 'sinatra/async'
require_relative 'trackr'
require 'json'

class App < Sinatra::Base
  register Sinatra::Async

  TRACKR = Trackr.new

  aget '/' do
  end

  aget '/track/:site/:uid' do
    site = params[:site]
    uid = params[:uid]
    url = params[:location]

    TRACKR.track!(site, uid, url)

    content_type 'image/gif'
    body ''
  end

  aget '/api/sites/:site' do
    site = params[:site]
    json_response = {
      :online_right_now => TRACKR.recent_visitors(site).size,
      :history => TRACKR.history(site),
      :top_urls => TRACKR.top_urls(site)
    }.to_json

    if callback = params.delete('callback')
      content_type :js
      response = "#{callback}(#{json_response})"
    else
      content_type :json
      response = json_response
    end
    body response
  end
end
