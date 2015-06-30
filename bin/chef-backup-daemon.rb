#!/usr/bin/env ruby

execpath = File.expand_path(File.join(File.dirname(__FILE__), ".."))
$:.unshift(File.join(execpath, "lib"))

app = File.basename($0, File.extname($0))

require 'yaml'
require 'fileutils'
require 'pathname'

begin
  config = YAML.load_file(File.join(execpath, 'config', 'chef-backup.yml'))['chef-backup']
rescue Errno::ENOENT
  config = YAML.load_file(File.join('config', 'chef-backup.yml'))['chef-backup']
end

require 'optparse'
require 'ostruct'

@options = OpenStruct.new
@options.verbose = false
@options.daemon = false
@options.path = config['path'] ? config['path'] : "#{ENV['PWD']}/backup"
@options.piddir = config['piddir'] ? config['piddir'] : "#{ENV['PWD']}"
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

  opts.on('-d', '--daemon', 'daemonize') do |daemon|
    @options[:daemon] = daemon
  end
end.parse!

logfile = config['logfile'] ? config['logfile'] : File.join('log', File.basename(__FILE__) + '.log')
logfile = File.join(execpath, logfile) if ! (Pathname.new logfile).absolute?

require 'daemons'
require 'logger'

daemon_opts = {
  ontop:       !@options[:daemon],
  dir:         @options[:piddir],
  dir_mode:    :normal,
  app_name:    app,
  backtrace:   false,
  log_output:  false,
}

Daemons.daemonize(daemon_opts)

begin
  FileUtils.mkdir_p(File.dirname(logfile)) unless File.exists? File.dirname(logfile)
  @logger = Logger.new logfile
rescue Errno::EACCES
  STDERR.puts "permission denied creating logfile #{logfile}"
end

@logger.level = config['loglevel'] ? Logger.const_get(config['loglevel']) : Logger::INFO

@options.logger = @logger
@options.logfile = logfile

mode = @options[:daemon] ? "daemonized" : "foreground"
@logger.info "Starting chef-backup-daemon (#{mode}), backup path: #{@options['path']}" if @logger

require 'chef-backup'

backup = ChefBackup::Backup.new(@options)
frequency = @options['backup_frequency']

loop {
  begin
    backup.run
  rescue Exception
    @logger.fatal $!
    @logger.fatal $@
    STDERR.puts $!, $@
  end

  msg = "sleeping #{frequency}s"
  @logger.info msg
  STDERR.puts msg
  sleep frequency
}

