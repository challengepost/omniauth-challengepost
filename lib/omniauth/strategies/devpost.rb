require 'omniauth'
require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    class Devpost < OmniAuth::Strategies::OAuth2
      DEFAULT_SCOPE = "user"
      OMNIAUTH_PROVIDER_SITE = ENV.fetch('OMNIAUTH_PROVIDER_SITE') { 'https://api.devpost.com' }
      OMNIAUTH_AUTHORIZE_URL = ENV.fetch('OMNIAUTH_AUTHORIZE_URL') { 'https://oauth.devpost.com/oauth/authorize' }
      OMNIAUTH_TOKEN_URL     = ENV.fetch('OMNIAUTH_TOKEN_URL') { 'https://oauth.devpost.com/oauth/token' }

      option :name, "devpost"

      option :client_options, {
        :site => OMNIAUTH_PROVIDER_SITE,
        :authorize_url => OMNIAUTH_AUTHORIZE_URL,
        :token_url => OMNIAUTH_TOKEN_URL
      }

      option :authorize_options, [:scope]

      # For more info, see https://github.com/intridea/omniauth/wiki/Auth-Hash-Schema

      uid { raw_info['id'] }

      info do
        prune!({
          'name' => [raw_info['first_name'], raw_info['last_name']].join(" ").strip,
          'nickname' => raw_info['screen_name'],
          'email' => raw_info['email'],
          'location' => (raw_info['location'] || {})['address'],
          'first_name' => raw_info['first_name'],
          'last_name' => raw_info['last_name'],
          'description' => raw_info['tagline'],
          'image' => raw_info['avatar_url'],
          'urls' => {
            "Devpost" => raw_info['url'],
            "Github" => raw_info['urls']['github'],
            "Twitter" => raw_info['urls']['twitter'],
            "LinkedIn" => raw_info['urls']['linkedin'],
            "Website" => raw_info['urls']['website']
          }
        })
      end

      extra do
        prune!({
          'raw_info' => raw_info
        })
      end

      def raw_info
        @raw_info ||= raw_credentials_json["user"]
      end

      protected

      def raw_credentials_json
        @raw_credentials_json ||= begin
                                    access_token.options[:mode] = :query
                                    access_token.get('/user/credentials').parsed
                                  end
      end

      def prune!(hash)
        hash.delete_if do |_, value|
          prune!(value) if value.is_a?(Hash)
          value.nil? || (value.respond_to?(:empty?) && value.empty?)
        end
      end
    end
  end
end
