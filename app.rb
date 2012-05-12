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

    site, uid, value = TRACKR.track!(site, uid)

    content_type 'text/gif'
    body ''
  end

  aget '/api/sites/:site' do
    site = params[:site]
    content_type :json
    json_response = {
      :online_right_now => TRACKR.recent_visitors(site).size,
      :history => TRACKR.history(site)
    }.to_json
    body json_response
  end
end
