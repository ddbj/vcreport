# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/hash/indifferent_access'
require 'vcreport/job_manager'
require 'yaml'
require 'pathname'

module VCReport
  module Report
    # @abstract
    class Reporter
      EDAM_DOMAIN = 'http://edamontology.org'

      # @param job_manager [JobManager, nil]
      # @param targets         [Array<Pathname>]
      # @param deps            [Array<Pathname>]
      def initialize(job_manager, targets: [], deps: [])
        @job_manager = job_manager
        @target_paths, @dep_paths = [targets, deps].map do |e|
          e.is_a?(Array) ? e : [e]
        end
      end

      def try_parse
        exist_targets, exist_deps = [@target_paths, @dep_paths].map do |paths|
          paths.all? { |path| File.exist?(path) }
        end
        return nil unless IGNORE_DEPS_INEXISTENCE || exist_deps

        ret = exist_targets ? parse : nil
        unless @target_paths.empty?
          @job_manager&.post(@target_paths.first) { run_metrics }
        end
        ret
      end

      private

      # @abstract
      def parse; end

      # @abstract
      def run_metrics; end

      def store_job_file(job_path, job_definition)
        File.write(job_path, YAML.dump(job_definition.deep_stringify_keys))
      end

      # @param path     [String, Pathmame]
      # @param absolute [Boolean]
      # @param edam     [Integer]
      # @return         [Hash{ Symbol => String }]
      def cwl_file_field(path, absolute: true, edam: nil)
        field = { class: 'File' }
        path = File.expand_path(path) if absolute
        field[:path] = path.to_s
        field[:format] = "#{EDAM_DOMAIN}/format_#{edam}" if edam
        field
      end

      # @return [Boolean]
      def run_cwl(script_path, job_definition, out_dir)
        job_path = out_dir / 'job.yaml'
        store_job_file(job_path, job_definition)
        JobManager.shell <<~COMMAND.squish
          cwltool
          --singularity
          --outdir #{out_dir}
          #{script_path}
          #{job_path}
          >& #{out_dir / 'cwl.log'}
        COMMAND
      end
    end
  end
end
