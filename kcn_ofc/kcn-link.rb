require 'kcn-host'
require 'kcn-switch'

class KcnLink
	attr_reader :node, :port, :peer, :peerport, :bandwidth
	@@links = Hash.new

	def initialize(name, port, peername, peerport, bandwidth)
		@node = find_node(name, port)
		@port = port
		@peer = find_node(peername, peerport)
		@peerport = peerport
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

	def self.add(name, port, peername, peerport, bandwidth)
		self.new(name, port, peername, peerport, bandwidth)
		self.new(peername, peerport, name, port, bandwidth)
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
