module Stronglyboards
  class Storyboard

    EXTENSION = '.storyboard'

    def initialize(file)
      @file = file
      @full_path = Xcodeproj::Project::Object::GroupableHelper.real_path(file)
      @name = File.basename(file.path, EXTENSION)
    end

  end
end
