//+------------------------------------------------------------------+
//|                                         ICT_SilverBullet_EA.mq4  |
//|                        ICT Silver Bullet Strategy for MT4        |
//|                         Ottimizzato per XAUUSD e XAGUSD          |
//|                            RoboForex Conto Cent - GMT+1          |
//+------------------------------------------------------------------+
#property copyright "ICT Silver Bullet EA"
#property link      ""
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//|                         ENUMERAZIONI                              |
//+------------------------------------------------------------------+
enum ENUM_BIAS_TYPE
{
   BIAS_NONE = 0,      // Nessun bias
   BIAS_BULLISH = 1,   // Bias rialzista
   BIAS_BEARISH = -1   // Bias ribassista
};

enum ENUM_FVG_TYPE
{
   FVG_NONE = 0,       // Nessun FVG
   FVG_BULLISH = 1,    // FVG rialzista
   FVG_BEARISH = -1    // FVG ribassista
};

enum ENUM_SESSION_TYPE
{
   SESSION_NONE = 0,
   SESSION_ASIAN = 1,
   SESSION_LONDON = 2,
   SESSION_NY_AM = 3,
   SESSION_NY_PM = 4
};

//+------------------------------------------------------------------+
//|                      INPUT PARAMETERS                             |
//+------------------------------------------------------------------+

//--- General Settings
input string   GeneralSettings = "═══════ GENERAL SETTINGS ═══════";
input int      MagicNumber = 123456;           // Magic Number
input int      GMT_Offset = 1;                 // GMT Offset Server (RoboForex = +1)
input string   TradeComment = "ICT_SilverBullet"; // Commento Trade

//--- Symbol Settings
input string   SymbolSettings = "═══════ SYMBOL SETTINGS ═══════";
input double   LotSize_XAU = 0.60;             // Lot Size XAUUSD
input double   LotSize_XAG = 0.40;             // Lot Size XAGUSD

//--- Risk Management
input string   RiskSettings = "═══════ RISK MANAGEMENT ═══════";
input double   RiskPercent = 2.0;              // Risk % per Trade
input bool     UseFixedLot = true;             // Usa Lot Fisso (true) o Risk% (false)
input double   RR_Min = 2.0;                   // Risk:Reward Minimo
input double   RR_Max = 2.5;                   // Risk:Reward Massimo

//--- Session Settings (GMT+1)
input string   SessionSettings = "═══════ SESSION SETTINGS (GMT+1) ═══════";
input bool     UseAsianSession = true;         // Sessione Asian (02:00-06:00)
input int      AsianStartHour = 2;             // Asian Start Hour
input int      AsianEndHour = 6;               // Asian End Hour
input bool     UseLondonSession = true;        // Sessione London (09:00-15:00)
input int      LondonStartHour = 9;            // London Start Hour
input int      LondonEndHour = 15;             // London End Hour
input bool     UseNYAMSession = true;          // Sessione NY AM (14:00-17:00)
input int      NYAMStartHour = 14;             // NY AM Start Hour
input int      NYAMEndHour = 17;               // NY AM End Hour
input bool     UseNYPMSession = true;          // Sessione NY PM (19:00-22:00)
input int      NYPMStartHour = 19;             // NY PM Start Hour
input int      NYPMEndHour = 22;               // NY PM End Hour

//--- Displacement Settings (ATR Multiplier)
input string   DisplacementSettings = "═══════ DISPLACEMENT SETTINGS ═══════";
input double   Displacement_ATR_XAU = 2.0;     // Displacement ATR Multiplier XAU
input double   Displacement_ATR_XAG = 1.5;     // Displacement ATR Multiplier XAG
input int      ATR_Period = 14;                // ATR Period

//--- SL/TP Dynamic Settings
input string   SLTPSettings = "═══════ SL/TP DYNAMIC SETTINGS ═══════";
input double   SL_ATR_Multi_XAU = 1.5;         // SL ATR Multiplier XAU
input double   SL_ATR_Multi_XAG = 1.2;         // SL ATR Multiplier XAG
input int      MinSL_Points_XAU = 500;         // Min SL Points XAU (50 pips)
input int      MinSL_Points_XAG = 100;         // Min SL Points XAG (10 pips)
input int      MaxSL_Points_XAU = 3000;        // Max SL Points XAU (300 pips)
input int      MaxSL_Points_XAG = 500;         // Max SL Points XAG (50 pips)

//--- News Filter
input string   NewsSettings = "═══════ NEWS FILTER ═══════";
input bool     UseNewsFilter = true;           // Usa Filtro Notizie
input int      NewsMinutesBefore = 30;         // Minuti Prima Notizia
input int      NewsMinutesAfter = 30;          // Minuti Dopo Notizia
input bool     FilterHighImpact = true;        // Filtra High Impact
input bool     FilterMediumImpact = false;     // Filtra Medium Impact

//--- Trade Management
input string   TradeManagement = "═══════ TRADE MANAGEMENT ═══════";
input int      MaxTradesPerSession = 4;        // Max Trades per Sessione
input int      MaxTradesPerDay = 10;           // Max Trades per Giorno
input int      MaxSpread_XAU = 50;             // Max Spread XAU (points)
input int      MaxSpread_XAG = 30;             // Max Spread XAG (points)
input bool     TradeOnlyNewBar = true;         // Trade Solo su Nuova Candela

//--- FVG Settings
input string   FVGSettings = "═══════ FVG SETTINGS ═══════";
input int      FVG_MinSize_XAU = 100;          // FVG Min Size XAU (points)
input int      FVG_MinSize_XAG = 20;           // FVG Min Size XAG (points)
input int      FVG_MaxAge = 20;                // FVG Max Age (candele M5)
input double   FVG_RetestBuffer = 0.1;         // FVG Retest Buffer (% of FVG)

//--- Rejection Candle Settings
input string   RejectionSettings = "═══════ REJECTION CANDLE ═══════";
input double   RejectionWickRatio = 0.5;       // Wick/Body Ratio Minimo
input double   RejectionMinBody = 0.3;         // Body Minimo (% della candela)

//+------------------------------------------------------------------+
//|                      GLOBAL VARIABLES                             |
//+------------------------------------------------------------------+
datetime lastBarTime_M5 = 0;
datetime lastBarTime_M15 = 0;
int tradesThisSession = 0;
int tradesThisDay = 0;
datetime lastTradeDay = 0;
ENUM_SESSION_TYPE currentSession = SESSION_NONE;
ENUM_SESSION_TYPE lastSessionTraded = SESSION_NONE;

// FVG Storage
struct FVG_Data
{
   bool     isValid;
   int      type;          // 1 = bullish, -1 = bearish
   double   highPrice;
   double   lowPrice;
   datetime createTime;
   int      barIndex;
   bool     isMitigated;
   bool     hasRejection;
};

FVG_Data activeFVG;
bool waitingForEntry = false;
bool rejectionDetected = false;
datetime rejectionBarTime = 0;

//+------------------------------------------------------------------+
//|                    INITIALIZATION                                 |
//+------------------------------------------------------------------+
int OnInit()
{
   // Verifica simbolo
   string currentSymbol = Symbol();
   if(StringFind(currentSymbol, "XAU") < 0 && StringFind(currentSymbol, "XAG") < 0)
   {
      Print("ERRORE: EA ottimizzato per XAUUSD o XAGUSD. Simbolo corrente: ", currentSymbol);
      return(INIT_FAILED);
   }

   // Reset variabili
   ResetFVG();
   tradesThisSession = 0;
   tradesThisDay = 0;
   lastTradeDay = 0;

   // Info inizializzazione
   Print("═══════════════════════════════════════════════════");
   Print("ICT Silver Bullet EA Inizializzato");
   Print("Simbolo: ", currentSymbol);
   Print("Lot Size: ", GetLotSize());
   Print("GMT Offset: ", GMT_Offset);
   Print("Risk: ", RiskPercent, "%");
   Print("R:R Range: 1:", RR_Min, " - 1:", RR_Max);
   Print("═══════════════════════════════════════════════════");

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                      DEINIT                                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Print("ICT Silver Bullet EA Rimosso. Motivo: ", reason);
}

//+------------------------------------------------------------------+
//|                      MAIN TICK                                    |
//+------------------------------------------------------------------+
void OnTick()
{
   // Verifica connessione
   if(!IsConnected() || IsStopped()) return;

   // Reset contatore giornaliero
   CheckDayReset();

   // Verifica sessione attiva
   ENUM_SESSION_TYPE session = GetCurrentSession();
   if(session == SESSION_NONE)
   {
      // Fuori sessione - reset se cambio sessione
      if(currentSession != SESSION_NONE)
      {
         tradesThisSession = 0;
         ResetFVG();
      }
      currentSession = SESSION_NONE;
      return;
   }

   // Cambio sessione
   if(session != currentSession)
   {
      currentSession = session;
      tradesThisSession = 0;
      ResetFVG();
      Print("Nuova sessione attiva: ", GetSessionName(session));
   }

   // Verifica limiti trade
   if(tradesThisSession >= MaxTradesPerSession)
   {
      return;
   }
   if(tradesThisDay >= MaxTradesPerDay)
   {
      return;
   }

   // Verifica spread
   if(!CheckSpread())
   {
      return;
   }

   // Filtro notizie
   if(UseNewsFilter && IsNewsTime())
   {
      return;
   }

   // Nuova candela M5
   bool newBar_M5 = IsNewBar(PERIOD_M5);
   bool newBar_M15 = IsNewBar(PERIOD_M15);

   // Aggiorna bias su M15
   if(newBar_M15)
   {
      // Bias aggiornato automaticamente quando necessario
   }

   // Logica principale su M5
   if(newBar_M5 || !TradeOnlyNewBar)
   {
      ProcessTradingLogic();
   }
}

//+------------------------------------------------------------------+
//|               PROCESS TRADING LOGIC                               |
//+------------------------------------------------------------------+
void ProcessTradingLogic()
{
   // STEP 1: Ottieni bias M15
   ENUM_BIAS_TYPE bias = GetBias_M15();
   if(bias == BIAS_NONE) return;

   // STEP 2: Cerca displacement e FVG se non ne abbiamo uno attivo
   if(!activeFVG.isValid)
   {
      SearchForFVG(bias);
   }

   // Se abbiamo un FVG valido
   if(activeFVG.isValid)
   {
      // Verifica età FVG
      int fvgAge = iBarShift(Symbol(), PERIOD_M5, activeFVG.createTime);
      if(fvgAge > FVG_MaxAge)
      {
         Print("FVG troppo vecchio (", fvgAge, " candele). Reset.");
         ResetFVG();
         return;
      }

      // STEP 3: Verifica retest FVG
      if(!activeFVG.isMitigated)
      {
         CheckFVGRetest();
      }

      // STEP 4: Cerca rejection candle
      if(activeFVG.isMitigated && !activeFVG.hasRejection)
      {
         CheckRejectionCandle(bias);
      }

      // STEP 5: Entry su chiusura candela di conferma
      if(activeFVG.hasRejection && rejectionDetected)
      {
         CheckEntryConfirmation(bias);
      }
   }
}

//+------------------------------------------------------------------+
//|                    GET BIAS M15                                   |
//+------------------------------------------------------------------+
ENUM_BIAS_TYPE GetBias_M15()
{
   // Struttura di mercato su M15: HH/HL = bullish, LH/LL = bearish
   double high1 = iHigh(Symbol(), PERIOD_M15, 1);
   double high2 = iHigh(Symbol(), PERIOD_M15, 2);
   double high3 = iHigh(Symbol(), PERIOD_M15, 3);
   double low1 = iLow(Symbol(), PERIOD_M15, 1);
   double low2 = iLow(Symbol(), PERIOD_M15, 2);
   double low3 = iLow(Symbol(), PERIOD_M15, 3);

   // Verifica struttura rialzista (Higher High + Higher Low)
   bool higherHigh = high1 > high2 && high2 > high3;
   bool higherLow = low1 > low2 && low2 > low3;

   // Verifica struttura ribassista (Lower High + Lower Low)
   bool lowerHigh = high1 < high2 && high2 < high3;
   bool lowerLow = low1 < low2 && low2 < low3;

   // Determina bias
   if(higherHigh && higherLow)
   {
      return BIAS_BULLISH;
   }
   else if(lowerHigh && lowerLow)
   {
      return BIAS_BEARISH;
   }

   // Bias alternativo con EMA
   double ema20 = iMA(Symbol(), PERIOD_M15, 20, 0, MODE_EMA, PRICE_CLOSE, 1);
   double close1 = iClose(Symbol(), PERIOD_M15, 1);

   if(close1 > ema20 && high1 > high2)
   {
      return BIAS_BULLISH;
   }
   else if(close1 < ema20 && low1 < low2)
   {
      return BIAS_BEARISH;
   }

   return BIAS_NONE;
}

//+------------------------------------------------------------------+
//|                 SEARCH FOR FVG                                    |
//+------------------------------------------------------------------+
void SearchForFVG(ENUM_BIAS_TYPE bias)
{
   // Cerca FVG nelle ultime candele M5
   for(int i = 2; i <= 10; i++)
   {
      // Verifica displacement prima
      if(!CheckDisplacement(i, bias)) continue;

      // Cerca FVG
      double high0 = iHigh(Symbol(), PERIOD_M5, i-2);  // Candela dopo gap
      double low0 = iLow(Symbol(), PERIOD_M5, i-2);
      double high1 = iHigh(Symbol(), PERIOD_M5, i-1);  // Candela displacement
      double low1 = iLow(Symbol(), PERIOD_M5, i-1);
      double high2 = iHigh(Symbol(), PERIOD_M5, i);    // Candela prima gap
      double low2 = iLow(Symbol(), PERIOD_M5, i);

      double fvgHigh, fvgLow;
      int fvgType = FVG_NONE;

      // Bullish FVG: Low della candela successiva > High della candela precedente
      if(bias == BIAS_BULLISH && low0 > high2)
      {
         fvgHigh = low0;
         fvgLow = high2;
         fvgType = FVG_BULLISH;
      }
      // Bearish FVG: High della candela successiva < Low della candela precedente
      else if(bias == BIAS_BEARISH && high0 < low2)
      {
         fvgHigh = low2;
         fvgLow = high0;
         fvgType = FVG_BEARISH;
      }

      // Verifica dimensione FVG
      if(fvgType != FVG_NONE)
      {
         double fvgSize = (fvgHigh - fvgLow) / Point;
         double minFVGSize = IsGold() ? FVG_MinSize_XAU : FVG_MinSize_XAG;

         if(fvgSize >= minFVGSize)
         {
            // FVG valido trovato
            activeFVG.isValid = true;
            activeFVG.type = fvgType;
            activeFVG.highPrice = fvgHigh;
            activeFVG.lowPrice = fvgLow;
            activeFVG.createTime = iTime(Symbol(), PERIOD_M5, i-1);
            activeFVG.barIndex = i-1;
            activeFVG.isMitigated = false;
            activeFVG.hasRejection = false;

            Print("FVG ", (fvgType == FVG_BULLISH ? "BULLISH" : "BEARISH"),
                  " trovato! High: ", fvgHigh, " Low: ", fvgLow,
                  " Size: ", fvgSize, " points");

            // Disegna FVG sul grafico
            DrawFVG();
            return;
         }
      }
   }
}

//+------------------------------------------------------------------+
//|              CHECK DISPLACEMENT                                   |
//+------------------------------------------------------------------+
bool CheckDisplacement(int barIndex, ENUM_BIAS_TYPE bias)
{
   // Calcola ATR
   double atr = iATR(Symbol(), PERIOD_M5, ATR_Period, barIndex);
   double displacementMulti = IsGold() ? Displacement_ATR_XAU : Displacement_ATR_XAG;
   double minDisplacement = atr * displacementMulti;

   // Dimensione candela
   double candleHigh = iHigh(Symbol(), PERIOD_M5, barIndex);
   double candleLow = iLow(Symbol(), PERIOD_M5, barIndex);
   double candleSize = candleHigh - candleLow;

   // Verifica direzione e dimensione
   double candleOpen = iOpen(Symbol(), PERIOD_M5, barIndex);
   double candleClose = iClose(Symbol(), PERIOD_M5, barIndex);

   if(bias == BIAS_BULLISH)
   {
      // Candela bullish con displacement significativo
      if(candleClose > candleOpen && candleSize >= minDisplacement)
      {
         return true;
      }
   }
   else if(bias == BIAS_BEARISH)
   {
      // Candela bearish con displacement significativo
      if(candleClose < candleOpen && candleSize >= minDisplacement)
      {
         return true;
      }
   }

   return false;
}

//+------------------------------------------------------------------+
//|               CHECK FVG RETEST                                    |
//+------------------------------------------------------------------+
void CheckFVGRetest()
{
   double currentPrice = (activeFVG.type == FVG_BULLISH) ? Bid : Ask;
   double fvgMid = (activeFVG.highPrice + activeFVG.lowPrice) / 2;
   double buffer = (activeFVG.highPrice - activeFVG.lowPrice) * FVG_RetestBuffer;

   if(activeFVG.type == FVG_BULLISH)
   {
      // Per bullish FVG, prezzo deve scendere nella zona
      if(currentPrice <= activeFVG.highPrice + buffer &&
         currentPrice >= activeFVG.lowPrice - buffer)
      {
         activeFVG.isMitigated = true;
         Print("FVG BULLISH mitigato a prezzo: ", currentPrice);
      }
   }
   else if(activeFVG.type == FVG_BEARISH)
   {
      // Per bearish FVG, prezzo deve salire nella zona
      if(currentPrice >= activeFVG.lowPrice - buffer &&
         currentPrice <= activeFVG.highPrice + buffer)
      {
         activeFVG.isMitigated = true;
         Print("FVG BEARISH mitigato a prezzo: ", currentPrice);
      }
   }
}

//+------------------------------------------------------------------+
//|            CHECK REJECTION CANDLE                                 |
//+------------------------------------------------------------------+
void CheckRejectionCandle(ENUM_BIAS_TYPE bias)
{
   // Analizza ultima candela chiusa (index 1)
   double open1 = iOpen(Symbol(), PERIOD_M5, 1);
   double high1 = iHigh(Symbol(), PERIOD_M5, 1);
   double low1 = iLow(Symbol(), PERIOD_M5, 1);
   double close1 = iClose(Symbol(), PERIOD_M5, 1);

   double body = MathAbs(close1 - open1);
   double candleRange = high1 - low1;
   double upperWick = high1 - MathMax(open1, close1);
   double lowerWick = MathMin(open1, close1) - low1;

   if(candleRange == 0) return;

   double bodyRatio = body / candleRange;

   if(activeFVG.type == FVG_BULLISH && bias == BIAS_BULLISH)
   {
      // Rejection bullish: wick inferiore nel FVG, chiusura sopra
      if(low1 <= activeFVG.highPrice && low1 >= activeFVG.lowPrice)
      {
         // Verifica wick ratio
         double wickRatio = lowerWick / (body > 0 ? body : candleRange);
         if(wickRatio >= RejectionWickRatio && bodyRatio >= RejectionMinBody)
         {
            if(close1 > open1) // Candela bullish
            {
               activeFVG.hasRejection = true;
               rejectionDetected = true;
               rejectionBarTime = iTime(Symbol(), PERIOD_M5, 1);
               Print("REJECTION BULLISH rilevata! Candela: ", TimeToString(rejectionBarTime));
            }
         }
      }
   }
   else if(activeFVG.type == FVG_BEARISH && bias == BIAS_BEARISH)
   {
      // Rejection bearish: wick superiore nel FVG, chiusura sotto
      if(high1 >= activeFVG.lowPrice && high1 <= activeFVG.highPrice)
      {
         // Verifica wick ratio
         double wickRatio = upperWick / (body > 0 ? body : candleRange);
         if(wickRatio >= RejectionWickRatio && bodyRatio >= RejectionMinBody)
         {
            if(close1 < open1) // Candela bearish
            {
               activeFVG.hasRejection = true;
               rejectionDetected = true;
               rejectionBarTime = iTime(Symbol(), PERIOD_M5, 1);
               Print("REJECTION BEARISH rilevata! Candela: ", TimeToString(rejectionBarTime));
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//|          CHECK ENTRY CONFIRMATION                                 |
//+------------------------------------------------------------------+
void CheckEntryConfirmation(ENUM_BIAS_TYPE bias)
{
   // Verifica candela di conferma (ultima candela chiusa dopo rejection)
   datetime currentBarTime = iTime(Symbol(), PERIOD_M5, 1);

   // La candela di conferma deve essere DOPO la rejection
   if(currentBarTime <= rejectionBarTime) return;

   double open1 = iOpen(Symbol(), PERIOD_M5, 1);
   double close1 = iClose(Symbol(), PERIOD_M5, 1);

   bool entryConfirmed = false;

   if(activeFVG.type == FVG_BULLISH && bias == BIAS_BULLISH)
   {
      // Conferma: candela bullish
      if(close1 > open1)
      {
         entryConfirmed = true;
      }
   }
   else if(activeFVG.type == FVG_BEARISH && bias == BIAS_BEARISH)
   {
      // Conferma: candela bearish
      if(close1 < open1)
      {
         entryConfirmed = true;
      }
   }

   if(entryConfirmed)
   {
      ExecuteTrade(bias);
   }
}

//+------------------------------------------------------------------+
//|                  EXECUTE TRADE                                    |
//+------------------------------------------------------------------+
void ExecuteTrade(ENUM_BIAS_TYPE bias)
{
   // Calcola SL e TP dinamici
   double sl, tp, entryPrice;
   double lotSize = GetLotSize();
   int orderType;

   // Calcola ATR per SL dinamico
   double atr = iATR(Symbol(), PERIOD_M5, ATR_Period, 0);
   double slATRMulti = IsGold() ? SL_ATR_Multi_XAU : SL_ATR_Multi_XAG;
   double slDistance = atr * slATRMulti;

   // Applica limiti SL
   double minSL = (IsGold() ? MinSL_Points_XAU : MinSL_Points_XAG) * Point;
   double maxSL = (IsGold() ? MaxSL_Points_XAU : MaxSL_Points_XAG) * Point;
   slDistance = MathMax(minSL, MathMin(maxSL, slDistance));

   // Calcola TP con R:R dinamico (tra RR_Min e RR_Max)
   double rrRatio = RR_Min + (RR_Max - RR_Min) * 0.5; // Media tra min e max
   double tpDistance = slDistance * rrRatio;

   if(bias == BIAS_BULLISH)
   {
      orderType = OP_BUY;
      entryPrice = Ask;
      sl = entryPrice - slDistance;
      tp = entryPrice + tpDistance;

      // SL sotto FVG low se più protettivo
      double fvgSL = activeFVG.lowPrice - (10 * Point);
      if(fvgSL < sl)
      {
         sl = fvgSL;
         slDistance = entryPrice - sl;
         tp = entryPrice + (slDistance * rrRatio);
      }
   }
   else
   {
      orderType = OP_SELL;
      entryPrice = Bid;
      sl = entryPrice + slDistance;
      tp = entryPrice - tpDistance;

      // SL sopra FVG high se più protettivo
      double fvgSL = activeFVG.highPrice + (10 * Point);
      if(fvgSL > sl)
      {
         sl = fvgSL;
         slDistance = sl - entryPrice;
         tp = entryPrice - (slDistance * rrRatio);
      }
   }

   // Calcola lot size basato su risk se non fisso
   if(!UseFixedLot)
   {
      lotSize = CalculateLotSize(slDistance);
   }

   // Normalizza prezzi
   sl = NormalizeDouble(sl, Digits);
   tp = NormalizeDouble(tp, Digits);

   // Esegui ordine
   int ticket = OrderSend(
      Symbol(),
      orderType,
      lotSize,
      entryPrice,
      30,        // Slippage
      sl,
      tp,
      TradeComment + "_" + GetSessionName(currentSession),
      MagicNumber,
      0,
      (orderType == OP_BUY) ? clrGreen : clrRed
   );

   if(ticket > 0)
   {
      tradesThisSession++;
      tradesThisDay++;

      Print("═══════════════════════════════════════════════════");
      Print("TRADE ESEGUITO!");
      Print("Tipo: ", (orderType == OP_BUY ? "BUY" : "SELL"));
      Print("Entry: ", entryPrice);
      Print("SL: ", sl, " (", DoubleToString(slDistance/Point, 0), " points)");
      Print("TP: ", tp, " (", DoubleToString(tpDistance/Point, 0), " points)");
      Print("R:R = 1:", DoubleToString(rrRatio, 2));
      Print("Lot: ", lotSize);
      Print("Sessione: ", GetSessionName(currentSession));
      Print("Trade #", tradesThisSession, " della sessione");
      Print("═══════════════════════════════════════════════════");

      // Reset FVG dopo trade
      ResetFVG();
   }
   else
   {
      int error = GetLastError();
      Print("ERRORE apertura ordine: ", error, " - ", ErrorDescription(error));
   }
}

//+------------------------------------------------------------------+
//|              CALCULATE LOT SIZE                                   |
//+------------------------------------------------------------------+
double CalculateLotSize(double slDistance)
{
   double accountBalance = AccountBalance();
   double riskAmount = accountBalance * (RiskPercent / 100.0);

   // Calcola valore pip
   double tickValue = MarketInfo(Symbol(), MODE_TICKVALUE);
   double tickSize = MarketInfo(Symbol(), MODE_TICKSIZE);
   double pipValue = tickValue * (Point / tickSize);

   // Calcola lot size
   double slPips = slDistance / Point;
   double calculatedLot = riskAmount / (slPips * pipValue);

   // Normalizza
   double minLot = MarketInfo(Symbol(), MODE_MINLOT);
   double maxLot = MarketInfo(Symbol(), MODE_MAXLOT);
   double lotStep = MarketInfo(Symbol(), MODE_LOTSTEP);

   calculatedLot = MathFloor(calculatedLot / lotStep) * lotStep;
   calculatedLot = MathMax(minLot, MathMin(maxLot, calculatedLot));

   return calculatedLot;
}

//+------------------------------------------------------------------+
//|                  UTILITY FUNCTIONS                                |
//+------------------------------------------------------------------+

// Verifica se è oro
bool IsGold()
{
   return (StringFind(Symbol(), "XAU") >= 0);
}

// Ottieni lot size in base al simbolo
double GetLotSize()
{
   return IsGold() ? LotSize_XAU : LotSize_XAG;
}

// Verifica nuova candela
bool IsNewBar(int timeframe)
{
   datetime currentTime = iTime(Symbol(), timeframe, 0);

   if(timeframe == PERIOD_M5)
   {
      if(currentTime != lastBarTime_M5)
      {
         lastBarTime_M5 = currentTime;
         return true;
      }
   }
   else if(timeframe == PERIOD_M15)
   {
      if(currentTime != lastBarTime_M15)
      {
         lastBarTime_M15 = currentTime;
         return true;
      }
   }

   return false;
}

// Ottieni sessione corrente
ENUM_SESSION_TYPE GetCurrentSession()
{
   datetime serverTime = TimeCurrent();
   int hour = TimeHour(serverTime);

   // Asian Session
   if(UseAsianSession && hour >= AsianStartHour && hour < AsianEndHour)
   {
      return SESSION_ASIAN;
   }

   // London Session
   if(UseLondonSession && hour >= LondonStartHour && hour < LondonEndHour)
   {
      return SESSION_LONDON;
   }

   // NY AM Session
   if(UseNYAMSession && hour >= NYAMStartHour && hour < NYAMEndHour)
   {
      return SESSION_NY_AM;
   }

   // NY PM Session
   if(UseNYPMSession && hour >= NYPMStartHour && hour < NYPMEndHour)
   {
      return SESSION_NY_PM;
   }

   return SESSION_NONE;
}

// Nome sessione
string GetSessionName(ENUM_SESSION_TYPE session)
{
   switch(session)
   {
      case SESSION_ASIAN:  return "ASIAN";
      case SESSION_LONDON: return "LONDON";
      case SESSION_NY_AM:  return "NY_AM";
      case SESSION_NY_PM:  return "NY_PM";
      default:             return "NONE";
   }
}

// Verifica spread
bool CheckSpread()
{
   double currentSpread = MarketInfo(Symbol(), MODE_SPREAD);
   double maxSpread = IsGold() ? MaxSpread_XAU : MaxSpread_XAG;

   if(currentSpread > maxSpread)
   {
      return false;
   }
   return true;
}

// Reset FVG
void ResetFVG()
{
   activeFVG.isValid = false;
   activeFVG.type = FVG_NONE;
   activeFVG.highPrice = 0;
   activeFVG.lowPrice = 0;
   activeFVG.createTime = 0;
   activeFVG.barIndex = 0;
   activeFVG.isMitigated = false;
   activeFVG.hasRejection = false;
   waitingForEntry = false;
   rejectionDetected = false;
   rejectionBarTime = 0;

   // Rimuovi oggetti grafici FVG
   ObjectDelete(0, "FVG_Zone");
   ObjectDelete(0, "FVG_Label");
}

// Reset giornaliero
void CheckDayReset()
{
   datetime today = StringToTime(TimeToString(TimeCurrent(), TIME_DATE));
   if(today != lastTradeDay)
   {
      lastTradeDay = today;
      tradesThisDay = 0;
      Print("Nuovo giorno di trading. Reset contatori.");
   }
}

// Filtro notizie (semplificato - può essere integrato con servizio esterno)
bool IsNewsTime()
{
   // Implementazione base: evita trading durante ore specifiche
   // Per filtro completo, integrare con calendario economico

   int hour = TimeHour(TimeCurrent());
   int minute = TimeMinute(TimeCurrent());

   // Evita NFP (primo venerdì del mese, 14:30 GMT+1)
   datetime current = TimeCurrent();
   int dayOfWeek = TimeDayOfWeek(current);
   int dayOfMonth = TimeDay(current);

   // Primo venerdì del mese
   if(dayOfWeek == 5 && dayOfMonth <= 7)
   {
      if(hour == 14 && minute >= 0 && minute <= 59)
      {
         Print("Filtro News: NFP attivo");
         return true;
      }
   }

   // FOMC (mercoledì, solitamente 20:00 GMT+1)
   if(dayOfWeek == 3)
   {
      if(hour == 20 && minute >= (60 - NewsMinutesBefore))
      {
         Print("Filtro News: FOMC attivo");
         return true;
      }
      if(hour == 21 && minute <= NewsMinutesAfter)
      {
         return true;
      }
   }

   return false;
}

// Disegna FVG sul grafico
void DrawFVG()
{
   string objName = "FVG_Zone";

   ObjectDelete(0, objName);
   ObjectDelete(0, "FVG_Label");

   datetime startTime = activeFVG.createTime;
   datetime endTime = TimeCurrent() + PeriodSeconds(PERIOD_M5) * 20;

   color fvgColor = (activeFVG.type == FVG_BULLISH) ? clrLimeGreen : clrCrimson;

   ObjectCreate(0, objName, OBJ_RECTANGLE, 0, startTime, activeFVG.highPrice, endTime, activeFVG.lowPrice);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, fvgColor);
   ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, objName, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, objName, OBJPROP_FILL, true);
   ObjectSetInteger(0, objName, OBJPROP_BACK, true);
   ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);

   // Label
   string labelName = "FVG_Label";
   ObjectCreate(0, labelName, OBJ_TEXT, 0, startTime, activeFVG.highPrice);
   ObjectSetString(0, labelName, OBJPROP_TEXT, (activeFVG.type == FVG_BULLISH ? "BULLISH FVG" : "BEARISH FVG"));
   ObjectSetInteger(0, labelName, OBJPROP_COLOR, fvgColor);
   ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 8);
}

// Descrizione errore
string ErrorDescription(int error)
{
   switch(error)
   {
      case 0:    return "No error";
      case 1:    return "No error but result unknown";
      case 2:    return "Common error";
      case 3:    return "Invalid trade parameters";
      case 4:    return "Trade server is busy";
      case 5:    return "Old version of client terminal";
      case 6:    return "No connection with trade server";
      case 7:    return "Not enough rights";
      case 8:    return "Too frequent requests";
      case 9:    return "Malfunctional trade operation";
      case 64:   return "Account disabled";
      case 65:   return "Invalid account";
      case 128:  return "Trade timeout";
      case 129:  return "Invalid price";
      case 130:  return "Invalid stops";
      case 131:  return "Invalid trade volume";
      case 132:  return "Market is closed";
      case 133:  return "Trade is disabled";
      case 134:  return "Not enough money";
      case 135:  return "Price changed";
      case 136:  return "Off quotes";
      case 137:  return "Broker is busy";
      case 138:  return "Requote";
      case 139:  return "Order is locked";
      case 140:  return "Only long positions allowed";
      case 141:  return "Too many requests";
      case 145:  return "Modification denied";
      case 146:  return "Trade context is busy";
      case 147:  return "Expirations denied";
      case 148:  return "Too many orders";
      default:   return "Unknown error";
   }
}

//+------------------------------------------------------------------+
