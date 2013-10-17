# -*- encoding : utf-8 -*-
#encoding=utf-8
#以下不需要改动

require 'net/http'
require 'uri'
require 'open-uri'
require 'multi_json'

class Qq
	attr_reader :token,:openid,:auth
	
	# scope=get_user_info,get_other_info,add_t,add_share
	def self.login_url(scope)
		options = {which: :ConfirmPage,client_id: Setting.qq_key,response_type: :code,redirect_uri: Setting.qq_redurl,state: :production,display: :pc,scope: scope}
		"#{Setting.qq_open_api}/authorize?" + options.to_query
	end

	# code=params[:code],httpstat=request.env['HTTP_CONNECTION']
	def initialize(code,httpstat=:production)
		@appid = Setting.qq_key
		@secret = Setting.qq_secret
		@redurl = Setting.qq_redurl

		get_token(code,httpstat)
		get_open_api()
	end	

    #获取令牌
	def get_token(code,httpstat)
		options = {grant_type: :authorization_code,client_id: @appid,client_secret: @secret,redirect_uri: @redurl,code: code,state: httpstat}
		@token=open("#{Setting.qq_open_api}/token?" + options.to_query,verify_mode).read[/(?<=access_token=)\w{32}/] || ''
	end

    #获取Openid
	def get_open_api()
		options = {access_token: @token}
		@openid=open("#{Setting.qq_open_api}/me?" + options.to_query,verify_mode).read[/\w{32}/]
	end

    #获取用户信息:比如figureurl,nickname
	def get_user_info()
    Rails.logger.info "*"*10
    Rails.logger.info "#{Setting.qq_user_url}" + auth
		MultiJson.decode(open("#{Setting.qq_user_url}" + auth,verify_mode).read.force_encoding('utf-8'))
	end

	# 获取通用验证参数
	def auth
		@auth ||={access_token: @token,oauth_consumer_key: @appid,openid: @openid }.to_query
	end

	def verify_mode
		{ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}
	end
end
