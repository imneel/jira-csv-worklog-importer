# frozen_string_literal: true

class Sync
  def initialize(from_date, till_date)
    @from_date = from_date
    @till_date = till_date
    @success_ids = []
  end

  def execute
    fetch_records && push_worklogs && mark_synced && delete_clockwork_records
  end

  private

  attr_reader :time_entries, :success_ids, :from_date, :till_date

  def push_worklog(id, desc, start, dur, tags)
    if tags.include?('JIRA')
      return puts("Already pushed skipping...#{desc} #{start}")
    end

    issue, description = desc.scan(/(\A[^:]+):\s*(.*\z)/).first
    unless issue && description
      return puts("Unsupported description format #{desc}")
    end

    issue = ENV['ADHOC_ISSUE_ID'] if issue =~ /\Aadhoc/i
    issue = ENV['SUPPORT_ISSUE_ID'] if issue =~ /\Asupport/i
    started_at = Time.parse(start)
    time_spent = dur / 1000
    unless jira_api.create_worklog(issue.strip, time_spent, description, started_at)
      return
    end

    success_ids << id
  end

  def delete_clockwork_records
    jira.delete_clockwork_worklogs(Time.parse(from_date))
  end

  def extract_vals(entry)
    %w[id description start dur tags].map {|key| entry[key] }
  end

  def push_worklogs
    time_entries.each { |entry| push_worklog(*extract_vals(entry)) }
  end

  def mark_synced
    success_ids.each_slice(25) { |ids| toggl_api.attach_tag('JIRA', ids) }
  end

  def fetch_records
    @time_entries = toggl_api.fetch_records(
      ENV['TOGGL_WORKSPACE_ID'],
      ENV['TOGGL_CLIENT_ID'],
      ENV['TOGGL_USER_AGENT'],
      from_date,
      till_date
    )
  end

  def toggl_api
    @toggl_api ||= Toggl.new
  end

  def jira_api
    @jira_api ||= Jira.new
  end
end
