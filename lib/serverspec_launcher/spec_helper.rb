# frozen_string_literal: true
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'serverspec'
require 'rspec'

require 'net/ssh'
require 'tempfile'
require 'yaml'
require 'rubygems'
require 'docker'
require 'bundler'
require 'specinfra'

require 'serverspec_launcher/helpers/example_helper'
require 'serverspec_launcher/helpers/properties_loader'
require 'serverspec_launcher/helpers/symbolize_helper'

# Does all the setup fo r the serverspec tests
class SpecHelper
  include ExampleHelper
  using SymbolizeHelper

  attr_reader :properties, :target_properties, :target_variables

  def initialize(host = ENV['TARGET_HOST'], target = ENV['TARGET'], properties = nil, task_source = ENV['TASK_SOURCE'], environment = ENV['TASK_ENV'])
    @host = host
    @target = target
    @source = task_source
    @environment = environment
    load_properties properties
  end

  def load_properties(properties = nil)
    @properties = if properties
                    properties.deep_symbolize_keys
                  else
                    YAML.load_file('properties.yml').deep_symbolize_keys
                  end
    @target_properties = if @source == 'environment'
     @properties[:environments][@environment.to_sym][:targets][@target.to_sym]
    else
      @properties[:targets][@target.to_sym]
    end
    if @source == 'environment'
      vars = @properties[:environments][@environment.to_sym][:variables] ? @properties[:environments][@environment.to_sym][:variables] : {}
      @target_variables =  @properties[:variables] ? @properties[:variables].deep_merge(vars) : {}.deep_merge(vars)
    else
      @target_variables = @properties[:variables] ? @properties[:variables] : {}
    end

    @backend = @target_properties[:backend] || 'ssh'
    @target_properties[:target] = ENV['TASK_NAME']

    @target_properties[:variables] =  @target_variables.deep_merge(@target_properties[:variables])
    @target_properties[:environment] =  @properties[:environment] ? @properties[:variables].deep_merge(@target_properties[:environment]) : {}.deep_merge(@target_properties[:environment])

    set_property @target_properties
  end

  def setup_backend
    if @backend == 'exec'
      set :backend, :exec
    elsif @backend == 'docker'
      docker_backend
    elsif @backend == 'inspec'
    else
      ssh_backend
    end
  end

  def ssh_backend
    set :backend, :ssh

    sudo_checks



    ssh_user = @target_properties[:user] || Etc.getlogin

    options = if @backend == 'vagrant'
                vagrant_backend
              else
                Net::SSH::Config.for(@host)
              end
    password_checks(options)
    options[:user] ||= ssh_user
    options[:keys] = [@target_properties[:identity_file]] if @target_properties[:identity_file]
    options[:port] = @target_properties[:ssh_port] if @target_properties[:ssh_port]
    host_key_checking(options)


    set :host, options[:host_name] || @host
    set :ssh_options, options


    # Disable sudo
    # set :disable_sudo, true

    # Set environment variables
    return unless @target_properties[:environment]

    env = @target_properties[:environment].map do |en|
      variable, value = en.split('=')
      { variable.to_sym => value }
    end.reduce({}, :merge)
    set :env, env
  end

  def sudo_checks
    if ENV['ASK_SUDO_PASSWORD']
      begin
        require 'highline/import'
      rescue LoadError
        raise 'highline is not available. Try installing it.'
      end
      set :sudo_password, ask('Enter sudo password: ') { |q| q.echo = false }
    else
      set :sudo_password, ENV['SUDO_PASSWORD']
    end
  end

  def password_checks(options)
    if ENV['ASK_LOGIN_PASSWORD']
      begin
        require 'highline/import'
      rescue LoadError
        raise 'highline is not available. Try installing it.'
      end
      options[:password] = ask('Enter login password: ') { |q| q.echo = false }
    else
      options[:password] =  ENV['LOGIN_PASSWORD']
    end
  end

  def vagrant_backend
    @host = @target_properties[:vagrant_host] || 'default'
    vagrant_dir = @target_properties[:vagrant_dir]

    old_dir = Dir.pwd
    Dir.chdir(vagrant_dir) if vagrant_dir
    reprovision = @target_properties[:vagrant_reprovision] ? '--provision' : ''
    vagrant_up = "vagrant up #{@host} #{reprovision}"
    if @target_properties[:vagrant_output]
      Open3.popen2e vagrant_up do |_stdin, stdout_and_stderr, _wait_thr|
        while (line = stdout_and_stderr.gets) do
          puts line
        end
      end
    elsif @target_properties[:vagrant_errors]
      system(vagrant_up, out: File::NULL)
    else
      system(vagrant_up, out: File::NULL, err: File::NULL)
    end

    config = Tempfile.new('', Dir.tmpdir)
    config.write(`vagrant ssh-config #{@host}`)
    config.close
    Dir.chdir old_dir
    Net::SSH::Config.for(@host, [config.path])
  end

  def docker_backend
    set :backend, :docker

    set_docker_image
    set_docker_container
    set :docker_url, @target_properties[:docker_url] if @target_properties[:docker_url]
  end

  def set_docker_container
    set :docker_container, @target_properties[:docker_container] if @target_properties[:docker_container]
    set :docker_container_create_options, @target_properties[:docker_options] if @target_properties[:docker_options]
  end

  def set_docker_image
    if @target_properties[:dockerfile]
      puts "Building Docker Image from #{@target_properties[:dockerfile]}"
      commands = File.read(@target_properties[:dockerfile])
      image = Docker::Image.build(commands)
      set :docker_image, image.id
    elsif @target_properties[:docker_build_dir]
      puts "Building Docker Image in dir #{@target_properties[:docker_build_dir]}"
      image = Docker::Image.build_from_dir(@target_properties[:docker_build_dir])
      set :docker_image, image.id
    else
      set :docker_image, @target_properties[:docker_image] if @target_properties[:docker_image]
    end
  end

  def self.load(host = ENV['TARGET_HOST'], target = ENV['TARGET'], properties = nil, task_source = ENV['TASK_SOURCE'], environment = ENV['TASK_ENV'])
    props = PropertiesLoader.new properties
    helper = SpecHelper.new host, target, props.properties, task_source, environment
    props = helper.properties[:shared_example_gems] || []
    helper.load_shared_examples props
    helper.setup_backend
    helper
  end

  private

  def host_key_checking(options)
    options[:verify_host_key] = @target_properties[:verify_host_key].to_sym if @target_properties[:verify_host_key]
  end
end

SpecHelper.load unless $dont_load_spec_helper
