require 'bundler'
Bundler.require(:default)

require 'dotenv/load'
require 'excon'
require 'csv'
require 'time'

class Jira
  def create_worklog(issue_id, t_spent, description, started_at)
    payload = {
      timeSpentSeconds: t_spent,
      started: started_at.strftime('%Y-%m-%dT%H:%M:%S.%L%z'),
      comment: {
        type: "doc",
        version: 1,
        content: [{
          type: "paragraph",
          content: [{
            text: description,
            type: "text"
          }]
        }]
      }
    }
    reqpath = "rest/api/3/issue/#{issue_id}/worklog"
    resp = api.request(method: :post, path: reqpath, body: payload.to_json, headers: headers)
    out = resp.status.to_s =~ /\A20/ ? "success" : "failure"
    puts "Issue#{issue_id} -> #{description} -> #{started_at} -> #{t_spent} push #{out} ID:#{JSON.parse(resp.body)['id']}"
  end

  def api
    @api ||= ::Excon.new(ENV["JIRA_REST_API_URL"], user: ENV["JIRA_ACCOUNT_MAIL"], password: ENV["JIRA_ACCESS_TOKEN"])
  end

  def headers
    {
      "Content-Type" => "application/json",
      "Accept" => "application/json"
    }
  end
end

class WorklogImporter
  def str_to_sec(str)
    out = str.split(":")
    out[0].to_i * 3600 + out[1].to_i * 60 + out[2].to_i
  end

  def jira_api
    @jira_api ||= ::Jira.new
  end

  def import
    CSV.foreach(ENV["TIMESHEET_CSV_URL"], headers: true) do |row|
      issue, description = row["Description"].scan(/(\A[^:]+:)(.*\z)/).first
      unless issue && description
        issue = row["Issue"]
        description = row["Description"]
      end
      issue_id = issue =~ /adhoc|support/i ? "AI-2722" : issue.strip
      timeSpent = str_to_sec(row["Duration"])
      startedAt = Time.parse(row["Start date"] + " " + row["Start time"])
      jira_api.create_worklog(issue_id, timeSpent, description, startedAt)
    end
  end
end

importer = ::WorklogImporter.new
importer.import