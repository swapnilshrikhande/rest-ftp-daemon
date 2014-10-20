rest-ftp-daemon
====================================================================================



This is a pretty simple FTP client daemon, controlled through a RESTfull API.

As of today, its main features are :

* Allow environment-specific configuration in a YAML file
* Delegate a transfer job by ``POST```'ing a simple JSON structure
* Spawn a dedicated thread to handle this job in its own context
* Report transfer status, progress and errors for each job in realtime
* Expose JSON status of workers on ```GET /jobs/``` for automated monitoring
* Parralelize jobs as soon as they arrive
* Handle job queues and priority as an attribute of the job
* Allow dynamic evaluation of priorities, and change of any attribute until the job is picked
* Provide RESTful notifications to the requesting client
* Allow authentication in FTP target in a standard URI-format
* Allow configuration-based path templates to abstract local mounts or remote FTPs (endpoint tokens)
* Remote supported protocols: FTP and FTPs
* Allow main file transfer protocols: sFTP, FTPs / FTPes
* Automatically clean-up jobs after a configurable amount of time (failed, finished)

Expected features in a short-time range :

* Allow change of priorities or other attributes after a job has been started
* Offer a basic dashboard directly within the daemon HTTP interface
* Periodically send an update-notification with transfer status and progress
* Allow fallback file source when first file path is unavailable (failover)
* Provide swagger-style API documentation
* Authenticate API clients
* Allow to specify random remote/local source/target
* Allow more transfer protocols (sFTP, HTTP POST etc)



Installation
------------------------------------------------------------------------------------

This project is available as a rubygem, requires Ruby 2.1 and rubygems installed.


You may use ```rbenv``` and ```ruby-build``` to get the right Ruby version

```
# apt-get install ruby-build rbenv

```

Use a dedicated user for the daemon

```
# useradd rftpd
# su rftpd -l
```

Install the right ruby version, update rubygems

```
# rbenv install 2.1.0
# rbenv local 2.1.0
# rbenv rehash
# gem update --system
```

Get and install the gem from rubygems.org

```
# gem install rest-ftp-daemon --no-ri --no-rdoc
# rest-ftp-daemon start
```

Finally start the daemon on the standart port, or on a specific port using ```-p```

```
# rest-ftp-daemon -p 4000 start
```

Check that the daemon is running and providing its status info.
If the daemon seems to exit as soon as it's launched, this may be due to logfiles that cannot be written on (check permissions or owner).

```
http://localhost:3200/
```

Configuration
------------------------------------------------------------------------------------
Most of the configuration options live in a YAML configuration file, containing two main sections:

* the ``defaults`` section should be left as-is and will be used is no other environment-specific value is provided.
* the ``production`` section can receive personnalized settings according to your environment-specific setup and paths.

Configuration priority is defined as follows (from most important to last resort):

* command-line parameters
* config file defaults section
* config file environment section
* application internal defaults

As a starting point, ``rest-ftp-daemon.yml.sample`` is an exemple config file that can be  copied into the expected location ``/etc/rest-ftp-daemon.yml``.

Default administrator credentials are admin/admin. Please change the password in this configuration file before starting any kind of production.

Logging
------------------------------------------------------------------------------------

The application will not log to any file by default, if not specified in its configuration.
Otherwise separate logging paths can be provided for the Thin webserver, API related messages, and workers related messages. Providing and empty value will simply activate logging to ``STDOUT``.


Usage examples
Job cleanup
------------------------------------------------------------------------------------

* Start a job to transfer a file named "file.iso" to a local FTP server
Job can be cleanup up after a certain amount of time, when they reach on of these status:

```
curl -H "Content-Type: application/json" -X POST -D /dev/stdout -d \
'{"source":"~/file.iso","target":"ftp://anonymous@localhost/incoming/dest2.iso"}' "http://localhost:3000/jobs"
```

Requesting notifications is achieved by passing a "notify" key in the request, with a callback URL.
This URL will be called at some points, ``POST```'ing a generic JSON structure with progress information.
- failed, after conchita.clean_failed seconds
- finished, after conchita.clean_finished seconds

Cleanup is done on a regular basis, every few seconds (conchita.timer)

* Start a job requesting notifications ``POST```'ed on "http://requestb.in/1321axg1"

```
curl -H "Content-Type: application/json" -X POST -D /dev/stdout -d \
'{"source":"~/file.dmg","target":"ftp://anonymous@localhost/incoming/dest4.dmg","notify":"http://requestb.in/1321axg1"}' "http://localhost:3000/jobs"
```

* Start a job with all the above plus a priority

```
curl -H "Content-Type: application/json" -X POST -D /dev/stdout -d \
'{"source":"~/file.dmg","priority":"3", target":"ftp://anonymous@localhost/incoming/dest4.dmg","notify":"http://requestb.in/1321axg1"}' "http://localhost:3000/jobs"
```

* Start a job using endpoint tokens

First define ``nas`` ans ``ftp1`` in the configuration file :

```
defaults: &defaults

development:
  <<: *defaults

  endpoints:
    nas: "~/"
    ftp1: "ftp://anonymous@localhost/incoming/"
```

Thos tokens will be expanded when the job is ran :

```
curl -H "Content-Type: application/json" -X POST -D /dev/stdout -d \
'{"source":"~/file.dmg","priority":"3", target":"ftp://anonymous@localhost/incoming/dest4.dmg","notify":"http://requestb.in/1321axg1"}' "http://localhost:3000/jobs"
```

NB: a special token [RANDOM] helps to generate a random filename when needed

* Get status of a specific job based on its ID

```
curl -H "Content-Type: application/json" -X GET -D /dev/stdout "http://localhost:3000/jobs/3"
```


* Delete a specific job based on its ID

```
curl -H "Content-Type: application/json" -X DELETE -D /dev/stdout "http://localhost:3000/jobs/3"
```


Getting status
------------------------------------------------------------------------------------

* A global JSON status is provided on ``` GET /status ```

* A nice dashboard gives a global view of the daemon, jobs in queue, and system status, exposed on ``` GET /```

* The server exposes its jobs list on ``` GET /jobs ```

```
http://localhost:3000/jobs
```

This query will return a job list :

```
[
  {
    "source": "~/file.dmg",
    "target": "ftp://anonymous@localhost/incoming/dest2.dmg",
    "worker_name": "bob-92439-1",
    "created": "2014-08-01 16:53:08 +0200",
    "id": 16,
    "runtime": 17.4,
    "status": "graceful_ending",
    "source_size": 37109074,
    "error": 0,
    "errmsg": "finished",
    "progress": 100.0,
    "transferred": 37100000
  },
  {
    source: "[nas]/file.dmg",
    target: "[ftp2]/dest4.dmg",
    notify: "http://requestb.in/1321axg1",
    updated_at: "2014-09-17 22:56:14 +0200",
    id: 2,
    started_at: "2014-09-17 22:56:01 +0200",
    status: "uploading",
    error: 0,
    debug_source: "/Users/bruno/file.dmg",
    debug_target: "#<URI::FTP:0x007ffa9289e650 URL:ftp://uuuuuuuu:yyyyyyyyy@ftp.xxxxxx.fr/subdir/dest4.dmg>",
    file_size: 32093208,
    file_progress: 5.6,
    file_sent: 1800000
  }
]
```


About
------------------------------------------------------------------------------------

Bruno MEDICI Consultant

http://bmconseil.com/
