require 'active_support/all'
require 'lighthouse'
require 'octokit'
ActiveSupport::XmlMini.backend = 'Nokogiri'

class Migrator
  CLOSED_TICKET_STATES = ['resolved', 'invalid']

  attr_accessor :lighthouse_project
  attr_accessor :github_client, :github_repo

  attr_accessor :milestone_map

  def initialize(options)
    Lighthouse.account = options[:lighthouse_account]
    Lighthouse.token = options[:lighthouse_token]
    @lighthouse_project = Lighthouse::Project.find(options[:lighthouse_project])

    @github_client = Octokit::Client.new(:login => options[:github_user], :password => options[:github_password], :oauth_token => options[:github_token])
    @github_repo = "#{options[:github_owner]}/#{options[:github_repo]}"

    @milestone_map = {}
    @assignee_map = {
      'Brandon Caplan' => 'bcaplan',
      'Brian Moran' => 'bmo',
      'Brian Warren' => 'good',
      'Charles Mount' => 'cmount',
      'Leigh Caplan' => 'texel',
      'Matthew Anderson' => 'WanderingMatt',
      'Onehub' => 'onehub-dev', 
      'W. Andrew Loe III' => 'loe'
    }
  end

  def migrate!
    milestones = load_lighthouse_milestones

    @milestone_map = milestones.inject(@milestone_map) do |m, lh_milestone|
      puts "Creating milestone: #{lh_milestone.title}"
      gh_milestone = @github_client.create_milestone(@github_repo, lh_milestone.title, {:description => lh_milestone.goals, :due_on => lh_milestone.due_on, :state => lh_milestone.completed_at ? 'closed' : 'open'})

      m[gh_milestone.title] = gh_milestone.number

      m
    end

    tickets = load_lighthouse_tickets
    tickets.sort_by! { |t| t.number }

    tickets.each do |t|
      ticket = Lighthouse::Ticket.find(t.number, :params => {:project_id => @lighthouse_project.id})
      main = ticket.versions.shift

      assignee = ticket.versions.last.assigned_user_name if ticket.versions.last.assigned_user_name
      title = ticket.title
      body = main.body

      puts "Creating ticket: #{title} (#{@assignee_map[assignee]})"
      begin
        issue = @github_client.create_issue(@github_repo, title, body, {
          :milestone => @milestone_map[ticket.milestone_title],
          :assignee => @assignee_map[assignee],
          :labels => ticket.tags.map { |tag| {:name => tag} }
        })

        if CLOSED_TICKET_STATES.include?(ticket.state)
          @github_client.update_issue(@github_repo, issue.number, title, body, {:state => 'closed'})
        end

        ticket.versions.each do |version|
          if version.body.present? && !version.body =~ /\(from \[/i
            @github_client.add_comment(@github_repo, issue.number, "@#{@assignee_map[version.creator_name]}:\n\n#{version.body}")
          end
        end
      rescue Octokit::InternalServerError
        retry
      rescue Octokit::UnprocessableEntity => e
        puts e.response_body
        raise e
      end
    end
  end

  def load_lighthouse_milestones(page = 1)
    milestones = []
    begin
      page_of_milestones = @lighthouse_project.milestones(:page => page)
      milestones += page_of_milestones
      page +=1
    end while page_of_milestones.size > 0

    milestones
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
