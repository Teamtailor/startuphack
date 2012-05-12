require 'sinatra/async'

class App < Sinatra::Base
  register Sinatra::Async

  aget '/' do
    body "hello async"
  end

end