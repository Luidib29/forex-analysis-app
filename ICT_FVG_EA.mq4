//+------------------------------------------------------------------+
//|                                                   ICT_FVG_EA.mq4 |
//|                                    ICT Strategy - FVG + OB + SMC |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "ICT Strategy EA"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Input Parameters                                                  |
//+------------------------------------------------------------------+
// === RISK MANAGEMENT ===
input double   RiskPercentage = 1.0;           // Risk per trade (% of balance)
input double   RiskRewardRatio = 2.0;          // Risk:Reward ratio (1:2 default)
input bool     UseTrailingStop = true;         // Enable trailing stop
input double   TrailingStopPips = 20;          // Trailing stop distance (pips)

// === STRATEGY SETTINGS ===
input int      FVG_MinPips = 5;                // Minimum FVG size (pips)
input int      OB_Lookback = 20;               // Order Block lookback bars
input int      MS_SwingBars = 10;              // Market Structure swing detection bars

// === KILLZONE TIMING ===
input bool     UseKillzoneFilter = true;       // Enable Killzone timing filter
input int      LondonOpen = 9;                 // London Killzone start (Server Time)
input int      LondonClose = 15;               // London Killzone end (Server Time)
input int      NewYorkOpen = 16;               // New York Killzone start (Server Time)
input int      NewYorkClose = 23;              // New York Killzone end (Server Time)

// === TRADE MANAGEMENT ===
input int      MagicNumber = 12345;            // EA Magic Number
input int      MaxTradesPerDay = 2;            // Maximum trades per day
input double   MinRiskReward = 1.5;            // Minimum RR to enter trade

// === TIMEFRAME ===
input ENUM_TIMEFRAMES Timeframe = PERIOD_H1;   // Trading Timeframe

//+------------------------------------------------------------------+
//| Global Variables                                                  |
//+------------------------------------------------------------------+
double Point_Value;
int    TradesCountToday = 0;
datetime LastTradeDate = 0;

// Structure for Fair Value Gap
struct FVG_Structure {
   bool exists;
   bool isBullish;
   double topPrice;
   double bottomPrice;
   int barIndex;
};

// Structure for Order Block
struct OB_Structure {
   bool exists;
   bool isBullish;
   double topPrice;
   double bottomPrice;
   int barIndex;
};

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
{
   // Calculate point value for 4/5 digit brokers
   Point_Value = Point;
   if(Digits == 3 || Digits == 5) Point_Value = Point * 10;

   Print("===================================");
   Print("ICT FVG EA Initialized Successfully");
   Print("Symbol: ", Symbol());
   Print("Timeframe: ", EnumToString(Timeframe));
   Print("Risk per trade: ", RiskPercentage, "%");
   Print("Risk:Reward: 1:", RiskRewardRatio);
   Print("===================================");

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("ICT FVG EA stopped. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
   // Reset daily trade count
   if(TimeDayOfYear(TimeCurrent()) != TimeDayOfYear(LastTradeDate))
   {
      TradesCountToday = 0;
      LastTradeDate = TimeCurrent();
   }

   // Check if max trades reached
   if(TradesCountToday >= MaxTradesPerDay) return;

   // Check killzone filter
   if(UseKillzoneFilter && !IsInKillzone()) return;

   // Check if we already have open positions
   if(CountOpenTrades() > 0)
   {
      ManageTrades(); // Manage existing trades
      return;
   }

   // Wait for new bar
   static datetime lastBarTime = 0;
   if(Time[0] == lastBarTime) return;
   lastBarTime = Time[0];

   // === MAIN TRADING LOGIC ===

   // 1. Analyze Market Structure
   int trendDirection = AnalyzeMarketStructure();

   // 2. Detect Fair Value Gaps
   FVG_Structure fvg = DetectFVG();

   // 3. Detect Order Blocks
   OB_Structure ob = DetectOrderBlock();

   // 4. Check for BUY setup
   if(trendDirection == 1 && fvg.exists && fvg.isBullish)
   {
      // Check if price is touching FVG or Order Block
      if(IsPriceTouchingFVG(fvg) || (ob.exists && ob.isBullish && IsPriceTouchingOB(ob)))
      {
         double sl = CalculateBuySL(fvg, ob);
         double tp = CalculateBuyTP(sl);
         double rr = CalculateRiskReward(Ask, sl, tp);

         if(rr >= MinRiskReward)
         {
            OpenBuyTrade(sl, tp);
         }
      }
   }

   // 5. Check for SELL setup
   if(trendDirection == -1 && fvg.exists && !fvg.isBullish)
   {
      // Check if price is touching FVG or Order Block
      if(IsPriceTouchingFVG(fvg) || (ob.exists && !ob.isBullish && IsPriceTouchingOB(ob)))
      {
         double sl = CalculateSellSL(fvg, ob);
         double tp = CalculateSellTP(sl);
         double rr = CalculateRiskReward(Bid, sl, tp);

         if(rr >= MinRiskReward)
         {
            OpenSellTrade(sl, tp);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Detect Fair Value Gap (FVG)                                       |
//+------------------------------------------------------------------+
FVG_Structure DetectFVG()
{
   FVG_Structure fvg;
   fvg.exists = false;

   // Check last 3 candles for FVG
   // Bullish FVG: High[3] < Low[1] (gap up)
   // Bearish FVG: Low[3] > High[1] (gap down)

   // Bullish FVG
   if(iHigh(Symbol(), Timeframe, 3) < iLow(Symbol(), Timeframe, 1))
   {
      double gapSize = (iLow(Symbol(), Timeframe, 1) - iHigh(Symbol(), Timeframe, 3)) / Point_Value;

      if(gapSize >= FVG_MinPips)
      {
         fvg.exists = true;
         fvg.isBullish = true;
         fvg.topPrice = iLow(Symbol(), Timeframe, 1);
         fvg.bottomPrice = iHigh(Symbol(), Timeframe, 3);
         fvg.barIndex = 2;

         // Draw FVG rectangle
         DrawFVGRectangle(fvg, "FVG_Bull_" + TimeToString(iTime(Symbol(), Timeframe, 2)));
      }
   }

   // Bearish FVG
   if(iLow(Symbol(), Timeframe, 3) > iHigh(Symbol(), Timeframe, 1))
   {
      double gapSize = (iLow(Symbol(), Timeframe, 3) - iHigh(Symbol(), Timeframe, 1)) / Point_Value;

      if(gapSize >= FVG_MinPips)
      {
         fvg.exists = true;
         fvg.isBullish = false;
         fvg.topPrice = iLow(Symbol(), Timeframe, 3);
         fvg.bottomPrice = iHigh(Symbol(), Timeframe, 1);
         fvg.barIndex = 2;

         // Draw FVG rectangle
         DrawFVGRectangle(fvg, "FVG_Bear_" + TimeToString(iTime(Symbol(), Timeframe, 2)));
      }
   }

   return fvg;
}

//+------------------------------------------------------------------+
//| Detect Order Block                                                |
//+------------------------------------------------------------------+
OB_Structure DetectOrderBlock()
{
   OB_Structure ob;
   ob.exists = false;

   // Look for the last bullish/bearish candle before a strong move
   // Bullish OB: Last bearish candle before strong bullish move
   // Bearish OB: Last bullish candle before strong bearish move

   double avgRange = 0;
   for(int i = 1; i <= 20; i++)
   {
      avgRange += iHigh(Symbol(), Timeframe, i) - iLow(Symbol(), Timeframe, i);
   }
   avgRange = avgRange / 20;

   // Search for bullish order block
   for(int i = 1; i <= OB_Lookback; i++)
   {
      double candleBody = MathAbs(iClose(Symbol(), Timeframe, i) - iOpen(Symbol(), Timeframe, i));
      double nextMove = iClose(Symbol(), Timeframe, i-1) - iOpen(Symbol(), Timeframe, i-1);

      // Bearish candle followed by strong bullish move
      if(iClose(Symbol(), Timeframe, i) < iOpen(Symbol(), Timeframe, i) &&
         nextMove > avgRange * 1.5)
      {
         ob.exists = true;
         ob.isBullish = true;
         ob.topPrice = iOpen(Symbol(), Timeframe, i);
         ob.bottomPrice = iClose(Symbol(), Timeframe, i);
         ob.barIndex = i;
         break;
      }
   }

   // Search for bearish order block
   for(int i = 1; i <= OB_Lookback; i++)
   {
      double candleBody = MathAbs(iClose(Symbol(), Timeframe, i) - iOpen(Symbol(), Timeframe, i));
      double nextMove = iOpen(Symbol(), Timeframe, i-1) - iClose(Symbol(), Timeframe, i-1);

      // Bullish candle followed by strong bearish move
      if(iClose(Symbol(), Timeframe, i) > iOpen(Symbol(), Timeframe, i) &&
         nextMove > avgRange * 1.5)
      {
         ob.exists = true;
         ob.isBullish = false;
         ob.topPrice = iClose(Symbol(), Timeframe, i);
         ob.bottomPrice = iOpen(Symbol(), Timeframe, i);
         ob.barIndex = i;
         break;
      }
   }

   return ob;
}

//+------------------------------------------------------------------+
//| Analyze Market Structure                                          |
//+------------------------------------------------------------------+
int AnalyzeMarketStructure()
{
   // Find swing highs and lows
   // Returns: 1 = Uptrend (HH/HL), -1 = Downtrend (LH/LL), 0 = Ranging

   double swingHighs[3];
   double swingLows[3];
   int highCount = 0;
   int lowCount = 0;

   // Initialize arrays
   ArrayInitialize(swingHighs, 0);
   ArrayInitialize(swingLows, 0);

   // Find last 3 swing highs and lows
   for(int i = MS_SwingBars; i < 100 && (highCount < 3 || lowCount < 3); i++)
   {
      bool isSwingHigh = true;
      bool isSwingLow = true;

      // Check if current bar is swing high
      for(int j = 1; j <= MS_SwingBars; j++)
      {
         if(iHigh(Symbol(), Timeframe, i) <= iHigh(Symbol(), Timeframe, i-j) ||
            iHigh(Symbol(), Timeframe, i) <= iHigh(Symbol(), Timeframe, i+j))
         {
            isSwingHigh = false;
            break;
         }
      }

      // Check if current bar is swing low
      for(int j = 1; j <= MS_SwingBars; j++)
      {
         if(iLow(Symbol(), Timeframe, i) >= iLow(Symbol(), Timeframe, i-j) ||
            iLow(Symbol(), Timeframe, i) >= iLow(Symbol(), Timeframe, i+j))
         {
            isSwingLow = false;
            break;
         }
      }

      if(isSwingHigh && highCount < 3)
      {
         swingHighs[highCount] = iHigh(Symbol(), Timeframe, i);
         highCount++;
      }

      if(isSwingLow && lowCount < 3)
      {
         swingLows[lowCount] = iLow(Symbol(), Timeframe, i);
         lowCount++;
      }
   }

   // Analyze structure
   if(highCount >= 2 && lowCount >= 2)
   {
      // Check for Higher Highs and Higher Lows (Uptrend)
      if(swingHighs[0] > swingHighs[1] && swingLows[0] > swingLows[1])
         return 1;

      // Check for Lower Highs and Lower Lows (Downtrend)
      if(swingHighs[0] < swingHighs[1] && swingLows[0] < swingLows[1])
         return -1;
   }

   return 0; // Ranging
}

//+------------------------------------------------------------------+
//| Check if in Killzone                                              |
//+------------------------------------------------------------------+
bool IsInKillzone()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   int currentHour = dt.hour;

   // London Killzone
   if(currentHour >= LondonOpen && currentHour < LondonClose)
      return true;

   // New York Killzone
   if(currentHour >= NewYorkOpen && currentHour < NewYorkClose)
      return true;

   return false;
}

//+------------------------------------------------------------------+
//| Check if price is touching FVG                                     |
//+------------------------------------------------------------------+
bool IsPriceTouchingFVG(FVG_Structure &fvg)
{
   double currentPrice = (Ask + Bid) / 2;

   if(currentPrice >= fvg.bottomPrice && currentPrice <= fvg.topPrice)
      return true;

   // Also check if recent candles touched it
   if(iLow(Symbol(), Timeframe, 0) <= fvg.topPrice &&
      iHigh(Symbol(), Timeframe, 0) >= fvg.bottomPrice)
      return true;

   return false;
}

//+------------------------------------------------------------------+
//| Check if price is touching Order Block                            |
//+------------------------------------------------------------------+
bool IsPriceTouchingOB(OB_Structure &ob)
{
   double currentPrice = (Ask + Bid) / 2;

   if(currentPrice >= ob.bottomPrice && currentPrice <= ob.topPrice)
      return true;

   // Also check if recent candles touched it
   if(iLow(Symbol(), Timeframe, 0) <= ob.topPrice &&
      iHigh(Symbol(), Timeframe, 0) >= ob.bottomPrice)
      return true;

   return false;
}

//+------------------------------------------------------------------+
//| Calculate Buy Stop Loss                                           |
//+------------------------------------------------------------------+
double CalculateBuySL(FVG_Structure &fvg, OB_Structure &ob)
{
   double sl = 0;

   // Use Order Block bottom if available
   if(ob.exists && ob.isBullish)
   {
      sl = ob.bottomPrice - (10 * Point_Value); // 10 pips buffer
   }
   else
   {
      // Use FVG bottom
      sl = fvg.bottomPrice - (10 * Point_Value);
   }

   return NormalizeDouble(sl, Digits);
}

//+------------------------------------------------------------------+
//| Calculate Sell Stop Loss                                          |
//+------------------------------------------------------------------+
double CalculateSellSL(FVG_Structure &fvg, OB_Structure &ob)
{
   double sl = 0;

   // Use Order Block top if available
   if(ob.exists && !ob.isBullish)
   {
      sl = ob.topPrice + (10 * Point_Value); // 10 pips buffer
   }
   else
   {
      // Use FVG top
      sl = fvg.topPrice + (10 * Point_Value);
   }

   return NormalizeDouble(sl, Digits);
}

//+------------------------------------------------------------------+
//| Calculate Buy Take Profit                                         |
//+------------------------------------------------------------------+
double CalculateBuyTP(double sl)
{
   double slDistance = Ask - sl;
   double tp = Ask + (slDistance * RiskRewardRatio);

   return NormalizeDouble(tp, Digits);
}

//+------------------------------------------------------------------+
//| Calculate Sell Take Profit                                        |
//+------------------------------------------------------------------+
double CalculateSellTP(double sl)
{
   double slDistance = sl - Bid;
   double tp = Bid - (slDistance * RiskRewardRatio);

   return NormalizeDouble(tp, Digits);
}

//+------------------------------------------------------------------+
//| Calculate Risk:Reward ratio                                       |
//+------------------------------------------------------------------+
double CalculateRiskReward(double entry, double sl, double tp)
{
   double risk = MathAbs(entry - sl);
   double reward = MathAbs(tp - entry);

   if(risk == 0) return 0;

   return reward / risk;
}

//+------------------------------------------------------------------+
//| Calculate Position Size based on Risk %                           |
//+------------------------------------------------------------------+
double CalculateLotSize(double sl)
{
   double balance = AccountBalance();
   double riskAmount = balance * (RiskPercentage / 100.0);

   double slPips = MathAbs(Ask - sl) / Point_Value;
   double tickValue = MarketInfo(Symbol(), MODE_TICKVALUE);

   if(Digits == 3 || Digits == 5)
      tickValue = tickValue / 10;

   double lotSize = riskAmount / (slPips * tickValue);

   // Normalize lot size
   double minLot = MarketInfo(Symbol(), MODE_MINLOT);
   double maxLot = MarketInfo(Symbol(), MODE_MAXLOT);
   double lotStep = MarketInfo(Symbol(), MODE_LOTSTEP);

   lotSize = MathFloor(lotSize / lotStep) * lotStep;

   if(lotSize < minLot) lotSize = minLot;
   if(lotSize > maxLot) lotSize = maxLot;

   return NormalizeDouble(lotSize, 2);
}

//+------------------------------------------------------------------+
//| Open Buy Trade                                                     |
//+------------------------------------------------------------------+
void OpenBuyTrade(double sl, double tp)
{
   double lots = CalculateLotSize(sl);

   int ticket = OrderSend(Symbol(), OP_BUY, lots, Ask, 3, sl, tp,
                          "ICT FVG EA - BUY", MagicNumber, 0, clrGreen);

   if(ticket > 0)
   {
      TradesCountToday++;
      Print("BUY order opened: Ticket #", ticket, " | Lots: ", lots,
            " | SL: ", sl, " | TP: ", tp);
   }
   else
   {
      Print("Error opening BUY order: ", GetLastError());
   }
}

//+------------------------------------------------------------------+
//| Open Sell Trade                                                    |
//+------------------------------------------------------------------+
void OpenSellTrade(double sl, double tp)
{
   double lots = CalculateLotSize(sl);

   int ticket = OrderSend(Symbol(), OP_SELL, lots, Bid, 3, sl, tp,
                          "ICT FVG EA - SELL", MagicNumber, 0, clrRed);

   if(ticket > 0)
   {
      TradesCountToday++;
      Print("SELL order opened: Ticket #", ticket, " | Lots: ", lots,
            " | SL: ", sl, " | TP: ", tp);
   }
   else
   {
      Print("Error opening SELL order: ", GetLastError());
   }
}

//+------------------------------------------------------------------+
//| Count Open Trades                                                 |
//+------------------------------------------------------------------+
int CountOpenTrades()
{
   int count = 0;

   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
            count++;
      }
   }

   return count;
}

//+------------------------------------------------------------------+
//| Manage Open Trades (Trailing Stop)                                |
//+------------------------------------------------------------------+
void ManageTrades()
{
   if(!UseTrailingStop) return;

   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
         {
            double trailDistance = TrailingStopPips * Point_Value;

            if(OrderType() == OP_BUY)
            {
               double newSL = Bid - trailDistance;

               if(newSL > OrderStopLoss() && newSL < Bid)
               {
                  bool result = OrderModify(OrderTicket(), OrderOpenPrice(),
                                           NormalizeDouble(newSL, Digits),
                                           OrderTakeProfit(), 0, clrBlue);

                  if(result)
                     Print("Trailing Stop updated for BUY #", OrderTicket(), " | New SL: ", newSL);
               }
            }

            if(OrderType() == OP_SELL)
            {
               double newSL = Ask + trailDistance;

               if(newSL < OrderStopLoss() && newSL > Ask)
               {
                  bool result = OrderModify(OrderTicket(), OrderOpenPrice(),
                                           NormalizeDouble(newSL, Digits),
                                           OrderTakeProfit(), 0, clrBlue);

                  if(result)
                     Print("Trailing Stop updated for SELL #", OrderTicket(), " | New SL: ", newSL);
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Draw FVG Rectangle on Chart                                       |
//+------------------------------------------------------------------+
void DrawFVGRectangle(FVG_Structure &fvg, string name)
{
   color rectangleColor = fvg.isBullish ? clrGreen : clrRed;

   datetime time1 = iTime(Symbol(), Timeframe, fvg.barIndex);
   datetime time2 = iTime(Symbol(), Timeframe, 0) + PeriodSeconds(Timeframe) * 10;

   ObjectCreate(0, name, OBJ_RECTANGLE, 0, time1, fvg.topPrice, time2, fvg.bottomPrice);
   ObjectSetInteger(0, name, OBJPROP_COLOR, rectangleColor);
   ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DOT);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
   ObjectSetInteger(0, name, OBJPROP_FILL, true);
}

//+------------------------------------------------------------------+
