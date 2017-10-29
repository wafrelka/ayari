$:.unshift(File.join(File.dirname(File.expand_path(__FILE__)), 'app'))
require 'ayari/router'

map('/') { run Ayari::Router }
