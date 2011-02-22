
require 'rubygems'
require 'rake/gempackagetask'

$LOAD_PATH.unshift('lib')
require 'hexwrench'

spec = Gem::Specification.new do |s|
        s.name = 'hexwrench'
        s.rubyforge_project = 'hexwrench'
        s.version = HexWrench::VERSION
        s.author = HexWrench::AUTHORS.first
        s.homepage = HexWrench::WEBSITE
        s.summary = "A data miner glue layer for your Welo resources"
        s.email = "crapooze@gmail.com"
        s.platform = Gem::Platform::RUBY

        s.files = [
          'Rakefile', 
          'TODO', 
          'README',
          'lib/hexwrench.rb',
          'lib/hexwrench/core/explorer.rb',
          'lib/hexwrench/core/feature.rb',
          'lib/hexwrench/core/resource.rb',
          'lib/hexwrench/weka.rb',
          'lib/hexwrench/weka/explorer.rb',
          'lib/hexwrench/weka/feature.rb',
        ]

        s.require_path = 'lib'
        s.bindir = 'bin'
        s.executables = []
        s.has_rdoc = true

        s.add_dependency('welo', '>= 0.0.6')
end

Rake::GemPackageTask.new(spec) do |pkg|
        pkg.need_tar = true
end

task :gem => ["pkg/#{spec.name}-#{spec.version}.gem"] do
        puts "generated #{spec.version}"
end

