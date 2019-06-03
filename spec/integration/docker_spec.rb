require 'spec_helper'
require 'serverspec_launcher/spec_helper'


context 'Docker Example' do
  describe package('busybox') do
    it { should be_installed }
  end
end