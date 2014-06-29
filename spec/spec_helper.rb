require 'json'
require 'faker'
require 'vimrunner'
require 'vimrunner/testing'
require_relative 'lib/cmakevim'
require_relative 'lib/vimrunner/extras'

I18n.enforce_available_locales = false

RSpec.configure do | config |
  # Include some helpers from Vimrunner, we don't use stock.
  config.include Vimrunner::Testing
  config.include Vimrunner::Extras
  config.include CMakeVim::Environment
  config.include CMakeVim::RSpec

  config.around(:each) do | example |
    dir = Dir.mktmpdir
    Dir.chdir(dir) do
      vim.command('cd ' + dir)
      expect(vim.command('pwd')).to match(dir)
      example.run
      cleanup_cmake unless cmake.nil?
      vim.kill
    end
  end
end
