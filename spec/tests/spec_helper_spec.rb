# frozen_string_literal: true
require 'spec_helper'
$dont_load_spec_helper = true
$dont_load_rake_tasks  = true
require 'serverspec_launcher/spec_helper'
require 'helpers/spec_infra'
require 'helpers/shared_examples'
require 'helpers/properties_helper'

describe SpecHelper do
  include SpecInfraHelper
  include SharedExamplesHelper
  include PropertiesHelper

  before(:all) do
    @properties = default_properties
  end

  it 'Should set the correct backend when using ssh ' do
    SpecHelper.load('ssh-example', 'ssh-example', @properties)
    expect(serverspec_backend).to equal :ssh
  end

  it 'Should set the correct backend when using exec ' do
    SpecHelper.load('exec-example', 'exec-example', @properties)
    expect(serverspec_backend).to equal :exec
  end

  it 'should autoload shared_examples' do
    dir = create_shared_example 'test::example'
    sh = SpecHelper.load('exec-example', 'exec-example', @properties)
    sh.load_shared_examples [], dir

    expect(sh.shared_examples).to include 'test::example'
    FileUtils.rm_r dir
  end

  it 'should be able to load properties per globally' do
    sh = SpecHelper.load('exec-example', 'exec-example', @properties)
    expect(sh.target_properties[:variables][:leek]).to eq 'sheek'
  end

  it 'should be able to load properties per environment ' do
    sh = SpecHelper.load('target2', 'target2', @properties, 'environment', 'test')
    expect(sh.target_properties[:variables][:leek]).to eq 'treek'
  end


  it 'should be able to load properties per environment target ' do
    sh = SpecHelper.load('target1', 'target1', @properties, 'environment', 'test')
    expect(sh.target_properties[:variables][:leek]).to eq 'meek'
  end

  it 'should be able to load properties per target' do
    sh = SpecHelper.load('ssh-example', 'ssh-example', @properties)
    expect(sh.target_properties[:variables][:leek]).to eq 'bleek'
  end

end
