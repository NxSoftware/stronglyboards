# Overview #

Stronglyboards is a [Ruby gem](https://rubygems.org) that generates code that can be used to provide a strongly-typed interface to [iOS Storyboards](https://developer.apple.com/library/ios/recipes/xcode_help-IB_storyboard/chapters/AboutStoryboards.html).

# Installation & Basic Usage #

Use the `gem` command to install Stronglyboards:

```gem install stronglyboards```

Run stronglyboards on your Xcode project file:

```stronglyboards install MyProject.xcodeproj```

By default it will generate Objective-C files in the current directory.

Stronglyboards will automatically add the generated files into your project
and setup a new "Run Script" build phase to keep up-to-date with any
storyboard changes you might make.

# Usage #

`install <PROJECT>`

This will install Stronglyboards into the specified Xcode project. Replace `<PROJECT>` with your `.xcodeproj` file.

`update <PROJECT>`

This will attempt to update Stronglyboards in a project where it is already installed. Replace `<PROJECT>` with your `.xcodeproj` file.
Note that things will likely go wrong if you have manually renamed any of the generated files.

`uninstall <PROJECT>`

This will attempt to remove Stronglyboards from a project where it has been previously installed. Replace `<PROJECT>` with your `.xcodeproj` file.
Note that things will likely go wrong if you have manually renamed any of the generated files.

# Installation Options #

`--output` specifies the name of the output file(s).
You can use this parameter to output to a different directory.
e.g. `Classes/GeneratedStoryboardAPI`.
You should **not** provide a file extension as part of this file name.
This is an optional parameter, default is `Stronglyboards`.
Note that this path is essentially a template, the actual generated filenames
will be different.

`--language` specifies the output language as either `objc` or `swift`.
This is an optional parameter, default is `objc`.

`--prefix` specifies a string to be used as the prefix for all generated classes.
This is an optional parameter, default is no prefix.
Note that the prefix does not affect the output file name.