# -*- encoding: utf-8 -*-
$LOAD_PATH.push File.expand_path('../lib', __FILE__)

require 'pronto/flow/version'

Gem::Specification.new do |s|
  s.name = 'pronto-flow'
  s.version = Pronto::FlowVersion::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ['Kevin Jalbert']
  s.email = 'kevin.j.jalbert@gmail.com'
  s.homepage = 'https://github.com/kevinjalbert/pronto-flow'
  s.summary = <<-EOF
    Pronto runner for flow, a static type checker for javascript.
  EOF

  s.licenses = ['MIT']
  s.required_ruby_version = '>= 2.0.0'
  s.rubygems_version = '1.8.23'

  s.files = Dir.glob('{lib}/**/*') + %w(LICENSE README.md)
  s.test_files = `git ls-files -- {spec}/*`.split("\n")
  s.extra_rdoc_files = ['LICENSE', 'README.md']
  s.require_paths = ['lib']
  s.requirements << 'flow (in PATH)'

  s.add_dependency('pronto', '~> 0.9.0')
  s.add_dependency('rugged', '~> 0.24', '>= 0.23.0')
  s.add_development_dependency('rake', '~> 12.0')
  s.add_development_dependency('rspec', '~> 3.4')
end
