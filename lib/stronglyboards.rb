require 'xcodeproj'

# Open the existing Xcode project
project_file = 'Picker.xcodeproj'
project = Xcodeproj::Project.open(project_file)

project.files.each { |file|
  if file.path.end_with? ".storyboard"
    puts "Found storyboard!"
    puts file.name
    puts file.path
    puts Xcodeproj::Project::Object::GroupableHelper.real_path(file)
  end
}
