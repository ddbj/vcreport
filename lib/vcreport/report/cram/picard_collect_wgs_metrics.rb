# frozen_string_literal: true

require 'pathname'
require 'vcreport/chr_region'
require 'vcreport/report/table'

module VCReport
  module Report
    class Cram
      class PicardCollectWgsMetrics
        # For the definition of each metrics, see
        # https://broadinstitute.github.io/picard/picard-metric-definitions.html

        class CoverageStats
          # @return [Float]
          attr_reader :mean, :sd, :median, :mad

          def initialize(mean, sd, median, mad)
            @mean = mean
            @sd = sd
            @median = median
            @mad = mad
          end
        end

        class PercentExcluded
          FIELDS = %i[adapter mapq dupe unpaired baseq overlap capped total].freeze

          # @return [Float]
          attr_reader(*FIELDS)

          def initialize(**params)
            FIELDS.each { |k| instance_variable_set("@#{k}", params[k]) }
          end
        end

        class HetSnp
          # @return [Float]
          attr_reader :sensitivity

          # @return [Integer]
          attr_reader :q

          def initialize(sensitivity, q)
            @sensitivity = sensitivity
            @q = q
          end
        end

        # @return [ChrRegion]
        attr_reader :chr_region

        # @return [String]
        attr_reader :command_log

        # @return [Integer]
        attr_reader :territory

        # @return [CoverageStats]
        attr_reader :coverage_stats

        # @return [Hash{Integer => Float}] coverage -> percent
        attr_reader :percent_coverage

        # @return [HetSnp]
        attr_reader :het_snp

        # @return [Hash{Integer => Integer] coverage -> count
        attr_reader :histograma

        def initialize(chr_region,
                       command_log,
                       territory,
                       coverage_stats,
                       percent_excluded,
                       percent_coverage,
                       het_snp,
                       histogram)
          @chr_region = chr_region
          @command_log = command_log
          @territory = territory
          @coverage_stats = coverage_stats
          @percent_excluded = percent_excluded
          @percent_coverage = percent_coverage
          @het_snp = het_snp
          @histogram = histogram
        end

        # @return [Table]
        def coverage_stats_table
          desc = %w[mean median SD MAD]
          coverage = desc.map { |k| @coverage_stats.send(k.downcase) }
          header = %w[statistic coverage]
          rows = [desc, coverage].transpose
          type = %i[string float]
          Table.new(header, rows, type)
        end

        # @return [Table]
        def percent_excluded_table
          desc = %w[mapQ dupe unpaired baseQ overlap capped total]
          excluded = desc.map do |k|
            percent = @percent_excluded.send(k.downcase) * 100
            format('%.4<percent>f', percent: percent)
          end
          header = ['filter type', 'excluded (%)']
          rows = [desc, excluded].transpose
          type = %i[string float]
          Table.new(header, rows, type)
        end
      end
    end
  end
end
