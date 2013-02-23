require 'lighthouse'
require 'octokit'

class Migrator

  attr_accessor :lighthouse_project
  attr_accessor :github_repo

  def initialize(options)
    Lighthouse.account = options[:lighthouse_account]
    Lighthouse.token = options[:lighthouse_token]
    @lighthouse_project = Project.find(options[:lighthouse_project])

    client = Octokit::Client.new(:login => options[:github_user], :password => options[:github_password])
    @github_repo = client.repository(:user => options[:github_owner], :repo => options[:github_repo])
  end

end
