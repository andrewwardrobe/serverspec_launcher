# frozen_string_literal: true
require 'erb'

# Generates the propetires.yml to be used in tests
class ExampleSpecGenerator
  def initialize(root_path = nil)
    @path = root_path ? "#{root_path}/" : ''
    @template_path = File.expand_path('../../../../templates', __FILE__)
    @spec_file = "#{@path}spec/example_spec.rb"
  end

  def template
    File.read "#{@template_path}/example_spec.rb.erb"
  end

  def generate
    renderer = ERB.new template
    Dir.mkdir "#{@path}spec" unless Dir.exists? "#{@path}spec"
    File.open(@spec_file, 'w') { |file| file.write renderer.result } unless File.exists? @spec_file
  end
end
