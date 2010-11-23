# Copyright 2010 The Googlyscript Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


class Googly

  # Although Googlyscript can run as an app or in a cascade, most installations
  # will use this {Middleware} configured with Googly.script().
  # @example config.ru
  #  require 'googlyscript'
  #  Googly.script '/myapp', '../src'
  #  use Googly::Middleware, '../public/index.html'
  
  class Middleware
    
    # @param (String) home_page File to serve at the root.  Handy for stand-alone projects.
    #   You can use a template, even in non-source folders, by using the url extension
    #   e.g. 'index.html' instead of the actual filename 'index.haml'.
    def initialize(app, home_page=nil)
      @app = app
      @server = Server.new(Googly.sources, home_page)
    end

    def call(env)
      status, headers, body = @server.call(env)
      return @app.call(env) if headers["X-Cascade"] == "pass"
      [status, headers, body]
    end

  end
  
end
