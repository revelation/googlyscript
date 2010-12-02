Licensed under the Apache License, Version 2.0 (the "License"); 
(http://www.apache.org/licenses/LICENSE-2.0)

Getting Started documentation is on the wiki:
(https://github.com/dturnbull/googlyscript/wiki)

Googlyscript - An experience with Google Closure.

* Every Google Closure compiler option is supported.
* Easy to install rack middleware.  Works in frameworks or stand-alone.
* No config files to manage or command line tools to learn.  Complexity removed, not added.
* On-the-fly deps.js generation with source change detection.  Never think about this again.
* Compiler checks File.mtime and won't run if you haven't modified source.
* Completely replaces python tools and plovr.
* Thread-safe.  Can handle hundreds of requests per second on a single Mongrel.
* Performance-tuned caching strategy that won't manifest stale pages in development.
* Java REPL so you only pay the Java startup cost once.
* Server-side templates.  ERB and Haml or add your own.
* Sass-compatible.  See Googly::Sass.
* Soy (coming soon)
