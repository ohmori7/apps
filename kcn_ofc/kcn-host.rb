require 'kcn-node'

class KcnHost < KcnNode
	alias ip key

	def initialize(name, ip)
		super(name, ip, true)
		KcnHost.add(self)
	end
end
