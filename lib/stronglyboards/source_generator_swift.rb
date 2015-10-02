require_relative 'source_generator'
require_relative 'view_controller'

module Stronglyboards
  class SourceGeneratorSwift < AbstractSourceGenerator

    public
    def initialize(prefix, output_file_name)
      @implementation_file_path = output_file_name + '.swift'

      super(prefix, @implementation_file_path)
    end

    def parse_storyboards

      puts "Source file: #{@implementation_file_path}"

      # Generate framework imports
      @implementation_file.write("import UIKit\n\n")

      # Generate the base storyboard class
      base_class_name = create_base_storyboard_class

      # Generate classes for each storyboard
      @storyboards.each { |s| create_storyboard_class(s, base_class_name) }

      # Generate the storyboard category
      create_storyboard_category

      output_files
    end

    private
    def create_base_storyboard_class
      class_name = "#{@prefix}Stronglyboard"
      output = Array.new(1, "class #{class_name} {")
      output.push "\tlet storyboard: UIStoryboard"
      output.push "\tinit(name: String, bundle: NSBundle?) {"
      output.push "\t\tstoryboard = UIStoryboard(name: name, bundle: bundle)"
      output.push "\t}"
      output.push '}'

      # Convert to string and write to file
      output = output.join("\n")
      @implementation_file.write(output + "\n\n")

      class_name
    end

    # Generate the class for the provided storyboard
    private
    def create_storyboard_class(storyboard, base_class_name)
      class_name = storyboard.class_name(@prefix)
      puts "Processing storyboard class #{class_name}."

      output = Array.new(1, "class #{class_name} : #{base_class_name} {")

      storyboard.view_controllers.each do |vc|
        cast = " as! #{vc.class_name}" unless vc.class_name == ViewController::UIVIEWCONTROLLER
        if vc.initial_view_controller?
          cast = '!' if vc.class_name == ViewController::UIVIEWCONTROLLER
          output.push "\tfunc instantiateInitialViewController() -> #{vc.class_name} {"
          output.push "\t\treturn self.storyboard.instantiateInitialViewController()#{cast}"
        else
          output.push "\tfunc instantiate#{vc.storyboard_identifier}ViewController() -> #{vc.class_name} {"
          output.push "\t\treturn self.storyboard.instantiateViewControllerWithIdentifier(\"#{vc.storyboard_identifier}\") #{cast}"
        end
        output.push "\t}"
      end # view controller iterator

      # End the storyboard subclass
      output.push '}'

      # Convert to string
      output = output.join("\n")

      # Output to files
      @implementation_file.write(output)
      @implementation_file.write("\n\n")
    end

    # Generate the category for UIStoryboard with methods
    # for each storyboard that has been provided
    private
    def create_storyboard_category
      output = Array.new(1, 'extension UIStoryboard {')

      @storyboards.each do |storyboard|
        class_name = storyboard.class_name(@prefix)
        func_name = "#{storyboard.lowercase_name(@prefix)}Storyboard"
        output.push "\tclass func #{func_name}() -> #{class_name} {"
        output.push "\t\treturn #{class_name}(name: \"#{storyboard.name}\", bundle: nil)"
        output.push "\t}"
      end

      output.push '}'

      # Convert to a string
      output = output.join("\n")

      # Output to file
      puts 'Writing UIStoryboard category.'
      @implementation_file.write(output)
    end

  end
end
