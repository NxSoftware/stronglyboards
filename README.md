# Overview #

Stronglyboards generates code that can be used to provide a strongly-typed interface to [iOS Storyboards](https://developer.apple.com/library/ios/recipes/xcode_help-IB_storyboard/chapters/AboutStoryboards.html).

Reduce mistakes introduced when using string based storyboard and view controller identifiers.

It is inspired by [Natalie](https://github.com/krzyzanowskim/Natalie) but is a [Ruby gem](https://rubygems.org) and generates a slightly different API,
 and I believe [competition is a good thing](https://vimeo.com/124317403).

# Features

- Safe instantiation of:-
  - storyboards,
  - the storyboard's initial view controller,
  - view controllers with storyboard identifiers
- Outputs **Objective-C** or **Swift** depending on your preference.
- Integrates seamlessly into your project.
  - Creates a build phase to automatically keep the generated code up-to-date with storyboard changes.
- Supports **localized** and non-localized Storyboards.

# Todo #

- Segues
- Table and Collection View cells
- More...

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

# Contributing #

Submit an issue, or ideally a pull request.

# Authors & Contributors #

- [@nxsteveo](http://twitter.com/nxsteveo)
- \<Your name here>

# License #

The MIT License (MIT)

Copyright (c) 2015 Steve Wilford

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.