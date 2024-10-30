import streamlit as st
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from tiingo import TiingoClient
from datetime import datetime, timedelta

# Configura client Tiingo
config = {}
config['session'] = True
config['api_key'] = st.secrets["e01a41babcd49cf76f97fdc98c6bf944abdd154e"]
client = TiingoClient(config)

# Configurazione pagina
st.set_page_config(
    page_title="Analisi Forex",
    layout="wide"
)

# Titolo dell'app
st.title('📊 Analisi Tecnica Forex')

# Dizionario delle coppie forex
forex_pairs = {
    # Dizionario delle coppie forex
forex_pairs = {
    'EUR/USD': 'eurusd',
    'GBP/USD': 'gbpusd',
    'USD/JPY': 'usdjpy',
    'AUD/USD': 'audusd',
    'USD/CAD': 'usdcad',
    'USD/CHF': 'usdchf',
    'NZD/USD': 'nzdusd',
    'EUR/GBP': 'eurgbp',
    'EUR/JPY': 'eurjpy'
}


# Selezione periodo
periodo = st.selectbox(
    'Seleziona il periodo di analisi (in giorni):',
    [30, 90, 180, 365]
)


def analisi_forex(symbol, pair_name):
    # Scarica i dati da Tiingo
    end_date = datetime.now()
    start_date = end_date - timedelta(days=periodo)
    # Scarica e prepara i dati da Tiingo
df = pd.DataFrame(client.get_forex_price_history(
    symbol,
    startDate=start_date,
    endDate=end_date,
    resampleFreq='1day'
))

# Prepara il DataFrame
df.index = pd.to_datetime(df.index)
df = df.rename(columns={
    'adjClose': 'Close',
    'adjHigh': 'High',
    'adjLow': 'Low',
    'adjOpen': 'Open'
})
    
    # Rinomina le colonne per match con il codice esistente
    df = df.rename(columns={
        'adjClose': 'Close',
        'adjHigh': 'High',
        'adjLow': 'Low',
        'adjOpen': 'Open'
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
    
    for i in range(len(df)):
        rsi = df['RSI'].iloc[i]
        macd = df['MACD'].iloc[i]
        signal = df['Signal'].iloc[i]
        
        if rsi < 35:  # Più sensibile
            if macd > signal:
                df.loc[df.index[i], 'Segnale'] = 'COMPRA'
            else:
                df.loc[df.index[i], 'Segnale'] = 'ATTENDI (RSI ipervenduto ma MACD negativo)'
        elif rsi > 65:  # Più sensibile
            if macd < signal:
                df.loc[df.index[i], 'Segnale'] = 'VENDI'
            else:
                df.loc[df.index[i], 'Segnale'] = 'ATTENDI (RSI ipercomprato ma MACD positivo)'
        else:
            if macd > signal and rsi > 35:
                df.loc[df.index[i], 'Segnale'] = 'COMPRA'
            elif macd < signal and rsi < 65:
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
