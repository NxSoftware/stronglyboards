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
      process(project, options)

      # Finalise installation
      update_lock_file(project_file, options)
      project.save
    end

    desc 'update', 'Updates the generated source code for the project'
    def update(project_name)
      if !File.exists?(LOCK_FILE_NAME)
        puts 'Stronglyboards must first be installed using the install command.'
      else
        puts 'Updating Stronglyboards...'

        # Load the lock file containing configuration
        lock_file = File.open(LOCK_FILE_NAME, 'r')
        options = YAML::load(lock_file)

        # Open the Xcode project
        project = Xcodeproj::Project.open("#{project_name}.xcodeproj")

        process(project, options)
      end
    end

    private
    def process(project, options)
      output_file = options[:output]
      language = options[:language]
      prefix = options[:prefix]

      project.native_targets
          .select { |target| target.product_type == 'com.apple.product-type.application' }
          .each do |target|

        # Provide a default output filename
        if output_file == nil
          output_file = prefix + 'Stronglyboards'
        end
        output_file += "_#{target.name}"

        # Instantiate a source generator appropriate for the selected language
        source_generator = source_generator(language, prefix, output_file)

        # Iterate the target's resource files looking for storyboards
        target.resources_build_phase.files.each do |build_file|
          next unless build_file.display_name.end_with? Storyboard::EXTENSION

          file_or_group = build_file.file_ref

          if file_or_group.is_a? Xcodeproj::Project::Object::PBXFileReference
            # Getting the real path is sufficient for non-localized storyboards
            # as it will return the absolute path to the .storyboard
            path = file_or_group.real_path
          elsif file_or_group.is_a? Xcodeproj::Project::Object::PBXVariantGroup
            # Localized storyboards will be a group and will
            # need the path constructing from the Base storyboard.
            base_storyboard_file = file_or_group.children.find { |f| f.name == 'Base' }
            if base_storyboard_file == nil
              puts "No Base storyboard found for #{file_or_group}!!!"
              next
            end
            path = base_storyboard_file.real_path
          end

          storyboard = Storyboard.new(path)

          source_generator.add_storyboard(storyboard)
        end # end project file iterator

        output_files = source_generator.finalize()

        # Add the output files to the target
        add_files_to_target(project, target, output_files)
        add_build_script(project, target)
      end
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

    private
    def source_generator(language, prefix, output_file)
      case language
         when 'objc'
           SourceGeneratorObjC.new(prefix, output_file)
         when 'swift'
           SourceGeneratorSwift.new(prefix, output_file)
         else
           puts 'Language must be objc or swift.'
           exit
       end
    end

  end

end
