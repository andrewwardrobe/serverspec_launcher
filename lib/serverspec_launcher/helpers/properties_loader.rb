
require 'serverspec_launcher/helpers/symbolize_helper'
require 'yaml'
class PropertiesLoader
  using SymbolizeHelper
  def initialize(properties = nil)
    load properties
  end

  def load(properties)

    @raw_properties =  if properties.is_a? Hash
      properties.deep_symbolize_keys
    elsif properties.is_a? String
      YAML.safe_load(expand_env_vars(properties)).deep_symbolize_keys
    else
      properties_file = ENV['SERVERSPEC_CONFIG'] || 'properties.yml'
      str = File.read(properties_file)
      YAML.safe_load(expand_env_vars(str)).deep_symbolize_keys
    end
  end

  def expand_env_vars(text)
    text.gsub /\${([^}]+)}/ do
      data = $1.split(/:[-=]/)
      var_name = data[0]
      var_default = data[1]
      ENV[var_name] || var_default
    end
  end

  def properties
    @properties ||= @raw_properties
  end
end