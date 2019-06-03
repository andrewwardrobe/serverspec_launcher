# Helpers for the spec_helper generatort tests
module SpecFileHelper
  def spec_helper_data
    <<~HEREDOC
      # frozen_string_literal: true
      $LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
      
      require 'serverspec_launcher'
      require 'fileutils'
      require 'docker'

      ##some other stuff
    HEREDOC
  end

  def target_spec_helper_data
    <<~HEREDOC
      # frozen_string_literal: true
      $LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
      
      require 'serverspec_launcher'
      require 'fileutils'
      require 'docker'
      require 'serverspec_launcher/spec_helper'

      ##some other stuff
    HEREDOC
  end

  def make_spec_helper(path)
    File.open(path,'w') do |file|
      file.write spec_helper_data
    end
  end
end