# frozen_string_literal: true
require 'specinfra'

module SpecInfraHelper
  def serverspec_backend
    Specinfra.backend.get_config(:backend)
  end

  def serverspec_config(symbol)
    Specinfra.backend.get_config(symbol)
  end
end
