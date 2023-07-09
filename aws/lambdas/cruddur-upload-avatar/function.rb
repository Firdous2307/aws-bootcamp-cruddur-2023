require 'aws-sdk-s3'

s3 = Aws::S3::Resource.new
bucket_name = ENV["UPLOADS_BUCKET_NAME"]
object_key = 'mock.jpg'

obj = s3.bucket(bucket_name).object(object_key)
url = obj.presigned_url(:put, expires_in: 3600)
puts url