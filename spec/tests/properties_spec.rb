# frozen_string_literal: true
require 'spec_helper'

describe PropertiesGenerator do
  before(:all) do
    @testdir = Dir.mktmpdir
    @generator = PropertiesGenerator.new @testdir
  end

  describe '.generate' do
    it 'should create file properties.yaml' do
      @generator.generate
      expect(File.exist?("#{@testdir}/properties.yml")).to be_truthy
    end
  end

  after(:all) do
    FileUtils.rm_r @testdir
  end
end
