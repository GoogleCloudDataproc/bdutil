# bdutil

bdutil is a command-line script used to manage Apache Hadoop and Apache Spark instances on [Google Compute Engine](https://cloud.google.com/compute). bdutil manages deployment, configuration, and shutdown of your Hadoop instances.

## Requirements

bdutil depends on the [Google Cloud SDK](https://cloud.google.com/sdk). bdutil is supported in any posix-compliant Bash v3 or greater shell.

## Usage

See the [QUICKSTART](/docs/QUICKSTART.md) file in the `docs` directory to learn how to set up your Hadoop instances using bdutil.

1. Install and configure the [Google Cloud SDK](https://cloud.google.com/sdk) if you have already not done so
1. Clone this repository with `git clone https://github.com/GoogleCloudPlatform/bdutil.git`
1. Modify the following variables in the bdutil_env.sh file:
  1. `PROJECT` - Set to the project ID for all bdutil commands. The project value will be overridden in the following order (where 1 overrides 2, and 2 overrides 3):
    * -p flag value, or if not specified then
    * PROJECT value in bdutil_env.sh, or if not specified then
    * gcloud default project value
  1. `CONFIGBUCKET` - Set to a Google Compute Storage bucket that your project has read/write access to.
1. Run `bdutil --help` for a list of commands.

The script implements the following commands, which are very similar:

* `bdutil create` creates and starts instances, but will not apply most configuration settings. You can call `bdutil run_command_steps` on instances afterward to apply configuration settings to them. Typically you wouldn't use this, but would use `bdutil deploy` instead.
* `bdutil deploy` creates and starts instances with all the configuration options specified in the command line and any included configuration scripts.

## Components installed

The latest release of bdutil is `1.3.5`. This bdutil release installs the following versions of open source components:

* Apache Hadoop - 1.2.1 (2.7.1 if you use the `-e` argument)
* Apache Spark - 1.5.0
* Apache Pig - 0.12
* Apache Hive - 1.2.1

## Documentation

The following documentation is useful for bdutil.

* **[Quickstart](/docs/QUICKSTART.md)** - A guide on how to get started with bdutil quickly.
* **[Jobs](/docs/JOBS.md)** - How to submit jobs (work) to a bdutil cluster.
* **[Monitoring](/docs/MONITORING.md)** - How to monitor bdutil cluster.
* **[Shutdown](/docs/SHUTDOWN.md)** - How shutdown a bdutil cluster.
