require 'xcodeproj'
require 'optparse'

require 'stronglyboards/version'
require 'stronglyboards/storyboard'
require 'stronglyboards/source_generator_objc'
require 'stronglyboards/source_generator_swift'

module Stronglyboards

  # Process the command line arguments
  options = {}
  OptionParser.new do |opts|
    opts.banner = 'Usage: stronglyboards [options]'

    opts.on('-i', '--input FILE', 'Project file (MyApp.xcodeproj)') { |v| options[:project_file] = v }
    opts.on('-o', '--output FILE', 'Output file') { |v| options[:output_file] = v }
    opts.on('-l', '--lang [LANGUAGE]', [:objc, :swift], 'Output language (objc [default], swift)') { |v| options[:language] = v }
    opts.on('--prefix PREFIX', 'Class prefix') { |v| options[:prefix] = v }

  end.parse!

  project_file = options[:project_file]
  output_file = options[:output_file]
  language = options[:language]
  prefix = options[:prefix] || ''

  # Sanitize the arguments
  if project_file == nil
    puts 'Must specify a .xcodeproj file.'
    exit
  end
  # Default language is Objective-C
  if language == nil
    language = :objc
  end
  # Provide a default output filename
  if output_file == nil
    output_file = prefix + 'Stronglyboards'
  end

  # Open the existing Xcode project
  project = Xcodeproj::Project.open(project_file)

  # Instantiate a source generator appropriate for the selected language
  source_generator = case language
  when :objc
    Stronglyboards::SourceGeneratorObjC.new
  when :swift
    Stronglyboards::SourceGeneratorSwift.new
  end

  # Iterate the project files looking for storyboards
  project.files.each do |file|
    if file.path.end_with? Stronglyboards::Storyboard::EXTENSION
      storyboard = Stronglyboards::Storyboard.new(file)
      source_generator.doSomething
    end
  end # end project file iterator

end
