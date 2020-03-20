# frozen_string_literal: true

class Jira
  def create_worklog(issue_id, t_spent, description, started_at)
    payload = {
      timeSpentSeconds: t_spent,
      started: started_at.strftime('%Y-%m-%dT%H:%M:%S.%L%z'),
      comment: {
        type: 'doc',
        version: 1,
        content: [{
          type: 'paragraph',
          content: [{
            text: description.strip,
            type: 'text'
          }]
        }]
      }
    }
    reqpath = "rest/api/3/issue/#{issue_id}/worklog"
    resp = api.request(method: :post, path: reqpath, body: payload.to_json, headers: headers)
    out = resp.status.to_s =~ /\A20/ ? 'success' : 'failure'
    puts "Issue #{issue_id} -> #{description} -> #{started_at} -> #{t_spent} push #{out} ID:#{JSON.parse(resp.body)['id']}"
    out == 'success'
  end

  def fetch_recent_worklog_ids(started_at)
    reqpath = "rest/api/3/worklog/updated"
    resp = api.request(method: :get, path: reqpath, query: {since: started_at.to_i}, headers: headers)
    out = resp.status.to_s =~ /\A20/ ? 'success' : 'failure'
    return false unless out == 'success'
    JSON.parse(resp.body)["values"].map {|wl| wl["worklogId"]}
  end

  def fetch_worklogs_by_ids(ids)
    reqpath = "rest/api/3/worklog/list"
    resp = api.request(method: :post, path: reqpath, body: {ids: ids}.to_json, headers: headers)
    out = resp.status.to_s =~ /\A20/ ? 'success' : 'failure'
    return false unless out == 'success'
    JSON.parse(resp.body)
  end

  def fetch_recent_worklogs(started_at)
    ids = fetch_recent_worklog_ids(started_at)
    return [] if ids.empty?
    fetch_worklogs_by_ids(ids)
  end

  def clockwork_worklog?(worklog)
    worklog.dig("comment", "content", 0, "content", 0, "text") == "Automatically logged by Clockwork" &&
    worklog.dig("author", "emailAddress") == ENV["JIRA_ACCOUNT_MAIL"]
  end

  def delete_worklog(issueId, worklogId)
    reqpath = "rest/api/3/issue/#{issueId}/worklog/#{worklogId}"
    resp = api.request(method: :delete, path: reqpath, query: {adjustEstimate: 'leave'}, headers: headers)
    out = resp.status.to_s =~ /\A20/ ? 'success' : 'failure'
    out == 'success'
  end

  def delete_clockwork_worklogs(started_at)
    worklogs = fetch_recent_worklogs(started_at)
    return true if worklogs.nil? || worklogs.empty?

    worklogs.each do |worklog|
      next unless clockwork_worklog?(worklog)
      if delete_worklog(worklog["issueId"], worklog["id"])
        puts "deleted worklog##{worklog["id"]} of issue##{worklog["issueId"]}"
      else
        puts "Failed to delete worklog##{worklog["id"]} of issue##{worklog["issueId"]}"
      end
    end
    true
  end

  def api
    @api ||= ::Excon.new(ENV['JIRA_REST_API_URL'], user: ENV['JIRA_ACCOUNT_MAIL'], password: ENV['JIRA_ACCESS_TOKEN'])
  end

  def headers
    {
      'Content-Type' => 'application/json',
      'Accept' => 'application/json'
    }
  end
end
