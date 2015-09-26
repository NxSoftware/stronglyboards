require_relative 'source_generator'

module Stronglyboards
  class SourceGeneratorObjC < Stronglyboards::AbstractSourceGenerator

    def initialize(prefix, output_file)
      @prefix = prefix
      @header_file = output_file + '.h'
      @implementation_file = output_file + '.m'
      @storyboards = Array.new
    end

    # Generates source code for components of the provided storyboard
    def process(storyboard)

      # Store this storyboard for further processing later
      @storyboards.push(storyboard)

      puts "Writing storyboard #{storyboard.name} to #{@header_file} and #{@implementation_file}"

      createStoryboardClass(storyboard)

    end

    # Generate the class for the provided storyboard
    private
    def createStoryboardClass(storyboard)
      class_name = storyboard.class_name(@prefix)
      interface = Array.new(1, "@interface #{class_name} : UIStoryboard")
      implementation = Array.new(1, "@implementation #{class_name}")
      interface.push('@end')
      implementation.push('@end')

      # Convert to string
      interface = interface.join("\n")
      implementation = implementation.join("\n")

      puts interface
      puts '--------'
      puts implementation

    end

    # Finalizes processing
    public
    def finalize
      createStoryboardCategory
    end

    # Generate the category for UIStoryboard with methods
    # for each storyboard that has been provided.
    private
    def createStoryboardCategory
      interface = Array.new(1, '@interface UIStoryboard (Stronglyboards)')
      implementation = Array.new(1, '@implementation UIStoryboard (Stronglyboards)')

      @storyboards.each do |storyboard|
        method_signature = "+(#{storyboard.class_name(@prefix)} *)#{storyboard.lowercase_name(@prefix)}Storyboard;"
        interface.push(method_signature)
        implementation.push(method_signature + ' {')
        implementation.push("\t" + createStoryboardInstantiation(storyboard))
        implementation.push('}')
      end
      interface.push('@end')
      implementation.push('@end')

      # Convert to a string
      interface = interface.join("\n")
      implementation = implementation.join("\n")

      puts interface
      puts '--------'
      puts implementation

    end

    private
    def createStoryboardInstantiation(storyboard)
      "return [#{storyboard.class_name(@prefix)} storyboardWithName:@\"#{storyboard.name}\" bundle:nil];"
    end

  end
end
