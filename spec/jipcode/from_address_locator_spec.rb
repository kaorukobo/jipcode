require "jipcode/from_address_locator"

RSpec.describe Jipcode::FromAddressLocator do
  describe '#locate' do
    subject {
      Jipcode::FromAddressLocator.new.locate(address)
    }
    context '与えられた住所文字列に対応する住所があるとき' do
      let(:address) {
        '東京都千代田区永田町1-7-1'
      }

      it '対応する住所を返す' do
        is_expected.to eq({
            :city => "千代田区",
            :prefecture => "東京都",
            :rest => "1-7-1",
            :town => "永田町",
            :zipcode => "1000014"
        })
      end
    end
    context '与えられた住所に対応する住所情報がないとき' do
      let(:address) {
        '東京都万代田区'
      }

      it 'nilを返す' do
        is_expected.to be_nil
      end
    end
  end
end
