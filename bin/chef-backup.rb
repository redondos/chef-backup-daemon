#!/usr/bin/env ruby

execpath = File.expand_path(File.join(File.dirname(__FILE__), ".."))
$:.unshift(File.join(execpath, "lib"))

require 'yaml'
require 'logger'
require 'optparse'
require 'ostruct'

require 'git'
require 'repo'
require 'util'
require 'chef/knife'
require 'chef/api_client'
require 'chef/user'
require 'chef/node'

config = YAML.load_file(File.join(execpath, 'config', 'chef-backup.yml'))['chef-backup']

logfile = config['logfile'] ? config['logfile'] : File.join('log', File.basename(__FILE__) + '.log')

begin
  FileUtils.mkdir_p(File.dirname(logfile)) unless File.exists? File.dirname(logfile)
  @logger = Logger.new logfile
rescue Errno::EACCES
  STDERR.puts "permission denied creating logfile #{logfile}, exiting"
end

@logger.level = config['loglevel'] ? Logger.const_get(config['loglevel']) : Logger::INFO

@options = OpenStruct.new
@options.verbose = false
@options.path = config['path'] ? config['path'] : "#{ENV['PWD']}/backup"

OptionParser.new do |opts|
  opts.banner = "Usage: #{ARGV[0]} [options]"

  opts.on('-v', '--[no-]verbose', 'enable verbose') do |v|
    @options[:verbose] = v
  end

  opts.on('-p', '--path PATH', 'save files in PATH') do |path|
    @options[:path] = path
  end
end.parse!

Chef::Knife.new.configure_chef

path = @options[:path]

begin
  r = Git::Base.open(path, {log: @logger})
rescue ArgumentError
  repo_url = config['repo_url']
  unless repo_url
    msg = 'local git repository does not exist, please specify repo_url in the config file'
    @logger.fatal msg
    STDERR.puts msg
    exit 15
  end

  msg = "local git repository does not exist, cloning from `#{repo_url}' into `#{path}'"
  @logger.warn msg
  STDERR.puts msg

  r = Git.clone(repo_url, path)
rescue
  msg = 'unable to create/clone repository'
  @logger.fatal msg
  STDERR.puts msg
  STDERR.puts "Exception: #{$!}", $@
  exit 10
end

# empty working tree
r.clean

# fetch objects

## Nodes, roles, environments
objects = {
  nodes: Chef::Node,
  users: Chef::User,
  clients: Chef::ApiClient,
  roles: Chef::Role,
  environments: Chef::Environment,
}

objects.each do |type, klass|
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
    break
  end
end

## Data bags
STDERR.puts "Saving data bags..."
api_request("Chef::DataBag.list").keys.each do |bag|
  api_request("Chef::DataBag.load('#{bag}')").keys.each do |item|
    path = "#{@options[:path]}/data_bags/#{bag}/#{item}.json"
    data = api_request("Chef::DataBag.load('#{bag}/#{item}')")
    save_file(path, data, @options[:verbose])
    break
  end
  break
end

# update tree
r.update_all

