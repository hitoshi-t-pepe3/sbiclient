# -*- coding: utf-8 -*- 

$: << "../lib"

require "rubygems"
require "logger"
require 'sbiclient'
require "common"
require 'jiji/plugin/plugin_loader'
require 'jiji/plugin/securities_plugin'

# jijiプラグインのテスト
# ※実際に取引を行うので注意!
describe "jiji plugin" do
  #
  before(:all) {
    # ロード
    JIJI::Plugin::Loader.new.load
    plugins = JIJI::Plugin.get( JIJI::Plugin::SecuritiesPlugin::FUTURE_NAME )
    @plugin = plugins.find {|i| i.plugin_id == :sbi_securities }
    @logger = Logger.new STDOUT
  }
  #
  it "jiji pluginのテスト" do
    @plugin.should_not be_nil
    @plugin.display_name.should == "SBI Securities"

    begin
      @plugin.init_plugin( {:user=>USER, :password=>PASS, :trade_password=>ORDER_PASS}, @logger )

      # 売り/買い
      sell = @plugin.order( :MSDJPY, :sell, 1 )
      buy  = @plugin.order( :MSDJPY, :buy, 1 )
      sell.position_id.should_not be_nil
      buy.position_id.should_not be_nil

      # 約定
      @plugin.commit sell.position_id, 1
      @plugin.commit buy.position_id, 1
    ensure
      @plugin.destroy_plugin
    end
  end
  #
  it "売り IFD 指値-指値" do
    @plugin.should_not be_nil
    @plugin.display_name.should == "SBI Securities"
    
    begin
      @plugin.init_plugin( {:user=>USER, :password=>PASS, :trade_password=>ORDER_PASS}, @logger )

      # 利用可能な通貨ペア一覧とレート
      pairs = @plugin.list_pairs
      rates =  @plugin.list_rates
      
      # 売り
      sell  = @plugin.order( :MSDJPY, :sell, 1, { 
        :rate => rates[SBIClient::FX::MSDJPY].bid + 0.005,
        :settle => {
          :rate => rates[SBIClient::FX::MSDJPY].ask - 0.040,
          :execution_expression => SBIClient::FX::EXECUTION_EXPRESSION_LIMIT_ORDER
        },
        :execution_expression => SBIClient::FX::EXECUTION_EXPRESSION_LIMIT_ORDER,
        :expiration_type => SBIClient::FX::EXPIRATION_TYPE_TODAY
      })
      sell.position_id.should_not be_nil

      sleep 1

      # cancel order
      @plugin.cancel_order(sell.order_no)
    ensure
      @plugin.destroy_plugin
    end
  end
  #
  it "can use list-order throgh jiji-plugin" do
    @plugin.should_not be_nil
    @plugin.display_name.should == "SBI Securities"
    begin
      @plugin.init_plugin({
         :user => USER,
         :password => PASS,
         :trade_password => ORDER_PASS
        },
        @logger
      )
      # 利用可能な通貨ペア一覧とレート
      pairs = @plugin.list_pairs
      rates =  @plugin.list_rates
      #
      before_orders = @plugin.list_orders()
      before_orders.size.should >= 0
      # 買い
      buy  = @plugin.order( :MSDJPY, :buy, 1, { 
        :rate => rates[SBIClient::FX::MSDJPY].bid - 0.005,
        :settle => {
          :rate => rates[SBIClient::FX::MSDJPY].ask + 0.040,
          :execution_expression => SBIClient::FX::EXECUTION_EXPRESSION_LIMIT_ORDER
        },
        :execution_expression => SBIClient::FX::EXECUTION_EXPRESSION_LIMIT_ORDER,
        :expiration_type => SBIClient::FX::EXPIRATION_TYPE_TODAY
      })
      #
      sleep 0.5
      orders = @plugin.list_orders()
      pp orders
      # ifd注文は、発注中の注文は1つが加算される。
      orders.size.should == before_orders.size + 1 
      # cancel order
      @plugin.cancel_order(buy.order_no)
    ensure
      @plugin.destroy_plugin
    end
  end
end
