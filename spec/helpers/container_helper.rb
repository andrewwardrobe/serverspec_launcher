require_relative './hash_helper'

module ContainerHelper
  def default_options
    { 'name' => "serverspec-launcher-ssh_#{Time.now.to_i}",
      'Image' => 'serverspec-launcher-ssh:latest',
      'HostConfig' => {
          'PortBindings' => {
              '22/tcp' => [{ 'HostPort' => '1022' }]
          }
      },
      'NetworkSettings' => {
        'Networks' => {
            'test_network' => {
                "IPAMConfig" => {
                    "IPv4Address" => "172.18.0.22"
                },
                "IPAddress" => "172.18.0.22"
            }
        }
      },
      'Hostname' => 'ssh'
    }
  end


  def create_network
    options = {'Name' => 'test_network',
               'CheckDuplicate' => true,
               'Driver' => 'bridge',
               "IPAM" => {
                   "Driver" => 'default',
                   "Config" => [{ 'Subnet' => '172.18.0.0/16' }]
               }
    }
    @network = Docker::Network.create('test_network', options)
  end

  def build_ssh_image(output = false)
    image = Docker::Image.build_from_dir('spec/resources', {'dockerfile' => 'Dockerfile.ssh'}) do |v|
      if (log = JSON.parse(v)) && log.has_key?("stream")
        $stdout.puts log["stream"] if output
      end
    end
    image.tag('repo' => 'serverspec-launcher-ssh', 'tag' => 'latest')
  end

  def start_ssh_container(opts = {})
    options = default_options.deep_merge opts
    build_ssh_image unless Docker::Image.exist? 'serverspec-launcher-ssh:latest'
    @container = Docker::Container.create(
        options
    )
    create_network
    networkopts = {"EndpointConfig" => { "IPAMConfig" => {"IPAddress" =>  ENV['TARGET_HOST'], "IPv4Address" =>  ENV['TARGET_HOST'] }}}
    @network.connect(@container.id,{}, networkopts)
    @container.start
    @consul_id = @container.id[0..10]
    sleep(10)
  end

  def stop_ssh_container
    @container.stop
    @container.delete
    @network.delete
  end

  def container_name
    @container.name
  end
end
