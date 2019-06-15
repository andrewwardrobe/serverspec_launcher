require 'spec_helper'
require 'serverspec_launcher/spec_helper'


context 'Docker Example' do
  describe file('/tmp') do
    it { should exist }
    it { should be_a_directory }
  end
end