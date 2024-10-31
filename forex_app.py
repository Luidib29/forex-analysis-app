import streamlit as st
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import mplfinance as mpf
from datetime import datetime, timedelta
from tiingo import TiingoClient

# Configurazione pagina
st.set_page_config(
    page_title="Pro Forex Analysis",
    page_icon="📊",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Stili CSS
st.markdown("""
    <style>
    .main {
        background-color: var(--background-color);
        color: var(--text-color);
    }
    .stButton>button {
        width: 100%;
        background-color: #4CAF50;
        color: white;
        border-radius: 4px;
        padding: 0.5rem 1rem;
    }
    .metric-card {
        background-color: var(--card-background);
        padding: 1rem;
        border-radius: 0.5rem;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        margin-bottom: 1rem;
    }
    h1 {
        color: #1E88E5;
        font-size: 2.5rem;
        padding: 1rem 0;
    }
    h2 {
        color: #333;
        font-size: 1.8rem;
        padding: 0.5rem 0;
    }
    </style>
""", unsafe_allow_html=True)

# Configura client Tiingo
config = {
    'session': True,
    'api_key': 'e01a41babcd49cf76f97fdc98c6bf944abdd154e'
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
    # Scarica i dati
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
        
        return df
        
    except Exception as e:
        st.error(f"Errore nel download dei dati per {pair_name}: {str(e)}")
        return None
        
    except Exception as e:
        st.error(f"Errore nel download dei dati per {pair_name}: {str(e)}")
        return None

# Sidebar
with st.sidebar:
    st.image("https://via.placeholder.com/150x150.png?text=FOREX", width=150)
    st.title("Configurazione")
    
    # Dark/Light mode toggle
    theme = st.toggle("🌓 Dark Mode", False)
    
    # Selezione periodo
    periodo = st.selectbox(
        "Periodo di Analisi",
        [90, 180, 365],
        format_func=lambda x: f"{x} giorni"
    )
    
    # Selezione coppie forex
    selected_pairs = st.multiselect(
        "Seleziona Coppie Forex",
        list(forex_pairs.keys()),
        default=list(forex_pairs.keys())[:3]
    )
    
    # Impostazioni grafico
    st.subheader("Impostazioni Grafico")
    show_volume = st.checkbox("Mostra Volume", value=True)
    show_ma = st.checkbox("Mostra Medie Mobili", value=True)
    
    if st.button("🔄 Aggiorna Dati"):
        st.rerun()

# Titolo principale e panoramica
st.title("📊 Pro Forex Analysis Dashboard")

# Market Overview
st.header("🌍 Panoramica Mercato")
col1, col2, col3 = st.columns(3)
with col1:
    st.metric("Mercati Analizzati", len(selected_pairs))
with col2:
    st.metric("Periodo Analisi", f"{periodo} giorni")
with col3:
    st.metric("Ultimo Aggiornamento", datetime.now().strftime("%H:%M:%S"))

# Analisi per coppia
for pair_name in selected_pairs:
    symbol = forex_pairs[pair_name]
    st.header(f"📈 Analisi {pair_name}")
    
    # Crea tabs per organizzare il contenuto
    tab1, tab2, tab3 = st.tabs(["Grafico", "Indicatori", "Dettagli"])
    
    df = analisi_forex(symbol, pair_name)
    if df is not None:
        with tab1:
            # Selettore per tipo di grafico
            chart_type = st.radio(
                "Tipo di Grafico",
                ["Candele", "Lineare"],
                horizontal=True
            )
            
            if chart_type == "Candele":
                fig = plot_candlestick(df, pair_name)
                st.pyplot(fig)
            else:
                # Grafico lineare
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
        
        with tab3:
            st.dataframe(df[['Close', 'RSI', 'MACD', 'Signal']].tail())

# Footer
st.markdown("---")
st.markdown("""
    <div style='text-align: center; padding: 1rem;'>
        <p>Sviluppato con ❤️ | Ultimo aggiornamento: {}</p>
    </div>
""".format(datetime.now().strftime("%d/%m/%Y %H:%M:%S")), unsafe_allow_html=True)
