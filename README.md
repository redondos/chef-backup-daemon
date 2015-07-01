# Chef-Backup-Daemon

chef-backup-daemon is a service that will retrieve objects from a Chef API server and store a JSON-serialized copy in a local or remote Git repository. This can serve as a backup system for your Chef repo, including encrypted data bags such as those created by [chef-vault](https://github.com/Nordstrom/chef-vault).

## Installation
This service requires Ruby >= 1.9.3, as well as a few gems.

Clone the repository and run `bundle install` to obtain the required dependencies.

## Configuration

Chef API configuration will be imported from your knife.rb file, see the [knife.rb documentation](https://docs.chef.io/config_rb_knife.html).


In addition, the daemon will loook for a file named `config/chef-backup.yml`, and accepts the following settings:

- `path`: path to git repository to back up to (default: $PWD/backup)
- `repo_url`: if `path` does not exist, clone repository from this URL
- `logfile`: file to log status to (default: `log/chef-backup-daemon.log`, relative to $PWD)
- `piddir`: directory where chef-backup-daemon.pid will be created (default: $PWD)
- `loglevel`: see the [Logger documentation](http://ruby-doc.org/stdlib-2.1.0/libdoc/logger/rdoc/Logger.html) (default: INFO)
- `frequency`: interval between backups, in minutes (default: 30)
- `push`: whether to push to a remote repository after backup has been created (default: true)

## Usage
`$ ruby bin/chef-backup-daemon.rb`

Options:
- `-v | --verbose`: output status progress to STDERR
- `-d | --daemon`: daemonize process
- `-p | --path`: override git repository path specified in config file

## Objects
This service currently stores:
- Nodes
- Roles
- Environments
- Data bags

It can also back up:
- Clients
- Users

Chef Client keys are not able to obtain the required permissions to read the latter, so this is disabled by default. If you'd like to back up client and user objects, please use a real Chef user's private key.

## Version
0.0.1

## Author
Angelo Olivera (aolivera@gmail.com)

## License
GPL, Version 2.0

