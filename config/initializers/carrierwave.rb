CarrierWave.configure do |config|  
    config.storage = :aws
    config.aws_credentials = {
      :access_key_id      => ENV['wasabi_access_key'],
      :secret_access_key  => ENV['wasabi_secret'], 
      region: 'us-east-1'
    }
    config.aws_acl = :public_read
    config.aws_bucket = "biathlon-#{Rails.env.to_s}"
  # configog_attributes = {'Cache-Control'=>'max-age=315576000'}  # optional, defaults to {}
end
Aws.config.update({endpoint: 'https://s3.wasabisys.com'})
