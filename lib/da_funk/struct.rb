module DaFunk
  class Struct
    attr_accessor :values, :members

    def self.klass(*variables)
      Proc.new do |*args|
        struct = DaFunk::Struct.new(*variables)
        args.each_with_index do |value, index|
          struct.send("#{variables[index]}=", value)
        end
        struct
      end
    end

    def initialize(*variables)
      self.members = variables
      self.values  = variables.inject({}){|hash,v| hash[v.to_sym] = nil; hash}
    end

    def []=(key, value)
      self.values[key] = value
    end

    def [](key)
      self.values[key]
    end

    def method_missing(method, *args, &block)
      param = method.to_s
      if self.include? method
        self[method]
      elsif (param[-1..-1] == "=" && self.include?(key = param[0..-2]))
        self[key.to_sym] = args.first
      else
        super
      end
    end

    def include?(key)
      self.members.include?(key.to_sym)
    end
  end
end

