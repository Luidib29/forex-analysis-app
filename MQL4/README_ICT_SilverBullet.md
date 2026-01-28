# ICT Silver Bullet EA - MetaTrader 4

## Descrizione
Expert Advisor basato sulla strategia ICT Silver Bullet, ottimizzato per XAUUSD (Oro) e XAGUSD (Argento) su conti cent RoboForex.

## Logica di Trading

### Sequenza Entry (5 Step)
1. **BIAS M15** - Determina trend su timeframe 15 minuti
2. **DISPLACEMENT M5** - Candela impulsiva che rompe struttura
3. **FVG CREATION** - Identifica Fair Value Gap creato
4. **RETEST FVG** - Prezzo ritorna nella zona FVG
5. **REJECTION + ENTRY** - Candela di rejection + conferma

### Sessioni di Trading (GMT+1 RoboForex)
| Sessione | Orario | Input |
|----------|--------|-------|
| Asian | 02:00 - 06:00 | `UseAsianSession` |
| London | 09:00 - 15:00 | `UseLondonSession` |
| NY AM | 14:00 - 17:00 | `UseNYAMSession` |
| NY PM | 19:00 - 22:00 | `UseNYPMSession` |

## Installazione

### 1. Copia i File
```
1. Apri MT4
2. File -> Apri Cartella Dati
3. Naviga in: MQL4/Experts/
4. Copia il file ICT_SilverBullet_EA.mq4
```

### 2. Compila l'EA
```
1. Apri MetaEditor (F4 in MT4)
2. Apri il file ICT_SilverBullet_EA.mq4
3. Premi F7 per compilare
4. Verifica che non ci siano errori
```

### 3. Attiva l'EA
```
1. Torna su MT4
2. Aggiorna la lista degli Expert (click destro -> Aggiorna)
3. Trascina l'EA sul grafico XAUUSD o XAGUSD
4. Abilita "Consenti trading automatico"
5. Clicca OK
```

## Parametri Principali

### General Settings
- `MagicNumber`: Identificatore univoco EA (default: 123456)
- `GMT_Offset`: Offset GMT del server (RoboForex = 1)

### Lot Size
- `LotSize_XAU`: 0.60 (per XAUUSD)
- `LotSize_XAG`: 0.40 (per XAGUSD)
- `UseFixedLot`: true = usa lot fissi, false = calcola da Risk%

### Risk Management
- `RiskPercent`: 2.0% del capitale per trade
- `RR_Min`: 2.0 (Risk:Reward minimo 1:2)
- `RR_Max`: 2.5 (Risk:Reward massimo 1:2.5)

### Sessions
- `UseAsianSession`: true/false
- `UseLondonSession`: true/false
- `UseNYAMSession`: true/false
- `UseNYPMSession`: true/false

### Displacement (sensibilità)
- `Displacement_ATR_XAU`: 2.0 (XAU più volatile)
- `Displacement_ATR_XAG`: 1.5 (XAG meno volatile)

### SL/TP Dinamici
- `SL_ATR_Multi_XAU`: 1.5x ATR
- `SL_ATR_Multi_XAG`: 1.2x ATR
- `MinSL_Points_XAU`: 500 points (50 pips)
- `MaxSL_Points_XAU`: 3000 points (300 pips)

### Trade Management
- `MaxTradesPerSession`: 4
- `MaxTradesPerDay`: 10
- `MaxSpread_XAU`: 50 points
- `MaxSpread_XAG`: 30 points

## Configurazione Consigliata per Conto Cent

### XAUUSD
```
LotSize_XAU = 0.60
Displacement_ATR_XAU = 2.0
SL_ATR_Multi_XAU = 1.5
MaxSpread_XAU = 50
```

### XAGUSD
```
LotSize_XAG = 0.40
Displacement_ATR_XAG = 1.5
SL_ATR_Multi_XAG = 1.2
MaxSpread_XAG = 30
```

## Funzionalità

### Pannello Statistiche (NUOVO v2.0)
Pannello grafico in tempo reale con statistiche complete:

**Stato Corrente:**
- Simbolo attivo
- Sessione corrente (Asian/London/NY AM/NY PM)
- Bias M15 (Bullish/Bearish/None)
- Stato FVG (None/BULL/BEAR + [MIT]/[REJ])
- Spread corrente

**Statistiche Giornaliere (TODAY):**
- Trades totali (Win/Loss)
- Win Rate %
- Profit netto $
- Profit Factor
- Best/Worst trade

**Statistiche Complessive (TOTAL):**
- Trades totali storici
- Win Rate % complessivo
- Net Profit $
- Profit Factor
- Max Drawdown $
- Best/Worst trade storico
- Max Consecutive Wins/Losses

**Info Account:**
- Balance
- Equity (colorato verde/rosso)
- Open Trades
- Floating P/L

**Parametri Pannello:**
- `ShowPanel`: true/false - Mostra/nascondi pannello
- `PanelCorner`: Posizione (Top Left/Right, Bottom Left/Right)
- `PanelX/Y`: Offset posizione
- `PanelBgColor`: Colore sfondo
- `PanelBorderColor`: Colore bordo
- `PanelTitleColor`: Colore titolo
- `PanelTextColor`: Colore testo
- `PanelProfitColor`: Colore profit (default: Lime)
- `PanelLossColor`: Colore loss (default: Red)
- `PanelFontSize`: Dimensione font
- `PanelFontName`: Nome font (default: Consolas)

### Filtro Notizie
L'EA include un filtro base per:
- NFP (Non-Farm Payrolls) - primo venerdì del mese
- FOMC - annunci Fed

Parametri:
- `UseNewsFilter`: true/false
- `NewsMinutesBefore`: 30 minuti prima
- `NewsMinutesAfter`: 30 minuti dopo

### Visualizzazione FVG
L'EA disegna automaticamente le zone FVG sul grafico:
- Verde: FVG Bullish
- Rosso: FVG Bearish

### Log Dettagliati
Tutti gli eventi vengono loggati nella scheda "Esperti":
- Rilevamento FVG
- Mitigazione
- Rejection candle
- Entry/Exit trades

## Note Importanti

1. **Backtest**: Usa dati M1 per backtest accurato
2. **Timeframe**: Applica su grafico M5
3. **Spread**: Verifica che lo spread sia accettabile durante le sessioni
4. **VPS**: Consigliato per trading 24/5

## Troubleshooting

### EA non fa trade
1. Verifica che "Auto Trading" sia abilitato
2. Controlla spread corrente
3. Verifica di essere in una sessione attiva
4. Controlla i log per errori

### Errore 130 (Invalid Stops)
- Lo SL/TP potrebbe essere troppo vicino al prezzo
- Aumenta `MinSL_Points_XAU` o `MinSL_Points_XAG`

### Errore 134 (Not Enough Money)
- Riduci `LotSize_XAU` o `LotSize_XAG`
- Oppure imposta `UseFixedLot = false` per calcolo automatico

## Disclaimer
Questo EA è fornito solo a scopo educativo. Il trading comporta rischi significativi. Testa sempre su conto demo prima di usare su conto reale.

## Versione
- v2.00 - Aggiunto pannello statistiche completo
  - Statistiche giornaliere e complessive
  - Info account in tempo reale
  - Stato FVG e sessione
  - Personalizzazione colori e posizione
- v1.00 - Release iniziale
- Ottimizzato per RoboForex Conto Cent
- GMT+1 Server Time
