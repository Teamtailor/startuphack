require 'sinatra/async'
require_relative 'trackr'

class App < Sinatra::Base
  register Sinatra::Async

  TRACKR = Trackr.new

  aget '/' do
    env = ENV['RACK_ENV']
    sites = TRACKR.sites
    sites_str = sites.map do |site|
      "<li><a href='/stats/#{site}'>#{site.to_s}</a></li>"
    end

    local_domain = env == "production" ? "startuphack.herokuapp.com" : "localhost:3000"

    body <<-BODY
      <html>
        <head>
          <script type="text/javascript">
            var _trackr_config_variables={domain:"#{local_domain}"};
            (function(){
              function loadTrackr() {
                window._sf_endpt=(new Date()).getTime();
                var e = document.createElement('script');
                e.setAttribute('language', 'javascript');
                e.setAttribute('type', 'text/javascript');
                e.setAttribute('src',"//#{local_domain}/trackr#{"-local" unless env == "production"}.js");
                document.body.appendChild(e);
              }
              var oldonload = window.onload;
              window.onload = (typeof window.onload != 'function') ?
                 loadTrackr : function() { oldonload(); loadTrackr(); };
            })();
          </script>
        </head>
        <body>
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
        </body>
      </html>
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
          Online right now: #{TRACKR.recent_visitors(site)}
        </li>
        <li>
          history: #{TRACKR.history(site)}
        </li>
      </ul>
    BODY
  end
end
