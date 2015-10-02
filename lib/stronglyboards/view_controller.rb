module Stronglyboards
  class ViewController

    attr_reader :class_name
    attr_reader :storyboard_identifier

    UIVIEWCONTROLLER = 'UIViewController'
    UITABLEVIEWCONTROLLER = 'UITableViewController'
    UINAVIGATIONCONTROLLER = 'UINavigationController'

    def initialize(xml, is_initial_view_controller = false)
      @class_name = xml.attr('customClass') || class_name_from_type(xml)
      @storyboard_identifier = xml.attr('storyboardIdentifier')
      @is_initial_view_controller = is_initial_view_controller
    end

    def initial_view_controller?
      @is_initial_view_controller
    end

    # Determines the name of the class from this view controller's type
    private
    def class_name_from_type(xml)
      case xml.name
        when 'viewController'
          UIVIEWCONTROLLER
        when 'tableViewController'
          UITABLEVIEWCONTROLLER
        when 'navigationController'
          UINAVIGATIONCONTROLLER
          # TODO: Add more built-in classes
      end
    end

  end
end