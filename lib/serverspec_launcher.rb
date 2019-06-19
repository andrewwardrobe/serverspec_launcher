# frozen_string_literal: true
require 'serverspec_launcher/version'
require 'serverspec_launcher/helpers/reshaper'
require 'serverspec_launcher/generators/properties_generator'
require 'serverspec_launcher/generators/rakefile_generator'
require 'serverspec_launcher/generators/spec_helper_generator'
require 'serverspec_launcher/generators/role_spec_generator'
require 'serverspec_launcher/generators/example_spec_generator'
require 'serverspec_launcher/generators/gemspec_generator'

# Main Class
module ServerspecLauncher

  def self.generate_properties
    properties = PropertiesGenerator.new
    properties.generate
  end

  def self.generate_rolespec
    properties = RoleSpecGenerator.new
    properties.generate
  end


  def self.generate_examplespec
    properties = ExampleSpecGenerator.new
    properties.generate
  end

  def self.generate_spec_helper
    properties = SpecHelperGenerator.new
    properties.generate
  end

  def self.generate_rakefile
    properties = RakefileGenerator.new
    properties.generate
  end

  def self.generate_gemspec(options = {})
    gemspec = GemspecGenerator.new options
    gemspec.generate
  end


  def self.which(cmd)
    exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
    ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
      exts.each { |ext|
        exe = File.join(path, "#{cmd}#{ext}")
        return exe if File.executable?(exe) && !File.directory?(exe)
      }
    end
    return nil
  end

  def self.create_repo
    if which 'git'
      name = `git config user.name`.chomp
      email = `git config user.email`.chomp

      system('git init .') unless Dir.exists? '.git'
      return {
          name: name == '' ? nil : name,
          email: email == '' ? nil : email,
      }
    end
    {}
  end

  def self.check_args(args)
    if args.length.zero?
      puts 'Usage: serverspec_launcher init'
      exit 1
    end
  end
  
  def self.init
    generate_properties 
    generate_rolespec 
    generate_examplespec
    generate_spec_helper
    generate_rakefile 
    generate_rolespec 
    generate_gemspec create_repo
  end

  def self.process_command(args)
    check_args args
    command = args.shift
    parameters = args

    case command
    when 'init'
      init
    when 'version'
      puts "Serverspec Launcher version #{ServerspecLauncher::VERSION}"
    when 'reshape'

      ReShaper.reshape_report args[0]
    end

  end
end
