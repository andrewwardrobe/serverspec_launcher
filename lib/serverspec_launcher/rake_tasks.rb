# frozen_string_literal: false
require 'bundler/gem_tasks'
require 'bundler'
require 'rake'
require 'rspec/core/rake_task'
require 'yaml'
require 'docker-api'
require 'etc'

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'serverspec_launcher/helpers/example_helper'
require 'serverspec_launcher/helpers/symbolize_helper'
require 'serverspec_launcher/helpers/properties_loader'

# loads up the rake tasks
class ServerspecLauncherRakeTasks
  include ::Rake::DSL if defined?(::Rake::DSL)
  include ExampleHelper
  using SymbolizeHelper

  def initialize(properties = nil)
    @properties = properties
    options = @properties[:options] || {}
    @fail_on_err = options[:fail_on_err]
    @formatters = options[:formatters] || ['tick']
    @colorize = options[:color].nil? ? true : options[:color]
  end

  def load_tasks
    task serverspec: 'serverspec:all'

    namespace :serverspec do
      targets = @properties[:targets] || {}
      desc 'Run all targets and environments'
      task all: targets.keys.map { |key| 'serverspec:' + key.to_s.split('.')[0] }
      targets.keys.each do |key|
        target = targets[key]
        process_target(key, target)
      end

      environments = @properties[:environments] || {}
      environments.keys.each do |key|
        desc "Run all tasks in environment #{key}"
        task key.to_sym => "serverspec:#{key}:all"
        namespace key.to_sym do
          environment = environments[key]
          task all: environment[:targets].map { |target, _hash| "serverspec:#{key}:#{target.to_s.split(':')[0].to_sym}" }
          environment[:targets].each do |target, hash|
            process_target("#{target}", hash, 'environment', key.to_s)
          end
        end
      end

    end
  end

  def serverspec_task_array(key, spec_type, target, options)
    env = options[:source] == 'environment' ? ":"+ options[:environment] : ""
    desc "Run serverspec to #{key}"
    task key.to_sym => "serverspec#{env}:#{key}:all"
      namespace key.to_sym do
        desc "Run #{key} against all hosts"
        task :all do
          target[:hosts].each do |host|
            Rake::Task["serverspec#{env}:#{key}:#{host.split(':')[0].to_sym}"].execute
          end
        end
        target[:hosts].each do |host|
          task_name = "#{host || target[:name]}"
          serverspec_rake_task(host, key, task_name, spec_type, options)
        end
      end
  end

  def serverspec_rake_task(host, key, task_name, spec_type, options = {}, target = {})
    desc "Run serverspec to #{key}"
    RSpec::Core::RakeTask.new(task_name.to_s.to_sym) do |t|
      ENV['TARGET_HOST'] = host.to_s
      ENV['TARGET'] = key.to_s
      ENV['TASK_NAME'] = task_name.to_s
      ENV['TASK_SOURCE'] = options[:source]
      ENV['TASK_ENV'] = options[:environment]
      t.pattern = "spec/#{spec_type}_spec.rb"
      t.fail_on_error = options[:fail_on_err]
      report_name = options[:environment] ? "reports/#{options[:environment]}/#{key.to_s}/#{host.to_s}" : "reports/#{key.to_s}/#{host.to_s}"
      set_formatters(report_name, options, t)
    end
  end

  def set_formatters(report_path, options, t)
    opts = t.rspec_opts
    if options[:formatters].include?('junit') || options[:formatters].include?('xml')
      opts = "#{opts}  --format RspecJunitFormatter --out #{report_path}.xml"
    end
    if options[:formatters].include?('docs') || options[:formatters].include?('documentation') || options[:formatters].include?('docs_file')
      opts = "#{opts}  --format documentation --out #{report_path}.docs"
    end
    if options[:formatters].include?('docs_screen')
      opts = "#{opts}  --format documentation"
    end
    if options[:formatters].include?('tick')
      opts = "#{opts}  --format RspecTickFormatter"
    end
    if options[:formatters].include?('tick_file')
      opts = "#{opts}  --format RspecTickFormatter --out #{report_path}.tick"
    end
    if options[:formatters].include?('progress')
      opts = "#{opts}  --format progress"
    end
    if options[:formatters].include?('html')
      opts = "#{opts}  --format html --out #{report_path}.html"
    end
    if options[:formatters].include?('html_report') || options[:formatters].include?('html_pretty')
      opts = "#{opts}  --format RspecHtmlReporter"
    end
    if options[:formatters].include?('json')
      opts = "#{opts}  --format j --out #{report_path}.json"
    end
    if options[:formatters].include?('launcher')
      opts = "#{opts}  --format LauncherJsonFormatter --out #{report_path}_extended.json"
    end
    unless options[:color]
      opts = "#{opts} --no-color"
    end
    if File.exist?('.rspec')
      opts = "#{opts}  --options .rspec"
    end
    t.rspec_opts = opts
  end

  def debug_tasks
    namespace :debug do
      desc 'View loaded Shared examples'
      task :shared_examples do
        puts 'Loaded Shared Examples:\n======================='
        load_shared_examples @properties[:shared_example_gems] || []
        shared_examples.each do |ex|
          puts "\t#{ex}"
        end
      end
    end
  end

  def self.load(properties = nil)
    props = PropertiesLoader.new properties
    tasks = ServerspecLauncherRakeTasks.new props.properties
    tasks.load_tasks
  end

  private

  def process_target(key, target, task_source = 'target', environment = nil)
    options = {
        fail_on_err: target[:fail_on_err] || @fail_on_err,
        formatters: target[:formatters] || @formatters,
        color: target[:color].nil? ? @colorize : target[:color],
        source: task_source,
        environment: environment
    }
    if target[:backend] == 'inspec'
      inspec_target(key, options, target)
    else
      serverspec_target(key, options, target)
    end
  end

  def inspec_target(key, options, target)
    spec_type, options = get_inspec_type(target, options)
    if target[:hosts].is_a?(Array)
      inspec_task_array(key, spec_type, target, options)
    elsif target[:hosts]
      host = target[:hosts]
      task_name = (key || target[:name]).to_s
      inspec_task(host, "#{key}/#{host}", task_name, spec_type, options, target)
    else
      host = (target[:hosts] || 'local' )
      task_name = (key || target[:name]).to_s
      inspec_task(host, "#{key}/#{host}", task_name, spec_type, options, target)
    end
  end

  def inspec_task_array(key, spec_type, target, options)
    env = options[:source] == 'environment' ? ":"+ options[:environment] : ""
    desc "Run serverspec to #{key}"
    task key.to_sym => "serverspec#{env}:#{key}:all"
    namespace key.to_sym do
      desc "Run #{key} against all hosts"
      task :all do
        target[:hosts].each do |host|
          Rake::Task["serverspec#{env}:#{key}:#{host.split(':')[0].to_sym}"].execute
        end
      end
      target[:hosts].each do |host|
        task_name = "#{host || target[:name]}"
        inspec_task(host, "#{key}/#{host}", task_name, spec_type, options, target)
      end
    end
  end

  def get_inspec_type(target, options)
    spec_type = 'role'
    if (target[:control] && target[:profile]) || (target[:control] && target[:spec_type]) || (target[:spec_type] && target[:profile])
      puts 'WARNING: Multiple options specified: they will be evalated in the follow precidence profile > control > spec_type'
    end
    if target[:spec_type]
      spec_type = target[:spec_type]
      options[:spec_type] = 'spec'
    end
    if target[:control]
      spec_type = target[:control]
      options[:spec_type] = 'control'
    end
    if target[:profile]
      spec_type = target[:profile]
      options[:spec_type] = 'control'
    end
    return spec_type, options
  end

  def inspec_task(host, key, task_name, spec_type, options = {}, target = {})
    protocol = host == 'local' ? 'local' : 'ssh'
    command = inspec_commandline(target,key,host, spec_type, protocol, options)
    Rake::Task.define_task(task_name.to_s.to_sym) do

      unless Docker::Image.exist? 'chef/inspec:latest'
        Docker::Image.create('fromImage' => 'chef/inspec:latest')
      end

      container = Docker::Container.create(
          'Image' => 'chef/inspec:latest',
          'Mounts' => inspec_mounts(target, protocol),
          'Cmd' => command,
          'Tty' => STDIN.tty?,
          'Env' => inspec_environment(target, protocol)
      )
      begin
        puts "inspec #{command.join(' ')}"
        networks = target[:attach_to] || []
        networks.each do |nw|
          network = Docker::Network.get(nw)
          network.connect(container.id)  
        end
        container.start
        container.wait
      rescue Docker::Error::TimeoutError => ex
        container.stop
        puts "A Docker::Error::TimeoutError occurred, most likey because you are using password protected ssh key, whihc is not supported"
        puts "Either agent your ssh key and use 'agent' as the auth_method in your target settings or use an unprotected key (not recommended)"
        puts 'Container Logs: '
        puts container.logs(stderr: true)
      ensure
        puts container.logs(stdout: true)
        container.delete
        #Report have wrong permission hookie fix
        chown_files(protocol, target)
      end
    end
  end

  def chown_files(protocol, target)
    unless Docker::Image.exist? 'alpine:latest'
      Docker::Image.create('fromImage' => 'alpine:latest')
    end
    command = %W[chown -R #{Etc.getpwnam(ENV['USER']).uid}:#{Etc.getpwnam(ENV['USER']).gid} /share/reports/]
    container = Docker::Container.create(
        'Image' => 'alpine:latest',
        'Mounts' => inspec_mounts(target, protocol),
        'Cmd' => command
    )
    container.start
    container.wait
    container.delete
  end

  def inspec_environment(target_info, protocol)
    environment = []
    environment << "SSH_AUTH_SOCK=#{ENV['SSH_AUTH_SOCK']}" if target_info[:auth_method] == 'agent'
    environment
  end

  def inspec_mounts(target_info, protocol)
    mounts = [{
         'Type' => 'bind',
         'Source' => "#{Dir.pwd}",
         'Target' => "/share"
     }, {
         'Type' => 'bind',
         'Source' => "/etc/hosts",
         'Target' => "/etc/hosts"
     }]
    mount_ssh = target_info[:mount_ssh_dir] ? target_info[:mount_ssh_dir] : true
    mounts <<  { 'Type' => 'bind', 'Source' => "#{File.expand_path('~')}/.ssh", 'Target' => "#{File.expand_path('~')}/.ssh" } if mount_ssh && protocol == 'ssh'
    mounts <<  { 'Type' => 'bind', 'Source' => "#{ENV['SSH_AUTH_SOCK']}", 'Target' => "#{ENV['SSH_AUTH_SOCK']}" } if target_info[:auth_method] == 'agent'
    mounts
  end

  def inspec_commandline(target_info, key, host, spec_type, protocol, options = {})
    spec = if options[:spec_type] == 'spec'
      "spec/#{spec_type}_spec.rb"
    else
      spec_type
    end
    target = "#{protocol}://#{protocol == 'local' ? '' : host}"
    command =  %W[exec #{spec} -t #{target}]
    authmethod = target_info[:auth_method] ? target_info[:auth_method] : 'ssh-keys'
    keyfile = target_info[:keyfile] ? target_info[:keyfile] : "#{File.expand_path('~')}/.ssh/id_rsa"
    if protocol == 'ssh' && authmethod == 'ssh-keys'
      command << '-i'
      command << keyfile
    end
    command << "--user=#{target_info[:user]}" if target_info[:user]
    command << "--port=#{target_info[:ssh_port]}" if target_info[:ssh_port]
    command << "--password=#{target_info[:password]}" if target_info[:password]
    command << "--bastion-host=#{target_info[:bastion_host]}" if target_info[:bastion_host]
    command << "--bastion-port=#{target_info[:bastion_port]}" if target_info[:bastion_port]
    command << "--bastion-user=#{target_info[:bastion_user]}" if target_info[:bastion_user]
    command <<  set_inspec_reporters(key, host, options)
    command
  end

  def set_inspec_reporters(key, host, options)
    reporters = []
    report_path = options[:environment] ? "/share/reports/#{options[:environment]}/#{key}" :  "/share/reports/#{key}"
    reporters <<  "junit:#{report_path}.xml" if options[:formatters].include?('junit') || options[:formatters].include?('xml')
    reporters <<  "documentation:#{report_path}.docs" if options[:formatters].include?('docs') || options[:formatters].include?('documentation') || options[:formatters].include?('docs_file')
    reporters <<  'documentation' if options[:formatters].include?('docs_screen')
    reporters <<  'cli' if options[:formatters].include?('tick')
    reporters <<  "cli:#{report_path}.tick" if options[:formatters].include?('tick_file')
    reporters <<  'progress' if options[:formatters].include?('progress')
    reporters <<  "html:#{report_path}.html" if options[:formatters].include?('html')
    reporters <<  "html#{report_path}.html" if (options[:formatters].include?('html_report') || options[:formatters].include?('html_pretty')) && !options[:formatters].include?('html')
    reporters <<  "json-rspec:#{report_path}.json" if options[:formatters].include?('json')
    "--reporter=#{reporters.join(' ')}"
  end

  def serverspec_target(key, options, target)
    spec_type = target[:spec_type] || 'role'
    if target[:hosts].is_a?(Array)
      serverspec_task_array(key, spec_type, target, options)
    elsif target[:hosts]
      host = target[:hosts]
      task_name = (key || target[:name]).to_s
      serverspec_rake_task(host, key, task_name, spec_type, options)
    else
      task_name = (key || target[:name]).to_s
      serverspec_rake_task(key, key, task_name, spec_type, options)
    end
  end
end

ServerspecLauncherRakeTasks.load unless $dont_load_rake_tasks
