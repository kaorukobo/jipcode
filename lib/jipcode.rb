require "jipcode/version"
require 'csv'
require 'yaml'

module Jipcode
  ZIPCODE_PATH = "#{File.dirname(__FILE__)}/../zipcode/latest".freeze
  PREFECTURE_CODE = YAML.load_file("#{File.dirname(__FILE__)}/../prefecture_code.yml").freeze

  def locate(zipcode, opt={})
    # 数字7桁以外の入力は受け付けない
    return [] unless zipcode&.match?(/\A\d{7}?\z/)

    csv_entry = CsvEntry.by_zipcode(zipcode) or return []

    addresses_array = csv_entry.load_addresses.select { |address| address[0] == zipcode }

    if opt.empty?
      # optが空の場合、直接basic_address_fromを呼んで不要な判定を避ける。
      addresses_array.map { |address_param| basic_address_from(address_param) }
    else
      addresses_array.map { |address_param| extended_address_from(address_param, opt) }
    end
  end

  # `Jipcode::FromAddressLocator.new.locate(addr_string)` に同じ。
  # @see Jipcode::FromAddressLocator#locate
  # @note
  #   複数回連続して呼び出す場合は、毎回CSVファイルを読み込む無駄が生じるため、
  #   Jipcode::FromAddressLocator を直接使うほうがよい。
  def locate_by_addr_string(addr_string)
    require "jipcode/from_address_locator"
    Jipcode::FromAddressLocator.new.locate(addr_string)
  end

  def basic_address_from(address_param)
    {
      zipcode:    address_param[0],
      prefecture: address_param[1],
      city:       address_param[2],
      town:       address_param[3]
    }
  end

  def extended_address_from(address_param, opt={})
    address = basic_address_from(address_param)
    address[:prefecture_code] = PREFECTURE_CODE.invert[address_param[1]] if opt[:prefecture_code]
    address
  end

  module_function :locate, :locate_by_addr_string, :basic_address_from, :extended_address_from

  # CSVファイルをあらわすオブジェクト。
  class CsvEntry
    def initialize(path)
      @path = path
    end

    def load_addresses
      CSV.read(@path)
    end

    # すべてのCSVファイルに対応する CsvEntry の配列を返す。
    # @return [Array<CsvEntry>]
    def self.all
      Dir["#{ZIPCODE_PATH}/*.csv"].map { |file|
        new(file)
      }
    end

    # 上3桁にマッチするファイルを探す。存在しなければ nil を返す。
    # @return [CsvEntry, nil]
    def self.by_zipcode(zipcode)
      path = "#{ZIPCODE_PATH}/#{zipcode[0..2]}.csv"
      File.exist?(path) ? new(path) : nil
    end
  end
end
