# frozen_string_literal: true
require 'erb'

# Generates the propetires.yml to be used in tests
class PropertiesGenerator
  def initialize(root_path = nil)
    path = root_path ? "#{root_path}/" : ''
    @template_path = File.expand_path('../../../../templates', __FILE__)
    @properties_file = "#{path}properties.yml"
    @full_properties_file = "#{path}properties.full.example.yml"
  end

  def properties_template
    File.read "#{@template_path}/properties-light.yaml.erb"
  end

  def full_properties_template
    File.read "#{@template_path}/properties.yaml.erb"
  end

  def generate
    renderer = ERB.new properties_template
    File.open(@properties_file, 'w') { |file| file.write renderer.result } unless File.exists? @properties_file
    File.open(@full_properties_file, 'w') { |file| file.write renderer.result } unless File.exists? @full_properties_file
  end
end
