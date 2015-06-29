#!/usr/bin/env ruby

execpath = File.expand_path(File.join(File.dirname(__FILE__), ".."))
$:.unshift(File.join(execpath, "lib"))

require 'yaml'
require 'logger'
require 'ostruct'
require 'optparse'

require 'chef-backup'

begin
  config = YAML.load_file(File.join(execpath, 'config', 'chef-backup.yml'))['chef-backup']
rescue Errno::ENOENT
  config = YAML.load_file(File.join('config', 'chef-backup.yml'))['chef-backup']
end

logfile = config['logfile'] ? config['logfile'] : File.join('log', File.basename(__FILE__) + '.log')

begin
  FileUtils.mkdir_p(File.dirname(logfile)) unless File.exists? File.dirname(logfile)
  @logger = Logger.new logfile
rescue Errno::EACCES
  STDERR.puts "permission denied creating logfile #{logfile}"
end

@logger.level = config['loglevel'] ? Logger.const_get(config['loglevel']) : Logger::INFO

@options = OpenStruct.new
@options.logger = @logger
@options.verbose = false
@options.path = config['path'] ? config['path'] : "#{ENV['PWD']}/backup"
@options.repo_url = config['repo_url'] ? config['repo_url'] : nil
@options.backup_frequency = config['frequency'] ? config['frequency'] : 30
@options.backup_frequency *= 60 # minutes to seconds
@options.push = !config['push'].nil? ? config['push'] : true

OptionParser.new do |opts|
  opts.banner = "Usage: #{ARGV[0]} [options]"

  opts.on('-v', '--[no-]verbose', 'enable verbose') do |v|
    @options[:verbose] = v
  end

  opts.on('-p', '--path PATH', 'save files in PATH') do |path|
    @options[:path] = path
  end
end.parse!

b = ChefBackup::Daemon.new(@options)

begin
  b.run
rescue Interrupt
  @logger.info "received interrupt, exiting"
end


