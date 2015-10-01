module Stronglyboards

  class OutputFile < Struct.new(:file, :is_source)
  end

  class AbstractSourceGenerator

    protected
    attr_accessor :prefix

    public
    def output_files
      raise 'This method should be overridden.'
    end

  end
end