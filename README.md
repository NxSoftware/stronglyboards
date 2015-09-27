# Overview #

Stronglyboards is a [Ruby gem](https://rubygems.org) that generates code that can be used to provide a strongly-typed interface to [iOS Storyboards](https://developer.apple.com/library/ios/recipes/xcode_help-IB_storyboard/chapters/AboutStoryboards.html).

# Installation & Basic Usage #

Use the `gem` command to install Stronglyboards:

```gem install stronglyboards```

Run stronglyboards with your Xcode project file:

```stronglyboards -i MyProject.xcodeproj```

By default it will generate Objective-C files named `Stronglyboards.h` and `Stronglyboards.m` in the current directory.

Import these files into your Xcode project.

# Options #

`--input` or `-i` specifies the Xcode project file. This is required.

`--output` or `-o` specifies the name of the output file(s). You can use this parameter to output to a different directory. i.e. `-o Classes/GeneratedStoryboardAPI`. You should **not** provide a file extension as part of this file name. This is an optional parameter, default is `Stronglyboards`.

`--lang` or `-l` specifies the output language as either `objc` or `swift` (not yet supported). This is an optional parameter, default is `objc`.

`--prefix` specifies a string to be used as the prefix for all generated classes. This is an optional parameter, default is no prefix. Note that the prefix does not affect the output file name.