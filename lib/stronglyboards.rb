require 'xcodeproj'
require 'optparse'
require 'thor'
require 'yaml'

require_relative 'stronglyboards/version'
require_relative 'stronglyboards/storyboard'
require_relative 'stronglyboards/source_generator_objc'
require_relative 'stronglyboards/source_generator_swift'

module Stronglyboards

  class Stronglyboards < Thor

    LOCK_FILE_NAME = 'Stronglyboards.lock'
    BUILD_SCRIPT_NAME = 'Update Stronglyboards'

    # ---- Begin external interface ----

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

      puts "Installing Stronglyboards into #{project_file}"

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
    def update(project_file)
      configuration = load_lock_file

      puts "Updating Stronglyboards in #{project_file}"

      # Open the Xcode project
      project = Xcodeproj::Project.open(project_file)

      process(project, configuration)
    end

    desc 'uninstall PROJECT', 'Uninstalls Stronglyboards from the specified .xcodeproj file.'
    def uninstall(project_file)
      configuration = load_lock_file

      base_output_file = configuration[:output]
      language = configuration[:language]
      prefix = configuration[:prefix]

      puts "Uninstalling Stronglyboards from #{project_file}"

      files_to_delete = Array.new

      # Open the Xcode project
      project = Xcodeproj::Project.open(project_file)
      project_root = project.path.dirname

      # Gather the targets that we're interested in
      targets = interesting_targets(project)

      targets.each do |target|
        # Find and delete the build script phase for this target
        target.build_phases.select { |phase|
          phase.is_a? Xcodeproj::Project::PBXShellScriptBuildPhase and phase.name == BUILD_SCRIPT_NAME
        }.each { |phase|
          target.build_phases.delete(phase)
        }

        # Get a source generator for this target
        output_file = base_output_file_for_target(base_output_file, target, prefix)
        source_generator = source_generator(language, prefix, output_file)

        # Gather the files that would have been generated for this target.
        # Bare in mind that this target may have been created since the
        # last time the install or update command ran, so there may be
        # files in this list that don't actually exist.
        files_to_delete << source_generator.output_files
      end

      # Expand the paths of the files to be deleted to be absolute
      files_to_delete.flatten!.uniq!
      paths_to_delete = files_to_delete.collect do |file|
        project_root + file.file.path
      end

      # Look through each target to see if this file is a member,
      # removing it from the source build phase if necessary.
      # TODO: There's got to be a better way, question asked.
      # http://stackoverflow.com/questions/32908231/how-to-get-the-targets-for-a-pbxfilereference-in-xcodeproj
      targets.each do |target|
        target.source_build_phase.files.each do |build_file|
          full_path = build_file.file_ref.real_path
          if paths_to_delete.include?(full_path)

            # Need to get a reference to the underlying file reference
            # as it will be removed when the build file is removed
            # from the target's build phase.
            file = build_file.file_ref

            # Remove the file from the build phase, project, and file system
            target.source_build_phase.remove_build_file(build_file)
            file.remove_from_project
            File.delete(full_path)
          end
        end
      end

      # Iterate through the files to delete to get rid of any non-source files
      files_to_delete.each do |file|
        unless file.is_source
          full_path = File.realpath(file.file)
          file_ref = project.reference_for_path(full_path)
          file_ref.remove_from_project
          File.delete(full_path)
        end
      end

      project.save

      # Finally delete the lock file
      File.delete(LOCK_FILE_NAME)

    end

    # ---- End external interface ----

    private
    def process(project, options)
      base_output_file = options[:output]
      language = options[:language]
      prefix = options[:prefix]

      interesting_targets(project).each do |target|

        # Provide a default output filename
        output_file = base_output_file_for_target(base_output_file, target, prefix)

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

        output_files = source_generator.parse_storyboards

        # Add the output files to the target
        add_files_to_target(project, target, output_files)
        add_build_script(project, target)
      end
    end

    private
    def interesting_targets(project)
      project.native_targets.select { |target| target.product_type == 'com.apple.product-type.application' }
    end

    private
    def base_output_file_for_target(base_file, target, prefix)
      if base_file == nil
        base_file = prefix + 'Stronglyboards'
      end
      base_file + "_#{target.name}"
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
      phase.name = BUILD_SCRIPT_NAME
      phase.shell_script = 'stronglyboards update ${PROJECT_NAME}.xcodeproj'
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
    def load_lock_file
      if !File.exists?(LOCK_FILE_NAME)
        puts 'Stronglyboards must first be installed using the install command.'
        exit
      else
        # Load the lock file containing configuration
        lock_file = File.open(LOCK_FILE_NAME, 'r')
        YAML::load(lock_file)
      end
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

  Stronglyboards.start(ARGV)

end
