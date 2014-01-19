require 'kcn-host'
require 'kcn-switch'

class KcnDijkstra
	class KcnVertex
		attr_accessor :plink, :spf
		attr_reader :node, :distance

		def initialize(node, distance, pv, plink)
			@node = node
			@distance = distance
			@pv = pv
			@plink = plink
			@spf = false
		end

		def <=> (other) 
			return @distance - other.distance
		end

		def is_root?
			return @plink == nil
		end

		def get_path
			return Array.new if @plink == nil
			path = @pv.get_path
			path.push(@plink)
			return path
		end
	end

	attr_reader :root

	def initialize(root)
		@root = root
		@vertextable = Hash.new
		@candidatelist = Array.new
		add(root, nil, nil)
	end

	def each(&block)
		@vertextable.values.each(&block)
	end

	def dump
		each do |v|
			puts 'From ' + @root.name + ' to ' + v.node.name
			path = v.get_path
			path.each do |l|
				print l.get_name + ' -> ' + l.get_peername + ' '
			end
			print "\n"
		end
	end

	def run
		while (v = get_nearest) != nil do
			next if ! v.is_root? && v.node.class == KcnHost
			links = KcnLink.get_links(v.node)
			links.each do |l|
				add(l.peer, v, l)
			end
		end
	end

	private

	def add(node, v, l)
		if v == nil
			distance = 0
		else
			distance = v.distance + 1
		end
		w = lookup(node)
		if w != nil
			return w if w.spf
			return w if w.distance < distance
			return w if w.distance == distance
			w.distance = distance
			w.pv = v
			w.plink = l
			return w
		end
		w = KcnVertex.new(node, distance, v, l)
		@vertextable[node] = w
		@candidatelist.unshift(w)
		return w
	end

	def lookup(node)
		return @vertextable[node]
	end

	def get_nearest
		return nil if @candidatelist.size == 0
		@candidatelist.sort!
		v = @candidatelist.shift
		v.spf = true
		return v
	end
end
