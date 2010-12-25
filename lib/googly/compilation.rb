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
  
  class Compilation
    
    # Java won't let you change working directories and the Closure Compiler
    # doesn't allow setting a base path.  No problem, we can do it.
    
    # These are filename options and will be expanded to a new base.
    # If supplied as arguments, output options are available as instance
    # variables and attributes that have been expanded to the new base.
    OUTPUT_OPTIONS = %w{
      --create_source_map
      --js_output_file
      --output_manifest
      --property_map_output_file
      --variable_map_output_file
    }
    
    # These are filename options and will be expanded to a new base.
    # These will have their modifification times checked against js_output_file.
    INPUT_OPTIONS = %w{
      --js
      --externs
      --property_map_input_file
      --variable_map_input_file
    }
    
    # @param (Hash) env Rack environment.  If you want the response to be cachable.
    def initialize(env={})
      @env = env
    end
    
    
    # @param (Array) args Arguments for the compiler.
    # @param (String) base All filenames will be expanded to this location.
    # @param (Array) dependencies Any other files to check mtime on, like makefiles.
    def compile_js(args, base, dependencies = [])
      args = Array.new args
      files = []
      # Scan to expand paths and extend self with output options
      args_index = 0
      while args_index < args.length
        option, value = args[args_index, 2]
        if INPUT_OPTIONS.include?(option)
          files << args[args_index+1] = File.expand_path(value, base)
        end
        if OUTPUT_OPTIONS.include?(option)
          var_name = option.sub(/^--/, '')
          instance_variable_set "@#{var_name}", args[args_index+1] = File.expand_path(value, base)
          eval "def self.#{var_name}; @#{var_name}; end"
        end
        args_index = args_index + 2
      end
      # We don't bother compiling if we can detect that no sources were modified
      if @js_output_file
        js_mtime = File.mtime @js_output_file rescue Errno::ENOENT
        compiled = !!File.size?(@js_output_file) # catches empty files too
        (files + dependencies).each do |filename|
          break unless compiled
          mtime = File.mtime filename
          compiled = false if !mtime or mtime > js_mtime
        end
        return if compiled
        File.unlink @js_output_file rescue Errno::ENOENT
      end
      # Do it; defensive .to_s.dump allows for bools and nums
      java_opts = args.collect{|a|a.to_s.dump}.join(', ')
      @stdout, @stderr = Googly.java("Googly.compile_js(new String[]{#{java_opts}});")
    end
    
    # Compilation state is an error
    def stderr=(e)
      @stdout = ''
      @stderr = e.to_s
    end
    
    # Allows http caching of the js_output_file for templates that want to do
    # their own error checking.
    # @example
    #   <% @response = goog.compile(args).to_response %>
    # @return (#finish) 
    def to_response
      if @js_output_file
        FileResponse.new @env, @js_output_file, 'application/javascript'
      else
        response = Rack::Response.new
        response.headers['Content-Type'] = 'application/javascript'
        response.headers["Cache-Control"] = "no-cache"
        response.write @stdout
        response
      end
    end
    
    # Checks the compilation status and will log to the javascript console.
    # This is the best technique for compiling unless you have different
    # needs for reporting errors.
    # @example
    #   <% @response = goog.compile(args).to_response_with_console %>
    def to_response_with_console
      return to_response if !stderr or stderr.empty?
      response = Rack::Response.new
      response.headers['Content-Type'] = 'application/javascript'
      response.headers["Cache-Control"] = "no-cache"
      split_log = stderr.split("\n")
      if split_log.last =~ /^\d+ err/i
        error_message = split_log.pop
      else
        error_message = split_log.shift
      end
      error_log = "Closure Compiler: #{error_message}".dump
      error_log += ',"\n\n",' + split_log.join("\n").dump unless split_log.empty?
      if error_message =~ /^0 err/i
        response.write "try{console.log(#{error_log})}catch(err){};\n"
      else
        response.write "try{console.error(#{error_log})}catch(err){};\n"
      end
      response.write javascript
      response
    end

    # Always returns the compiled javascript, or possibly an empty string.
    # @example
    #   <%= goog.compile(args) %>
    def javascript
      if @js_output_file
        File.read(@js_output_file) rescue ''
      else
        @stdout
      end
    end
    alias :to_s :javascript
    
    # Results from compiler.jar.  If you didn't specify a --js_output_file
    # then this will be the compiled script.  Otherwise, it's usually empty
    # but may contain output depending on the arguments.
    # If nil, compilation was skipped because js_output_file was up to date.
    attr_reader :stdout
    
    # Results from compiler.jar.  The log, when there is one, is found here.
    # Use `--summary_detail_level 3` to see log when no errors or warnings.
    # If nil, compilation was skipped because js_output_file was up to date.
    attr_reader :stderr
    
  end
  
end
