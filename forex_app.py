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
import streamlit_authenticator as stauth
import yaml
from yaml.loader import SafeLoader

# Configurazione pagina
st.set_page_config(
    page_title="Pro Forex Analysis",
    page_icon="🇪🇺🇺🇸 🇬🇧🇺🇸 🇺🇸🇯🇵 🇦🇺🇺🇸 🇺🇸🇨🇦 🇺🇸🇨🇭 🇳🇿🇺🇸 🇪🇺🇬🇧 🇪🇺🇯🇵",
    layout="wide",
    initial_sidebar_state="collapsed"
)

# Inizializzazione dello stato di sessione
if 'authentication_status' not in st.session_state:
    st.session_state['authentication_status'] = None

# Configurazione dell'authenticator
with open('config.yaml') as file:
    config = yaml.load(file, Loader=SafeLoader)

authenticator = stauth.Authenticate(
    config['credentials'],
    config['cookie']['name'],
    config['cookie']['key'],
    config['cookie']['expiry_days']
)
# Sistema di autenticazione
name, authentication_status, username = authenticator.login('Login', 'main')  # Cambiato da 'sidebar' a 'main'

if authentication_status is False:
    st.error('Username/password non corretti')
elif authentication_status is None:
    # Form di registrazione (quando non si è loggati)
    try:
        if authenticator.register_user('Registrati', preauthorization=False):
            st.success('Utente registrato con successo!')
            st.balloons()
            with open('config.yaml', 'w') as file:
                yaml.dump(config, file, default_flow_style=False)
    except Exception as e:
        st.error(e)

if authentication_status:
    # Sidebar per utente autenticato
    with st.sidebar:
        st.write(f'👤 Benvenuto *{name}*')
        authenticator.logout('Logout', 'main')  # Cambiato da 'sidebar' a 'main'
        
        # Reset password
        try:
            if authenticator.reset_password(username, 'Reset Password', location='main'):  # Aggiunto location='main'
                st.success('Password resettata con successo')
                with open('config.yaml', 'w') as file:
                    yaml.dump(config, file, default_flow_style=False)
        except Exception as e:
            st.error(e)
        try:
        with open('config.yaml', 'r') as file:
            debug_config = yaml.safe_load(file)
            if st.sidebar.checkbox("Debug: Mostra utenti registrati"):
                st.sidebar.write("Config attuale:", debug_config)
    except Exception as e:
        if st.sidebar.checkbox("Debug: Mostra errori"):
            st.sidebar.error(f"Errore lettura config: {str(e)}")
    # Configurazione Tiingo e dizionario forex
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

    # Funzioni di utilità
    def is_valid_email(email):
        pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        return re.match(pattern, email) is not None

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
        df_mpf = df.copy()
        if not isinstance(df_mpf.index, pd.DatetimeIndex):
            df_mpf.index = pd.to_datetime(df_mpf.index)
        
        mc = mpf.make_marketcolors(
            up='green',
            down='red',
            edge='inherit',
            wick='inherit',
            volume='in',
            ohlc='inherit'
        )
        
        s = mpf.make_mpf_style(
            marketcolors=mc,
            gridstyle='--',
            figcolor='white',
            gridcolor='gray'
        )
        
        add_plot = [
            mpf.make_addplot(df['MA20'], color='blue', width=0.8),
            mpf.make_addplot(df['MA50'], color='red', width=0.8)
        ]
        
        try:
            fig, axes = mpf.plot(
                df_mpf,
                type='candlestick',
                style=s,
                addplot=add_plot,
                volume=False,
                figsize=(12, 8),
                returnfig=True,
                title=f'\n{pair_name} Analisi Tecnica'
            )
            return fig
        except Exception as e:
            st.error(f"Errore nella creazione del grafico: {str(e)}")
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
            
            df = pd.DataFrame({
                'Open': data['open'],
                'High': data['high'],
                'Low': data['low'],
                'Close': data['close']
            })
            
            # Calcolo indicatori
            df['MA20'] = df['Close'].rolling(window=20).mean()
            df['MA50'] = df['Close'].rolling(window=50).mean()
            
            # RSI
            delta = df['Close'].diff()
            gain = (delta.where(delta > 0, 0)).rolling(window=14).mean()
            loss = (-delta.where(delta < 0, 0)).rolling(window=14).mean()
            rs = gain / loss
            df['RSI'] = 100 - (100 / (1 + rs))
            
            # MACD
            df['EMA12'] = df['Close'].ewm(span=12, adjust=False).mean()
            df['EMA26'] = df['Close'].ewm(span=26, adjust=False).mean()
            df['MACD'] = df['EMA12'] - df['EMA26']
            df['Signal'] = df['MACD'].ewm(span=9, adjust=False).mean()
            
            # Pivot Points Fibonacci
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
          # Mostra l'interfaccia principale solo se l'utente è autenticato
if authentication_status:
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
        
        /* Tabs styling */
        .stTabs {
            background-color: transparent !important;
        }
        
        .stTabs [data-baseweb="tab-list"] {
            gap: 30px !important;
            background-color: transparent !important;
            padding: 0 20px !important;
            margin-bottom: 20px !important;
        }
        
        .stTabs [data-baseweb="tab"] {
            color: #FFFFFF !important;
            font-family: 'Roboto', sans-serif !important;
            font-size: 1rem !important;
            background-color: transparent !important;
            border: none !important;
            padding: 10px 20px !important;
            font-weight: 400 !important;
        }
        
        .stTabs [data-baseweb="tab"][aria-selected="true"] {
            color: #FFFFFF !important;
            font-weight: 500 !important;
            border-bottom: 2px solid white !important;
        }
        
        /* Testi generici */
        .main p, .main span, .main div {
            color: #FFFFFF !important;
            font-family: 'Roboto', sans-serif !important;
        }
        
        /* Grafico e contenuti delle tab */
        .stTabs [data-baseweb="tab-panel"] {
            padding: 20px 0 !important;
        }
        
        /* Stile header */
        .header-container {
            padding: 1rem;
            margin-bottom: 2rem;
        }
        
        /* Stile per i selectbox nell'header */
        .header-container .stSelectbox {
            background-color: rgba(255, 255, 255, 0.2);
            border-radius: 5px;
        }
        </style>
    """, unsafe_allow_html=True)

    # Header dell'app
    st.markdown("""
        <div style='text-align: center; padding: 2rem;'>
            <h1 style='color: white; font-size: 2.5rem;'>Pro Forex Analysis</h1>
            <p style='color: #E0E0E0; font-size: 1.2rem; max-width: 800px; margin: 2rem auto;'>
                Analisi tecnica forex con segnali di trading in tempo reale basati su AI.
            </p>
        </div>
    """, unsafe_allow_html=True)

    # Header con impostazioni
    st.markdown('<div class="header-container">', unsafe_allow_html=True)
    col1, col2, col3, col4 = st.columns([3,2,2,1])

    with col1:
        st.markdown("""
            <div style='color: #E0E0E0; font-family: Roboto, sans-serif; font-size: 0.95rem; 
            padding: 0.5rem 0; line-height: 1.6;'>
            <strong style='color: white; font-size: 1.1rem;'>Professional Trading System</strong>
            </div>
        """, unsafe_allow_html=True)

    with col2:
        selected_pairs = st.multiselect(
            "Seleziona Coppie Forex",
            list(forex_pairs.keys()),
            default=list(forex_pairs.keys())[:3]
        )

    with col3:
        periodo = st.selectbox(
            "Periodo di Analisi",
            [90, 180, 365],
            format_func=lambda x: f"{x} giorni"
        )

    with col4:
        if st.button("🔄 Aggiorna"):
            st.rerun()

    st.markdown('</div>', unsafe_allow_html=True)

    # Market Overview
    st.header("🌍 Panoramica Mercato")
    col1, col2, col3 = st.columns(3)
    with col1:
        st.metric("Mercati Analizzati", len(selected_pairs))
    with col2:
        st.metric("Periodo Analisi", f"{periodo} giorni")
    with col3:
        st.metric("Ultimo Aggiornamento", datetime.now().strftime("%H:%M:%S"))
      # Loop principale per ogni coppia forex
    if authentication_status:
        for pair_name in selected_pairs:
            symbol = forex_pairs[pair_name]
            st.header(f"📈 Analisi {pair_name}")
            
            # Crea tabs per organizzare il contenuto
            tab1, tab2, tab3 = st.tabs(["Grafico", "Indicatori", "Dettagli"])
            
            df = analisi_forex(symbol, pair_name)
            if df is not None:
                with tab1:
                    chart_type = st.radio(
                        "Tipo di Grafico",
                        ["Candele", "Lineare"],
                        key=f"radio_{pair_name}",
                        horizontal=True
                    )
                    
                    if chart_type == "Candele":
                        fig = plot_candlestick(df, pair_name)
                        st.pyplot(fig)
                    else:
                        fig, (ax1, ax2, ax3) = plt.subplots(3, 1, figsize=(12, 12))
                        ax1.plot(df.index, df['Close'], label=pair_name)
                        ax1.plot(df.index, df['MA20'], label='MA20')
                        ax1.plot(df.index, df['MA50'], label='MA50')
                        ax1.set_title('Prezzo e Medie Mobili')
                        ax1.legend()
                        
                        ax2.plot(df.index, df['RSI'])
                        ax2.axhline(y=70, color='r', linestyle='--')
                        ax2.axhline(y=30, color='g', linestyle='--')
                        ax2.set_title('RSI')
                        
                        ax3.plot(df.index, df['MACD'], label='MACD')
                        ax3.plot(df.index, df['Signal'], label='Signal')
                        ax3.set_title('MACD')
                        ax3.legend()
                        
                        plt.tight_layout()
                        st.pyplot(fig)
                
                with tab2:
                    col1, col2 = st.columns(2)
                    with col1:
                        st.metric("RSI", f"{df['RSI'].iloc[-1]:.2f}")
                        st.metric("MACD", f"{df['MACD'].iloc[-1]:.6f}")
                    with col2:
                        st.metric("Signal", f"{df['Signal'].iloc[-1]:.6f}")
                        trend = "RIALZISTA" if df['Close'].iloc[-1] > df['MA20'].iloc[-1] else "RIBASSISTA"
                        st.metric("Trend", trend)
                    
                    st.subheader("Grafico RSI")
                    fig_rsi, ax_rsi = plt.subplots(figsize=(12, 4))
                    ax_rsi.plot(df.index, df['RSI'], label='RSI', color='purple')
                    ax_rsi.axhline(y=70, color='r', linestyle='--')
                    ax_rsi.axhline(y=30, color='g', linestyle='--')
                    ax_rsi.fill_between(df.index, 70, 30, alpha=0.1, color='gray')
                    ax_rsi.set_ylim(0, 100)
                    ax_rsi.legend()
                    ax_rsi.grid(True)
                    st.pyplot(fig_rsi)
                    
                    st.subheader("Grafico MACD")
                    fig_macd, ax_macd = plt.subplots(figsize=(12, 4))
                    ax_macd.plot(df.index, df['MACD'], label='MACD', color='blue')
                    ax_macd.plot(df.index, df['Signal'], label='Signal', color='red')
                    ax_macd.bar(df.index, df['MACD'] - df['Signal'], alpha=0.3, color='gray')
                    ax_macd.legend()
                    ax_macd.grid(True)
                    st.pyplot(fig_macd)
                
                with tab3:
                    realtime_price = get_forex_realtime_price(symbol)
                    if realtime_price:
                        st.subheader("Prezzo in Tempo Reale")
                        col1, col2 = st.columns(2)
                        with col1:
                            st.metric("Prezzo Medio", f"{realtime_price['midPrice']:.4f}")
                            st.metric("Bid", f"{realtime_price['bidPrice']:.4f}")
                        with col2:
                            st.metric("Ask", f"{realtime_price['askPrice']:.4f}")
                            st.metric("Ultimo Aggiornamento", 
                                    datetime.fromisoformat(realtime_price['timestamp'].replace('Z', '+00:00')).strftime('%H:%M:%S'))

                    st.subheader("Prezzo di Chiusura")
                    prezzo_attuale = df['Close'].iloc[-1]
                    variazione = ((prezzo_attuale - df['Close'].iloc[-2]) / df['Close'].iloc[-2]) * 100
                    col_prezzo1, col_prezzo2 = st.columns(2)
                    with col_prezzo1:
                        st.metric("Chiusura", f"{prezzo_attuale:.4f}")
                    with col_prezzo2:
                        st.metric("Variazione %", f"{variazione:.2f}%",
                                delta=f"{variazione:.2f}%",
                                delta_color="inverse" if variazione >= 0 else "normal")

                    st.subheader("Livelli Fibonacci")
                    col1, col2 = st.columns(2)
                    with col1:
                        st.metric("Resistenza R1", f"{df['R1'].iloc[-1]:.4f}")
                        st.metric("Resistenza R2", f"{df['R2'].iloc[-1]:.4f}")
                        st.metric("Pivot Point", f"{df['PP'].iloc[-1]:.4f}")
                    with col2:
                        st.metric("Supporto S1", f"{df['S1'].iloc[-1]:.4f}")
                        st.metric("Supporto S2", f"{df['S2'].iloc[-1]:.4f}")
                    
                    st.subheader("Segnali di Trading")
                    st.metric("Segnale Attuale", df['Segnale'].iloc[-1])
                    
                    st.subheader("Ultimi 5 Giorni")
                    df_last_5 = df[['Close', 'RSI', 'MACD', 'Signal', 'Segnale']].tail()
                    df_last_5.index = df_last_5.index.strftime('%Y-%m-%d')
                    st.dataframe(df_last_5)

        # Footer
        st.markdown("---")
        st.markdown("""
            <div style='text-align: center; padding: 1rem;'>
                <p>Sviluppato con ❤️ | Ultimo aggiornamento: {}</p>
            </div>
        """.format(datetime.now().strftime("%d/%m/%Y %H:%M:%S")), unsafe_allow_html=True)
