require_relative 'source_generator'

module Stronglyboards
  class SourceGeneratorObjC < AbstractSourceGenerator

    def initialize(prefix, output_file_name)
      @implementation_file_path = output_file_name + '.m'

      super(prefix, @implementation_file_path)

      @header_file_path = output_file_name + '.h'
      @header_file = File.open(@header_file_path, 'w+')
    end

    # Parses the storyboards
    public
    def parse_storyboards

      puts "Header:         #{@header_file_path}"
      puts "Implementation: #{@implementation_file_path}"

      # Generate framework and header imports
      @header_file.write("@import UIKit;\n\n")
      @implementation_file.write("#import \"#{File.basename(@header_file_path)}\"\n\n")

      @header_file.write("NS_ASSUME_NONNULL_BEGIN\n\n")

      # Generate the base storyboard class
      base_class_name = create_base_storyboard_class

      # Generate forward declaration of view controller classes
      view_controller_classes.each do |class_name|
        @header_file.write("@class #{class_name};\n")
      end
      @header_file.write("\n")

      # Generate classes for each storyboard
      @storyboards.each { |s| create_storyboard_class(s, base_class_name) }

      # Generate the storyboard category
      create_storyboard_category

      @header_file.write("\n\nNS_ASSUME_NONNULL_END")

      output_files
    end

    private
    def create_base_storyboard_class
      class_name = "#{@prefix}Stronglyboard"

      # Create the public interface
      interface = Array.new
      interface.push("@interface #{class_name} : NSObject")
      interface.push('@property (nonatomic, strong, readonly) UIStoryboard *storyboard;')
      interface.push('@end')

      # Create the private interface to expose the storyboard as a read-write property
      implementation = Array.new
      implementation.push("@interface #{class_name} ()")
      implementation.push('@property (nonatomic, strong) UIStoryboard *storyboard;')
      implementation.push('@end')

      # Create the implementation of the base storyboard class
      implementation.push("@implementation #{class_name}")
      implementation.push('- (instancetype)initWithName:(NSString *)name bundle:(NSBundle *)bundleOrNil {')
      implementation.push("\tself = [super init];")
      implementation.push("\tif (self) {")
      implementation.push("\t\t_storyboard = [UIStoryboard storyboardWithName:name bundle:bundleOrNil];")
      implementation.push("\t}")
      implementation.push("\treturn self;")
      implementation.push('}')
      implementation.push('@end')

      # Convert to string
      interface = interface.join("\n")
      implementation = implementation.join("\n")

      @header_file.write(interface + "\n\n")
      @implementation_file.write(implementation + "\n\n")

      class_name
    end

    # Generate the class for the provided storyboard
    private
    def create_storyboard_class(storyboard, base_class_name)
      class_name = storyboard.class_name(@prefix)
      puts "Processing storyboard class #{class_name}."

      interface = Array.new(1, "@interface #{class_name} : #{base_class_name}")
      implementation = Array.new(1, "@implementation #{class_name}")

      storyboard.view_controllers.each do |vc|
        if vc.initial_view_controller?
          method_signature = "- (#{vc.class_name} *)instantiateInitialViewController;"
          method_body = create_initial_view_controller_instantiation(vc)
        else
          method_signature = "- (#{vc.class_name} *)instantiate#{vc.storyboard_identifier}ViewController;"
          method_body = create_view_controller_instantiation(vc)
        end

        interface.push(method_signature)
        implementation.push(method_signature + ' {')
        implementation.push("\t" + method_body)
        implementation.push('}')
      end # view controller iterator

      interface.push('@end')
      implementation.push('@end')

      # Convert to string
      interface = interface.join("\n")
      implementation = implementation.join("\n")

      # Output to files
      @header_file.write(interface)
      @header_file.write("\n\n")
      @implementation_file.write(implementation)
      @implementation_file.write("\n\n")
    end

    # Generate the category for UIStoryboard with methods
    # for each storyboard that has been provided.
    private
    def create_storyboard_category
      interface = Array.new(1, '@interface UIStoryboard (Stronglyboards)')
      implementation = Array.new(1, '@implementation UIStoryboard (Stronglyboards)')

      @storyboards.each do |storyboard|
        method_signature = "+(#{storyboard.class_name(@prefix)} *)#{storyboard.lowercase_name(@prefix)}Storyboard;"
        interface.push(method_signature)
        implementation.push(method_signature + ' {')
        implementation.push("\t" + create_storyboard_instantiation(storyboard))
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

    # ---- Helpers ----

    public
    def output_files
      super.push OutputFile.new(@header_file, false)
    end

    private
    def create_storyboard_instantiation(storyboard)
      class_name = storyboard.class_name(@prefix)
      "return [[#{class_name} alloc] initWithName:@\"#{storyboard.name}\" bundle:nil];"
    end

    private
    def create_initial_view_controller_instantiation(view_controller)
      "return (#{view_controller.class_name} *)[self.storyboard instantiateInitialViewController];"
    end

    private
    def create_view_controller_instantiation(view_controller)
      "return (#{view_controller.class_name} *)[self.storyboard instantiateViewControllerWithIdentifier:@\"#{view_controller.storyboard_identifier}\"];"
    end

  end
end
