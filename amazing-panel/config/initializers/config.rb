APP_CONFIG = YAML.load_file("#{Rails.root}/config/config.yml")[Rails.env]

NEWS_SOURCES = [
  "http://helios.av.it.pt/projects/amazing-panel/news.json",
  "http://mytestbed.net/news.json"
]
