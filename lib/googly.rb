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


require 'ostruct'

# Googlyscript can be run with rackup using a config.ru, installed as
# middleware into a framework, or adapted to anything with a rack environment.
# @example config.ru
#   #\ -p 9009 -E none
#   require 'rubygems'
#   require 'googlyscript'
#   Googly.script '/goog', :goog
#   Googly.script '/myapp', './src/myapp'
#   use Rack::ShowExceptions
#   use Googly::Middleware
#   run Rack::File.new './public'

class Googly
  
  autoload(:VERSION, 'googly/version')
  autoload(:BeanShell, 'googly/beanshell')
  autoload(:Sass, 'googly/sass')
  autoload(:Template, 'googly/template')
  autoload(:Sources, 'googly/sources')
  autoload(:FileResponse, 'googly/file_response')
  autoload(:Middleware, 'googly/middleware')
  autoload(:Compilation, 'googly/compilation')
  autoload(:Server, 'googly/server')
  autoload(:Goog, 'googly/goog')
  autoload(:Soy, 'googly/soy')
  

  # Filesystem location of the Googlyscript install.
  # Typically, where the gem was installed.  This is mainly used
  # internally but may be useful for experimental configurations.
  # @return [String]
  def self.base_path
    @@base_path ||= File.expand_path(File.join(File.dirname(__FILE__), '..'))
  end
  

  # Scripts that are distributed with the gem.  These will help get you started quickly.
  # Googlyscript isn't tied to any Google Closure release, so feel free to use whatever
  # version you want and check it in to your repository.
  BUILT_INS = {
    :goog => File.join(base_path, 'closure-library', 'closure', 'goog'),
    :goog_vendor => File.join(base_path, 'closure-library', 'third_party', 'closure', 'goog'),
    :soy_js => File.join(base_path, 'closure-templates'),
    :googly => File.join(base_path, 'src', 'script')
  }
  
  
  # Easy config. This adds to the global instance of sources and
  # supports using the {BUILT_INS}.
  # @example
  #   Googly.script('/goog', :goog)
  #   Googly.script('/myapp', './myapp')
  # @overload script(path, directory)
  # @overload script(path, built_in)
  # @param (String) path http server mount point.
  # @param (String) directory Where the scripts are in the filesystem.
  # @param (Symbol) built_in
  def self.script(path, directory)
    directory = BUILT_INS[directory] if directory.kind_of? Symbol
    sources.add path, directory
  end


  # This is a global instance of sources, configured with Googly.script()
  # and used for {Googlyscript::Middleware} by default.
  # Path and directory pairs configured with Googly.script().
  # @return [Array]
  def self.sources
    @@sources ||= Sources.new
  end
  
  
  # Run Java command in a REPL (read-execute-print-loop).
  # This keeps Java running so you only pay the startup cost on the first job.
  # It will have compiler.jar and googly.jar loaded.
  # @param (String) command BeanShell Java command.
  # @return (Array)[stdout, stderr]
  def self.java(command)
    @@beanshell ||= BeanShell.new [
      config.compiler_jar,
      config.soy_js_jar,
      File.join(base_path, 'lib', 'googly.jar')
    ]
    @@beanshell.run(command)
  end
  
  
  # Set these before the rack server is called for the first time.
  # === Attributes:
  # - (String) *java* -- default: "java" -- Your Java executable.
  # - (String) *compiler_jar* -- A compiler.jar to use instead of the one in the gem.
  # - (Hash) *haml* -- Options hash for haml engine.
  # - (Array) *engines* -- Add new template engines here.
  # @return [OpenStruct]
  def self.config
    @@config ||= OpenStruct.new({
      :java => 'java',
      :compiler_jar => File.join(base_path, 'closure-compiler', 'compiler.jar'),
      :soy_js_jar => File.join(base_path, 'closure-templates', 'SoyToJsSrcCompiler.jar'),
      :haml => {},
      :engines => [
        ['.erb', Proc.new do |template, filename|
          require 'erb'
          erb = ::ERB.new(File.read(filename), nil, '-')
          erb.filename = filename
          erb.result(template.send(:binding))
        end],
        ['.haml', Proc.new do |template, filename|
          require 'haml'
          options = config.haml.merge(:filename => filename)
          ::Haml::Engine.new(File.read(filename), options).render(template)
        end]
      ]
    })
  end
  
end

