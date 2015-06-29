#!/usr/bin/env ruby

def api_request(op)
  total_tries = 3
  tries ||= total_tries
  @logger.debug "API call: #{op} (try #{total_tries-tries+1}/#{total_tries})"

  data = eval(op)

rescue Exception
  retry if (tries -= 1) > 0

  msg = "failure executing #{op}"
  @logger.fatal msg
  raise msg
else
  data
end


def save_file(path, data, verbose = false)
  msg = "#{path}"
  @logger.info "saving #{msg}"
  puts msg if verbose

  dir = File.dirname(path)
  unless File.directory?(dir)
    @logger.debug "creating directory #{dir}"
    FileUtils.mkdir_p(dir)
  end

  f = File.open(path, 'w')
  #pretty = JSON.pretty_generate(data)
  pretty = JSON.pretty_generate(data.to_hash)
  bytes = f.write(pretty)
  f.close

rescue Errno::EACCES
  msg = "permission denied saving file #{path}"
  @logger.fatal msg
  raise msg
rescue Exception
  msg = "error saving file #{path}"
  @logger.fatal msg
  raise msg
else
  bytes
end

