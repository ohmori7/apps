class KcnFdb
	class KcnFdbEntry
		attr_reader :src, :dst, :iport, :oport
		def initialize(src, dst, iport, oport)
			@src = src
			@dst = dst
			@iport = iport
			@oport = oport
		end
	end

	def initialize
		@fdb = Hash.new
	end

	def each(&block)
		@fdb.values.each do |a|
			a.each(&block)
		end
	end

	def update(src, dst, iport, oport)
		kfe = lookup(src, dst)
		if kfe == nil
			kfe = KcnFdbEntry.new(src, dst, iport, oport)
			if @fdb[hash(src, dst)] == nil
				@fdb[hash(src, dst)] = Array.new
			end
			@fdb[hash(src, dst)].push(kfe)
		elsif kfe.iport != iport || kfe.oport != oport
			kfe.iport = iport
			kfe.oport = oport
		else
			return false
		end
		return true
	end

	def lookup(src, dst)
		h = @fdb[hash(src, dst)]
		return nil if h == nil
		h.values.each do |e|
			return e if e.src == src && e.dst == dst
		end
	end

	def self.update(kd)
		kd.each do |v|
			next if v.is_root?
			next if v.node.class != KcnHost
			iport = nil
			prevsw = nil
			path = v.get_path
			v.get_path.each do |l|
				node = l.node
				if node.class == KcnSwitch
					raise 'invalid path' if node != prevsw
					raise 'bug' if iport == nil
					src = kd.root
					dst = v.node
					oport = l.port
					node.fdb.update(src, dst, iport, oport)
					iport = l.peerport
				elsif node.class == KcnHost
					if l.peer.class != KcnSwitch
						raise 'invalid path'
					end
					iport = l.peerport
				else
					raise 'bug'
				end
				break if l.peer.class == KcnHost
				prevsw = l.peer
			end
		end
	end

	private

	def hash(src, dst)
		return src.name + dst.name
	end
end