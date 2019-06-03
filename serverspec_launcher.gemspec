# coding: utf-8
# frozen_string_literal: true
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'serverspec_launcher/version'

Gem::Specification.new do |spec|
  spec.name          = 'serverspec_launcher'
  spec.version       = ServerspecLauncher::VERSION
  spec.authors       = ['Andrew Wardrobe']
  spec.email         = ['andrew.g.wardrobe@googlemail.com']

  spec.summary       = 'A utility to manage serverspec scripts'
  spec.description   = 'A utility to manage serverspec scripts'
  spec.homepage      = "https://github.com/andrewwardrobe/serverspec_launcher"
  spec.license       = 'MIT'


  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'debase'
  spec.add_development_dependency 'ruby-debug-ide', '0.7.0.beta6'
  spec.add_development_dependency 'conventional-changelog'
  spec.add_runtime_dependency 'serverspec'
  spec.add_runtime_dependency 'rspec_junit_formatter'
  spec.add_runtime_dependency 'rspec-tick-formatter', '0.1.3'
  spec.add_runtime_dependency 'rspec_html_reporter', '~> 1.0.0'
  spec.add_runtime_dependency 'docker-api'
  spec.add_runtime_dependency 'docker-swarm-sdk'
end
