# frozen_string_literal: true
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'serverspec_launcher'
require 'fileutils'
require 'docker'
require 'specinfra'

##some other stuff
require 'serverspec'
set :backend, :ssh
