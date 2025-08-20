"""
Streamlit UI for Crypto Trading Predictor
Advanced interface with configuration, visualization, and real-time predictions
"""

import streamlit as st
import pandas as pd
import numpy as np
import plotly.graph_objects as go
from plotly.subplots import make_subplots
import plotly.express as px
from crypto_predictor import CryptoPredictorLSTM
import yfinance as yf
from datetime import datetime, timedelta
import json

# Page configuration
st.set_page_config(
    page_title="Crypto Trading AI Predictor",
    page_icon="📈",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Custom CSS for better UI
st.markdown("""
<style>
    .main-header {
        font-size: 3rem;
        color: #1f77b4;
        text-align: center;
        margin-bottom: 2rem;
    }
    .metric-card {
        background-color: #f0f2f6;
        padding: 1rem;
        border-radius: 0.5rem;
        border-left: 4px solid #1f77b4;
    }
    .signal-buy {
        background-color: #d4edda;
        border-left: 4px solid #28a745;
        padding: 1rem;
        border-radius: 0.5rem;
    }
    .signal-sell {
        background-color: #f8d7da;
        border-left: 4px solid #dc3545;
        padding: 1rem;
        border-radius: 0.5rem;
    }
    .signal-hold {
        background-color: #fff3cd;
        border-left: 4px solid #ffc107;
        padding: 1rem;
        border-radius: 0.5rem;
    }
</style>
""", unsafe_allow_html=True)

class CryptoTradingUI:
    def __init__(self):
        self.predictor = None
        self.current_data = None
        
    def initialize_session_state(self):
        """Initialize session state variables"""
        if 'model_trained' not in st.session_state:
            st.session_state.model_trained = False
        if 'current_signal' not in st.session_state:
            st.session_state.current_signal = None
        if 'backtest_results' not in st.session_state:
            st.session_state.backtest_results = None
        if 'training_history' not in st.session_state:
            st.session_state.training_history = None
    
    def render_sidebar(self):
        """Render configuration sidebar"""
        st.sidebar.title("⚙️ Configuration")
        
        # Model Configuration
        st.sidebar.subheader("Model Settings")
        
        symbol = st.sidebar.selectbox(
            "Cryptocurrency",
            options=['BTC-USD', 'ETH-USD', 'ADA-USD', 'DOT-USD', 'LINK-USD', 'LTC-USD'],
            index=0,
            help="Select the cryptocurrency to analyze"
        )
        
        timeframe = st.sidebar.selectbox(
            "Timeframe",
            options=['1h', '4h', '1d'],
            index=0,
            help="Data timeframe for analysis"
        )
        
        data_period = st.sidebar.selectbox(
            "Data Period",
            options=['6mo', '1y', '2y', '5y'],
            index=2,
            help="Historical data period for training"
        )
        
        # Advanced Settings
        st.sidebar.subheader("Advanced Settings")
        
        confidence_threshold = st.sidebar.slider(
            "Confidence Threshold",
            min_value=0.5,
            max_value=0.95,
            value=0.8,
            step=0.05,
            help="Minimum confidence required for trading signals"
        )
        
        lookback_window = st.sidebar.slider(
            "Lookback Window",
            min_value=30,
            max_value=120,
            value=60,
            step=10,
            help="Number of time periods to analyze"
        )
        
        # Technical Indicators Selection
        st.sidebar.subheader("Technical Indicators")
        
        use_trend_indicators = st.sidebar.checkbox("Trend Indicators", value=True)
        use_momentum_indicators = st.sidebar.checkbox("Momentum Indicators", value=True)
        use_volatility_indicators = st.sidebar.checkbox("Volatility Indicators", value=True)
        use_volume_indicators = st.sidebar.checkbox("Volume Indicators", value=True)
        
        return {
            'symbol': symbol,
            'timeframe': timeframe,
            'data_period': data_period,
            'confidence_threshold': confidence_threshold,
            'lookback_window': lookback_window,
            'indicators': {
                'trend': use_trend_indicators,
                'momentum': use_momentum_indicators,
                'volatility': use_volatility_indicators,
                'volume': use_volume_indicators
            }
        }
    
    def render_header(self):
        """Render main header"""
        st.markdown('<h1 class="main-header">🚀 Crypto Trading AI Predictor</h1>', unsafe_allow_html=True)
        st.markdown("---")
        
        col1, col2, col3, col4 = st.columns(4)
        
        with col1:
            st.metric("Model Status", "✅ Ready" if st.session_state.model_trained else "⏳ Not Trained")
        
        with col2:
            if st.session_state.current_signal:
                action = st.session_state.current_signal['action']
                confidence = st.session_state.current_signal['confidence']
                st.metric("Current Signal", action, f"{confidence:.1%}")
        
        with col3:
            if st.session_state.backtest_results:
                win_rate = st.session_state.backtest_results['win_rate']
                st.metric("Win Rate", f"{win_rate:.1%}")
        
        with col4:
            if st.session_state.backtest_results:
                total_return = st.session_state.backtest_results['total_return']
                st.metric("Total Return", f"{total_return:.1%}")
    
    def render_training_section(self, config):
        """Render model training section"""
        st.subheader("🧠 Model Training")
        
        col1, col2 = st.columns([2, 1])
        
        with col1:
            if st.button("🚀 Train Model", type="primary", use_container_width=True):
                with st.spinner("Training model... This may take several minutes."):
                    try:
                        # Initialize predictor
                        self.predictor = CryptoPredictorLSTM(
                            symbol=config['symbol'],
                            timeframe=config['timeframe']
                        )
                        self.predictor.confidence_threshold = config['confidence_threshold']
                        self.predictor.lookback_window = config['lookback_window']
                        
                        # Fetch data
                        data = self.predictor.fetch_data(config['data_period'])
                        
                        if data is not None:
                            # Train model
                            history, processed_data = self.predictor.train_model(data)
                            
                            # Store in session state
                            st.session_state.model_trained = True
                            st.session_state.training_history = history.history
                            self.current_data = processed_data
                            
                            # Run backtest
                            backtest_results = self.predictor.backtest_model(data)
                            st.session_state.backtest_results = backtest_results
                            
                            st.success("✅ Model trained successfully!")
                            st.rerun()
                        else:
                            st.error("❌ Failed to fetch data")
                            
                    except Exception as e:
                        st.error(f"❌ Training failed: {str(e)}")
        
        with col2:
            st.info("📊 Training will use comprehensive technical analysis with LSTM neural network")
    
    def render_prediction_section(self, config):
        """Render current prediction section"""
        if not st.session_state.model_trained:
            st.warning("⚠️ Please train the model first")
            return
        
        st.subheader("🎯 Current Prediction")
        
        if st.button("🔄 Get Latest Signal", use_container_width=True):
            with st.spinner("Analyzing current market conditions..."):
                try:
                    # Fetch latest data
                    data = self.predictor.fetch_data('3mo')  # Get recent data for prediction
                    
                    if data is not None:
                        signal, current_data = self.predictor.predict_with_confidence(data)
                        st.session_state.current_signal = signal
                        
                        # Display signal
                        self.display_trading_signal(signal, current_data)
                    else:
                        st.error("❌ Failed to fetch latest data")
                        
                except Exception as e:
                    st.error(f"❌ Prediction failed: {str(e)}")
        
        # Display cached signal if available
        if st.session_state.current_signal:
            signal = st.session_state.current_signal
            st.subheader("📊 Latest Signal")
            self.display_trading_signal(signal, None)
    
    def display_trading_signal(self, signal, current_data):
        """Display trading signal with styling"""
        action = signal['action']
        confidence = signal['confidence']
        strength = signal['strength']
        explanation = signal['explanation']
        
        # Choose styling based on action
        if action == 'BUY':
            signal_class = 'signal-buy'
            icon = '📈'
            color = '#28a745'
        elif action == 'SELL':
            signal_class = 'signal-sell'
            icon = '📉'
            color = '#dc3545'
        else:
            signal_class = 'signal-hold'
            icon = '⏸️'
            color = '#ffc107'
        
        # Main signal display
        st.markdown(f"""
        <div class="{signal_class}">
            <h3>{icon} {action} Signal</h3>
            <p><strong>Confidence:</strong> {confidence:.1%}</p>
            <p><strong>Strength:</strong> {strength}</p>
            <p><strong>Explanation:</strong> {explanation}</p>
        </div>
        """, unsafe_allow_html=True)
        
        # Technical reasons
        if signal.get('technical_reasons'):
            st.subheader("🔍 Technical Analysis Details")
            for i, reason in enumerate(signal['technical_reasons'][:5], 1):
                st.write(f"{i}. {reason}")
        
        # Current market metrics
        if current_data is not None:
            st.subheader("📊 Current Market Metrics")
            
            col1, col2, col3, col4 = st.columns(4)
            
            with col1:
                st.metric("RSI", f"{current_data.get('RSI', 0):.1f}")
                st.metric("MACD", f"{current_data.get('MACD', 0):.4f}")
            
            with col2:
                st.metric("BB Position", f"{current_data.get('BB_Position', 0):.2f}")
                st.metric("Volume Ratio", f"{current_data.get('Volume_Ratio', 0):.1f}")
            
            with col3:
                st.metric("ADX", f"{current_data.get('ADX', 0):.1f}")
                st.metric("ATR", f"{current_data.get('ATR', 0):.2f}")
            
            with col4:
                st.metric("Williams %R", f"{current_data.get('Williams_R', 0):.1f}")
                st.metric("CCI", f"{current_data.get('CCI', 0):.1f}")
    
    def render_charts(self, config):
        """Render interactive charts"""
        if not st.session_state.model_trained:
            return
        
        st.subheader("📈 Interactive Charts")
        
        try:
            # Fetch data for charts
            data = yf.Ticker(config['symbol']).history(period='3mo', interval=config['timeframe'])
            
            if data.empty:
                st.error("No data available for charts")
                return
            
            # Create subplots
            fig = make_subplots(
                rows=4, cols=1,
                subplot_titles=('Price & Moving Averages', 'RSI', 'MACD', 'Volume'),
                vertical_spacing=0.05,
                row_heights=[0.5, 0.2, 0.2, 0.1]
            )
            
            # Price chart with moving averages
            fig.add_trace(
                go.Candlestick(
                    x=data.index,
                    open=data['Open'],
                    high=data['High'],
                    low=data['Low'],
                    close=data['Close'],
                    name='Price'
                ),
                row=1, col=1
            )
            
            # Calculate and add moving averages
            data['SMA_20'] = data['Close'].rolling(20).mean()
            data['SMA_50'] = data['Close'].rolling(50).mean()
            data['EMA_12'] = data['Close'].ewm(span=12).mean()
            
            fig.add_trace(
                go.Scatter(x=data.index, y=data['SMA_20'], name='SMA 20', line=dict(color='orange')),
                row=1, col=1
            )
            fig.add_trace(
                go.Scatter(x=data.index, y=data['SMA_50'], name='SMA 50', line=dict(color='red')),
                row=1, col=1
            )
            fig.add_trace(
                go.Scatter(x=data.index, y=data['EMA_12'], name='EMA 12', line=dict(color='purple')),
                row=1, col=1
            )
            
            # RSI
            delta = data['Close'].diff()
            gain = (delta.where(delta > 0, 0)).rolling(window=14).mean()
            loss = (-delta.where(delta < 0, 0)).rolling(window=14).mean()
            rs = gain / loss
            rsi = 100 - (100 / (1 + rs))
            
            fig.add_trace(
                go.Scatter(x=data.index, y=rsi, name='RSI', line=dict(color='blue')),
                row=2, col=1
            )
            fig.add_hline(y=70, line_dash="dash", line_color="red", row=2, col=1)
            fig.add_hline(y=30, line_dash="dash", line_color="green", row=2, col=1)
            
            # MACD
            exp1 = data['Close'].ewm(span=12).mean()
            exp2 = data['Close'].ewm(span=26).mean()
            macd_line = exp1 - exp2
            signal_line = macd_line.ewm(span=9).mean()
            histogram = macd_line - signal_line
            
            fig.add_trace(
                go.Scatter(x=data.index, y=macd_line, name='MACD', line=dict(color='blue')),
                row=3, col=1
            )
            fig.add_trace(
                go.Scatter(x=data.index, y=signal_line, name='Signal', line=dict(color='red')),
                row=3, col=1
            )
            fig.add_trace(
                go.Bar(x=data.index, y=histogram, name='Histogram'),
                row=3, col=1
            )
            
            # Volume
            fig.add_trace(
                go.Bar(x=data.index, y=data['Volume'], name='Volume', marker_color='lightblue'),
                row=4, col=1
            )
            
            # Update layout
            fig.update_layout(
                title=f"{config['symbol']} Technical Analysis",
                xaxis_rangeslider_visible=False,
                height=800,
                showlegend=True
            )
            
            st.plotly_chart(fig, use_container_width=True)
            
        except Exception as e:
            st.error(f"Error creating charts: {str(e)}")
    
    def render_backtest_results(self):
        """Render backtesting results"""
        if not st.session_state.backtest_results:
            return
        
        st.subheader("📊 Backtesting Results")
        
        results = st.session_state.backtest_results
        
        col1, col2, col3, col4 = st.columns(4)
        
        with col1:
            st.metric(
                "Total Return",
                f"{results['total_return']:.2%}",
                delta=f"{results['total_return']:.2%}"
            )
        
        with col2:
            st.metric(
                "Win Rate",
                f"{results['win_rate']:.1%}",
                delta="Target: 80%"
            )
        
        with col3:
            st.metric(
                "Number of Trades",
                results['num_trades']
            )
        
        with col4:
            st.metric(
                "Final Capital",
                f"${results['final_capital']:.2f}"
            )
        
        # Trade history
        if results['trades']:
            st.subheader("📋 Trade History")
            
            trades_df = pd.DataFrame(results['trades'])
            if not trades_df.empty:
                # Filter only completed trades (buy-sell pairs)
                sell_trades = trades_df[trades_df['type'] == 'SELL'].copy()
                
                if not sell_trades.empty:
                    sell_trades['return_pct'] = sell_trades['return'] * 100
                    
                    # Display recent trades
                    st.dataframe(
                        sell_trades[['timestamp', 'price', 'confidence', 'return_pct']].tail(10),
                        use_container_width=True
                    )
                    
                    # Returns distribution
                    fig = px.histogram(
                        sell_trades,
                        x='return_pct',
                        title='Trade Returns Distribution',
                        labels={'return_pct': 'Return (%)', 'count': 'Number of Trades'}
                    )
                    st.plotly_chart(fig, use_container_width=True)
    
    def render_model_performance(self):
        """Render model training performance"""
        if not st.session_state.training_history:
            return
        
        st.subheader("🎯 Model Training Performance")
        
        history = st.session_state.training_history
        
        col1, col2 = st.columns(2)
        
        with col1:
            # Accuracy plot
            fig = go.Figure()
            fig.add_trace(go.Scatter(
                y=history['accuracy'],
                name='Training Accuracy',
                line=dict(color='blue')
            ))
            fig.add_trace(go.Scatter(
                y=history['val_accuracy'],
                name='Validation Accuracy',
                line=dict(color='red')
            ))
            fig.update_layout(title='Model Accuracy', yaxis_title='Accuracy')
            st.plotly_chart(fig, use_container_width=True)
        
        with col2:
            # Loss plot
            fig = go.Figure()
            fig.add_trace(go.Scatter(
                y=history['loss'],
                name='Training Loss',
                line=dict(color='blue')
            ))
            fig.add_trace(go.Scatter(
                y=history['val_loss'],
                name='Validation Loss',
                line=dict(color='red')
            ))
            fig.update_layout(title='Model Loss', yaxis_title='Loss')
            st.plotly_chart(fig, use_container_width=True)
    
    def render_technical_analysis_summary(self, config):
        """Render technical analysis summary"""
        st.subheader("🔍 Technical Analysis Overview")
        
        # Explanation of indicators
        st.markdown("""
        ### Key Technical Indicators Used:
        
        **Trend Indicators:**
        - **Moving Averages (SMA, EMA):** Identify trend direction and momentum
        - **MACD:** Measures momentum and trend changes
        - **ADX:** Determines trend strength
        - **Parabolic SAR:** Identifies potential reversal points
        
        **Momentum Indicators:**
        - **RSI:** Identifies overbought/oversold conditions (>70 overbought, <30 oversold)
        - **Stochastic Oscillator:** Compares closing price to price range
        - **Williams %R:** Momentum oscillator for reversal signals
        - **CCI:** Identifies cyclical trends
        
        **Volatility Indicators:**
        - **Bollinger Bands:** Measure volatility and identify support/resistance
        - **ATR:** Measures market volatility
        
        **Volume Indicators:**
        - **OBV:** Relates volume to price changes
        - **VWAP:** Volume-weighted average price
        - **MFI:** Money flow index combining price and volume
        
        ### High-Confidence Trading Strategy:
        - Only trade when confidence > 80%
        - Multiple indicators must align
        - Strong volume confirmation required
        - Clear trend direction identified
        """)
    
    def run(self):
        """Main application runner"""
        self.initialize_session_state()
        
        # Render UI components
        config = self.render_sidebar()
        self.render_header()
        
        # Main content tabs
        tab1, tab2, tab3, tab4, tab5 = st.tabs([
            "🚀 Trading", "🧠 Training", "📈 Charts", "📊 Backtest", "📚 Analysis Guide"
        ])
        
        with tab1:
            self.render_prediction_section(config)
        
        with tab2:
            self.render_training_section(config)
            self.render_model_performance()
        
        with tab3:
            self.render_charts(config)
        
        with tab4:
            self.render_backtest_results()
        
        with tab5:
            self.render_technical_analysis_summary(config)
        
        # Footer
        st.markdown("---")
        st.markdown("""
        <div style='text-align: center; color: #666;'>
            <p>⚠️ <strong>Disclaimer:</strong> This tool is for educational purposes only. 
            Cryptocurrency trading involves significant risk. Always do your own research and never invest more than you can afford to lose.</p>
        </div>
        """, unsafe_allow_html=True)

if __name__ == "__main__":
    app = CryptoTradingUI()
    app.run()