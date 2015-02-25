class Device
  class ParamsDat
    FILE_NAME = "./main/params.dat"

    include Device::Helper

    class << self
      attr_accessor :file, :apps, :status
    end

    self.apps = Hash.new

    # To control if there is any app and parse worked
    self.status = false

    def self.setup
      if File.exists?(FILE_NAME)
        @file = FileDb.new(FILE_NAME)
      else
        false
      end
    end

    # TODO Scalone: Change after @bmsatierf change the format
    # For each apps on apps_list We'll have:
    # Today: <label>,<arquivo>,<pages>,<crc>;
    # After: <label>,<arquivo>,<type>,<crc>;
    # Today: "1 - App,pc2_app.posxml,1,E0A0;"
    # After: "1 - App,pc2_app.posxml,posxml,E0A0;"
    # After: "1 - App,pc2_app.zip,ruby,E0A0;"
    def self.parse_apps
      return unless self.setup

      @apps = []
      self.file["apps_list"].to_s.gsub("\"", "").split(";").each do |app|
        @apps << Device::Application.new(*app.split(","))
      end

      if (@apps.size >= 1)
        self.status = true
      else
        self.status = false
      end
    end

    def self.download
      if attach
        Device::Display.clear
        puts "Downloading Params"
        ret = Device::Transaction::Download.request_param_file(FILE_NAME)
        if value = check_download_error(ret)
          puts "Downloaded Successfully"
          Device::Network.close_socket
          # TODO
          #Device::Network.walk_socket.close unless Device::Network.walk_socket.closed?
          parse_apps
        end
        value
      end
    end

    def self.update_apps
      self.download unless self.status
      if self.status
        Device::Display.clear
        Device::Display.print("Press to Download #{@apps.size} apps", 3)
        getc

        @apps.each do |app|
          self.update_app(app)
        end
      end
    end

    def self.update_app(application)
      if attach && application
        Device::Display.clear
        puts "Downloading #{application.label}..."
        ret = Device::Transaction::Download.request_file(application.file_path, application.zip)
        Device::Network.close_socket
        # TODO
        #Device::Network.walk_socket.close unless Device::Network.walk_socket.closed?

        unless check_download_error ret
          sleep 2
        end
      end
    end

    def self.apps
      self.parse_apps unless self.status
      @apps
    end

    def self.executable_app
      selected = self.executable_apps
      if selected.size == 1
        selected[selected.keys.first]
      end
    end

    def self.executable_apps
      self.apps.select{|app| app.label != "X"}
    end

    def self.application_menu
      options = executable_apps.sort{|app| app.label}.group_by{|app| app.label}
      menu("Application Menu", options)
    end
  end
end

