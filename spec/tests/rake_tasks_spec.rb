# frozen_string_literal: true
require 'spec_helper'
$dont_load_rake_tasks = true

require 'serverspec_launcher/rake_tasks'
require 'helpers/rake'

describe ServerspecLauncherRakeTasks do
  include RakeHelpers

  after(:each) do
    Rake.application.clear
  end

  it 'should create a task for each target in the properties when provided as strings' do
    props = {
      targets: { 'target1' => { backend: 'exec' },
                 'target2' => { backend: 'exec' } }
    }

    ServerspecLauncherRakeTasks.load props
    expect(rake_tasks).to include('serverspec:target1', 'serverspec:target2')
  end

  it 'should create tasks for each host in each target in the properties when host is a string' do
    props = {
        targets: { 'target1' =>
                       { backend: 'exec',
                         hosts: 'host1' } }
    }

    ServerspecLauncherRakeTasks.load props
    expect(rake_tasks).to include('serverspec:target1')
  end

  it 'should create a task for each target in the properties when provided as symbols' do
    props = {
        targets: { target1: { backend: 'exec' },
                   target2: { backend: 'exec' } }
    }

    ServerspecLauncherRakeTasks.load props
    expect(rake_tasks).to include('serverspec:target1', 'serverspec:target2')
  end



  it 'should create tasks for each host in each target in the properties when host list is a list' do
    props = {
      targets: { 'target1' =>
                       { backend: 'exec',
                         hosts: %w(host1 host2) } }
    }

    ServerspecLauncherRakeTasks.load props
    expect(rake_tasks).to include('serverspec:target1:host1',
                                  'serverspec:target1:host2')
  end

  it 'create a task for each host in each target' do
    props = {
        environments: {
            test:{
                targets: { target1: { backend: 'exec',
                                      hosts: %w[host1 host2] },
                           target2: { backend: 'exec' }
                }
            },
            qa:{
                targets: { target1: { backend: 'exec' },
                           target2: { backend: 'exec' }
                }
            }
        }
    }
    ServerspecLauncherRakeTasks.load props
    expect(rake_tasks).to include('serverspec:qa:target1', 'serverspec:qa:target2')
  end

  it 'create a task for each host in each target when the host differs from the target name' do
    props = {
        environments: {
            test:{
                targets: { target1: { backend: 'ssh',
                                      hosts: 'leek' },
                }
            }
        }
    }
    ServerspecLauncherRakeTasks.load props
    expect(rake_tasks).to include('serverspec:test:target1')
  end

  it 'create a task for each host in each target in the environment' do
    props = {
        environments: {
            test:{
                targets: { target1: { backend: 'exec',
                                      hosts: %w[host1 host2] },
                           target2: { backend: 'exec' }
                }
            },
            qa:{
                targets: { target1: { backend: 'exec' },
                           target2: { backend: 'exec' }
                }
            }
        }
    }
    ServerspecLauncherRakeTasks.load props
    expect(rake_tasks).to include('serverspec:test:target1:host1', 'serverspec:test:target1:host2', 'serverspec:test:target2')
  end


  it 'create a task for the all tasks in the environment' do
    props = {
        environments: {
            test:{
                targets: { target1: { backend: 'exec',
                                      hosts: %w[host1 host2] },
                           target2: { backend: 'exec' }
                }
            },
            qa:{
                targets: { target1: { backend: 'exec' },
                           target2: { backend: 'exec' }
                }
            }
        }
    }
    ServerspecLauncherRakeTasks.load props
    expect(rake_tasks).to include('serverspec:test', 'serverspec:qa')
  end


end
