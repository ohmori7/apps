class KcnNode
	attr_reader :name, :key

	class << self
		attr_accessor :instances
		attr_accessor :instances_by_key
	end

	def initialize(name, key, up)
		@name = name
		@key = key
		@up = up
	end

	def up
		@up = true
	end

	def down
		@up = false
	end

	def is_up?
		return @up
	end

	def self.inherited(subclass)
		subclass.instances ||= Hash.new
		subclass.instances_by_key ||= Hash.new
	end

	def self.[](name)
		return nil if instances == nil
		instances[name]
	end

	def self.add(obj)
		return if instances == nil
		instances[obj.name] = obj
		instances_by_key[obj.key] = obj if obj.name != nil
	end

	def self.lookup_by_key(key)
		return nil if instances_by_key == nil
		instances_by_key[key]
	end

	def self.each &block
		return nil if instances == nil
		instances.values.each do | n |
			block.call n
		end
	end
end
