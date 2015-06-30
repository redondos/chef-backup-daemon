require 'git'

#Git.configure do |config|
  #true
  #config.git_ssh = 
#end

class Git::Base

  def clean
    path = @working_directory.to_s
    entries = Dir.entries(path).
      select { |i| !['.', '..', '.git'].include? i }.
      map { |i| File.join(path, i) }
    FileUtils.rm_rf(entries)
  end

  def update_all
    #modified = repo.status.select {|obj| obj.type == 'M' }.map { |obj| obj.path }
    #untracked = repo.status.select {|obj| obj.untracked == true }.map { |obj| obj.path }
    self.add(all: true)

    deleted = self.status.deleted.keys
    self.remove(deleted) if deleted.any?

    if self.tainted?
      self.commit(Time.now.strftime "Snapshot from %Y-%m-%d %H:%M:%S UTC (%a)").lines.first
    else
      'no changes'
    end
  end
end

