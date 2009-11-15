$: << "../lib"

require 'sbiclient'
require 'common'

describe "IFDOCO" do
  it_should_behave_like "login"   
  
  it "指値" do
    @order_id = @s.order( SBIClient::FX::EURJPY, SBIClient::FX::BUY, 1, {
      :rate=>@rates[SBIClient::FX::EURJPY].ask_rate - 0.5,
      :execution_expression=>SBIClient::FX::EXECUTION_EXPRESSION_LIMIT_ORDER,
      :expiration_type=>SBIClient::FX::EXPIRATION_TYPE_TODAY,
      :settle => {
        :rate=>@rates[SBIClient::FX::EURJPY].ask_rate + 0.5,
        :stop_order_rate=>@rates[SBIClient::FX::EURJPY].ask_rate - 1
      }
    })
    orders = @s.list_orders
    @order = orders[@order_id.order_no]
    @order_id.should_not be_nil
    @order_id.order_no.should_not be_nil
    @order.should_not be_nil
    @order.order_no.should == @order_id.order_no
    @order.trade_type.should == SBIClient::FX::TRADE_TYPE_NEW
    @order.execution_expression.should == SBIClient::FX::EXECUTION_EXPRESSION_LIMIT_ORDER
    @order.sell_or_buy.should == SBIClient::FX::BUY
    @order.pair.should == SBIClient::FX::EURJPY
    @order.count.should == 1
    @order.rate.should == @rates[SBIClient::FX::EURJPY].ask_rate - 0.5
    @order.order_type= SBIClient::FX::ORDER_TYPE_IFD_OCO
  end

  it "逆指値" do
    @order_id = @s.order( SBIClient::FX::EURUSD, SBIClient::FX::BUY, 1, {
     :rate=>@rates[SBIClient::FX::EURUSD].ask_rate + 0.05,
     :execution_expression=>SBIClient::FX::EXECUTION_EXPRESSION_REVERSE_LIMIT_ORDER,
     :expiration_type=>SBIClient::FX::EXPIRATION_TYPE_TODAY,
     :settle => {
        :rate=>@rates[SBIClient::FX::EURUSD].ask_rate + 0.1,
        :stop_order_rate=>@rates[SBIClient::FX::EURUSD].ask_rate-0.05
      }
    })
    @order_id.should_not be_nil
    @order_id.order_no.should_not be_nil
    @order = @s.list_orders[@order_id.order_no]
    @order.should_not be_nil
    @order.order_no.should == @order_id.order_no
    @order.trade_type.should == SBIClient::FX::TRADE_TYPE_NEW
    @order.execution_expression.should == SBIClient::FX::EXECUTION_EXPRESSION_REVERSE_LIMIT_ORDER
    @order.sell_or_buy.should == SBIClient::FX::BUY
    @order.pair.should == SBIClient::FX::EURUSD
    @order.count.should == 1
    @order.rate.should.to_s == (@rates[SBIClient::FX::EURUSD].ask_rate + 0.05).to_s
    @order.order_type= SBIClient::FX::ORDER_TYPE_IFD_OCO
  end
end