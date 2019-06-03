# frozen_string_literal: false
require 'erb'

# Generate the spec_helpr.rb file
class SpecHelperGenerator
  def initialize(root_path = nil)
    path = root_path ? "#{root_path}/" : ''
    @template_path = File.expand_path('../../../../templates', __FILE__)
    @spec_helper = "#{path}spec/spec_helper.rb"
  end

  def rakefile_template
    File.read "#{@template_path}/spec_helper.rb.erb"
  end

  def create_spec_dir
    Dir.mkdir File.dirname(@spec_helper) unless File.exist?(File.dirname(@spec_helper))
  end

  def generate
    if File.exist?(@spec_helper)
      str = File.read(@spec_helper)
      new_str = if str.include? "require 'serverspec_launcher/spec_helper'"
                  str
                else
                  str.sub(/((require .*\n)+)/, "\\1require 'serverspec_launcher/spec_helper'\n")
                end
      File.open(@spec_helper, 'w') { |file| file.write new_str }
    else
      create_spec_dir
      renderer = ERB.new rakefile_template
      File.open(@spec_helper, 'w') { |file| file.write renderer.result }
    end
  end
end
