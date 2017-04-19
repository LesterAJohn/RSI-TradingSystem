//+------------------------------------------------------------------+
//|                                                rsi-automated.mq4 |
//|                                      Copyright 2017, Lester John |
//|                  https://www.mql5.com/en/users/soubra2003/seller |
//+------------------------------------------------------------------+


#property copyright "Copyright 2017, Lester John"
#property link      "https://www.mql5.com/en/users/soubra2003/seller"
#property version   "1.00"
#property strict

#include <stdlib.mqh>


input int      BB_period   =  20;
input double   BB_dev      =  2;

double   BB_UPPER, BB_SMA, BB_LOWER, RSI_Value, MACD_Main, MACD_Signal, MACD_Main_Prev, MACD_Signal_Prev, MOM_Now, MOM_Prev, StopPrice;
int      limitticket, buysignal;
bool     MOM_Dir;

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   HideTestIndicators(true);
   //This function sets a flag hiding indicators called by the Expert Advisor
   
   BB_UPPER   = iBands(NULL ,PERIOD_M5 ,BB_period ,BB_dev ,0 ,PRICE_CLOSE ,MODE_UPPER ,0);
   BB_SMA     = iBands(NULL ,PERIOD_M5 ,BB_period ,BB_dev ,0 ,PRICE_CLOSE ,MODE_SMA   ,0);
   BB_LOWER   = iBands(NULL ,PERIOD_M5 ,BB_period ,BB_dev ,0 ,PRICE_CLOSE ,MODE_LOWER ,0);
   
   MACD_Main    = iMACD(NULL,0,12,26,9,PRICE_CLOSE,MODE_MAIN,0);
   MACD_Signal  = iMACD(NULL,0,12,26,9,PRICE_CLOSE,MODE_SIGNAL,0);
   MACD_Main_Prev    = iMACD(NULL,0,12,26,9,PRICE_CLOSE,MODE_MAIN,3);
   MACD_Signal_Prev  = iMACD(NULL,0,12,26,9,PRICE_CLOSE,MODE_SIGNAL,3);
   
   RSI_Value     = iRSI(NULL, PERIOD_M5, BB_period,PRICE_CLOSE, 0);
   
   MOM_Now     =  iMomentum(NULL,0,12,PRICE_CLOSE,0);
   MOM_Prev    =  iMomentum(NULL,0,12,PRICE_CLOSE,3);

//   if(OrdersTotal() > 0 && iVolume(NULL,PERIOD_M5,1)==3){
//      buysignal = 1;
//      TrailingStop();
//      }
//   else buysignal = 0;

   if(MOM_Now > MOM_Prev) MOM_Dir=true;
   if(MOM_Now < MOM_Prev) MOM_Dir=false;

   if(iVolume(NULL,PERIOD_M5,0)==1){
   
   if(iClose(NULL,PERIOD_M5,0) > iClose(NULL,PERIOD_M5,6) && RSI_Value>=60 && MOM_Dir==true) BuyLimitExecute();
   if(iClose(NULL,PERIOD_M5,0) < iClose(NULL,PERIOD_M5,6) && RSI_Value<=40 && MOM_Dir==false) SellLimitExecute();
   
   if (MACD_Signal > MACD_Main && MACD_Signal_Prev < MACD_Main_Prev && MOM_Dir==true) {BuyLimitExecute();Print("CrossOver");}
   if (MACD_Signal < MACD_Main && MACD_Signal_Prev > MACD_Main_Prev && MOM_Dir==false) {SellLimitExecute();Print("CrossUnder");}
   }
}


//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
//---
   Comment("");
}


//+------------------------------------------------------------------+
//| Expert BuyLimitExecute function
//+------------------------------------------------------------------+
void BuyLimitExecute()
{

   double LotSize;

   if(AccountBalance()> 10000){
      LotSize=(AccountBalance()*.2)/10000;
         }
      else{
         LotSize=AccountBalance()/10000;
         }

   limitticket=  OrderSend(OrderSymbol(),            //Pair
                  /*DOWN*/  OP_BUYLIMIT,              //Command Type
                            LotSize,                     //Lot Size
                            Ask-((Ask-Bid)/2),                 //Needed Price
                            3,                        //Max. Slippage
                            0,            //Stop Loss
                            (Ask-((Ask-Bid)/2))+(iATR(NULL, PERIOD_M5, BB_period, 0)*1),            //Take Profit
                            "RSI Automated",          //Comment
                            1221,                     //Magic No.
                            0,                        //Expiration (Only Pending Orders)
                            clrNONE);                 //Arrow Color
               
   if(limitticket>0){
      Print("Buy-Limit order successfully placed.");
      StopPrice = Bid-(iATR(NULL, PERIOD_M5, BB_period, 0)*2);
      }
   else
      Print("Error in placing buy-limit order: ", ErrorDescription(GetLastError()));
// Bid-(iATR(NULL, PERIOD_M5, BB_period, 0)*2) //Loss
// Ask+(iATR(NULL, PERIOD_M5, BB_period, 0)*0) //Profit
}


//+------------------------------------------------------------------+
//| Expert SellLimitExecute function
//+------------------------------------------------------------------+
void SellLimitExecute()
{
   
   double LotSize;
   
   if(AccountBalance()> 10000){
      LotSize=(AccountBalance()*.2)/10000;
         }
      else{
         LotSize=AccountBalance()/10000;
         }
   
   limitticket = OrderSend(OrderSymbol(),           //Pair
                     /*UP*/  OP_SELLLIMIT,            //Command Type
                             LotSize,                    //Lot Size
                             Bid+((Ask-Bid)/2),                //Needed Price
                             3,                       //Max. Slippage
                             0,          //Stop Loss
                             
                             (Bid+((Ask-Bid)/2))-(iATR(NULL, PERIOD_M5, BB_period, 0)*1),          //Take Profit
                             "RSI Automated",         //Comment
                             1221,                    //Magic No.
                             0,                       //Expiration (Only Pending Orders)
                             clrNONE);                //Arrow Color

   if(limitticket>0){
      Print("Sell-Limit order successfully placed.");
      StopPrice = Ask+(iATR(NULL, PERIOD_M5, BB_period, 0)*2);
      }
   else
      Print("Error in placing sell-limit order: ", ErrorDescription(GetLastError()));
// Ask+(iATR(NULL, PERIOD_M5, BB_period, 0)*2) //Loss
// Bid-(iATR(NULL, PERIOD_M5, BB_period, 0)*0) //Profit
}


//+------------------------------------------------------------------+
//| CLOSE ALL OPENED BUY
//+------------------------------------------------------------------+
void CloseAllBuy()
{
   int total = OrdersTotal();
   for(int i=total-1; i>=0; i--)
   {
      int  ticket = OrderSelect(i,SELECT_BY_POS);
      int  type   = OrderType();
      bool result = false;

      if( OrderMagicNumber() == 1221 )
      {
         switch(type)
         {
            //Close opened long positions
            case OP_BUY  : result = OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_BID),6,clrNONE);
         }
   
         if(!result)
         {
            Alert("Order ",OrderTicket()," failed to close. Error: ",ErrorDescription(GetLastError()));
            Sleep(750);
         }
      }
   }
}


//+------------------------------------------------------------------+
//| CLOSE ALL OPENED SELL
//+------------------------------------------------------------------+
void CloseAllSell()
{
   int total = OrdersTotal();
   for(int i=total-1; i>=0; i--)
   {
      int  ticket = OrderSelect(i,SELECT_BY_POS);
      int  type   = OrderType();
      bool result = false;

      if( OrderMagicNumber() == 1221 )
      {
         switch(type)
         {
            //Close opened short positions
            case OP_SELL : result = OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_ASK),6,clrNONE);
         }
   
         if(!result)
         {
            Alert("Order ",OrderTicket()," failed to close. Error: ",ErrorDescription(GetLastError()));
            Sleep(750);
         }
      }
   }
}


//+------------------------------------------------------------------+
//| CLOSE ALL PENDING POSITIONS
//+------------------------------------------------------------------+
void CloseAllPending()
{
   int total = OrdersTotal();
   for(int i=total-1; i>=0; i--)
   {
      int  ticket = OrderSelect(i,SELECT_BY_POS);
      int  type   = OrderType();
      bool result = false;

      switch(type)
      {
         case OP_BUYLIMIT  : result = OrderDelete(OrderTicket(),clrNONE);  break;
         case OP_SELLLIMIT : result = OrderDelete(OrderTicket(),clrNONE);
      }

      if(result==false)
      {
         Comment("Order ",OrderTicket()," failed to close. Error: ",ErrorDescription(GetLastError()));
         Sleep(750);
      }
   }
}


//+------------------------------------------------------------------+
//| TRAILLING BUY STOP
//+------------------------------------------------------------------+
void TrailingStop()
{
   OrderSelect(limitticket,SELECT_BY_TICKET);
   int TrailingStop = 50;
   int Ticket = OrderTicket();
   int Type   = OrderType();
   
//--- modifies Stop Loss price for buy/sell order

   if(Ticket>0 && Type==2 && Bid-OrderOpenPrice()>Point*TrailingStop && StopPrice<Bid-Point*TrailingStop)StopPrice = Bid-Point*TrailingStop; 
   if(Ticket>0 && Type==3 && OrderOpenPrice()-Ask>Point*TrailingStop && StopPrice>Ask+Point*TrailingStop)StopPrice = Ask+Point*TrailingStop;
   
   if(Ticket>0 && Type==2 && Bid-OrderOpenPrice()>Point*TrailingStop && OrderStopLoss()<Bid-Point*TrailingStop && OrderProfit()>0)
           {
            bool res=OrderModify(OrderTicket(),OrderOpenPrice(),Bid-Point*TrailingStop,OrderTakeProfit(),OrderExpiration(),Blue);
            if(!res)
               Print("Error in OrderModify. Error code=",GetLastError(),":b:",Bid-Point*TrailingStop);
            else
               Print("Order modified successfully.");
           }

   if(Ticket>0 && Type==3 && OrderOpenPrice()-Ask>Point*TrailingStop && OrderStopLoss()>Ask+Point*TrailingStop && OrderProfit()>0)
           {
            bool res=OrderModify(OrderTicket(),OrderOpenPrice(),Ask+Point*TrailingStop,OrderTakeProfit(),OrderExpiration(),Blue);
            if(!res)
               Print("Error in OrderModify. Error code=",GetLastError(),":s:",Ask+Point*TrailingStop);
            else
               Print("Order modified successfully.");
           }
  
} 


//+------------------------------------------------------------------+
