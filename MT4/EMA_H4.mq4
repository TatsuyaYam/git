//+------------------------------------------------------------------+
//|                                                     SampleEA.mq4 |
//|                                                         yamakayu |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "yamakayu"
#property link      "https://www.mql5.com"
#property version   "1.01"
#property strict
#include <stderror.mqh>
#include <stdlib.mqh>
//+------------------------------------------------------------------+
//| Global Variable Declara Area                                     |
//+------------------------------------------------------------------+

//買い用変数
int iBuyTicketOrder   = 0;
bool isBuyTicketClose = False;
bool isBuyEntryFlg    = False;
double dBuyStoploss   = 0;
double dBuyProfit     = 0;

//売り用変数
int iSellTicketOrder   = 0;
bool isSellTicketClose = False;
bool isSellEntryFlg    = False;
double dSellStoploss   = 0;
double dSellProfit     = 0;

//共通変数
input double dProfit   = 0.400;  //利確ポイント
input double dStopLoss = 0.400;  //損切ポイント
input int iLongPeriod  = 21;     //長期のEMAの期間
input int iShortPeriod = 5;      //短期のEMAの期間
input double dLots     = 1.0;    //取引ロット数
input int iSlippage    = 10;     //許容スリッページ

string fileName = "/MQL4/Files/Line.txt";

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {      
   //double dClose = iClose(_Symbol,PERIOD_H4,1);
   double dIMA_L = iMA(_Symbol,PERIOD_H4,iLongPeriod,0,MODE_EMA,PRICE_CLOSE,1);
   double dIMA_S = iMA(_Symbol,PERIOD_H4,iShortPeriod,0,MODE_EMA,PRICE_CLOSE,1);
   double dTempStoploss = 0;
   
   
   //注文準備
   preEntry(dIMA_L, dIMA_S);
   
   //買い注文１（ゴールデンクロス）
   if(dIMA_S > dIMA_L && isBuyEntryFlg){
      openLongTrade();
   }
   
   //売り注文２（デッドクロス）
   if(dIMA_L > dIMA_S && isSellEntryFlg){
      openShortTrade();
   }
      
   //トレーリング
   trailingStop(dTempStoploss);
   
   //買い決済
   if(iBuyTicketOrder > 0 && (dBuyStoploss >= Bid || dBuyProfit <= Bid)){
      Print("closeLongTrade:Profit ",dBuyProfit);
      Print("closeLongTrade:StopLoss ",dBuyStoploss);
      closeLongTrade();
   }
   //売り決済
   if(iSellTicketOrder > 0 && (dSellStoploss <= Ask || dSellProfit >= Ask)){
      Print("closeShortTrade:Profit ",dSellProfit);
      Print("closeShortTrade:StopLoss ",dSellStoploss);
      closeShortTrade();
   }
  }
  
//--注文準備--//
  void preEntry(double dIMA_L, double dIMA_S)
  {
   //手動で決済したときの対応
   if(iBuyTicketOrder > 0){
      if(OrderSelect(iBuyTicketOrder,SELECT_BY_TICKET) == false){
         iBuyTicketOrder = 0;
      }
   }
   if(iSellTicketOrder > 0){
      if(OrderSelect(iSellTicketOrder,SELECT_BY_TICKET) == false){
         iSellTicketOrder = 0;
      }
   }
   //買いエントリー準備（EMAの短期が長期より下にあり、買いエントリーが無いこと）
   if(dIMA_S < dIMA_L && iBuyTicketOrder == 0){
      isBuyEntryFlg = True;
   }
   //売りエントリー準備（EMAの短期が長期より上にあり、売りエントリーが無いこと）
   if(dIMA_S > dIMA_L && iSellTicketOrder == 0){
      isSellEntryFlg = True;
   }   
  }
  
//--買い注文処理--//
  void openLongTrade()
  {
   iBuyTicketOrder = OrderSend(_Symbol,OP_BUY,dLots,Ask,iSlippage,0,0,"EMA判定買注文",0,0,clrRed);
   
   //注文処理に失敗したときはログを出力して終了
   if(iBuyTicketOrder == -1){
      logError("openLongTrade", "could not open order", iBuyTicketOrder);
      iBuyTicketOrder = 0;
      return;
   }   
   isBuyEntryFlg   = False;
   dBuyStoploss    = Bid - dStopLoss;
   dBuyProfit      = Bid + dProfit;
   Print("openLongTrade:Profit ",dBuyProfit);
   Print("openLongTrade:StopLoss ",dBuyStoploss);
   
   //ファイルに書き込む
   string msg1 = "Buy注文";
   string msg2 = "注文価格：" + DoubleToStr(Ask,3);
   string msg3 = "損切ポイント：" + DoubleToStr(dBuyStoploss,3);
   
   fileWrite(msg1, msg2, msg3);
  }
  
//--売り注文処理--//
  void openShortTrade()
  {
   iSellTicketOrder = OrderSend(_Symbol,OP_SELL,dLots,Bid,iSlippage,0,0,"EMA判定売注文",0,0,clrBlue);
   
   //注文処理に失敗したときはログを出力して終了
   if(iSellTicketOrder == -1){
      logError("openShortTrade", "could not open order", iSellTicketOrder);
      iSellTicketOrder = 0;
      return;
   }
   isSellEntryFlg   = False;
   dSellStoploss    = Ask + dStopLoss;
   dSellProfit       = Ask - dProfit;
   Print("openShortTrade:Profit ",dSellProfit);
   Print("openShortTrade:StopLoss ",dSellStoploss);
   
   //ファイルに書き込む
   string msg1 = "Sell注文";
   string msg2 = "注文価格：" + DoubleToStr(Bid,3);
   string msg3 = "損切ポイント：" + DoubleToStr(dSellStoploss,3);
   
   fileWrite(msg1, msg2, msg3);
  }
  
//--トレーリングストップ処理--//
  void trailingStop(double dTempStoploss)
  {
   //買いストップロスの更新（現在のストップロスを算出し、設定しているストップロスよりも高ければ更新する）
   if(iBuyTicketOrder > 0){
      dTempStoploss = Bid - dStopLoss;
      if(dTempStoploss > dBuyStoploss){
         dBuyStoploss = dTempStoploss;
      }
   }
   //売りストップロスの更新（現在のストップロスを算出し、設定しているストップロスよりも低ければ更新する）
   if(iSellTicketOrder > 0){
      dTempStoploss = Ask + dStopLoss;
      if(dTempStoploss < dSellStoploss){
         dSellStoploss = dTempStoploss;
      }
   }
  }
  
//--買い決済処理--//
  void closeLongTrade()
  {
   bool bSelect = OrderSelect(iBuyTicketOrder, SELECT_BY_TICKET);
   double dProfitLoss = OrderProfit();
   
   isBuyTicketClose = OrderClose(iBuyTicketOrder,dLots,Bid,iSlippage,clrRed);
   if(isBuyTicketClose){
      iBuyTicketOrder = 0;
      dBuyStoploss    = 0;
   }else{
      logError("closeLongTrade", "could not close order", -1);
      return;
   }
   
   //ファイルに書き込む
   string msg1 = "Buy決済";
   string msg2 = "決済価格：" + DoubleToStr(Bid,3);
   string msg3 = "損益：" + DoubleToStr(dProfitLoss,0);
   
   fileWrite(msg1, msg2, msg3);
  }
  
//--売り決済処理--//
  void closeShortTrade()
  {
   bool bSelect = OrderSelect(iSellTicketOrder, SELECT_BY_TICKET);
   double dProfitLoss = OrderProfit();
   
   isSellTicketClose = OrderClose(iSellTicketOrder,dLots,Ask,iSlippage,clrBlue);
   if(isSellTicketClose){
      iSellTicketOrder = 0;
      dSellStoploss    = 0;
   }else{
      logError("closeShortTrade", "could not close order", -1);
      return;
   }
   
   //ファイルに書き込む
   string msg1 = "Sell決済";
   string msg2 = "決済価格：" + DoubleToStr(Ask,3);
   string msg3 = "損益：" + DoubleToStr(dProfitLoss,0);
   
   fileWrite(msg1, msg2, msg3);
  }

//--ファイル書き込み処理--//
  void fileWrite(string msg1, string msg2, string msg3)
  {
   int fileHandle = FileOpen(fileName, FILE_WRITE | FILE_TXT);
   int random = MathRand();
   
   //ファイルに書き込む
   FileWrite(fileHandle, 
            "Number:" + (string)random +
            "\n" + msg1 +
            "\n" + msg2 +
            "\n" + msg3
            );
   FileClose(fileHandle);
  }  

//--エラー処理--//
  void logError(string functionName, string msg, int errorCode)
  {   
   Print("ERROR: in " + functionName + "()");
   Print("ERROR: " + msg );
   
   int err = GetLastError();
   if(errorCode != -1) 
       err = errorCode;
       
   if(err != ERR_NO_ERROR)
     {
       Print("ERROR: code=", err, " - ", ErrorDescription( err ));
     }    
  }
