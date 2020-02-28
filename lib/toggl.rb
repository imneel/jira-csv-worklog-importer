# frozen_string_literal: true

class Toggl
  def fetch_records(workspace_id, client_id, user_agent, from_date, till_date)
    query = {
      since: from_date,
      until: till_date,
      user_agent: user_agent,
      workspace_id: workspace_id,
      client_ids: [client_id]
    }
    page = 0
    time_entries = []
    loop do
      page += 1
      reqpath = 'reports/api/v2/details'
      resp = api.request(method: :get, path: reqpath, query: query.merge(page: page), headers: headers)
      out = JSON.parse(resp.body)
      data, count = out["data"], out["total_count"]
      break unless data || puts("Failed #{out}")
      time_entries.concat(data)
      break if time_entries.size >= count
    end
    time_entries.sort_by { |entry| entry['start'] }
  end

  def attach_tag(tag, ids)
    payload = { time_entry: { tags: [tag], tag_action: 'add' } }
    reqpath = "api/v8/time_entries/#{ids.join(',')}"
    resp = api.request(method: :put, path: reqpath, body: payload.to_json, headers: headers)
    return true if resp.status.between?(200, 299)

    puts "Failed #{resp.body}"
  end

  def api
    @api ||= ::Excon.new(ENV['TOGGL_REST_API_URL'], user: ENV['TOGGL_ACCESS_TOKEN'], password: 'api_token')
  end

  def headers
    {
      'Content-Type' => 'application/json'
    }
  end
end
