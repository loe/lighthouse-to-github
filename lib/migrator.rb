require 'lighthouse'
require 'octokit'

class Migrator

  attr_accessor :lighthouse_account, :lighthouse_project, :lighthouse_token
  attr_accessor :github_account, :github_repo, :github_user, :github_password

  def initialize(options)
  end
end
