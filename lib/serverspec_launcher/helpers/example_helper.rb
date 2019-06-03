# frozen_string_literal: true
require 'rubygems'
require 'bundler'
require 'rspec'

# Helper to load and list shared_examples loaded in to RSpec
module ExampleHelper
  def shared_examples
    groups = RSpec.world.shared_example_group_registry.send(:shared_example_groups)
    examples = groups[:main].map do |example, _details|
      example
    end
    examples
  end

  def load_shared_examples(shared_example_gems = [], project_root = Dir.pwd, shareDir = 'shared')
    load_bundled_examples(shared_example_gems)
    Dir.glob("#{project_root}/**/#{shareDir}/**/*.rb") do |path|
      require path if File.open(path).grep(/shared_examples/).any?
    end
  end

  def load_bundled_examples(shared_example_gems)
    Bundler.load.specs.map(&:name).each do |dep|
      next unless shared_example_gems.include? dep
      load_examples_from_gem(dep)
      load_examples_from_gem(dep.tr('-', '/'))
    end
  end

  def load_examples_from_gem(dep)
    Gem.find_files("#{dep}/**/*.rb").each do |path|
      require path if File.open(path).grep(/shared_examples/).any?
    end
  end
end
