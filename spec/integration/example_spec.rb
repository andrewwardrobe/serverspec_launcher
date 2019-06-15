require 'spec_helper'
require 'serverspec_launcher/spec_helper'

describe file '/etc/hosts' do
  it { should exist }
  it { should be_a_file }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
end
