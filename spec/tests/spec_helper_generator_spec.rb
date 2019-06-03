# frozen_string_literal: true
require 'spec_helper'
require 'helpers/spec'

describe SpecHelperGenerator do
  include SpecFileHelper


  context 'With no spec_helper file' do
    before(:all) do
      @testdir = Dir.mktmpdir
      @generator = SpecHelperGenerator.new @testdir
      @specfile = "#{@testdir}/spec/spec_helper.rb"
    end

    describe '.generate' do
      it 'should create spec directory' do
        @generator.generate
        expect(Dir.exist?("#{@testdir}/spec")).to be_truthy
      end
      it 'should create file spec_helper.rb' do
        @generator.generate
        expect(File.exist?("#{@testdir}/spec/spec_helper.rb")).to be_truthy
      end
    end

    after(:all) do
      File.delete @specfile if File.exist? @specfile
      FileUtils.rm_r @testdir
    end
  end

  context 'With an existing spec_helper file' do
    before(:all) do
      @testdir = Dir.mktmpdir
      @generator = SpecHelperGenerator.new @testdir
      @specfile = "#{@testdir}/spec/spec_helper.rb"
      Dir.mkdir ("#{@testdir}/spec")
      make_spec_helper @specfile
    end

    describe '.generate' do
      it 'add a require for serverspec_launcher/spec_helper' do
        @generator.generate
        expect(File.read(@specfile)).to match target_spec_helper_data
      end

    end

    after(:all) do
      File.delete @specfile if File.exist? @specfile
      FileUtils.rm_r @testdir
    end
  end



end
