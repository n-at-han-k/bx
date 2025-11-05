require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'tests'
  t.test_files = FileList['tests/**/*test_*.rb']
  t.verbose = true
end

task default: :test
