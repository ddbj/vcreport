# frozen_string_literal: true

require 'pathname'
require 'vcreport/report/table'

module VCReport
  module Report
    class Cram
      class SamtoolsIdxstats
        TABLE_COLUMNS = [
          ['chr. region',         :name,         :string],
	  ['# of mapped reads',   :num_mapped,   :integer],
	  ['# of unmapped reads', :num_unmapped, :integer]
        ].freeze

        class Chromosome
          # @return [String] "chr..." is supposed
          attr_reader :name

          # @return [Integer]
          attr_reader :length

          # @return [Integer] # of mapped reads
          attr_reader :num_mapped

          # @return [Integer] # of unmapped reads
          attr_reader :num_unmapped

          def initialize(name, length, num_mapped, num_unmapped)
            @name = name
            @length = length
            @num_mapped = num_mapped
            @num_unmapped = num_unmapped
          end
        end

        # @return [Chromosome]
        attr_reader :chromosomes

        # @param chromosomes [Array<Chromosome>]
        def initialize(chromosomes)
          @chromosomes = chromosomes
        end

        # @return [Table]
        def to_table
          header, messages, type = TABLE_COLUMNS.transpose
          rows = @chromosomes.map do |chromosome|
            messages.map do |message|
              chromosome.send(message)
            end
          end
          Table.new(header, rows, type)
        end
      end
    end
  end
end