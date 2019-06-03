require 'spec_helper'
require 'serverspec_launcher/spec_helper'

describe package('openssh-server') do
  it { should be_installed }
end
