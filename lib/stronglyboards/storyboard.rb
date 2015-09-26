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

      # Find other view controllers
      view_controllers = find_view_controllers_with_storyboard_identifiers
      @view_controllers = view_controllers.collect { |vc| Stronglyboards::ViewController.new(vc) } unless !view_controllers
    end

    # Searches for the initial view controller
    private
    def find_initial_view_controller
      initial_view_controller_identifier = @xml.at_xpath('document').attr('initialViewController')
      view_controller_xml = object_with_identifier(initial_view_controller_identifier) unless !initial_view_controller_identifier
      if view_controller_xml
        Stronglyboards::ViewController.new(view_controller_xml)
      end
    end

    # Searches for view controllers
    private
    def find_view_controllers_with_storyboard_identifiers
      @xml.xpath('//scene/objects/*[@storyboardIdentifier]')
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
