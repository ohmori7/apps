require 'kcn-switch'
require 'kcn-dijkstra'
require 'kcn-ofc.conf'
require 'fib'

class KcnOfc < Controller
	include FIB
	include Trema::DefaultLogger

	def start
		kcn_init	# XXX
		#
		KcnHost.each do |host|
			sw = determine_nontransit_switch(host) # XXX not yet
			info host.name + " dislikes " + sw.name
			kd = KcnDijkstra.new(host)
			kd.run
			KcnFdb.update(kd)
		end
	end

	def install_fib(sw)
		fib_init(sw.dpid)
		sw.fdb.each do |e|
			fib_add(sw.dpid, e.src.ip, e.dst.ip, e.iport, e.oport)
			info "#{sw.name} #{e.src.name} #{e.dst.name} #{e.iport} #{e.oport}"
		end
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
		install_fib(sw)
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
			#forward_ipv4(dpid, m)
		else
			debug "unsupported protocol received"
		end
	end

	private

	def dpid2switch(dpid)
		return KcnSwitch.lookup_by_dpid(dpid)
	end

	def forward_ipv4(dpid, m)
		oport = resolve_out_port(dpid, m.ipv4_daddr)
		if oport == nil
			info 'unknown switch ' + dpid.to_hex
			return
		end
		if oport == m.in_port
			info 'LOOP: same in/out port resolved'
			return
		end
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
