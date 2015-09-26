module Stronglyboards
  class Storyboard

    EXTENSION = '.storyboard'

    attr_reader :name

    def initialize(file)
      @file = file
      @full_path = Xcodeproj::Project::Object::GroupableHelper.real_path(file)
      @name = File.basename(file.path, EXTENSION)
    end

    def class_name(prefix = nil)
      prefix + @name + 'Storyboard'
    end

    def lowercase_name(prefix = nil)
      lower = @name.dup
      lower[0] = lower[0].downcase
      if prefix == nil
        lower
      else
        prefix.downcase + '_' + lower
      end
    end

  end
end
