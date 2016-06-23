# coding: utf-8
Gem::Specification.new do |spec|

  # Project version
  spec.version      = "0.300.3"

  # Project description
  spec.name                   = "rest-ftp-daemon"
  spec.authors                = ["Bruno MEDICI"]
  spec.email                  = "rest-ftp-daemon@bmconseil.com"
  spec.description            = "This is a pretty simple FTP client daemon, controlled through a RESTful API"
  spec.summary                = "RESTful FTP client daemon"
  spec.homepage               = "http://github.com/bmedici/rest-ftp-daemon"
  spec.licenses               = ["MIT"]
  spec.date                   = Time.now.strftime("%Y-%m-%d")

  # List files and executables
  spec.files                  = `git ls-files -z`.split("\x0").reject{ |f| f == "dashboard.png"}
  spec.executables            = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths          = ["lib"]
  spec.required_ruby_version  = ">= 2.2"


  # Development dependencies
  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "http"
  spec.add_development_dependency "rubocop", "~> 0.32.0"
  spec.add_development_dependency "pry"

  # Runtime dependencies
  spec.add_runtime_dependency "thin", "~> 1"
  spec.add_runtime_dependency "grape"
  spec.add_runtime_dependency "grape-entity"
  spec.add_runtime_dependency "settingslogic"
  spec.add_runtime_dependency "chamber"
  spec.add_runtime_dependency "haml"
  spec.add_runtime_dependency "json"
  spec.add_runtime_dependency "net-sftp"
  spec.add_runtime_dependency "double-bag-ftps"
  spec.add_runtime_dependency "facter"
  spec.add_runtime_dependency "sys-cpu"
  spec.add_runtime_dependency "get_process_mem"
  spec.add_runtime_dependency "newrelic_rpm"
end
