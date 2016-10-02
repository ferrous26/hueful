# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hueful/version'

Gem::Specification.new do |spec|
  spec.name          = 'hueful'
  spec.version       = Hueful::VERSION
  spec.authors       = ['Mark Rada']
  spec.email         = ['mrada@marketcircle.com']

  spec.summary       = 'A library for experimenting with and orchestrating Philips Hue lights'
  spec.homepage      = 'https://github.com/ferrous26/hueful'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'http'
  spec.add_dependency 'nokogiri'

  spec.add_development_dependency 'bundler', '~> 1.13'
end
