# Configuration defaults
# DEFAULT_WORKERS         = 2
DEFAULT_POOL            = "default"
DEFAULT_WORKER_TIMEOUT  = 1800  # 1h
DEFAULT_SFTP_TIMEOUT    = 600   # 10mn
DEFAULT_FTP_CHUNK       = 1024  # 1 MB
DEFAULT_PAGE_SIZE       = 50    # 50 lines
DEFAULT_RETRY_DELAY     = 10    # 10s



# Constants: logger
LOG_ROTATION             = "daily"
LOG_FORMAT_PROGNAME     = "%d\t%s"

LOG_HEADER_TIME          = "%Y-%m-%d %H:%M:%S"
LOG_HEADER_FORMAT        = "%s \t%d\t%-8s %-15s "
LOG_MESSAGE_TRIM         = 100
LOG_MESSAGE_TEXT         = "%s%s"
LOG_MESSAGE_ARRAY        = "%s     - %s"
LOG_MESSAGE_HASH         = "%s     * %-15s %s"

# Constants: logger app-specific prefix
LOG_PREFIX_WID           = 8
LOG_PREFIX_JID           = JOB_IDENT_LEN + 3 + 2
LOG_PREFIX_ID            = 6
LOG_PREFIX_FORMAT        = "W:%#{-LOG_PREFIX_WID.to_i}sJ:%#{-LOG_PREFIX_JID.to_i}sID:%#{-LOG_PREFIX_ID.to_i}s"





# Internal job constants
JOB_RANDOM_LEN          = 8
JOB_IDENT_LEN           = 4
JOB_TEMPFILE_LEN        = 8
JOB_UPDATE_INTERVAL     = 1


# Jobs statuses
JOB_STATUS_PREPARING    = "preparing"
JOB_STATUS_RUNNING      = "running"
JOB_STATUS_CHECKING_SRC = "checking_source"
JOB_STATUS_CONNECTING   = "remote_connect"
JOB_STATUS_CHDIR        = "remote_chdir"
JOB_STATUS_UPLOADING    = "uploading"
JOB_STATUS_RENAMING     = "renaming"
JOB_STATUS_PREPARED     = "prepared"
JOB_STATUS_DISCONNECTING= "remote_disconnect"
JOB_STATUS_FINISHED     = "finished"
JOB_STATUS_FAILED       = "failed"
JOB_STATUS_QUEUED       = "queued"
JOB_STYLES = {
  JOB_STATUS_QUEUED      => :active,
  JOB_STATUS_FAILED      => :warning,
  JOB_STATUS_FINISHED    => :success,
  JOB_STATUS_UPLOADING   => :info,
  JOB_STATUS_RENAMING    => :info,
  }


# Jobs statuses
JOB_METHOD_FTP           = "ftp"
JOB_METHOD_FTPS          = "ftps"
JOB_METHOD_SFTP          = "sftp"
JOB_METHOD_FILE          = "file"


# Worker statuses
WORKER_STATUS_STARTING  = "starting"
WORKER_STATUS_WAITING   = "waiting"
WORKER_STATUS_RUNNING   = "running"
WORKER_STATUS_FINISHED  = "finished"
WORKER_STATUS_TIMEOUT   = "timeout"
WORKER_STATUS_CRASHED   = "crashed"
WORKER_STATUS_CLEANING  = "cleaning"
WORKER_STYLES = {
  WORKER_STATUS_WAITING  => nil,
  WORKER_STATUS_RUNNING  => :info,
  WORKER_STATUS_CRASHED  => :danger,
  WORKER_STATUS_FINISHED => :success,
  }


# Logging and startup
LOG_COL_WID             = 8
LOG_COL_JID             = JOB_IDENT_LEN + 3 + 2
LOG_COL_ID              = 6
LOG_TRIM_LINE           = 200
LOG_DUMPS               = File.dirname(__FILE__) + "/../../log/"
LOG_FORMAT_TIME         = "%Y-%m-%d %H:%M:%S"
LOG_FORMAT_PREFIX       = "%s %s\t%-#{LOG_PIPE_LEN.to_i}s\t"
LOG_FORMAT_MESSAGE      = "%#{-LOG_COL_WID.to_i}s\t%#{-LOG_COL_JID.to_i}s\t%#{-LOG_COL_ID.to_i}s"
LOG_NEWLINE             = "\n"
MOUNT_JOBS               = "/jobs"
MOUNT_BOARD              = "/board"
MOUNT_STATUS             = "/status"
MOUNT_DEBUG              = "/debug"
MOUNT_CONFIG             = "/config"


# Notifications
NOTIFY_PREFIX           = "rftpd"
NOTIFY_USERAGENT        = "#{APP_SPEC.name}/v#{APP_SPEC.version}"
NOTIFY_IDENTIFIER_LEN   = 4

