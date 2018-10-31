# Framework-specific configuration.
Rails.application.configure do
  # Load our custom config. This is implicitly consumed in a few remaining
  # places (e.g. RequestMailer). A good development improvement would be to
  # inject those configs like we're doing with the Patron class below.
  config.altmedia = config_for(:altmedia)

  # Configure Patron API lookups
  Patron.api_base_url = URI.parse(config.altmedia['patron_url'])
  Patron.expect_url = URI.parse(config.altmedia['expect_url'])
end
