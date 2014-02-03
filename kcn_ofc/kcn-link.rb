require 'kcn-host'
require 'kcn-switch'

class KcnLink
	attr_reader :node, :port, :maddr, :peer, :peerport, :peermaddr, :bandwidth
	@@links = Hash.new

	def initialize(name, port, maddr,
	    peername, peerport, peermaddr, bandwidth)
		@node = find_node(name, port)
		@port = port
		@maddr = maddr
		@peer = find_node(peername, peerport)
		@peerport = peerport
		@peermaddr = peermaddr
		@bandwidth = bandwidth
		@@links[node] = Array.new if @@links[node] == nil
		@@links[node].push(self)
	end

	def get_name
		return @node.name + '/' + @port.to_s
	end
	
	def get_peername
		return @peer.name + '/' + @peerport.to_s
	end

	def self.is_directly_connected?(node, peer)
		links = self.get_links(node)
		return false if links == nil
		links.each do |l|
			return true if peer == l.peer
		end
		return false
	end

	def self.get_links(node)
		return @@links[node]
	end

	def self.add(name, port, maddr, peername, peerport, peermaddr, bandwidth)
		self.new(name, port, maddr, peername, peerport, peermaddr, bandwidth)
		self.new(peername, peerport, peermaddr, name, port, maddr, bandwidth)
	end

	private

	def find_node(name, port)
		if port.class == String
			node = KcnHost[name]
		else
			node = KcnSwitch[name]
		end
		if node == nil
			raise "no such node exists: " + name
		end
		return node
	end
end
