require 'thread'
require 'delegate'

module Chain
  class Conn

    def initialize(url, key_id, key_secret)
      @url = url
      @key_id = key_id
      @key_secret = key_secret
      @conn_mutex = Mutex.new
    end

    def post(path, body, headers={})
      make_req!(Net::HTTP::Post, path, encode_body!(body), headers)
    end

    def put(path, body, headers={})
      make_req!(Net::HTTP::Put, path, encode_body!(body), headers)
    end

    def get(path, params={}, headers={})
      path = path + "?" + URI.encode_www_form(params) unless params.empty?
      headers['Range'] = params[:range] if params[:range]
      make_req!(Net::HTTP::Get, path, nil, headers)
    end

    def delete(path, headers={})
      make_req!(Net::HTTP::Delete, path, nil, headers)
    end

    private

    def make_req!(type, path, body=nil, headers={})
      conn do |c|
        req = type.new(@url.request_uri + path)
        req.basic_auth(@key_id, @key_secret)
        headers.each {|k, v| req[k] = v}
        req['Content-Type'] = 'application/json'
        req['User-Agent'] = 'chain-ruby/0'
        req.body = body
        resp = c.request(req)
        resp_code = Integer(resp.code)
        resp_body = parse_resp(resp)
        if resp_code / 100 != 2
          raise(ChainError, "#{resp_body['message']}")
        end
        return resp_body
      end
    end

    def encode_body!(hash)
      begin
        JSON.dump(hash)
      rescue => e
        raise(ChainError, "#{e.message}")
      end
    end

    def parse_resp(resp)
      begin
        ResponseDecorator.new(JSON.parse(resp.body)).tap do |r|
          r.headers = resp.to_hash
        end
      rescue => e
        raise(ChainError, "#{e.message}")
      end
    end

    def conn
      @conn_mutex.synchronize do
        @conn ||= establish_conn
        begin
          return yield(@conn)
        rescue => e
          @conn = nil
          raise(ChainError, "#{e.message}")
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

  class ResponseDecorator < SimpleDelegator
    attr_accessor :headers

    def next_range
      self.headers.fetch('next-range', [])[0]
    end
  end
end
