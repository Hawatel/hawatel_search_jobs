# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hawatel_search_jobs/version'

Gem::Specification.new do |spec|
  spec.name          = "hawatel_search_jobs"
  spec.version       = HawatelSearchJobs::VERSION
  spec.authors       = ['Przemyslaw Mantaj','Daniel Iwaniuk']
  spec.email         = ['przemyslaw.mantaj@hawatel.com', 'daniel.iwaniuk@hawatel.com']

  spec.summary       = %q{Hawatel_search_jobs, it is gem which provides ease access to API from popular job websites to get current job offers.}
  spec.description   = %q{Hawatel_search_jobs, it is gem which provides ease access to API from popular job websites
                         to get current job offers.  At this moment, supported backends are indeed.com, careerjet.com,
                         xing.com, careerbuilder.com and reed.co.uk.}
  spec.homepage      = "http://github.com/Hawatel/hawatel_search_jobs"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'xing_api'
  spec.add_runtime_dependency 'activesupport'

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
end
