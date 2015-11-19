
module ISO8583
  class FileParser
    PATH_DEFAULT = "/shared/bitmap.dat"

    def self.mount_parameters(data)
      if data[3].match(/[0-9]/)
        [data[1].to_i, "", ISO8583.const_get(data[2]), {:length => data[3].to_i}]
      else
        [data[1].to_i, "", ISO8583.const_get("#{data[3]}_#{data[2]}")]
      end
    end

    def create_mti(klass, mti_format, mti_messages)
      klass.mti_format *mti_format
      mti_messages.each do |number, description|
        klass.mti number, description
      end
    end

    def parse_file(filepath)
      return [] unless File.exists?(path)
      file = File.open(path, "r")

      file.readlines.inject([]) do |array, line|
        data = line.match(/([0-9]+)=\"ATT_([a-zA-Z]+);([0-9A-Z]+)/)
        next(array) unless data
        array << mount_parameters(data)
      end
    ensure
      file.close
    end

    def self.build_klass(mti_format, mti_messages, filepath = PATH_DEFAULT)
      Class.new(ISO8583::Message) do |klass|
        klass.include ISO8583
        #klass.mti_format ISO8583::N, :length => 4
        #klass.mti 200, "Authorization Request Acquirer Gateway"
        create_mti(klass, mti_format, mti_messages)

        parse_file(filepath).each do |parameters|
          klass.bmp(*parameters)
        end
      end
    end
  end
end
