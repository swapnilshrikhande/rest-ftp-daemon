
# Global libs
require "rubygems"
require "json"
require "haml"
require "uri"
require "timeout"
require "syslog"
require "net/http"
require "thread"
require "singleton"
require "grape"
require "grape-entity"
require "newrelic_rpm"


# Shared libs
require_relative "shared/logger_formatter"
require_relative "shared/logger_helper"
require_relative "shared/conf"
require_relative "shared/worker_base"


# Project's libs
require_relative "rest-ftp-daemon/constants"
require_relative "rest-ftp-daemon/array"
require_relative "rest-ftp-daemon/exceptions"
require_relative "rest-ftp-daemon/helpers"
require_relative "rest-ftp-daemon/logger_pool"
require_relative "rest-ftp-daemon/metrics"
require_relative "rest-ftp-daemon/paginate"
require_relative "rest-ftp-daemon/uri"
require_relative "rest-ftp-daemon/job_queue"
require_relative "rest-ftp-daemon/counters"
require_relative "rest-ftp-daemon/worker_pool"
require_relative "rest-ftp-daemon/workers/conchita"
require_relative "rest-ftp-daemon/workers/reporter"
require_relative "rest-ftp-daemon/workers/job"
require_relative "rest-ftp-daemon/job"
require_relative "rest-ftp-daemon/notification"

require_relative "rest-ftp-daemon/path"
require_relative "rest-ftp-daemon/remote"
require_relative "rest-ftp-daemon/remote_ftp"
require_relative "rest-ftp-daemon/remote_sftp"

require_relative "rest-ftp-daemon/api/job_presenter"
require_relative "rest-ftp-daemon/api/jobs"
require_relative "rest-ftp-daemon/api/dashboard"
require_relative "rest-ftp-daemon/api/status"
require_relative "rest-ftp-daemon/api/config"
require_relative "rest-ftp-daemon/api/debug"
require_relative "rest-ftp-daemon/api/root"

# Haml monkey-patching
require_relative "rest-ftp-daemon/patch_haml"
