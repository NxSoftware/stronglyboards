require 'nokogiri'
require_relative 'view_controller'

module Stronglyboards
  class Storyboard

    EXTENSION = '.storyboard'

    attr_reader :name
    attr_reader :initial_view_controller

    def initialize(file)
      @file = file
      @full_path = Xcodeproj::Project::Object::GroupableHelper.real_path(file)
      @name = File.basename(file.path, EXTENSION)

      file = File.open(@full_path)
      @xml = Nokogiri::XML(file)
      file.close

      # Find view controllers...
      @initial_view_controller = find_initial_view_controller
    end

    # Searches for the initial view controller
    private
    def find_initial_view_controller
      initial_view_controller_identifier = @xml.at_xpath('document').attr('initialViewController')
      view_controller_xml = object_with_identifier(initial_view_controller_identifier) unless initial_view_controller_identifier == nil
      if view_controller_xml != nil
        Stronglyboards::ViewController.new(view_controller_xml)
      end
    end

    # --------- Helpers ---------

    private
    def object_with_identifier(identifier)
      @xml.at_xpath("//scene/objects/*[@id='#{identifier}']")
    end

    public
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
