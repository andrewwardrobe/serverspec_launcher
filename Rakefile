# frozen_string_literal: true



require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'conventional_changelog'
require 'docker-api'
require_relative 'spec/helpers/container_helper'

require 'serverspec_launcher/rake_tasks'

include ContainerHelper

RSpec::Core::RakeTask.new(:spec) do |t|
  t.exclude_pattern = 'spec/integration/**/*_spec.rb'
end

task default: :spec


task :changelog do
  ConventionalChangelog::Generator.new.generate!
end


task :stop_ssh_container do
  stop_ssh_container
end

task :start_ssh_container do
  ENV['TARGET_HOST'] = '172.18.0.22'
  `ssh-keygen -f spec/resources/ssh.rsa -t rsa -N ""` unless File.exists? 'spec/resources/ssh.rsa'
  start_ssh_container
end

task :post_task_cleanup do
  at_exit { stop_ssh_container }
end


Rake::Task['serverspec:inspec-agent-example:all'].enhance ['post_task_cleanup', 'start_ssh_container']
Rake::Task['serverspec:inspec-ssh-example:all'].enhance ['post_task_cleanup', 'start_ssh_container']
Rake::Task['serverspec:inspec-password-example:all'].enhance ['post_task_cleanup', 'start_ssh_container']