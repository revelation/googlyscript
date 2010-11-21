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
  
  # @private
  class TemplateNotFoundError < StandardError
  end

  # @private
  class TemplateCallStackTooDeepError < StandardError
  end
  
  # A Googly::Template instance is the context in which Ruby templates are rendered.
  # It inherits everything from Rack::Request and supplies a response instance
  # you can use for redirects, cookies, and other controller actions.
  class Template < Rack::Request
    
    def initialize(env, sources, filename)
      super(env)
      @googly_template_render_stack = []
      @goog = Goog.new(env, sources, @googly_template_render_stack)
      @response = original_response = Rack::Response.new
      rendering = render(filename)
      if @response == original_response and @response.empty?
        @response.write rendering
      end
    rescue TemplateCallStackTooDeepError, TemplateNotFoundError => e
      e.set_backtrace e.backtrace[1..-1]
      raise e if @googly_template_render_stack.size > 1
      @response.status = 404
      @response.write "404 Not Found\n"
      @response.header["X-Cascade"] = "pass"
      @response.header["Content-Type"] = "text/plain"
    end
    
    # After rendering, #finish will be sent to the client.
    # If you replace the response or add to the response#body, 
    # the template rendering will not be added to this response.
    # @return [Rack::Response]
    attr_accessor :response

    # All the cool stuff lives here.
    attr_accessor :goog

    # Render another template.  The same Googly::Template instance is
    # used for all internally rendered templates so you can pass
    # information with instance variables.
    # @example view_test.erb
    #   <%= render 'util/logger_popup' %>
    # @param (String) filename Relative to current template.
    def render(filename)
      if @googly_template_render_stack.size > 100
        # Since nobody sane would recurse through here, this mainly
        # finds a render self that you might get after a copy and paste
        raise TemplateCallStackTooDeepError 
      elsif @googly_template_render_stack.size > 0
        # Hooray for relative paths and easily movable files
        filename = File.expand_path(filename, File.dirname(@googly_template_render_stack.last))
      else
        # Underbar templates are partials by convention; keep them from rendering at root
        filename = File.expand_path(filename)
        raise TemplateNotFoundError if File.basename(filename) =~ /^_/
      end
      ext = File.extname(filename)
      files1 = [filename]
      files1 << filename + '.html' if ext == ''
      files1 << filename.sub(/.html$/,'') if ext == '.html'
      files1.each do |filename1|
        Googly.config.engines.each do |ext, engine|
          files2 = [filename1+ext]
          files2 << filename1.gsub(/.html$/, ext) if File.extname(filename1) == '.html'
          unless filename1 =~ /^_/ or @googly_template_render_stack.empty?
            files2 = files2 + files2.collect {|f| "#{File.dirname(f)}/_#{File.basename(f)}"} 
          end
          files2.each do |filename2|
            if File.file?(filename2) and File.readable?(filename2)
              if @googly_template_render_stack.empty?
                response.header["Content-Type"] = Rack::Mime.mime_type(File.extname(filename1), 'text/html')
              end
              @goog.add_dependency filename2
              @googly_template_render_stack.push filename2
              result = engine.call self, filename2
              @googly_template_render_stack.pop
              return result
            end
          end
        end
      end
      raise TemplateNotFoundError
    end
    
    # Helper for URL escaping.
    # @param [String]
    # @return [String]
    def escape(s)
      Rack::Utils.escape(s)
    end

    # Helper and alias for HTML escaping.
    # @param [String]
    # @return [String]
    def escape_html(s)
      Rack::Utils.escape_html(s)
    end
    alias :h :escape_html
    
    # Helper for relative filenames.
    # @param [String]
    # @return [String]
    def expand_path(s)
      File.expand_path(s, File.dirname(@googly_template_render_stack.last))
    end

    # Helper to add file mtime as query for future-expiry caching.
    # @param [String]
    # @return [String]
    def expand_src(s)
      # If the file can't be read, simply skip the cache string.
      "#{s}?#{File.mtime(expand_path(s)).to_i}" rescue s
    end
    
    
  end
  
end
