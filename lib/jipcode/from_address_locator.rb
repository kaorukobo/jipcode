module Jipcode
  # @see FromAddressLocator#locate
  class FromAddressLocator
    Address = Struct.new(:csv_row, :addr)

    # 住所文字列 addr_string に最も合致する可能性のある住所情報を返す。
    #
    # @return [Hash] #locate の戻り値に同じ。ただし、市区町村以降をあらわす :rest を含む。
    # @example
    #   require "jipcode/from_address_locator"
    #
    #   locator = Jipcode::FromAddressLocator.new
    #
    #   addr = locator.locate('東京都千代田区永田町1-7-1')
    #   p addr
    #   # {
    #   #     :zipcode => "1000014"
    #   #     :prefecture => "東京都",
    #   #     :city => "千代田区",
    #   #     :town => "永田町",
    #   #     :rest => "1-7-1",
    #   # }
    # @note
    #   初回の #locate 呼び出しで、すべての郵便番号データが FromAddressLocator オブジェクトに読み込まれる。
    #   メモリの無駄を避けるため、 FromAddressLocator オブジェクトは必要な間だけ保持することが勧められる。
    def locate(addr_string)
      filtered_string = addr_string.to_s.gsub(/\s+/, "")

      ensure_csv_data_loaded

      possible_addresses = @addresses.find_all { |row|
        filtered_string.start_with?(row.addr)
      }.sort_by { |row|
        -(row.addr.length)
      }

      found = possible_addresses[0]

      if found
        rest = filtered_string.sub(/^#{Regexp.quote(found.addr)}/, "")
        Jipcode.basic_address_from(found.csv_row).merge(
            rest: rest
        )
      else
        nil
      end
    end

    # すべての郵便番号データを読み込む。 #locate を使う前に、事前にデータを読み込ませておきたい場合に使用する。
    def ensure_csv_data_loaded
      @addresses ||=
          Jipcode::CsvEntry.all.reduce([]) { |all, csv_entry|
            all.concat(
                csv_entry.load_addresses.map { |csv_row|
                  Address.new(csv_row, csv_row[1..-1].join(""))
                }
            )
          }
      self
    end
  end
end