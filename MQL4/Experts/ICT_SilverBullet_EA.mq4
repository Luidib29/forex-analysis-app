//+------------------------------------------------------------------+
//|                                         ICT_SilverBullet_EA.mq4  |
//|                        ICT Silver Bullet Strategy for MT4        |
//|                         Ottimizzato per XAUUSD e XAGUSD          |
//|                            RoboForex Conto Cent - GMT+1          |
//+------------------------------------------------------------------+
#property copyright "ICT Silver Bullet EA"
#property link      ""
#property version   "2.00"
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

enum ENUM_PANEL_CORNER
{
   CORNER_TOP_LEFT = 0,      // Angolo in alto a sinistra
   CORNER_TOP_RIGHT = 1,     // Angolo in alto a destra
   CORNER_BOTTOM_LEFT = 2,   // Angolo in basso a sinistra
   CORNER_BOTTOM_RIGHT = 3   // Angolo in basso a destra
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

//--- Panel Settings
input string   PanelSettings = "═══════ STATISTICS PANEL ═══════";
input bool     ShowPanel = true;               // Mostra Pannello Statistiche
input ENUM_PANEL_CORNER PanelCorner = CORNER_TOP_LEFT; // Posizione Pannello
input int      PanelX = 10;                    // Offset X Pannello
input int      PanelY = 30;                    // Offset Y Pannello
input color    PanelBgColor = C'25,25,35';     // Colore Sfondo Pannello
input color    PanelBorderColor = C'60,60,80'; // Colore Bordo Pannello
input color    PanelTitleColor = clrGold;      // Colore Titolo
input color    PanelTextColor = clrWhite;      // Colore Testo
input color    PanelProfitColor = clrLime;     // Colore Profit
input color    PanelLossColor = clrRed;        // Colore Loss
input int      PanelFontSize = 9;              // Dimensione Font
input string   PanelFontName = "Consolas";     // Nome Font

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

// Statistics Structure
struct StatisticsData
{
   int      totalTrades;
   int      winTrades;
   int      lossTrades;
   double   totalProfit;
   double   totalLoss;
   double   netProfit;
   double   winRate;
   double   profitFactor;
   double   avgWin;
   double   avgLoss;
   double   maxDrawdown;
   double   bestTrade;
   double   worstTrade;
   int      consecutiveWins;
   int      consecutiveLosses;
   int      maxConsecutiveWins;
   int      maxConsecutiveLosses;
   int      longTrades;
   int      shortTrades;
   int      longWins;
   int      shortWins;
};

StatisticsData dailyStats;
StatisticsData totalStats;
datetime lastStatsUpdate = 0;
int panelUpdateCounter = 0;

// Panel Object Names
string panelPrefix = "ICTPANEL_";

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

   // Inizializza statistiche
   ResetStatistics(dailyStats);
   ResetStatistics(totalStats);

   // Calcola statistiche iniziali
   CalculateStatistics();

   // Crea pannello
   if(ShowPanel)
   {
      CreatePanel();
      UpdatePanel();
   }

   // Info inizializzazione
   Print("═══════════════════════════════════════════════════");
   Print("ICT Silver Bullet EA v2.0 Inizializzato");
   Print("Simbolo: ", currentSymbol);
   Print("Lot Size: ", GetLotSize());
   Print("GMT Offset: ", GMT_Offset);
   Print("Risk: ", RiskPercent, "%");
   Print("R:R Range: 1:", RR_Min, " - 1:", RR_Max);
   Print("Pannello Statistiche: ", (ShowPanel ? "ATTIVO" : "DISATTIVO"));
   Print("═══════════════════════════════════════════════════");

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                      DEINIT                                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Rimuovi pannello
   DeletePanel();

   // Rimuovi oggetti FVG
   ObjectDelete(0, "FVG_Zone");
   ObjectDelete(0, "FVG_Label");

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

   // Aggiorna pannello ogni 10 tick
   if(ShowPanel)
   {
      panelUpdateCounter++;
      if(panelUpdateCounter >= 10)
      {
         CalculateStatistics();
         UpdatePanel();
         panelUpdateCounter = 0;
      }
   }

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

      // Aggiorna statistiche
      CalculateStatistics();
      if(ShowPanel) UpdatePanel();

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
//|                STATISTICS FUNCTIONS                               |
//+------------------------------------------------------------------+

// Reset Statistics
void ResetStatistics(StatisticsData &stats)
{
   stats.totalTrades = 0;
   stats.winTrades = 0;
   stats.lossTrades = 0;
   stats.totalProfit = 0;
   stats.totalLoss = 0;
   stats.netProfit = 0;
   stats.winRate = 0;
   stats.profitFactor = 0;
   stats.avgWin = 0;
   stats.avgLoss = 0;
   stats.maxDrawdown = 0;
   stats.bestTrade = 0;
   stats.worstTrade = 0;
   stats.consecutiveWins = 0;
   stats.consecutiveLosses = 0;
   stats.maxConsecutiveWins = 0;
   stats.maxConsecutiveLosses = 0;
   stats.longTrades = 0;
   stats.shortTrades = 0;
   stats.longWins = 0;
   stats.shortWins = 0;
}

// Calculate Statistics from Trade History
void CalculateStatistics()
{
   // Reset stats
   ResetStatistics(dailyStats);
   ResetStatistics(totalStats);

   datetime todayStart = StringToTime(TimeToString(TimeCurrent(), TIME_DATE));

   int tempConsecWins = 0;
   int tempConsecLosses = 0;
   double runningProfit = 0;
   double peakProfit = 0;

   // Scan closed orders
   for(int i = OrdersHistoryTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)) continue;
      if(OrderMagicNumber() != MagicNumber) continue;
      if(OrderSymbol() != Symbol()) continue;
      if(OrderType() > OP_SELL) continue; // Skip pending orders

      double profit = OrderProfit() + OrderSwap() + OrderCommission();
      datetime closeTime = OrderCloseTime();
      int orderType = OrderType();

      // Total Stats
      totalStats.totalTrades++;

      if(orderType == OP_BUY) totalStats.longTrades++;
      else totalStats.shortTrades++;

      if(profit > 0)
      {
         totalStats.winTrades++;
         totalStats.totalProfit += profit;
         if(profit > totalStats.bestTrade) totalStats.bestTrade = profit;

         if(orderType == OP_BUY) totalStats.longWins++;
         else totalStats.shortWins++;

         tempConsecWins++;
         if(tempConsecWins > totalStats.maxConsecutiveWins)
            totalStats.maxConsecutiveWins = tempConsecWins;
         tempConsecLosses = 0;
      }
      else if(profit < 0)
      {
         totalStats.lossTrades++;
         totalStats.totalLoss += MathAbs(profit);
         if(profit < totalStats.worstTrade) totalStats.worstTrade = profit;

         tempConsecLosses++;
         if(tempConsecLosses > totalStats.maxConsecutiveLosses)
            totalStats.maxConsecutiveLosses = tempConsecLosses;
         tempConsecWins = 0;
      }

      // Drawdown calculation
      runningProfit += profit;
      if(runningProfit > peakProfit) peakProfit = runningProfit;
      double drawdown = peakProfit - runningProfit;
      if(drawdown > totalStats.maxDrawdown) totalStats.maxDrawdown = drawdown;

      // Daily Stats
      if(closeTime >= todayStart)
      {
         dailyStats.totalTrades++;

         if(orderType == OP_BUY) dailyStats.longTrades++;
         else dailyStats.shortTrades++;

         if(profit > 0)
         {
            dailyStats.winTrades++;
            dailyStats.totalProfit += profit;
            if(profit > dailyStats.bestTrade) dailyStats.bestTrade = profit;

            if(orderType == OP_BUY) dailyStats.longWins++;
            else dailyStats.shortWins++;
         }
         else if(profit < 0)
         {
            dailyStats.lossTrades++;
            dailyStats.totalLoss += MathAbs(profit);
            if(profit < dailyStats.worstTrade) dailyStats.worstTrade = profit;
         }
      }
   }

   // Calculate derived stats - Total
   totalStats.netProfit = totalStats.totalProfit - totalStats.totalLoss;
   if(totalStats.totalTrades > 0)
      totalStats.winRate = (double)totalStats.winTrades / totalStats.totalTrades * 100.0;
   if(totalStats.totalLoss > 0)
      totalStats.profitFactor = totalStats.totalProfit / totalStats.totalLoss;
   if(totalStats.winTrades > 0)
      totalStats.avgWin = totalStats.totalProfit / totalStats.winTrades;
   if(totalStats.lossTrades > 0)
      totalStats.avgLoss = totalStats.totalLoss / totalStats.lossTrades;

   // Calculate derived stats - Daily
   dailyStats.netProfit = dailyStats.totalProfit - dailyStats.totalLoss;
   if(dailyStats.totalTrades > 0)
      dailyStats.winRate = (double)dailyStats.winTrades / dailyStats.totalTrades * 100.0;
   if(dailyStats.totalLoss > 0)
      dailyStats.profitFactor = dailyStats.totalProfit / dailyStats.totalLoss;
   if(dailyStats.winTrades > 0)
      dailyStats.avgWin = dailyStats.totalProfit / dailyStats.winTrades;
   if(dailyStats.lossTrades > 0)
      dailyStats.avgLoss = dailyStats.totalLoss / dailyStats.lossTrades;

   // Count open positions
   int openTrades = 0;
   double floatingPL = 0;
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderMagicNumber() != MagicNumber) continue;
      if(OrderSymbol() != Symbol()) continue;
      if(OrderType() > OP_SELL) continue;

      openTrades++;
      floatingPL += OrderProfit() + OrderSwap() + OrderCommission();
   }
}

//+------------------------------------------------------------------+
//|                   PANEL FUNCTIONS                                 |
//+------------------------------------------------------------------+

// Create Panel
void CreatePanel()
{
   int panelWidth = 280;
   int panelHeight = 420;
   int lineHeight = 18;
   int startY = PanelY;
   int startX = PanelX;

   // Adjust for corner
   int xDist = startX;
   int yDist = startY;
   ENUM_BASE_CORNER corner = CORNER_LEFT_UPPER;

   switch(PanelCorner)
   {
      case CORNER_TOP_RIGHT:
         corner = CORNER_RIGHT_UPPER;
         break;
      case CORNER_BOTTOM_LEFT:
         corner = CORNER_LEFT_LOWER;
         break;
      case CORNER_BOTTOM_RIGHT:
         corner = CORNER_RIGHT_LOWER;
         break;
      default:
         corner = CORNER_LEFT_UPPER;
   }

   // Background
   CreateRectLabel(panelPrefix + "BG", xDist, yDist, panelWidth, panelHeight, PanelBgColor, PanelBorderColor, corner);

   // Title
   int y = yDist + 8;
   CreateLabel(panelPrefix + "Title", xDist + 10, y, "ICT SILVER BULLET EA v2.0", PanelTitleColor, PanelFontSize + 2, corner, true);

   y += lineHeight + 5;
   CreateLabel(panelPrefix + "Symbol", xDist + 10, y, "Symbol: " + Symbol(), PanelTextColor, PanelFontSize, corner);

   y += lineHeight;
   CreateLabel(panelPrefix + "Session", xDist + 10, y, "Session: ---", PanelTextColor, PanelFontSize, corner);

   y += lineHeight;
   CreateLabel(panelPrefix + "Bias", xDist + 10, y, "Bias: ---", PanelTextColor, PanelFontSize, corner);

   y += lineHeight;
   CreateLabel(panelPrefix + "FVG", xDist + 10, y, "FVG: None", PanelTextColor, PanelFontSize, corner);

   y += lineHeight;
   CreateLabel(panelPrefix + "Spread", xDist + 10, y, "Spread: ---", PanelTextColor, PanelFontSize, corner);

   // Separator
   y += lineHeight + 5;
   CreateLabel(panelPrefix + "Sep1", xDist + 10, y, "---------- TODAY ----------", clrDarkGray, PanelFontSize - 1, corner);

   y += lineHeight;
   CreateLabel(panelPrefix + "DayTrades", xDist + 10, y, "Trades: 0 (W:0 L:0)", PanelTextColor, PanelFontSize, corner);

   y += lineHeight;
   CreateLabel(panelPrefix + "DayWinRate", xDist + 10, y, "Win Rate: 0.0%", PanelTextColor, PanelFontSize, corner);

   y += lineHeight;
   CreateLabel(panelPrefix + "DayProfit", xDist + 10, y, "Profit: $0.00", PanelTextColor, PanelFontSize, corner);

   y += lineHeight;
   CreateLabel(panelPrefix + "DayPF", xDist + 10, y, "Profit Factor: 0.00", PanelTextColor, PanelFontSize, corner);

   y += lineHeight;
   CreateLabel(panelPrefix + "DayBest", xDist + 10, y, "Best: $0.00", PanelProfitColor, PanelFontSize, corner);

   y += lineHeight;
   CreateLabel(panelPrefix + "DayWorst", xDist + 10, y, "Worst: $0.00", PanelLossColor, PanelFontSize, corner);

   // Separator
   y += lineHeight + 5;
   CreateLabel(panelPrefix + "Sep2", xDist + 10, y, "---------- TOTAL ----------", clrDarkGray, PanelFontSize - 1, corner);

   y += lineHeight;
   CreateLabel(panelPrefix + "TotalTrades", xDist + 10, y, "Trades: 0 (W:0 L:0)", PanelTextColor, PanelFontSize, corner);

   y += lineHeight;
   CreateLabel(panelPrefix + "TotalWinRate", xDist + 10, y, "Win Rate: 0.0%", PanelTextColor, PanelFontSize, corner);

   y += lineHeight;
   CreateLabel(panelPrefix + "TotalProfit", xDist + 10, y, "Net Profit: $0.00", PanelTextColor, PanelFontSize, corner);

   y += lineHeight;
   CreateLabel(panelPrefix + "TotalPF", xDist + 10, y, "Profit Factor: 0.00", PanelTextColor, PanelFontSize, corner);

   y += lineHeight;
   CreateLabel(panelPrefix + "TotalDD", xDist + 10, y, "Max Drawdown: $0.00", PanelLossColor, PanelFontSize, corner);

   y += lineHeight;
   CreateLabel(panelPrefix + "TotalBest", xDist + 10, y, "Best Trade: $0.00", PanelProfitColor, PanelFontSize, corner);

   y += lineHeight;
   CreateLabel(panelPrefix + "TotalWorst", xDist + 10, y, "Worst Trade: $0.00", PanelLossColor, PanelFontSize, corner);

   y += lineHeight;
   CreateLabel(panelPrefix + "ConsecWins", xDist + 10, y, "Max Consec Wins: 0", PanelProfitColor, PanelFontSize, corner);

   y += lineHeight;
   CreateLabel(panelPrefix + "ConsecLoss", xDist + 10, y, "Max Consec Loss: 0", PanelLossColor, PanelFontSize, corner);

   // Separator
   y += lineHeight + 5;
   CreateLabel(panelPrefix + "Sep3", xDist + 10, y, "-------- ACCOUNT --------", clrDarkGray, PanelFontSize - 1, corner);

   y += lineHeight;
   CreateLabel(panelPrefix + "Balance", xDist + 10, y, "Balance: $0.00", PanelTextColor, PanelFontSize, corner);

   y += lineHeight;
   CreateLabel(panelPrefix + "Equity", xDist + 10, y, "Equity: $0.00", PanelTextColor, PanelFontSize, corner);

   y += lineHeight;
   CreateLabel(panelPrefix + "OpenTrades", xDist + 10, y, "Open Trades: 0", PanelTextColor, PanelFontSize, corner);

   y += lineHeight;
   CreateLabel(panelPrefix + "FloatingPL", xDist + 10, y, "Floating P/L: $0.00", PanelTextColor, PanelFontSize, corner);

   ChartRedraw();
}

// Create Rectangle Label (Background)
void CreateRectLabel(string name, int x, int y, int width, int height, color bgColor, color borderColor, ENUM_BASE_CORNER corner)
{
   ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, corner);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bgColor);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_COLOR, borderColor);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
}

// Create Label
void CreateLabel(string name, int x, int y, string text, color textColor, int fontSize, ENUM_BASE_CORNER corner, bool bold = false)
{
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, corner);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, textColor);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
   ObjectSetString(0, name, OBJPROP_FONT, bold ? PanelFontName + " Bold" : PanelFontName);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
}

// Update Panel
void UpdatePanel()
{
   if(!ShowPanel) return;

   // Current state
   string sessionName = GetSessionName(currentSession);
   ENUM_BIAS_TYPE bias = GetBias_M15();
   string biasStr = (bias == BIAS_BULLISH) ? "BULLISH" : (bias == BIAS_BEARISH) ? "BEARISH" : "NONE";
   color biasColor = (bias == BIAS_BULLISH) ? PanelProfitColor : (bias == BIAS_BEARISH) ? PanelLossColor : PanelTextColor;

   string fvgStatus = "None";
   if(activeFVG.isValid)
   {
      fvgStatus = (activeFVG.type == FVG_BULLISH ? "BULL" : "BEAR");
      if(activeFVG.isMitigated) fvgStatus += " [MIT]";
      if(activeFVG.hasRejection) fvgStatus += " [REJ]";
   }

   double spread = MarketInfo(Symbol(), MODE_SPREAD);

   // Update labels
   ObjectSetString(0, panelPrefix + "Session", OBJPROP_TEXT, "Session: " + sessionName);
   ObjectSetString(0, panelPrefix + "Bias", OBJPROP_TEXT, "Bias: " + biasStr);
   ObjectSetInteger(0, panelPrefix + "Bias", OBJPROP_COLOR, biasColor);
   ObjectSetString(0, panelPrefix + "FVG", OBJPROP_TEXT, "FVG: " + fvgStatus);
   ObjectSetString(0, panelPrefix + "Spread", OBJPROP_TEXT, "Spread: " + DoubleToString(spread, 0) + " pts");

   // Daily Stats
   ObjectSetString(0, panelPrefix + "DayTrades", OBJPROP_TEXT,
      "Trades: " + IntegerToString(dailyStats.totalTrades) +
      " (W:" + IntegerToString(dailyStats.winTrades) +
      " L:" + IntegerToString(dailyStats.lossTrades) + ")");

   ObjectSetString(0, panelPrefix + "DayWinRate", OBJPROP_TEXT,
      "Win Rate: " + DoubleToString(dailyStats.winRate, 1) + "%");
   ObjectSetInteger(0, panelPrefix + "DayWinRate", OBJPROP_COLOR,
      dailyStats.winRate >= 50 ? PanelProfitColor : PanelLossColor);

   ObjectSetString(0, panelPrefix + "DayProfit", OBJPROP_TEXT,
      "Profit: $" + DoubleToString(dailyStats.netProfit, 2));
   ObjectSetInteger(0, panelPrefix + "DayProfit", OBJPROP_COLOR,
      dailyStats.netProfit >= 0 ? PanelProfitColor : PanelLossColor);

   ObjectSetString(0, panelPrefix + "DayPF", OBJPROP_TEXT,
      "Profit Factor: " + DoubleToString(dailyStats.profitFactor, 2));
   ObjectSetInteger(0, panelPrefix + "DayPF", OBJPROP_COLOR,
      dailyStats.profitFactor >= 1 ? PanelProfitColor : PanelLossColor);

   ObjectSetString(0, panelPrefix + "DayBest", OBJPROP_TEXT,
      "Best: $" + DoubleToString(dailyStats.bestTrade, 2));

   ObjectSetString(0, panelPrefix + "DayWorst", OBJPROP_TEXT,
      "Worst: $" + DoubleToString(dailyStats.worstTrade, 2));

   // Total Stats
   ObjectSetString(0, panelPrefix + "TotalTrades", OBJPROP_TEXT,
      "Trades: " + IntegerToString(totalStats.totalTrades) +
      " (W:" + IntegerToString(totalStats.winTrades) +
      " L:" + IntegerToString(totalStats.lossTrades) + ")");

   ObjectSetString(0, panelPrefix + "TotalWinRate", OBJPROP_TEXT,
      "Win Rate: " + DoubleToString(totalStats.winRate, 1) + "%");
   ObjectSetInteger(0, panelPrefix + "TotalWinRate", OBJPROP_COLOR,
      totalStats.winRate >= 50 ? PanelProfitColor : PanelLossColor);

   ObjectSetString(0, panelPrefix + "TotalProfit", OBJPROP_TEXT,
      "Net Profit: $" + DoubleToString(totalStats.netProfit, 2));
   ObjectSetInteger(0, panelPrefix + "TotalProfit", OBJPROP_COLOR,
      totalStats.netProfit >= 0 ? PanelProfitColor : PanelLossColor);

   ObjectSetString(0, panelPrefix + "TotalPF", OBJPROP_TEXT,
      "Profit Factor: " + DoubleToString(totalStats.profitFactor, 2));
   ObjectSetInteger(0, panelPrefix + "TotalPF", OBJPROP_COLOR,
      totalStats.profitFactor >= 1 ? PanelProfitColor : PanelLossColor);

   ObjectSetString(0, panelPrefix + "TotalDD", OBJPROP_TEXT,
      "Max Drawdown: $" + DoubleToString(totalStats.maxDrawdown, 2));

   ObjectSetString(0, panelPrefix + "TotalBest", OBJPROP_TEXT,
      "Best Trade: $" + DoubleToString(totalStats.bestTrade, 2));

   ObjectSetString(0, panelPrefix + "TotalWorst", OBJPROP_TEXT,
      "Worst Trade: $" + DoubleToString(totalStats.worstTrade, 2));

   ObjectSetString(0, panelPrefix + "ConsecWins", OBJPROP_TEXT,
      "Max Consec Wins: " + IntegerToString(totalStats.maxConsecutiveWins));

   ObjectSetString(0, panelPrefix + "ConsecLoss", OBJPROP_TEXT,
      "Max Consec Loss: " + IntegerToString(totalStats.maxConsecutiveLosses));

   // Account Info
   ObjectSetString(0, panelPrefix + "Balance", OBJPROP_TEXT,
      "Balance: $" + DoubleToString(AccountBalance(), 2));

   ObjectSetString(0, panelPrefix + "Equity", OBJPROP_TEXT,
      "Equity: $" + DoubleToString(AccountEquity(), 2));
   ObjectSetInteger(0, panelPrefix + "Equity", OBJPROP_COLOR,
      AccountEquity() >= AccountBalance() ? PanelProfitColor : PanelLossColor);

   // Open trades and floating P/L
   int openTrades = 0;
   double floatingPL = 0;
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderMagicNumber() != MagicNumber) continue;
      if(OrderSymbol() != Symbol()) continue;
      if(OrderType() > OP_SELL) continue;

      openTrades++;
      floatingPL += OrderProfit() + OrderSwap() + OrderCommission();
   }

   ObjectSetString(0, panelPrefix + "OpenTrades", OBJPROP_TEXT,
      "Open Trades: " + IntegerToString(openTrades));

   ObjectSetString(0, panelPrefix + "FloatingPL", OBJPROP_TEXT,
      "Floating P/L: $" + DoubleToString(floatingPL, 2));
   ObjectSetInteger(0, panelPrefix + "FloatingPL", OBJPROP_COLOR,
      floatingPL >= 0 ? PanelProfitColor : PanelLossColor);

   ChartRedraw();
}

// Delete Panel
void DeletePanel()
{
   int totalObjects = ObjectsTotal(0);
   for(int i = totalObjects - 1; i >= 0; i--)
   {
      string objName = ObjectName(0, i);
      if(StringFind(objName, panelPrefix) == 0)
      {
         ObjectDelete(0, objName);
      }
   }
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
      ResetStatistics(dailyStats);
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
