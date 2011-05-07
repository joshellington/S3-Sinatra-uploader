require 'rubygems'
require 'sinatra'
require 'yaml'
require 'aws/s3'

include AWS::S3

def s3_connect
	settings = YAML.load_file('./keys.yml')
	puts settings.inspect
	Base.establish_connection!(
		:access_key_id	=> settings['access_key'],
		:secret_access_key => settings['secret_access_key']
	)
end

get '/' do
	s3_connect
	@buckets = Service.buckets
	erb :index
end

get '/bucket/:key' do
	s3_connect
	@bucket = Bucket.find(params[:key])
	erb :bucket
end

get '/upload' do
	s3_connect
	@buckets = Service.buckets
	erb :upload
end

post '/upload' do
	s3_connect
	unless params[:file] && (tmpfile = params[:file][:tempfile]) && (name = params[:file][:filename])
		return erb(:upload)
	end
	while blk = tmpfile.read(65536)
		S3Object.store(name,open(tmpfile),Bucket.find(params[:bucket]).name,:access => :public_read)
		File.open(File.join(Dir.pwd,"public/uploads", name), "wb") { |f| f.write(tmpfile.read) }
	end
	bucket = Bucket.find(params[:bucket]).name
	@file = S3Object.url_for(params[:file][:filename], bucket, :authenticated => false)
	puts @file
	erb :success
end