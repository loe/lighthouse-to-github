require 'lighthouse'
require 'octokit'

class Migrator

  attr_accessor :lighthouse_project
  attr_accessor :github_repo

  def initialize(options)
    Lighthouse.account = options[:lighthouse_account]
    Lighthouse.token = options[:lighthouse_token]
    @lighthouse_project = Lighthouse::Project.find(options[:lighthouse_project])

    client = Octokit::Client.new(:login => options[:github_user], :oauth_token => options[:github_token])
    @github_repo = client.repository(:user => options[:github_owner], :repo => options[:github_repo])
  end

  def migrate!
    puts @lighthouse_project.inspect
    puts @github_repo.inspect
  end

end
