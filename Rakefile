
begin
  require "#{dir = File.dirname(__FILE__)}/task/gemgem"
rescue LoadError
  sh 'git submodule update --init'
  exec Gem.ruby, '-S', $PROGRAM_NAME, *ARGV
end

Gemgem.init(dir) do |s|
  require 'pork/version'
  s.name    = 'pork'
  s.version = Pork::VERSION
  %w[].each{ |g| s.add_runtime_dependency(g) }
end