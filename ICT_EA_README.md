# 🎯 ICT FVG Expert Advisor - Quick Start Guide

## 📖 Cos'è questo EA?

Un **Expert Advisor per MetaTrader 4** che implementa la strategia **ICT (Inner Circle Trader)** basata su:

- ✅ **Fair Value Gaps (FVG)** - Zone di inefficienza del mercato
- ✅ **Order Blocks (OB)** - Livelli istituzionali Smart Money
- ✅ **Market Structure** - Trend analysis con Higher Highs/Lower Lows
- ✅ **Killzone Timing** - Trading nelle sessioni Londra e New York
- ✅ **Risk Management** - Stop Loss e Take Profit automatici
- ✅ **Trailing Stop** - Protezione automatica dei profitti

---

## 🚀 Installazione Rapida (3 passi)

### 1️⃣ Copia il file
```
MetaTrader 4 → File → Apri Cartella Dati → MQL4/Experts/
Copia qui: ICT_FVG_EA.mq4
```

### 2️⃣ Compila
```
Apri MetaEditor (F4) → Trova ICT_FVG_EA.mq4 → Compila (F7)
```

### 3️⃣ Attiva sul grafico
```
Trascina l'EA sul grafico → Spunta "Consenti trading automatico" → OK
Verifica la faccina verde nell'angolo del grafico ✅
```

---

## ⚙️ Setup Consigliato per Iniziare

**Coppia**: EUR/USD
**Timeframe**: H1
**Preset**: BALANCED (vedi file `ICT_EA_PRESETS.txt`)

```
RiskPercentage = 1.0%
RiskRewardRatio = 2.0
MaxTradesPerDay = 2
UseKillzoneFilter = true
```

---

## 📊 Strategia in Breve

### BUY (Long):
1. Market Structure = Uptrend ↗️
2. Si forma Fair Value Gap bullish 📈
3. Prezzo ritorna sul FVG/Order Block
4. Siamo in Killzone (Londra/NY) ⏰
5. **→ APRE BUY**

### SELL (Short):
1. Market Structure = Downtrend ↘️
2. Si forma Fair Value Gap bearish 📉
3. Prezzo ritorna sul FVG/Order Block
4. Siamo in Killzone (Londra/NY) ⏰
5. **→ APRE SELL**

---

## 📁 File Inclusi

| File | Descrizione |
|------|-------------|
| `ICT_FVG_EA.mq4` | 🤖 Expert Advisor principale |
| `ICT_EA_DOCUMENTATION.md` | 📚 Documentazione completa (leggi!) |
| `ICT_EA_PRESETS.txt` | ⚙️ 7 preset configurazioni pronte |
| `ICT_EA_README.md` | 📖 Questa guida rapida |

---

## 💡 Migliori Pratiche

### ✅ DA FARE:
- ✅ **Testa su DEMO per almeno 1 mese**
- ✅ Usa broker ECN con spread bassi (< 1 pip EUR/USD)
- ✅ Rischia MAX 1-2% per trade
- ✅ Backtesta su 6-12 mesi di dati
- ✅ Usa VPS per evitare disconnessioni

### ❌ NON FARE:
- ❌ **MAI usare su live senza testare**
- ❌ Non tradare durante news (NFP, FOMC)
- ❌ Non modificare parametri dopo ogni perdita
- ❌ Non rischiare più del 2% per trade
- ❌ Non usare su timeframe < M15 se sei principiante

---

## 🎯 Preset Rapidi

| Setup | Risk | RR | Timeframe | Trade/Mese |
|-------|------|-----|-----------|------------|
| **Conservative** 🛡️ | 0.5% | 1:3 | H4 | 4-8 |
| **Balanced** ⚖️ | 1.0% | 1:2 | H1 | 10-20 |
| **Aggressive** 🚀 | 2.0% | 1:1.5 | M15 | 30-60 |

➡️ **Consiglio**: Inizia con **Balanced** su EUR/USD H1

Dettagli completi in `ICT_EA_PRESETS.txt`

---

## 🔧 Risoluzione Problemi

**L'EA non apre trade?**
- ✅ Verifica AutoTrading attivo (icona verde)
- ✅ Controlla di essere in Killzone
- ✅ Verifica MaxTradesPerDay non raggiunto
- ✅ Leggi il log (tab "Experts" in basso)

**Errori comuni:**
- `Trade context busy` → Chiudi altri EA/script
- `Not enough money` → Riduci RiskPercentage

---

## 📈 Metriche Target

**Backtest Performance**:
- ✅ Profit Factor: >= 1.5
- ✅ Win Rate: >= 40% (con RR 1:2)
- ✅ Max Drawdown: < 20%
- ✅ Total Trades: >= 50 (dati significativi)

---

## ⏰ Killzone (Orari CET)

- 🇬🇧 **London**: 08:00 - 11:00
- 🇺🇸 **New York**: 13:00 - 16:00

💡 In questi orari c'è più liquidità e volatilità

---

## 📚 Vuoi Saperne di Più?

Leggi la **documentazione completa**: `ICT_EA_DOCUMENTATION.md`

Include:
- Spiegazione dettagliata della strategia ICT
- Parametri configurabili (tutti)
- Guida al backtesting
- 7 preset ottimizzati
- Troubleshooting avanzato

---

## ⚠️ Disclaimer

⚠️ Il trading forex comporta **rischi elevati**
⚠️ Non investire denaro che non puoi permetterti di perdere
⚠️ Performance passate ≠ risultati futuri
⚠️ Testa SEMPRE su demo prima di live

---

## 🎓 Coppie Consigliate

| Coppia | Rating | Note |
|--------|--------|------|
| EUR/USD | ⭐⭐⭐⭐⭐ | Ottima - Spread bassissimo |
| GBP/USD | ⭐⭐⭐⭐ | Ottima - Movimenti forti |
| USD/JPY | ⭐⭐⭐⭐ | Ottima - Bassa volatilità |
| AUD/USD | ⭐⭐⭐ | Buona - Spread accettabile |

---

## 🎉 Pronto per Iniziare?

1. ✅ Installa l'EA su MT4
2. ✅ Scegli preset **Balanced**
3. ✅ Apri grafico EUR/USD H1
4. ✅ Attiva l'EA
5. ✅ Testa su **DEMO** per 1 mese
6. ✅ Analizza risultati
7. ✅ Se profittevole → Passa a live con capitale ridotto

---

## 📞 Hai Domande?

Controlla i log MT4: `File → Apri Cartella Dati → MQL4/Logs`

Ogni trade viene registrato con dettagli completi.

---

## 🏆 Buon Trading!

**Ricorda**: La disciplina è più importante della strategia! 💪

Segui il piano, gestisci il rischio, sii paziente. 🚀

---

*Version 1.00 | Gennaio 2026*
