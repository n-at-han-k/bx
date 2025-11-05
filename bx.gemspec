Gem::Specification.new do |spec|
  spec.name          = 'bx'
  spec.version       = '0.1.0'
  spec.authors       = ['ara.t.howard']
  spec.email         = ['ara.t.howard@gmail.com']

  spec.summary       = 'A tmux session manager with box-of-boxes paradigm'
  spec.description   = 'bx organizes development environments using a hierarchical "box of boxes" paradigm, combining process management, environment orchestration, and tmux session control'
  spec.homepage      = 'https://github.com/ahoward/bx'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 3.1.0'

  spec.files         = Dir['lib/**/*.rb', 'bin/*', 'config/**/*', 'README.md', 'LICENSE']
  spec.bindir        = 'bin'
  spec.executables   = ['bx']
  spec.require_paths = ['lib']

  # Runtime dependencies
  spec.add_dependency 'main', '~> 6.2'
  spec.add_dependency 'sqlite3', '~> 1.6'
  spec.add_dependency 'fattr', '~> 2.4'
  spec.add_dependency 'map', '~> 6.6'
  spec.add_dependency 'lockfile', '~> 2.1'
  spec.add_dependency 'dotenv', '~> 2.8'

  # Development dependencies
  spec.add_development_dependency 'rake', '~> 13.0'
end
