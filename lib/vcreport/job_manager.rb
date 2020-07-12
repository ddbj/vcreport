# frozen_string_literal: true

require 'vcreport/settings'
require 'concurrent-ruby'
require 'active_support'
require 'active_support/core_ext/string/filters'
require 'pathname'
require 'posix/spawn'
require 'thor'
require 'English'

module VCReport
  class JobManager
    include Thor::Shell

    # @return [Integer]
    attr_reader :num_threads

    # @return [Boolean]
    attr_reader :should_terminate

    # @param num_threads [Integer]
    def initialize(num_threads)
      @num_threads = num_threads
      @pool = Concurrent::FixedThreadPool.new(num_threads)
      # Hash{ String => Symbol }
      # The value may be :success, :fail, :unfinished
      @job_status = {}
    end

    # @param result_path [String, Pathname]
    def post(result_path)
      result_path = result_path.to_s
      if File.exist?(result_path)
        say_status 'skip', result_path, :yellow
        return
      end
      case @job_status[result_path]
      when :success
        warn <<~MESSAGE.squish
          File does not exist but job status is 'success'.
          Something went wrong: #{result_path}
        MESSAGE
        say_status 'start', result_path, :blue
      when :unfinished
        # the job is already in queue
        say_status 'queued', result_path, :yellow
        return
      when :fail
        say_status 'restart', result_path, :blue
      else
        say_status 'start', result_path, :blue
      end
      @job_status[result_path] = :unfinished
      @job_status[result_path] = @pool.post do
        is_success = yield
        if is_success
          say_status 'create', result_path, :green
          :success
        else
          say_status 'fail', result_path, :red
          :fail
        end
      end
    end

    def wait
      @pool.shutdown
      @pool.wait_for_termination
    end

    class << self
      # @param command [String]
      # @return        [Boolean] true iff the command succeeded
      def shell(command)
        pid = POSIX::Spawn.spawn(command)
        Process.waitpid(pid)
        $CHILD_STATUS.success?
      end
    end
  end
end