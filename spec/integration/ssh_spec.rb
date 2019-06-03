require 'spec_helper'
require 'serverspec_launcher/spec_helper'

require 'helpers/container_helper'

context 'SSH Example' do

  include ContainerHelper
  before(:all) do
    `ssh-keygen -f spec/resources/ssh.rsa -t rsa -N ""` unless File.exists? 'spec/resources/ssh.rsa'
    start_ssh_container
  end
  describe package('openssh-server') do
    it { should be_installed }
  end

  after(:all) do
    stop_ssh_container
  end
end