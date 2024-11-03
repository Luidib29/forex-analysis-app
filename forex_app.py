# Imports
import streamlit as st
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import mplfinance as mpf
from datetime import datetime, timedelta
from tiingo import TiingoClient
import requests
import re
import json
import os

# Configurazione pagina
st.set_page_config(
    page_title="Pro Forex Analysis",
    page_icon="🇪🇺🇺🇸 🇬🇧🇺🇸 🇺🇸🇯🇵 🇦🇺🇺🇸 🇺🇸🇨🇦 🇺🇸🇨🇭 🇳🇿🇺🇸 🇪🇺🇬🇧 🇪🇺🇯🇵",
    layout="wide",
    initial_sidebar_state="collapsed"
)

# Configura client Tiingo
config = {
    'session': True,
    'api_key': '704089b255ddc2cb8e3b5fd97f6367241505f3ac'
}
client = TiingoClient(config)

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
# Funzioni per il login
def is_valid_email(email):
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return re.match(pattern, email) is not None

def save_user_data(name, email):
    users_file = 'users_data.json'
    try:
        if os.path.exists(users_file):
            with open(users_file, 'r') as f:
                users = json.load(f)
        else:
            users = []
        
        user_data = {
            'name': name,
            'email': email,
            'registration_date': datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        }
        
        # Controlla se l'utente esiste già
        if not any(user['email'] == email for user in users):
            users.append(user_data)
            
            with open(users_file, 'w') as f:
                json.dump(users, f, indent=4)
            return True
        else:
            return 'exists'
    except Exception as e:
        print(f"Errore nel salvataggio: {e}")
        return False

def get_forex_realtime_price(symbol):
    try:
        endpoint = f"https://api.tiingo.com/tiingo/fx/{symbol}/top"
        headers = {
            'Content-Type': 'application/json',
            'Authorization': f'Token {config["api_key"]}'
        }
        response = requests.get(endpoint, headers=headers)
        data = response.json()
        return {
            'midPrice': data[0]['midPrice'],
            'bidPrice': data[0]['bidPrice'],
            'askPrice': data[0]['askPrice'],
            'timestamp': data[0]['quoteTimestamp']
        }
    except Exception as e:
        st.error(f"Errore nel recupero del prezzo realtime: {str(e)}")
        return None

def plot_candlestick(df, pair_name):
    # Prepara i dati per il grafico a candele
    df_mpf = df.copy()
    # Assicuriamoci che l'indice sia il datetime
    if not isinstance(df_mpf.index, pd.DatetimeIndex):
        df_mpf.index = pd.to_datetime(df_mpf.index)
    
    # Configura i colori
    mc = mpf.make_marketcolors(
        up='green',
        down='red',
        edge='inherit',
        wick='inherit',
        volume='in',
        ohlc='inherit'
    )
    
    # Configura lo stile
    s = mpf.make_mpf_style(
        marketcolors=mc,
        gridstyle='--',
        figcolor='white',
        gridcolor='gray'
    )
    
    # Aggiungi le medie mobili
    add_plot = [
        mpf.make_addplot(df['MA20'], color='blue', width=0.8),
        mpf.make_addplot(df['MA50'], color='red', width=0.8)
    ]
    
    try:
        # Crea il grafico senza volume
        fig, axes = mpf.plot(
            df_mpf,
            type='candlestick',
            style=s,
            addplot=add_plot,
            volume=False,  # Cambiato da True a False
            figsize=(12, 8),
            returnfig=True,
            title=f'\n{pair_name} Analisi Tecnica'
        )
        return fig
    except Exception as e:
        st.error(f"Errore nella creazione del grafico: {str(e)}")
        st.write("Colonne disponibili nel DataFrame:", df_mpf.columns.tolist())
        return None

def analisi_forex(symbol, pair_name):
    end_date = datetime.now()
    start_date = end_date - timedelta(days=periodo)
    
    try:
        data = client.get_dataframe(
            symbol,
            frequency='daily',
            startDate=start_date,
            endDate=end_date
        )
        
        # Rinomina le colonne
        df = pd.DataFrame({
            'Open': data['open'],
            'High': data['high'],
            'Low': data['low'],
            'Close': data['close']
        })
        
        # Calcola gli indicatori
        df['MA20'] = df['Close'].rolling(window=20).mean()
        df['MA50'] = df['Close'].rolling(window=50).mean()
        
        # Calcola RSI
        delta = df['Close'].diff()
        gain = (delta.where(delta > 0, 0)).rolling(window=14).mean()
        loss = (-delta.where(delta < 0, 0)).rolling(window=14).mean()
        rs = gain / loss
        df['RSI'] = 100 - (100 / (1 + rs))
        
        # Calcola MACD
        df['EMA12'] = df['Close'].ewm(span=12, adjust=False).mean()
        df['EMA26'] = df['Close'].ewm(span=26, adjust=False).mean()
        df['MACD'] = df['EMA12'] - df['EMA26']
        df['Signal'] = df['MACD'].ewm(span=9, adjust=False).mean()
        
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
        
    except Exception as e:
        st.error(f"Errore nel download dei dati per {pair_name}: {str(e)}")
        return None
        # Gestione della sessione
if 'logged_in' not in st.session_state:
    st.session_state.logged_in = False

# Pagina di intro
if not st.session_state.logged_in:
    st.markdown("""
        <div style='text-align: center; padding: 2rem;'>
            <h1 style='color: white; font-size: 2.5rem;'>Benvenuto in Pro Forex Analysis</h1>
            <p style='color: #E0E0E0; font-size: 1.2rem; max-width: 800px; margin: 2rem auto;'>
                Un'app professionale per l'analisi tecnica del forex con segnali di trading in tempo reale 
                basati su intelligenza artificiale.
            </p>
        </div>
    """, unsafe_allow_html=True)

    col1, col2 = st.columns(2)
    with col1:
        st.markdown("""
            <div style='background: rgba(255,255,255,0.1); padding: 1rem; border-radius: 10px;'>
                <h3 style='color: white;'>Caratteristiche principali:</h3>
                <ul style='color: #E0E0E0;'>
                    <li>Analisi tecnica in tempo reale</li>
                    <li>Segnali di trading automatici</li>
                    <li>Multiple coppie forex</li>
                    <li>Indicatori avanzati</li>
                </ul>
            </div>
        """, unsafe_allow_html=True)

    with col2:
        st.markdown("<h3 style='color: white;'>Registrati per iniziare:</h3>", unsafe_allow_html=True)
        name = st.text_input("Nome")
        email = st.text_input("Email")
        password = st.text_input("Password", type="password")
        
        if st.button("Accedi all'App"):
            if not name or not email or not password:
                st.error("Per favore, compila tutti i campi")
            elif len(name) < 2:
                st.error("Il nome deve contenere almeno 2 caratteri")
            elif not is_valid_email(email):
                st.error("Per favore, inserisci un indirizzo email valido")
            elif len(password) < 6:
                st.error("La password deve contenere almeno 6 caratteri")
            else:
                # Salva i dati utente
                save_result = save_user_data(name, email)
                if save_result == True:
                    st.success("Registrazione completata con successo!")
                    st.session_state.logged_in = True
                    st.rerun()
                elif save_result == 'exists':
                    st.info("Account già registrato. Puoi procedere con l'accesso.")
                    st.session_state.logged_in = True
                    st.rerun()
                else:
                    st.error("Si è verificato un errore durante la registrazione. Riprova più tardi.")
                   else:
    # Stili CSS
    st.markdown("""
        <style>
        /* Import Google Font - Roboto */
        @import url('https://fonts.googleapis.com/css2?family=Roboto:wght@300;400;500;700&display=swap');
    
        /* Sfondo principale */
        .stApp {
            background-color: #0066cc !important;
        }
        
        /* Titolo principale */
        .main h1 {
            color: #FFFFFF !important;
            font-family: 'Roboto', sans-serif !important;
            font-size: 2rem !important;
            font-weight: 500 !important;
        }
        
        /* Titolo delle sezioni */
        .main h2 {
            color: #FFFFFF !important;
            font-family: 'Roboto', sans-serif !important;
            font-size: 1.6rem !important;
            font-weight: 400 !important;
            margin-top: 2rem !important;
        }
        
        /* Testo metrica */
        .stMetric label {
            color: #FFFFFF !important;
            font-family: 'Roboto', sans-serif !important;
            font-size: 1rem !important;
        }
        
        /* Valore metrica */
        .stMetric .metric-value {
            color: #FFFFFF !important;
            font-family: 'Roboto', sans-serif !important;
            font-size: 1.2rem !important;
            font-weight: 500 !important;
        }
        
