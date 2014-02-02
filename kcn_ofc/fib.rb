module FIB
	TABLE_ID = 0
	ETHER_TYPE_IP = 0x0800

	# XXX
	OFP_NO_BUFFER = 0xffffffff
	OFPCML_NO_BUFFER = 0xffff

	def fib_add(dpid, ipsrc, ipdst, iport, oport)
		action = SendOutPort.new(port_number: oport)
		match = Match.new(
		    in_port: iport,
		    dl_type: ETHER_TYPE_IP,
		    nw_src: ipsrc, nw_dst: ipdst
		    )
		send_flow_mod_add(
		    dpid,
		    table_id: TABLE_ID,
		    buffer_id: OFP_NO_BUFFER,
		    match: match,
		    actions: [action],
		    strict: true
		    )
	end

	def fib_del(dpid, ipsrc, ipdst, iport, oport)
		match = Match.new(
		    in_port: iport,
		    dl_type: ETHER_TYPE_IP,
		    nw_src: ipsrc, nw_dst: ipdst
		    )
		send_flow_mod_del(
		    dpid,
		    table_id: TABLE_ID,
		    #priority: OFP_DEFAULT_PRIORITY,
		    out_port: oport,
		    out_group: OFPG_ANY,
		    match: match,
		    strict: true
		    )
	end

	def fib_add_flow(dpid, ipsrc, ipdst, sport, dport, iport, oport)
		action = SendOutPort.new(port_number: oport)
		match = Match.new(
		    in_port: iport,
		    dl_type: ETHER_TYPE_IP,
		    nw_proto: 6,	# XXX only TCP
		    nw_src: ipsrc, nw_dst: ipdst,
		    tp_src: sport, tp_dst: dport
		    )
		send_flow_mod_add(
		    dpid,
		    table_id: TABLE_ID,
		    buffer_id: OFP_NO_BUFFER,
		    match: match,
		    actions: [action],
		    strict: true
		    )
	end

	def fib_add_miss_flow_entry(dpid, table_id)
		action = SendOutPort.new(
		    port_number: Controller::OFPP_CONTROLLER,
		    max_len: OFPCML_NO_BUFFER)
		send_flow_mod_add(
		    dpid,
		    table_id: table_id,
		    idle_timeout: 0,
		    hard_timeout: 0,
		    #priority: OFP_LOW_PRIORITY,
		    buffer_id: OFP_NO_BUFFER,
		    actions: [action]
		    )
	end

	def fib_init(dpid)
		fib_add_miss_flow_entry(dpid, TABLE_ID)
	end
end
