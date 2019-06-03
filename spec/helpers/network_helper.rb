# frozen_string_literal: true

require 'socket'

class IpInfo
  def self.default_gateway
    `which ip`.empty? ? mac_os_gateway : linux_gateway
  end

  def self.mac_os_gateway
    ip_from `route -n get default | grep gateway`
  end

  def self.linux_gateway
    ip_from `ip route | grep default`
  end

  def self.ip_from(str)
    str.match(/([0-9]{1,3}\.){3}([0-9]{1,3}){1}/).to_s
  end

  def self.first_two(str)
    str.match(/([0-9]{1,3})\.([0-9]{1,3})/).to_s
  end

  def self.default_nic
    local_ip
  end

  def self.local_ip
    orig = Socket.do_not_reverse_lookup
    Socket.do_not_reverse_lookup = true # turn off reverse DNS resolution temporarily

    UDPSocket.open do |s|
      s.connect default_gateway, 1
      s.addr.last
    end
  ensure
    Socket.do_not_reverse_lookup = orig
  end
end

module NetworkHelper
  def default_nic
    IpInfo.local_ip
  end
end
