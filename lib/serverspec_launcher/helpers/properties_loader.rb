
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
      YAML.safe_load expand_env_vars(properties), symbolize_names: true
    else
      str = File.read('properties.yml')
      YAML.safe_load expand_env_vars(str), symbolize_names: true
    end
  end

  def expand_env_vars(text)
    text.gsub /\${([^}]+)}/ do
      ENV[$1]
    end
  end

  def properties
    @properties ||= @raw_properties
  end
end