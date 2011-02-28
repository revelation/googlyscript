# Copyright 2011 The Closure Script Authors
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

require 'thread'

class Closure
  
  class Templates
    
    class Error < StandardError
    end
    
    # Compiles soy to javascript with SoyToJsSrcCompiler.jar.  If you pass and
    # preserve the mtimes Hash, compilation will only be performed when source
    # files change.  Supports globbing on source filename arguments.
    # @example
    #  Closure::Templates.compile %w{
    #    --shouldProvideRequireSoyNamespaces
    #    --cssHandlingScheme goog
    #    --shouldGenerateJsdoc
    #    --outputPathFormat {INPUT_DIRECTORY}{INPUT_FILE_NAME_NO_EXT}.js
    #    app/javascripts/**/*.soy
    #    vendor/javascripts/**/*.soy
    #  }
    # @param (String) base All source filenames will be expanded to this location.
    def self.compile(args, mtimes={}, base = nil)
      new_mtimes = {}
      args = args.collect {|a| a.to_s } # for bools and numerics
      files = []
      # expand filename globs
      mode = :start
      args_index = 0
      while args_index < args.length
        if mode == :start
          if args[args_index] == '--outputPathFormat'
            mode = :expand
            args_index += 1
          end
          args_index += 1
        else 
          arg = args[args_index]
          arg = File.expand_path(arg, base) if base
          if arg =~ /\*/
            args[args_index,1] = Dir.glob arg
          else
            args[args_index,1] = arg
            args_index += 1
          end
        end
      end
      # extract filenames
      mode = :start
      args.each do |arg|
        mode = :out and next if arg == '--outputPathFormat'
        files << arg if mode == :collect
        mode = :collect if mode == :out
      end
      # detect source changes
      compiled = true
      files.each do |file|
        filename = File.expand_path file
        mtime = File.mtime filename rescue Errno::ENOENT
        last_mtime = mtimes[filename]
        if !mtime or !last_mtime or last_mtime != mtime
          compiled = false
        end
        new_mtimes[filename] = mtime
      end
      mtimes.clear
      # compile as needed
      if !compiled
        out, err = Closure.run_java Closure.config.soy_js_jar, 'com.google.template.soy.SoyToJsSrcCompiler', args
        unless err.empty?
          raise Error, err 
        end
      end
      mtimes.merge! new_mtimes
    end
    
    
  end
  
end
