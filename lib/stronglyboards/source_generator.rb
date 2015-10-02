module Stronglyboards

  class OutputFile < Struct.new(:file, :is_source)
  end

  class AbstractSourceGenerator

    protected
    attr_accessor :prefix

    public
    def initialize(prefix)
      @prefix = prefix
      @storyboards = Array.new
    end

    public
    def add_storyboard(storyboard)
      @storyboards.push(storyboard)
    end

    public
    def parse_storyboards
      raise 'This method should be overridden.'
    end

    public
    def output_files
      raise 'This method should be overridden.'
    end

  end
end