require 'kcn-node'
require 'kcn-fdb'

class KcnSwitch < KcnNode
	attr_reader :fdb
	alias dpid key

	def initialize(name, dpid)
		super(name, dpid, false)
		KcnSwitch.add(self)
		@fdb = KcnFdb.new
	end

	def self.lookup_by_dpid(dpid)
		return self.lookup_by_key(dpid)
	end
end
