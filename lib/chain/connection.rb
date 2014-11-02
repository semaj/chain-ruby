require 'thread'

module Chain
  class Connection

    # URI instance specifying a base URL.
    attr_accessor :url

    # String key identifier.
    attr_accessor :api_key_id

    # String key secret.
    attr_accessor :api_key_secret

    def initialize(url, api_key_id, api_key_secret)
      @url = url
      @api_key_id = api_key_id
      @api_key_secret = api_key_secret
      @conn_mutex = Mutex.new
    end

    def post(path, body)
      make_req!(Net::HTTP::Post, path, encode_body!(body))
    end

    def put(path, body)
      make_req!(Net::HTTP::Put, path, encode_body!(body))
    end

    def get(path, params={})
      path = path + "?" + URI.encode_www_form(params) unless params.empty?
      make_req!(Net::HTTP::Get, path)
    end

    def delete(path)
      make_req!(Net::HTTP::Delete, path)
    end

    private

    def make_req!(type, path, body=nil)
      conn do |c|
        req = type.new(@url.request_uri + path)
        req.basic_auth(@api_key_id, @api_key_secret)
        req['Content-Type'] = 'application/json'
        req['User-Agent'] = 'chain-ruby/0'
        req.body = body
        resp = c.request(req)
        resp_code = Integer(resp.code)
        resp_body = parse_resp(resp)
        if resp_code / 100 != 2
          raise(ChainNetworkError.new("#{resp_body['message']}", resp_code, resp_body['code']))
        end
        return resp_body
      end
    end

    def encode_body!(hash)
      begin
        JSON.dump(hash)
      rescue => e
        raise(ChainFormatError, "#{e.message}")
      end
    end

    def parse_resp(resp)
      begin
        JSON.parse(resp.body)
      rescue => e
        raise(ChainFormatError, "#{e.message}")
      end
    end

    def conn
      @conn ||= establish_conn
      @conn_mutex.synchronize do
        begin
          return yield(@conn)
        rescue ChainError => e # if it's our error, pass it as-is.
          @conn = nil
          raise e
        rescue => e # any other error (socket failure etc) is wrapped in ChainNetworkError.
          @conn = nil
          raise(ChainNetworkError, "#{e.message} (#{e.class})")
        end
      end
    end

    def establish_conn
      Net::HTTP.new(@url.host, @url.port).tap do |c|
        c.set_debug_output($stdout) if ENV['DEBUG']
        if @url.scheme == 'https'
          c.use_ssl = true
          c.verify_mode = OpenSSL::SSL::VERIFY_PEER
          c.ca_file = CHAIN_PEM
          c.cert_store = OpenSSL::X509::Store.new
        end
      end
    end

  end
end
