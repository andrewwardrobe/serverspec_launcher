# frozen_string_literal: false
require 'erb'

# Generates the rakefile that will bring in the serverspec tasks
class RakefileGenerator
  def initialize(root_path = nil)
    path = root_path ? "#{root_path}/" : ''
    @template_path = File.expand_path('../../../../templates', __FILE__)
    @rakefile = "#{path}Rakefile"
  end

  def rakefile_template
    File.read "#{@template_path}/Rakefile.erb"
  end

  def generate
    if File.exist? @rakefile
      str = File.read(@rakefile)
      new_str = if str.include? "require 'serverspec_launcher/rake_tasks'"
                  str
                else
                  str.sub(/((require .*\n)+)/, "\\1require 'serverspec_launcher/rake_tasks'\n")
                end
      File.open(@rakefile, 'w') { |file| file.write new_str }
    else
      renderer = ERB.new rakefile_template
      File.open(@rakefile, 'w') { |file| file.write renderer.result }
    end

  end
end
