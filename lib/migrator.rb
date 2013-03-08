require 'active_support/all'
require 'lighthouse'
require 'octokit'
ActiveSupport::XmlMini.backend = 'Nokogiri'

class Migrator

  attr_accessor :lighthouse_project
  attr_accessor :github_repo

  def initialize(options)
    Lighthouse.account = options[:lighthouse_account]
    Lighthouse.token = options[:lighthouse_token]
    @lighthouse_project = Lighthouse::Project.find(options[:lighthouse_project])

    client = Octokit::Client.new(:login => options[:github_user], :password => options[:github_password], :oauth_token => options[:github_token])
    @github_repo = client.repository(:user => options[:github_owner], :repo => options[:github_repo])
  end

  def migrate!
    tickets = load_lighthouse_tickets(11)

    tickets.each do |t|
      ticket = Lighthouse::Ticket.find(t.number, :params => {:project_id => @lighthouse_project.id})
      main = ticket.versions.shift

      asignee = ticket.versions.last.assigned_user_name if ticket.versions.last.assigned_user_name
      title = ticket.title
      body = main.body


      puts "ID: #{ticket.number}"
      puts "Asignee: #{asignee}"
      puts "Title: #{title}"
      puts "Labels: #{ticket.tags.join(', ')}"
      puts "Body: #{body}"
      ticket.versions.each do |version|
        puts "Comment (#{version.creator_name}): #{version.body}" if version.body.present?
      end
      puts "\n\n"
    end
  end

  def load_lighthouse_tickets(page = 1)
    tickets = []
    begin
      page_of_tickets = @lighthouse_project.tickets(:page => page)
      tickets += page_of_tickets
      page += 1
    end while page_of_tickets.size > 0

    tickets
  end

end
