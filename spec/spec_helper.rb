require 'simplecov'
SimpleCov.start

require 'rspec'
require 'pronto/flow'

Dir.glob(Dir.pwd + '/spec/support/**/*.rb') { |file| require file }

RSpec.configure do |c|
  c.include RepositoryHelper
end
