# Toggl To Jira worklog

## Setup

If you are linux replace brew with your package manager.

1. Install the ruby mentioned in `.ruby-version` along with `bundler` (We prefer `rbenv`)
2. Run `bundle install --path=.bundle --binstubs .bundle/bin --jobs=4 --retry=3`
3. Add credentials to `.env-sampl` and create symlink using `ln -s .env-sample .env`
4. Run `bundle exec ruby worklog.rb`
