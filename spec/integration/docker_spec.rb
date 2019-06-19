require 'spec_helper'
require 'serverspec_launcher/spec_helper'


context 'Docker Example', leek: 'sheek' do
  describe file('/tmp') do
    it { should exist }
    it { should be_a_directory }
    it { should be_a_directory }
  end
end