require_relative 'source_generator'

module Stronglyboards
  class SourceGeneratorObjC < Stronglyboards::AbstractSourceGenerator

    def initialize(prefix, output_file)
      @prefix = prefix

      @header_file_path = output_file + '.h'
      @implementation_file_path = output_file + '.m'
      @header_file = File.open(@header_file_path, 'w+')
      @implementation_file = File.open(@implementation_file_path, 'w+')

      @header_file.write("@import UIKit;\n\n")
      @implementation_file.write("#import \"#{File.basename(@header_file_path)}\"\n\n")

      puts "Header:         #{@header_file_path}"
      puts "Implementation: #{@implementation_file_path}"

      @storyboards = Array.new
    end

    # Generates source code for components of the provided storyboard
    def process(storyboard)
      # Store this storyboard for further processing later
      @storyboards.push(storyboard)
      createStoryboardClass(storyboard)
    end

    # Generate the class for the provided storyboard
    private
    def createStoryboardClass(storyboard)
      class_name = storyboard.class_name(@prefix)
      puts "Processing storyboard class #{class_name}."

      view_controller_classes = Array.new(storyboard.view_controllers.length)
      interface = Array.new(1, "@interface #{class_name} : UIStoryboard")
      implementation = Array.new(1, "@implementation #{class_name}")

      storyboard.view_controllers.each do |vc|
        view_controller_classes.push("@class #{vc.class_name};")

        if vc.initial_view_controller?
          # Provide an overridden declaration of the UIStoryboard -instantiateInitialViewController method
          interface.push("- (#{vc.class_name} *)instantiateInitialViewController;")
        else
          # Provide methods for instantiating view controllers by their storyboard ID
          method_signature = "- (#{vc.class_name} *)instantiate#{vc.storyboard_identifier}ViewController;"
          interface.push(method_signature)
          implementation.push(method_signature + ' {')
          implementation.push("\t" + createViewControllerInstantiation(vc))
          implementation.push('}')
        end

      end # view controller iterator

      interface.push('@end')
      implementation.push('@end')

      # Convert to string
      view_controller_classes = view_controller_classes.join("\n")
      interface = interface.join("\n")
      implementation = implementation.join("\n")

      # Output to file
      @header_file.write(view_controller_classes)
      @header_file.write(interface)
      @implementation_file.write(implementation)

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

      # Output to file
      puts 'Writing UIStoryboard category.'
      @header_file.write(interface)
      @implementation_file.write(implementation)

    end

    private
    def createStoryboardInstantiation(storyboard)
      "return [#{storyboard.class_name(@prefix)} storyboardWithName:@\"#{storyboard.name}\" bundle:nil];"
    end

    private
    def createViewControllerInstantiation(view_controller)
      "return [self instantiateViewControllerWithIdentifier:@\"#{view_controller.storyboard_identifier}\"];"
    end

  end
end
