# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'stronglyboards/version'

Gem::Specification.new do |spec|
  spec.name        = 'stronglyboards'
  spec.version     = Stronglyboards::VERSION
  spec.date        = '2015-09-24'

  spec.summary     = "A strongly-typed interface for your storyboards, view controllers, and segues."
  spec.description = "Generates a strongly-typed interface for your storyboards, view controllers, and segues."
  spec.license       = 'MIT'

  spec.authors     = ["Steve Wilford"]
  spec.email       = 'steve@offtopic.io'
  spec.homepage    =
    'http://stevewilford.co.uk/stronglyboards'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

end
