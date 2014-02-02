require 'kcn-switch'
require 'kcn-dijkstra'
require 'kcn-ofc.conf'
require 'fib'

class KcnOfc < Controller
	include FIB
	include Trema::DefaultLogger

	def start
		@is_reactive = true	# XXX should make this config

		kcn_init	# XXX
		#
		return if @is_reactive
		KcnHost.each do |host|
			sw = determine_nontransit_switch(host) # XXX not yet
			info host.name + " dislikes " + sw.name
			kd = KcnDijkstra.new(host)
			kd.run
			KcnFdb.update(kd)
		end
	end

	def install_fib(sw)
		sw.fdb.each do |e|
			fib_add(sw.dpid, e.src.ip, e.dst.ip, e.iport, e.oport)
			info "#{sw.name} #{e.src.name} #{e.dst.name} #{e.iport} #{e.oport}"
		end
	end

	def install_fib_by_flow(sw, src, dst, sport, dport)
		shost = KcnHost.lookup_by_key(src.to_s)
		dhost = KcnHost.lookup_by_key(dst.to_s)
		return nil if shost == nil or dhost == nil
		kd = KcnDijkstra.new(shost)
		kd.run
		#KcnFdb.update(kd)
		v = kd.lookup(dhost)
		return nil if v == nil
		# XXX update local fib
		iport = nil
		oport = nil
		prevsw = nil
		v.get_path.each do |l|
			node = l.node
			if node.class == KcnSwitch
				oport = l.port if node == sw
				fib_add_flow(node.dpid, src, dst, sport, dport,
				    iport, l.port)
				iport = l.peerport
			elsif node.class == KcnHost
				iport = l.peerport
			end
			break if l.peer.class == KcnHost
			prevsw = l.peer
		end
		return oport
	end

	def switch_ready(dpid)
		sw = dpid2switch(dpid)
		if sw == nil
			info "unknown switch #{dpid.to_hex} gets UP";
			return
		end
		return if sw.is_up?
		info "Switch #{sw.name} (#{dpid.to_hex}) gets UP";
		sw.up
		fib_init(sw.dpid)
		install_fib(sw) if ! @is_reactive
	end

	def switch_disconected(dpid)
		sw = dpid2switch(dpid)
		if sw == nil
			info "unknown switch #{dpid.to_hex} gets DOWN";
			return
		end
		info "Switch #{sw.name} (#{dpid.to_hex}) gets DOWN";
	end

	def packet_in(dpid, m)
		sw = dpid2switch(dpid)
		swname = sw != nil ? sw.name : "unknown"
		debug "received a packet from #{swname}"
		debug "datapath_id: #{dpid.to_hex}"
		debug "transaction_id: #{m.transaction_id.to_hex}"
		debug "buffer_id: #{m.buffer_id.to_hex}"
		debug "total_len: #{m.total_len}"
		debug "in_port: #{m.in_port}"
		debug "reason: #{m.reason.to_hex}"
		debug "data: #{m.data.unpack "H*"}"
		if m.ipv4?
			debug "IPv4 src: #{m.ipv4_saddr}"
			debug "IPv4 dst: #{m.ipv4_daddr}"
		else
			debug "unsupported protocol received"
			return
		end
		return if ! @is_reactive
		if ! m.tcp?
			info "unsupported transport protocol received"
			return
		end
		oport = install_fib_by_flow(sw, m.ipv4_saddr, m.ipv4_daddr,
		    m.tcp_src_port, m.tcp_dst_port)
		return if oport == nil
		forward_ipv4(dpid, oport, m)
	end

	private

	def dpid2switch(dpid)
		return KcnSwitch.lookup_by_dpid(dpid)
	end

	def forward_ipv4(dpid, oport, m)
		info 'LOOP: same in/out port resolved' if oport == m.in_port
		action = [ SendOutPort.new(oport) ]
		send_packet_out(dpid, :data => m.data, :actions => action)
	end

	def determine_nontransit_switch(host)
		while true do
			n = rand(KcnSwitch.instances.size)
			swnames = KcnSwitch.instances.keys
			sw = KcnSwitch[swnames[n]]
			return sw if ! KcnLink.is_directly_connected?(host, sw)
		end
	end
end
