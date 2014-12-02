module Chain
  class APIEnumerator
    include Enumerable

    def initialize(url, params, conn)
      @url = url
      @params = params || {}
      @conn = conn
    end

    def each
      return self unless block_given?

      until @end
        get_page.each do |item|
          yield item
        end
      end
    end

    private

    def get_page
      resp = @conn.get(@url, @params, headers)
      @next_range = resp.headers["next-range"]
      @end = @next_range.nil?
      resp
    end

    def headers
      {}.tap {|h| h['Range'] = @next_range if @next_range}
    end
  end
end
