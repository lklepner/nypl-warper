module Tilestache
  require "open3"
  extend ActiveSupport::Concern
  
  def tilestache_seed
    secret = ENV['s3_tiles_secret_access_key'] || APP_CONFIG['s3_tiles_secret_access_key'] 
    key_id = ENV['s3_tiles_access_key_id'] || APP_CONFIG['s3_tiles_access_key_id'] 
    bucket_name = ENV['s3_tiles_bucket_name'] || APP_CONFIG['s3_tiles_bucket_name']
    
    item_type  = self.class.to_s.downcase
    item_id =    self.id
    
    options = {
      :item_type => item_type, 
      :item_id => item_id, 
      :secret => secret, 
      :access => key_id, 
      :bucket => bucket_name}
    
    config_json = tilestache_config_json(options)
    
    config_file = File.join(Rails.root, 'tmp', "#{options[:item_type]}_#{options[:item_id]}_tilestache.json")
    File.open(config_file, "w+") do |f|
      f.write(config_json)
    end

    bbox = self.bbox.split(",")
    tile_bbox = bbox[1],bbox[0],bbox[3],bbox[2]
    tile_bbox_str = tile_bbox.join(" ")
    
    command = "cd #{APP_CONFIG['tilestache_path']}; python scripts/tilestache-seed.py -c #{config_file}" +
      " -l #{self.id} -b #{tile_bbox_str} --enable-retries -x 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21" # 13 14 15 16 17 18 19 20 21
    
    puts command
    logger.debug command
    
    t_stdout, t_stderr, t_status = Open3.capture3( command )

    unless t_status.success?
      
      puts t_stderr
      logger.error t_stderr

      return nil
    else
       return true
    end
    
    
  end
  
  
  private
  
  def tilestache_config_json(options)
    
    url = "http://#{APP_CONFIG['host']}/#{options[:item_type]}s/tile/#{options[:item_id]}/{Z}/{X}/{Y}.png"
    
    config = {
      "cache" => {
        "name" => "S3",
        "bucket" => options[:bucket],
        "access" => options[:access],
        "secret" => options[:secret]
      },
      "layers" => {
        options[:item_id] => {       
          "provider" => {
            "name" => "proxy", 
            "url" =>  url
          }
        }
      }
    }
    
#    test_config = {
#      "cache" => {
#        "name" => "Test",
#        "path" => "/tmp/stache"
#      },
#      "layers" => {
#        options[:item_id] => {       
#          "provider" => {
#            "name" => "proxy", 
#            "url" =>  url
#          }
#        }
#      }
#    }
    
    JSON.pretty_generate(config)
  end
  
end 
