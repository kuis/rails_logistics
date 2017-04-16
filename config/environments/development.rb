Lodgistics::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb
  config.eager_load = false

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # config.assets.prefix = '/assets_dev'

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.default_url_options = {
    host: ENV['HOST'] || Settings.host,
    only_path: false
  }
  config.action_mailer.asset_host = ENV['HOST'] || Settings.host

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Do not compress assets
  config.assets.compress = false

  # Expands the lines which load the assets
  config.assets.debug = true

  Rails.application.routes.default_url_options[:host] = ENV['HOST'] || Settings.host

  config.action_mailer.perform_deliveries = true

  config.action_mailer.delivery_method = Settings.action_mailer_delivery_method.to_sym rescue :smtp
  if config.action_mailer.delivery_method == :smtp
    ActionMailer::Base.smtp_settings = {
        port:           Settings.Mailgun.SMTP.PORT,
        address:        Settings.Mailgun.SMTP.SERVER,
        user_name:      Settings.Mailgun.SMTP.LOGIN,
        password:       Settings.Mailgun.SMTP.PASSWORD,
        domain:         Settings.Mailgun.domain,
        authentication: :plain,
    }
  else
    config.action_mailer.smtp_settings = { address: 'localhost', port: 1025 }
  end

  config.after_initialize do
    Bullet.enable = true
    Bullet.bullet_logger = true
    Bullet.console = true
    Bullet.rails_logger = true
    Bullet.add_footer = true
  end
end

$stdout.sync = true
