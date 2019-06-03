# frozen_string_literal: false
require 'erb'
require 'serverspec_launcher/version'
# Generates the rakefile that will bring in the serverspec tasks
class GemspecGenerator

  def initialize(options = {})
    path = options[:root_path] ? "#{options[:root_path]}/" : ''
    @template_path = File.expand_path('../../../../templates', __FILE__)
    @project_name =  Dir.pwd.split('/')[-1]
    @gemspec_file = "#{path}#{@project_name}.gemspec"
    @gem_file = "#{path}Gemfile"
    @name = options[:name] || '<Your Name>'
    @email = options[:email] || '<Your email>'
  end

  def gemspec_template
    File.read "#{@template_path}/gemspec.rb.erb"
  end

  def gemfile_template
    File.read "#{@template_path}/Gemfile.erb"
  end


  def generate
    renderer = ERB.new gemspec_template
    File.open(@gemspec_file, 'w') { |file| file.write renderer.result(binding) } if Dir['*.gemspec'].empty?
    renderer = ERB.new gemfile_template
    File.open(@gem_file, 'w') { |file| file.write renderer.result(binding) } unless File.exists? @gem_file
  end


end
