require 'xcodeproj'
require 'optparse'
require 'thor'

require 'stronglyboards/version'
require 'stronglyboards/storyboard'
require 'stronglyboards/source_generator_objc'
require 'stronglyboards/source_generator_swift'

module Stronglyboards

  class Stronglyboards < Thor

    desc 'install PROJECT', 'Installs Stronglyboards into your .xcodeproj file'
    option :output, :desc => 'Path to the output file'
    option :language, :default => 'objc', :desc => 'Output language (objc [default], swift)'
    option :prefix, :default => '', :desc => 'Class and category method prefix'
    def install(project_file)
      output_file = options[:output]
      language = options[:language]
      prefix = options[:prefix]

      # Provide a default output filename
      if output_file == nil
        output_file = prefix + 'Stronglyboards'
      end

      # Open the existing Xcode project
      project = Xcodeproj::Project.open(project_file)

      puts "output: #{output_file}"
      puts "language: #{language}"
      puts "prefix: #{prefix}"

      # Instantiate a source generator appropriate for the selected language
      source_generator = case language
      when 'objc'
        SourceGeneratorObjC.new(prefix, output_file)
      when 'swift'
        SourceGeneratorSwift.new(prefix, output_file)
      else
        puts 'Language must be objc or swift.'
        exit
      end

      # Iterate the project files looking for storyboards
      project.files.each do |file|
        if file.path.end_with? Storyboard::EXTENSION
          storyboard = Storyboard.new(file)

          source_generator.add_storyboard(storyboard)
        end
      end # end project file iterator

      source_generator.finalize()
    end

  end

  Stronglyboards.start(ARGV)

end
