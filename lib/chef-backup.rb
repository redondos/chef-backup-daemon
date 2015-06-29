require 'git'
require 'repo'
require 'util'
require 'chef/knife'
require 'chef/api_client'
require 'chef/user'
require 'chef/node'

require 'chef-backup/version'

module ChefBackup

  ObjectTypes ||= {
    roles: Chef::Role,
    environments: Chef::Environment,
    users: Chef::User,
    nodes: Chef::Node,
    clients: Chef::ApiClient,
  }

  class Backup
    def initialize(options)
      Chef::Knife.new.configure_chef

      @options = options
      @logger = options['logger']
    end

    def backup_environments
      self.backup_common(__method__.to_s.gsub(/.*_/, ''))
    end

    def backup_roles
      self.backup_common(__method__.to_s.gsub(/.*_/, ''))
    end

    def backup_users
      self.backup_common(__method__.to_s.gsub(/.*_/, ''))
    end

    def backup_nodes
      self.backup_common(__method__.to_s.gsub(/.*_/, ''))
    end

    def backup_clients
      self.backup_common(__method__.to_s.gsub(/.*_/, ''))
    end

    def backup_common(type)

      klass = ObjectTypes[type.to_sym]
      count = 0

      STDERR.puts "Saving #{type}..."
      klass.list.keys.each do |item|
        data = api_request("#{klass}.load('#{item}')")
        if klass == Chef::Node
          delete_keys = [ 'last_successful_run' ]
          data = {
            "name" => data.name,
            "chef_environment" => data.chef_environment,
            "run_list" => data.primary_runlist.run_list.map { |k| k.to_s },
            "normal" => data.attributes.normal.delete_if{ |k,_| delete_keys.include? k},
          }
        end
        path = "#{@options['path']}/#{type}/#{item}.json"
        save_file(path, data, @options[:verbose])
        count += 1
      end

      count
    end

    def backup_data_bags
      count = 0
      STDERR.puts "Saving data bags..."
      api_request("Chef::DataBag.list").keys.each do |bag|
        api_request("Chef::DataBag.load('#{bag}')").keys.each do |item|
          path = "#{@options[:path]}/data_bags/#{bag}/#{item}.json"
          data = api_request("Chef::DataBag.load('#{bag}/#{item}')")
          save_file(path, data, @options[:verbose])
          count += 1
        end
      end

      count
    end

    def configure_repo
      path = @options[:path]

      begin
        repo = Git::Base.open(path, {log: @logger})
      rescue ArgumentError
        repo_url = @options[:repo_url]
        unless repo_url
          msg = 'local git repository does not exist, please specify repo_url in the config file'
          @logger.fatal msg if @logger
          raise Git::GitExecuteError, msg
        end

        msg = "local git repository does not exist, cloning from `#{repo_url}' into `#{path}'"
        @logger.warn msg if @logger
        STDERR.puts msg

        repo = Git.clone(repo_url, path)
      rescue
        msg = 'unable to create/clone repository'
        @logger.fatal msg if @logger
        STDERR.puts msg
        STDERR.puts "Exception: #{$!}", $@
        exit 10
      end

      repo
    end

    def run

      @repo = self.configure_repo

      # empty working tree
      @repo.clean

      # Back up all common types
      ObjectTypes.keys.each do |type|
        total = self.send('backup_' + type.to_s)
        @logger.info "total: #{total}" if @logger
      end

      # Back up data bags
      self.backup_data_bags

      # update tree
      @repo.update_all
    end

  end
end

