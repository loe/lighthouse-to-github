$: << File.expand_path("../lib/", __FILE__)
require 'migrator'

class LighthouseToGithub < Thor

  desc "migrate", "migrate Lighthouse Tickets to Github Issues"
  method_option :lighthouse_account, :type => :string, :required => true
  method_option :lighthouse_project, :type => :numeric, :required => true
  method_option :lighthouse_token, :type => :string, :required => true
  method_option :github_owner, :type => :string, :required => true
  method_option :github_repo, :type => :string, :required => true
  method_option :github_user, :type => :string, :required => true
  method_option :github_token, :type => :string, :required => true
  def migrate
    Migrator.new(options).migrate!
  end

end
