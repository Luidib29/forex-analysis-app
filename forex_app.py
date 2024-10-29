import streamlit as st
import pandas as pd
import numpy as np
import yfinance as yf
import matplotlib.pyplot as plt

# Configurazione pagina
st.set_page_config(
    page_title="Analisi Forex",
    layout="wide"
)

# Titolo dell'app
st.title('📊 Analisi Tecnica Forex')


    # Dizionario delle coppie forex
forex_pairs = {
    'EUR/USD': 'EURUSD=X',
    'GBP/USD': 'GBPUSD=X',
    'USD/JPY': 'USDJPY=X',
    'AUD/USD': 'AUDUSD=X',
    'USD/CAD': 'USDCAD=X',
    'USD/CHF': 'USDCHF=X',
    'NZD/USD': 'NZDUSD=X',
    'EUR/GBP': 'EURGBP=X',
    'EUR/JPY': 'EURJPY=X'
}


# Selezione periodo
periodo = st.selectbox(
    'Seleziona il periodo di analisi:',
    ['1mo', '3mo', '6mo', '1y']
)

# Funzione di analisi (il tuo codice esistente)
def analisi_forex(symbol, pair_name):
    # Scarica i dati
    df = yf.download(symbol, period=periodo)
    
    # Estrai solo le colonne necessarie
    df = pd.DataFrame({
        'Close': df[('Close', symbol)],
        'High': df[('High', symbol)],
        'Low': df[('Low', symbol)],
        'Open': df[('Open', symbol)]
    })
    
    # Calcola le medie mobili
    df['MA20'] = df['Close'].rolling(window=20).mean()
    df['MA50'] = df['Close'].rolling(window=50).mean()
    
    # Calcola il RSI
    def calcola_rsi(data, periodi=14):
        delta = data['Close'].diff()
        gain = (delta.where(delta > 0, 0)).rolling(window=periodi).mean()
        loss = (-delta.where(delta < 0, 0)).rolling(window=periodi).mean()
        rs = gain / loss
        return 100 - (100 / (1 + rs))
    
    df['RSI'] = calcola_rsi(df)
    # Calcola il MACD
    df['EMA12'] = df['Close'].ewm(span=12, adjust=False).mean()
    df['EMA26'] = df['Close'].ewm(span=26, adjust=False).mean()
    df['MACD'] = df['EMA12'] - df['EMA26']
    df['Signal'] = df['MACD'].ewm(span=9, adjust=False).mean()
    df['MACD_Hist'] = df['MACD'] - df['Signal']
    
    # Logica dei segnali
    df['Segnale'] = 'ATTENDI'
    
    # Logica dei segnali
    df['Segnale'] = 'ATTENDI'
    
    for i in range(len(df)):
        rsi = df['RSI'].iloc[i]
        macd = df['MACD'].iloc[i]
        signal = df['Signal'].iloc[i]
        
        if rsi < 35:  # Aumentato da 30
            if macd > signal:
                df.loc[df.index[i], 'Segnale'] = 'COMPRA'
            else:
                df.loc[df.index[i], 'Segnale'] = 'ATTENDI (RSI ipervenduto ma MACD negativo)'
        elif rsi > 65:  # Diminuito da 70
            if macd < signal:
                df.loc[df.index[i], 'Segnale'] = 'VENDI'
            else:
                df.loc[df.index[i], 'Segnale'] = 'ATTENDI (RSI ipercomprato ma MACD positivo)'
        else:
            if macd > signal and rsi > 35:  # Diminuito da 40
                df.loc[df.index[i], 'Segnale'] = 'COMPRA'
            elif macd < signal and rsi < 65:  # Aumentato da 60
                df.loc[df.index[i], 'Segnale'] = 'VENDI'
            else:
                df.loc[df.index[i], 'Segnale'] = 'ATTENDI'
    
    return df
    # Analisi per ogni coppia
for pair_name, symbol in forex_pairs.items():
    st.header(f'Analisi {pair_name}')
    
    df = analisi_forex(symbol, pair_name)
    
    # Crea i grafici
    fig, (ax1, ax2, ax3) = plt.subplots(3, 1, figsize=(12,12))
    
    # Grafico superiore con prezzo e medie mobili
    ax1.plot(df.index, df['Close'], label=pair_name)
    ax1.plot(df.index, df['MA20'], label='MA20')
    ax1.plot(df.index, df['MA50'], label='MA50')
    ax1.set_title('Prezzo e Medie Mobili')
    ax1.legend()
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
