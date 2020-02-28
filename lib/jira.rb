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
