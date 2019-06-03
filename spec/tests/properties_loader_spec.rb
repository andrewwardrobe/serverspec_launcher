require 'spec_helper'
require 'serverspec_launcher/helpers/properties_loader'
require 'helpers/properties_helper'

describe PropertiesLoader do
  include PropertiesHelper
  it 'Should not be able to expand environment variables using $ syntax' do
    text = default_properties_yaml
    ENV['VAR1'] = 'var1'
    properties = PropertiesLoader.new(text).properties
    expect(properties[:variables][:var1]).to eq '$VAR1'
  end

  it 'Should be able to expand environment variables using ${} syntax' do
    text = default_properties_yaml
    ENV['VAR2'] = 'var2'
    properties = PropertiesLoader.new(text).properties
    expect(properties[:variables][:var2]).to eq 'var2'
  end



  it 'Should be able to escape \$ ' do
    text = default_properties_yaml
    properties = PropertiesLoader.new(text).properties
    expect(properties[:variables][:var3]).to eq '$VAR3'
  end
end