# frozen_string_literal: true
require 'spec_helper'

describe RakefileGenerator do
  before(:all) do
    @testdir = Dir.mktmpdir
    @generator = RakefileGenerator.new @testdir
  end

  describe '.generate' do
    it 'should create file Rakefile' do
      @generator.generate
      expect(File.exist?("#{@testdir}/Rakefile")).to be_truthy
    end
  end

  after(:all) do
    FileUtils.rm_r @testdir
  end
end
