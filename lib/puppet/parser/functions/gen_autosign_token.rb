begin
  require 'autosign'
  require 'socket'
  require 'logging'
  module Puppet::Parser::Functions
    newfunction(:gen_autosign_token, type: :rvalue, doc: <<-EOS
      Generate a JWT autosign token for use with the autosign gem's
      autosign policy executable.

      Requires a boolean hostname string as input. Token validity, the secret
      used to sign the token, and other settings are determined by settings in
      autosign.conf.
      EOS
               ) do |arguments|
      @logger = Logging.logger['Autosign']
      @logger.level = :info
      @logger.add_appenders Logging.appenders.stdout

      config = Autosign::Config.new
      case arguments.size
      when 1
        jwt_token_validity = config.settings['jwt_token']['validity']
      when 2
        raise(Puppet::ParseError, 'gen_autosign_token(): second argument must be a positive integer') unless arguments[1].to_i > 0
        jwt_token_validity = arguments[1].to_i
      else
        raise(Puppet::ParseError, 'gen_autosign_token(): Wrong number of arguments ' \
        "given (#{arguments.size} for 1 or 2)")
      end

      jwt_secret = ENV['JWT_TOKEN_SECRET'] unless ENV['JWT_TOKEN_SECRET'].nil?
      jwt_secret = config.settings['jwt_token']['secret'] unless config.settings['jwt_token']['secret'].nil?

      if jwt_secret.nil?
        raise(Puppet::ParseError, 'gen_autosign_token(): cannot generate token. ' \
              'No secret provided in /etc/autosign.conf or JWT_TOKEN_SECRET env variable')
      end

      token = Autosign::Token.new(arguments[0].to_s, false, jwt_token_validity.to_i, Socket.gethostname.to_s, jwt_secret)

      # value = function_str2bool([arguments[0]])

      # We have real boolean values as well ...
      result = token.sign

      return result
    end
  end
rescue LoadError
  # This will end up causing puppet compilation to fail because the function cannot
  # be loaded
  Puppet.warning('autosign gem is missing, cannot load gen_autosign_token function')
end
# vim: set ts=2 sw=2 et :
