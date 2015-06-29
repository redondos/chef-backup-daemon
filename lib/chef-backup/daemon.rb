require 'chef-backup'

module ChefBackup

  class Daemon
    def initialize(options)
      @backup = Backup.new(options)
      @logger = options['logger']
      @frequency = (options['backup_frequency'])
    end


    def run

      @repo = @backup.configure_repo

      # empty working tree
      @repo.clean

      # Back up all common types
      ObjectTypes.keys.each do |type|
        total = @backup.send('backup_' + type.to_s)
        @logger.info "total: #{total}" if @logger
      end

      # Back up data bags
      @backup.backup_data_bags

      # update tree
      @repo.update_all
    end


    def run(frequency = 1800)

      while true
        @backup.run
        msg = "sleeping #{frequency}"
        @logger.info msg
        sleep frequency
      end

    end

  end
end

