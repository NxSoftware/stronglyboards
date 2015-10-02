module Stronglyboards

  class OutputFile < Struct.new(:file, :is_source)
  end

  class AbstractSourceGenerator

    protected
    attr_accessor :prefix

    public
    def initialize(prefix, output_file_name)
      @prefix = prefix
      @storyboards = Array.new

      @implementation_file = File.open(output_file_name, 'w+')
    end

    # Gathers a set of view controller classes from all storyboards
    protected
    def view_controller_classes
      @storyboards.collect { |storyboard|
        storyboard.view_controllers.collect { |vc| vc.class_name }
      }.flatten.uniq
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
      [OutputFile.new(@implementation_file, true)]
    end

  end
end