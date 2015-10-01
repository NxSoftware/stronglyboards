require 'xcodeproj'
require 'optparse'
require 'thor'
require 'yaml'

require 'stronglyboards/version'
require 'stronglyboards/storyboard'
require 'stronglyboards/source_generator_objc'
require 'stronglyboards/source_generator_swift'

module Stronglyboards

  class Stronglyboards < Thor

    LOCK_FILE_NAME = 'Stronglyboards.lock'

    desc 'install PROJECT', 'Installs Stronglyboards into your .xcodeproj file'
    option :output, :desc => 'Path to the output file'
    option :language, :default => 'objc', :desc => 'Output language (objc [default], swift)'
    option :prefix, :default => '', :desc => 'Class and category method prefix'
    def install(project_file)
      lock_file_path = lock_file_path(project_file)
      if File.exists?(lock_file_path)
        puts 'It appears that Stronglyboards has already been installed on this project.'
        return
      end

      puts "Installing into #{project_file}"

      # Open the existing Xcode project
      project = Xcodeproj::Project.open(project_file)

      # TODO: Should expand target support throughout the gem
      # i.e. some storyboards may be part of the
      # # project but are only associated with
      # certain targets (extensions).
      target = project.native_targets.first

      # Do main processing
      output_files = process(project, options)

      # Finalise installation
      add_files_to_target(project, target, output_files)
      add_build_script(project, target)
      update_lock_file(project_file, options)
      project.save
    end

    desc 'update', 'Updates the generated source code for the project'
    def update(project_name)
      puts 'Updating Stronglyboards...'

      # Load the lock file containing configuration
      lock_file = File.open(LOCK_FILE_NAME, 'r')
      options = YAML::load(lock_file)

      # Open the Xcode project
      project = Xcodeproj::Project.open("#{project_name}.xcodeproj")

      process(project, options)
    end

    private
    def process(project, options)
      output_file = options[:output]
      language = options[:language]
      prefix = options[:prefix]

      # Provide a default output filename
      if output_file == nil
        output_file = prefix + 'Stronglyboards'
      end

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

    private
    def add_files_to_target(project, target, output_files)
      puts "Adding files to target \"#{target}\""

      output_files.each do |output_file|
        # Insert the file into the root group in the project
        file_reference = project.new_file(output_file.file)

        # Add the file to the target to ensure it is compiled
        target.source_build_phase.add_file_reference(file_reference) if output_file.is_source
      end

    end

    private
    def add_build_script(project, target)
      puts 'Adding build script'

      phase = project.new(Xcodeproj::Project::Object::PBXShellScriptBuildPhase)
      phase.name = 'Update Stronglyboards'
      phase.shell_script = 'stronglyboards update ${PROJECT_NAME}'
      target.build_phases.insert(0, phase)
    end

    private
    def update_lock_file(project_file, options)
      lock_file_path = lock_file_path(project_file)
      puts "Write hidden #{lock_file_path} file"

      lock_file = File.open(lock_file_path, 'w+')
      lock_file.write(YAML::dump(options))
    end

    private
    def lock_file_path(project_file)
      File.dirname(project_file) + '/' + LOCK_FILE_NAME
    end

  end

  Stronglyboards.start(ARGV)

end
