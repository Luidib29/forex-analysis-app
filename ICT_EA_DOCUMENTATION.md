# 📊 ICT FVG Expert Advisor - Documentazione Completa

## 🎯 Panoramica

Questo Expert Advisor implementa una strategia **ICT (Inner Circle Trader)** basata su:
- **Fair Value Gaps (FVG)** - Zone di inefficienza del mercato
- **Order Blocks (OB)** - Livelli istituzionali di supporto/resistenza
- **Market Structure** - Analisi di trend tramite Higher Highs/Lower Lows
- **Killzone Timing** - Trading nelle sessioni di Londra e New York

---

## 📥 Installazione

### 1. Copiare il file EA
1. Aprire MetaTrader 4
2. Andare su **File → Apri Cartella Dati**
3. Navigare in: `MQL4/Experts/`
4. Copiare il file `ICT_FVG_EA.mq4` in questa cartella

### 2. Compilare l'EA
1. In MT4, aprire **MetaEditor** (tasto F4 o icona nella toolbar)
2. Nel navigatore, trovare `ICT_FVG_EA.mq4` sotto `Experts`
3. Fare doppio click per aprirlo
4. Cliccare su **Compila** (F7) o icona compila
5. Verificare che non ci siano errori nella finestra "Toolbox"

### 3. Attivare l'EA sul grafico
1. Trascinare l'EA dal **Navigator** sul grafico desiderato
2. Nella finestra che si apre:
   - Tab **Comune**: spuntare "Consenti trading automatico"
   - Tab **Input**: configurare i parametri (vedi sotto)
   - Cliccare **OK**
3. Verificare che appaia la faccina sorridente nell'angolo del grafico

---

## ⚙️ Parametri Configurabili

### 🛡️ RISK MANAGEMENT

| Parametro | Default | Descrizione |
|-----------|---------|-------------|
| **RiskPercentage** | 1.0 | Rischio per trade (% del capitale). Es: 1.0 = rischia 1% del saldo per trade |
| **RiskRewardRatio** | 2.0 | Rapporto Rischio:Ricompensa. 2.0 = target a 2x lo stop loss |
| **UseTrailingStop** | true | Attiva trailing stop per proteggere profitti |
| **TrailingStopPips** | 20 | Distanza del trailing stop in pips |

**💡 Consiglio**: Non superare 2% di rischio per trade. Per account piccoli usare 0.5-1%

---

### 📈 STRATEGY SETTINGS

| Parametro | Default | Descrizione |
|-----------|---------|-------------|
| **FVG_MinPips** | 5 | Dimensione minima FVG in pips per essere valido |
| **OB_Lookback** | 20 | Quante candele indietro cercare Order Blocks |
| **MS_SwingBars** | 10 | Numero barre per identificare swing high/low |

**💡 Consiglio**:
- Timeframe alti (H4/D1): aumentare FVG_MinPips a 10-15
- Timeframe bassi (M15/H1): mantenere FVG_MinPips a 5

---

### ⏰ KILLZONE TIMING

| Parametro | Default | Descrizione |
|-----------|---------|-------------|
| **UseKillzoneFilter** | true | Attiva filtro orario (solo Londra/NY) |
| **LondonOpen** | 8 | Inizio sessione Londra (ore CET) |
| **LondonClose** | 11 | Fine sessione Londra (ore CET) |
| **NewYorkOpen** | 13 | Inizio sessione New York (ore CET) |
| **NewYorkClose** | 16 | Fine sessione New York (ore CET) |

**💡 Consiglio**:
- Killzone = orari con più liquidità e movimenti forti
- Se disattivi il filtro (false), l'EA tradirà H24

**Orari Killzone (CET - Central European Time):**
- 🇬🇧 London Killzone: 08:00 - 11:00
- 🇺🇸 New York Killzone: 13:00 - 16:00

---

### 🎯 TRADE MANAGEMENT

| Parametro | Default | Descrizione |
|-----------|---------|-------------|
| **MagicNumber** | 12345 | Numero identificativo per gli ordini dell'EA |
| **MaxTradesPerDay** | 2 | Massimo numero trade al giorno (evita overtrading) |
| **MinRiskReward** | 1.5 | RR minimo per entrare a mercato |

**💡 Consiglio**:
- MaxTradesPerDay = 1-2 per strategia di qualità (non quantità)
- MinRiskReward almeno 1.5 per essere profittevoli nel lungo periodo

---

### 📊 TIMEFRAME

| Parametro | Default | Descrizione |
|-----------|---------|-------------|
| **Timeframe** | PERIOD_H1 | Timeframe di analisi (H1, H4, D1, ecc.) |

**💡 Consiglio**:
- **H1** (default): bilanciato tra segnali e affidabilità
- **H4**: più affidabile, meno segnali
- **D1**: massima affidabilità, pochi trade
- **M15**: più segnali ma più rumore (solo per esperti)

---

## 🔄 Come Funziona la Strategia

### 1️⃣ **Rilevamento Fair Value Gap (FVG)**

Un FVG si forma quando c'è un "gap" tra 3 candele consecutive:

**FVG Bullish** (segnale BUY potenziale):
```
Candela 3: High molto basso
Candela 2: Gap
Candela 1: Low molto alto
= Il prezzo è "saltato", lasciando una zona non tradatta
```

**FVG Bearish** (segnale SELL potenziale):
```
Candela 3: Low molto alto
Candela 2: Gap
Candela 1: High molto basso
```

💡 **Logica ICT**: Il mercato tende a ritornare per "riempire" questi gap (inefficienze)

---

### 2️⃣ **Rilevamento Order Block (OB)**

Un Order Block è l'ultima candela prima di un forte movimento:

**Order Block Bullish**:
- Ultima candela ribassista prima di una forte salita
- Zone dove le istituzioni hanno piazzato ordini BUY

**Order Block Bearish**:
- Ultima candela rialzista prima di una forte discesa
- Zone dove le istituzioni hanno piazzato ordini SELL

💡 **Logica ICT**: Quando il prezzo ritorna su queste zone, lo Smart Money entra di nuovo

---

### 3️⃣ **Analisi Market Structure**

L'EA identifica il trend analizzando swing highs e lows:

**Uptrend** (segnali BUY):
- Higher Highs (HH): ogni massimo supera il precedente
- Higher Lows (HL): ogni minimo supera il precedente

**Downtrend** (segnali SELL):
- Lower Highs (LH): ogni massimo è inferiore al precedente
- Lower Lows (LL): ogni minimo è inferiore al precedente

💡 **Regola d'oro**: Compra solo in uptrend, vendi solo in downtrend

---

### 4️⃣ **Segnali di Entrata**

#### 📈 LONG (BUY):
1. ✅ Market Structure = Uptrend (HH/HL)
2. ✅ Si è formato un FVG bullish
3. ✅ Prezzo ritorna sul FVG o Order Block bullish
4. ✅ (Opzionale) Siamo in Killzone Londra/NY
5. ✅ Risk:Reward >= 1.5

➡️ **APRE BUY**

**Stop Loss**: Sotto l'Order Block o FVG + buffer 10 pips
**Take Profit**: 2x lo stop loss (RR 1:2)

---

#### 📉 SHORT (SELL):
1. ✅ Market Structure = Downtrend (LH/LL)
2. ✅ Si è formato un FVG bearish
3. ✅ Prezzo ritorna sul FVG o Order Block bearish
4. ✅ (Opzionale) Siamo in Killzone Londra/NY
5. ✅ Risk:Reward >= 1.5

➡️ **APRE SELL**

**Stop Loss**: Sopra l'Order Block o FVG + buffer 10 pips
**Take Profit**: 2x lo stop loss (RR 1:2)

---

## 📊 Indicatori Visivi sul Grafico

L'EA disegna automaticamente sul grafico:

- 🟢 **Rettangoli VERDI**: Fair Value Gap bullish
- 🔴 **Rettangoli ROSSI**: Fair Value Gap bearish

I rettangoli mostrano le zone dove il prezzo potrebbe ritornare per entry.

---

## 🚀 Setup Consigliati

### Setup Conservativo (Basso Rischio)
```
RiskPercentage = 0.5%
RiskRewardRatio = 3.0
MaxTradesPerDay = 1
Timeframe = H4 o D1
UseKillzoneFilter = true
```
✅ Pro: Massima sicurezza, meno drawdown
❌ Contro: Pochi trade, crescita lenta

---

### Setup Bilanciato (Default)
```
RiskPercentage = 1.0%
RiskRewardRatio = 2.0
MaxTradesPerDay = 2
Timeframe = H1
UseKillzoneFilter = true
```
✅ Pro: Buon equilibrio rischio/rendimento
✅ Consigliato per iniziare

---

### Setup Aggressivo (Alto Rischio)
```
RiskPercentage = 2.0%
RiskRewardRatio = 1.5
MaxTradesPerDay = 3
Timeframe = M15
UseKillzoneFilter = false
```
✅ Pro: Più trade, crescita rapida
❌ Contro: Rischio alto, drawdown elevato

⚠️ **ATTENZIONE**: Setup aggressivo solo per trader esperti!

---

## 🎓 Migliori Coppie Forex

Consigliato su coppie majors con spread basso:

| Coppia | Spread | Raccomandazione |
|--------|--------|-----------------|
| **EUR/USD** | ⭐⭐⭐⭐⭐ | Ottima - Spread bassissimo, alta liquidità |
| **GBP/USD** | ⭐⭐⭐⭐ | Ottima - Movimenti forti nelle Killzone |
| **USD/JPY** | ⭐⭐⭐⭐ | Ottima - Buona per sessione asiatica |
| **AUD/USD** | ⭐⭐⭐ | Buona - Spread accettabile |
| **USD/CHF** | ⭐⭐⭐ | Buona - Bassa volatilità |
| **EUR/GBP** | ⭐⭐ | Media - Spread più alto |

💡 **Consiglio**: Inizia con EUR/USD o GBP/USD per testare

---

## 🔍 Backtesting

### Come fare Backtest su MT4:

1. **Aprire Strategy Tester** (Ctrl + R)
2. Selezionare:
   - Expert Advisor: `ICT_FVG_EA`
   - Symbol: `EURUSD` (o altra coppia)
   - Period: `H1` (o il tuo timeframe)
   - Date: Almeno 6-12 mesi di dati
   - Model: `Every tick` (più preciso)
3. Cliccare su **Input** per configurare parametri
4. Cliccare **Start**

### Metriche da Analizzare:

- ✅ **Profit Factor** >= 1.5 (buono), >= 2.0 (eccellente)
- ✅ **Drawdown Max** < 20% (accettabile), < 10% (ottimo)
- ✅ **Win Rate** >= 40% (con RR 1:2)
- ✅ **Total Trades** >= 50 (dati significativi)

---

## ⚠️ Avvertenze e Best Practices

### ✅ DO (Fai):
- ✅ Testa SEMPRE su demo prima di usare denaro reale
- ✅ Usa broker ECN con spread bassi
- ✅ Backtesta su almeno 6-12 mesi
- ✅ Monitora regolarmente le performance
- ✅ Usa VPS per evitare interruzioni
- ✅ Rischia max 1-2% per trade

### ❌ DON'T (Non fare):
- ❌ NON usare su account reale senza testare
- ❌ NON aumentare il rischio oltre il 2% per trade
- ❌ NON tradare durante news ad alto impatto (NFP, FOMC, ecc.)
- ❌ NON modificare parametri dopo ogni trade perdente
- ❌ NON usare su broker con spread alti (> 2 pips EUR/USD)
- ❌ NON tradare su timeframe < M15 senza esperienza

---

## 🔧 Risoluzione Problemi

### L'EA non apre trade

**Possibili cause**:
1. ✅ Verifica che "AutoTrading" sia attivo (icona verde in alto)
2. ✅ Controlla che siamo in Killzone (se filtro attivo)
3. ✅ Verifica che non siano stati già aperti MaxTradesPerDay
4. ✅ Controlla il log per errori (tab "Experts" in basso)
5. ✅ Assicurati che ci sia un FVG + trend valido

### Errore "Trade context is busy"

**Soluzione**:
- Chiudi altri EA/script in esecuzione
- Riavvia MT4

### Errore "Not enough money"

**Soluzione**:
- Riduci `RiskPercentage`
- Aumenta il saldo del conto
- Verifica che il broker consenta lotti minimi (0.01)

### L'EA non disegna FVG sul grafico

**Soluzione**:
- L'EA disegna solo FVG recenti validi
- Aspetta che si formi un FVG (serve gap minimo di 5 pips)
- Verifica che il grafico non sia bloccato

---

## 📈 Monitoraggio Performance

### Cosa controllare giornalmente:
- Numero trade aperti oggi
- Profitto/perdita totale
- Drawdown attuale vs massimo storico

### Cosa controllare settimanalmente:
- Win Rate % (target >= 40%)
- Profit Factor (target >= 1.5)
- Average RR dei trade chiusi

### Quando fermare l'EA:
- ⛔ Drawdown > 20%
- ⛔ Più di 5 trade perdenti consecutivi
- ⛔ Durante news ad alto impatto
- ⛔ Se qualcosa non funziona come previsto

---

## 📞 Supporto e Aggiornamenti

### Log Files:
- Tutti i trade sono registrati nel log MT4
- Path: `File → Apri Cartella Dati → MQL4/Logs`

### Versione:
- **Current Version**: 1.00
- **Release Date**: Gennaio 2026

---

## 📚 Risorse Aggiuntive ICT

Per approfondire i concetti ICT:
- **Order Blocks**: Cerca "ICT Order Blocks tutorial"
- **Fair Value Gaps**: Cerca "ICT FVG trading strategy"
- **Market Structure**: Cerca "ICT Break of Structure (BOS)"
- **Killzones**: Cerca "ICT London/NY Killzone"

---

## ⚖️ Disclaimer

⚠️ **IMPORTANTE**:
- Il trading forex comporta rischi elevati
- Non investire denaro che non puoi permetterti di perdere
- Le performance passate non garantiscono risultati futuri
- Questo EA è fornito "as-is" senza garanzie
- Testa sempre su demo prima di usare denaro reale

---

## 🎉 Buon Trading!

Hai domande o problemi? Controlla i log MT4 per dettagli tecnici.

**Ricorda**: La disciplina e il money management sono più importanti della strategia stessa! 💪

---

*Ultimo aggiornamento: Gennaio 2026*
