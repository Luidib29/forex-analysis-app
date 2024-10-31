import streamlit as st
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from datetime import datetime, timedelta
from tiingo import TiingoClient

# Configurazione pagina
st.set_page_config(
    page_title="Analisi Forex",
    layout="wide"
)

# Configura client Tiingo
config = {
    'session': True,
    'api_key': 'e01a41babcd49cf76f97fdc98c6bf944abdd154e'
}
client = TiingoClient(config)

# Titolo dell'app
st.title('📊 Analisi Tecnica Forex')

# Dizionario delle coppie forex
forex_pairs = {
    'EUR/USD': 'EURUSD',
    'GBP/USD': 'GBPUSD',
    'USD/JPY': 'USDJPY',
    'AUD/USD': 'AUDUSD',
    'USD/CAD': 'USDCAD',
    'USD/CHF': 'USDCHF',
    'NZD/USD': 'NZDUSD',
    'EUR/GBP': 'EURGBP',
    'EUR/JPY': 'EURJPY'
}

# Selezione periodo
periodo = st.selectbox(
    'Seleziona il periodo di analisi (in giorni):',
    [30, 90, 180, 365]
)

def analisi_forex(symbol, pair_name):
    # Scarica i dati
    end_date = datetime.now()
    start_date = end_date - timedelta(days=periodo)
    
    # Scarica i dati usando l'API Tiingo
    try:
        data = client.get_dataframe(
            symbol,
            frequency='daily',
            startDate=start_date,
            endDate=end_date
        )
        
        # Rinomina le colonne
        df = pd.DataFrame({
            'Close': data['close'],
            'High': data['high'],
            'Low': data['low'],
            'Open': data['open']
        })
        
    except Exception as e:
        st.error(f"Errore nel download dei dati per {pair_name}: {str(e)}")
        return None
    
    # Calcola le medie mobili
    df['MA20'] = df['Close'].rolling(window=20).mean()
    df['MA50'] = df['Close'].rolling(window=50).mean()
    
    # Calcola il RSI
    delta = df['Close'].diff()
    gain = (delta.where(delta > 0, 0)).rolling(window=14).mean()
    loss = (-delta.where(delta < 0, 0)).rolling(window=14).mean()
    rs = gain / loss
    df['RSI'] = 100 - (100 / (1 + rs))
    
    # Calcolo Pivot Points Fibonacci
    df['PP'] = (df['High'].shift(1) + df['Low'].shift(1) + df['Close'].shift(1)) / 3
    daily_range = df['High'].shift(1) - df['Low'].shift(1)
    
    # Livelli Fibonacci
    df['R1'] = df['PP'] + (0.382 * daily_range)
    df['R2'] = df['PP'] + (0.618 * daily_range)
    df['R3'] = df['PP'] + (1.000 * daily_range)
    df['S1'] = df['PP'] - (0.382 * daily_range)
    df['S2'] = df['PP'] - (0.618 * daily_range)
    df['S3'] = df['PP'] - (1.000 * daily_range)
    
    # Calcola il MACD
    df['EMA12'] = df['Close'].ewm(span=12, adjust=False).mean()
    df['EMA26'] = df['Close'].ewm(span=26, adjust=False).mean()
    df['MACD'] = df['EMA12'] - df['EMA26']
    df['Signal'] = df['MACD'].ewm(span=9, adjust=False).mean()
    df['MACD_Hist'] = df['MACD'] - df['Signal']
    
    # Logica dei segnali
    df['Segnale'] = 'ATTENDI'
    
    for i in range(len(df)):
        rsi = df['RSI'].iloc[i]
        macd = df['MACD'].iloc[i]
        signal = df['Signal'].iloc[i]
        prezzo = df['Close'].iloc[i]
        s1 = df['S1'].iloc[i]
        r1 = df['R1'].iloc[i]
        
        if (rsi < 35 and (prezzo <= s1)):
            if macd > signal:
                df.loc[df.index[i], 'Segnale'] = 'COMPRA (Supporto Fib)'
            else:
                df.loc[df.index[i], 'Segnale'] = 'ATTENDI (RSI + Fib favorevoli, MACD non conferma)'
        elif (rsi > 65 and (prezzo >= r1)):
            if macd < signal:
                df.loc[df.index[i], 'Segnale'] = 'VENDI (Resistenza Fib)'
            else:
                df.loc[df.index[i], 'Segnale'] = 'ATTENDI (RSI + Fib favorevoli, MACD non conferma)'
        else:
            if macd > signal and rsi > 35 and prezzo > s1:
                df.loc[df.index[i], 'Segnale'] = 'COMPRA (Trend + Fib)'
            elif macd < signal and rsi < 65 and prezzo < r1:
                df.loc[df.index[i], 'Segnale'] = 'VENDI (Trend + Fib)'
            else:
                df.loc[df.index[i], 'Segnale'] = 'ATTENDI'
    
    return df

# Analisi per ogni coppia
for pair_name, symbol in forex_pairs.items():
    st.header(f'Analisi {pair_name}')
    
    df = analisi_forex(symbol, pair_name)
    if df is None:
        continue
        
    # Crea i grafici
    fig, (ax1, ax2, ax3) = plt.subplots(3, 1, figsize=(12,12))
    
    # Grafico superiore con prezzo e medie mobili
    ax1.plot(df.index, df['Close'], label=pair_name, color='blue')
    ax1.plot(df.index, df['MA20'], label='MA20', linewidth=1, alpha=0.7)
    ax1.plot(df.index, df['MA50'], label='MA50', linewidth=1, alpha=0.7)
    
    # Aggiungi livelli Fibonacci
    ax1.plot(df.index, df['R1'], '--', label='R1 (0.382)', color='red', alpha=0.5)
    ax1.plot(df.index, df['R2'], '--', label='R2 (0.618)', color='red', alpha=0.3)
    ax1.plot(df.index, df['PP'], '-', label='Pivot', color='purple', alpha=0.5)
    ax1.plot(df.index, df['S1'], '--', label='S1 (-0.382)', color='green', alpha=0.5)
    ax1.plot(df.index, df['S2'], '--', label='S2 (-0.618)', color='green', alpha=0.3)
    
    ax1.set_title('Prezzo con Medie Mobili e Livelli Fibonacci')
    ax1.legend(loc='upper left', bbox_to_anchor=(1.05, 1))
    ax1.grid(True)
    
    # Grafico centrale con RSI
    ax2.plot(df.index, df['RSI'], color='purple')
    ax2.axhline(y=70, color='r', linestyle='--')
    ax2.axhline(y=30, color='g', linestyle='--')
    ax2.set_title('RSI (14)')
    ax2.grid(True)
    
    # Grafico inferiore con MACD
    ax3.plot(df.index, df['MACD'], label='MACD')
    ax3.plot(df.index, df['Signal'], label='Signal')
    ax3.bar(df.index, df['MACD_Hist'], color='gray', alpha=0.3)
    ax3.set_title('MACD')
    ax3.legend()
    ax3.grid(True)
    
    plt.tight_layout()
    st.pyplot(fig)
    
    # Mostra gli ultimi dati
    st.subheader('Ultimi Segnali')
    ultimi_dati = df[['Close', 'RSI', 'MACD', 'Signal', 'Segnale']].tail()
    st.dataframe(ultimi_dati)
    
   # Analisi finale
    ultimo = df.iloc[-1]
    
    col1, col2, col3, col4 = st.columns(4)
    
    with col1:
        st.metric("Trend Breve", "RIALZISTA" if ultimo['Close'] > ultimo['MA20'] else "RIBASSISTA")
    with col2:
        st.metric("RSI", f"{ultimo['RSI']:.2f}")
    with col3:
        st.metric("MACD", f"{ultimo['MACD']:.6f}")
    with col4:
        st.metric("Segnale", ultimo['Segnale'])
# Aggiungi pulsante di refresh
if st.button('Aggiorna Dati'):
    st.rerun()
