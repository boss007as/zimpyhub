"""
Comprehensive Crypto Trading Predictor with LSTM and Technical Analysis
High-confidence trading signals with detailed explanations
"""

import numpy as np
import pandas as pd
import tensorflow as tf
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import LSTM, Dense, Dropout, Attention, Input
from tensorflow.keras.optimizers import Adam
from sklearn.preprocessing import MinMaxScaler
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score
import yfinance as yf
import ccxt
import talib
import ta
import pandas_ta as pta
from datetime import datetime, timedelta
import warnings
warnings.filterwarnings('ignore')

class CryptoPredictorLSTM:
    def __init__(self, symbol='BTC-USD', timeframe='1h'):
        """
        Initialize the crypto predictor with LSTM and comprehensive technical analysis
        
        Args:
            symbol: Trading symbol (e.g., 'BTC-USD', 'ETH-USD')
            timeframe: Data timeframe ('1m', '5m', '15m', '1h', '4h', '1d')
        """
        self.symbol = symbol
        self.timeframe = timeframe
        self.model = None
        self.scaler = MinMaxScaler()
        self.feature_scalers = {}
        self.lookback_window = 60  # Number of time periods to look back
        self.confidence_threshold = 0.8  # High confidence threshold
        
        # Technical indicators configuration
        self.indicators_config = {
            'trend': ['SMA', 'EMA', 'MACD', 'ADX', 'Parabolic_SAR'],
            'momentum': ['RSI', 'Stochastic', 'Williams_R', 'ROC', 'CCI'],
            'volatility': ['Bollinger_Bands', 'ATR', 'Keltner_Channels'],
            'volume': ['OBV', 'VWAP', 'Volume_SMA', 'MFI', 'A/D_Line'],
            'support_resistance': ['Pivot_Points', 'Fibonacci_Retracements']
        }
        
    def fetch_data(self, period='2y'):
        """
        Fetch historical cryptocurrency data
        """
        try:
            # Using yfinance for reliable data
            ticker = yf.Ticker(self.symbol)
            data = ticker.history(period=period, interval=self.timeframe)
            
            if data.empty:
                raise ValueError(f"No data found for symbol {self.symbol}")
                
            # Clean and prepare data
            data = data.dropna()
            data.index = pd.to_datetime(data.index)
            
            print(f"Fetched {len(data)} data points for {self.symbol}")
            return data
            
        except Exception as e:
            print(f"Error fetching data: {e}")
            return None
    
    def calculate_technical_indicators(self, data):
        """
        Calculate comprehensive technical analysis indicators
        """
        df = data.copy()
        
        # Price data
        high = df['High'].values
        low = df['Low'].values
        close = df['Close'].values
        volume = df['Volume'].values
        open_price = df['Open'].values
        
        # Trend Indicators
        df['SMA_20'] = talib.SMA(close, timeperiod=20)
        df['SMA_50'] = talib.SMA(close, timeperiod=50)
        df['SMA_200'] = talib.SMA(close, timeperiod=200)
        df['EMA_12'] = talib.EMA(close, timeperiod=12)
        df['EMA_26'] = talib.EMA(close, timeperiod=26)
        df['EMA_50'] = talib.EMA(close, timeperiod=50)
        
        # MACD
        macd, macd_signal, macd_hist = talib.MACD(close)
        df['MACD'] = macd
        df['MACD_Signal'] = macd_signal
        df['MACD_Histogram'] = macd_hist
        
        # ADX (Average Directional Index)
        df['ADX'] = talib.ADX(high, low, close, timeperiod=14)
        df['DI_Plus'] = talib.PLUS_DI(high, low, close, timeperiod=14)
        df['DI_Minus'] = talib.MINUS_DI(high, low, close, timeperiod=14)
        
        # Parabolic SAR
        df['PSAR'] = talib.SAR(high, low, acceleration=0.02, maximum=0.2)
        
        # Momentum Indicators
        df['RSI'] = talib.RSI(close, timeperiod=14)
        df['RSI_30'] = talib.RSI(close, timeperiod=30)
        
        # Stochastic Oscillator
        slowk, slowd = talib.STOCH(high, low, close)
        df['Stoch_K'] = slowk
        df['Stoch_D'] = slowd
        
        # Williams %R
        df['Williams_R'] = talib.WILLR(high, low, close, timeperiod=14)
        
        # Rate of Change
        df['ROC'] = talib.ROC(close, timeperiod=10)
        
        # Commodity Channel Index
        df['CCI'] = talib.CCI(high, low, close, timeperiod=14)
        
        # Volatility Indicators
        # Bollinger Bands
        bb_upper, bb_middle, bb_lower = talib.BBANDS(close, timeperiod=20)
        df['BB_Upper'] = bb_upper
        df['BB_Middle'] = bb_middle
        df['BB_Lower'] = bb_lower
        df['BB_Width'] = (bb_upper - bb_lower) / bb_middle
        df['BB_Position'] = (close - bb_lower) / (bb_upper - bb_lower)
        
        # Average True Range
        df['ATR'] = talib.ATR(high, low, close, timeperiod=14)
        
        # Volume Indicators
        df['OBV'] = talib.OBV(close, volume)
        df['Volume_SMA'] = talib.SMA(volume, timeperiod=20)
        df['Volume_Ratio'] = volume / df['Volume_SMA']
        
        # Money Flow Index
        df['MFI'] = talib.MFI(high, low, close, volume, timeperiod=14)
        
        # Accumulation/Distribution Line
        df['AD'] = talib.AD(high, low, close, volume)
        
        # Additional Advanced Indicators
        # Ichimoku Cloud components
        df['Tenkan'] = (df['High'].rolling(9).max() + df['Low'].rolling(9).min()) / 2
        df['Kijun'] = (df['High'].rolling(26).max() + df['Low'].rolling(26).min()) / 2
        df['Senkou_A'] = ((df['Tenkan'] + df['Kijun']) / 2).shift(26)
        df['Senkou_B'] = ((df['High'].rolling(52).max() + df['Low'].rolling(52).min()) / 2).shift(26)
        
        # VWAP (Volume Weighted Average Price)
        df['VWAP'] = (df['Close'] * df['Volume']).cumsum() / df['Volume'].cumsum()
        
        # Price action indicators
        df['Price_Change'] = df['Close'].pct_change()
        df['High_Low_Ratio'] = df['High'] / df['Low']
        df['Close_Open_Ratio'] = df['Close'] / df['Open']
        
        # Volatility measures
        df['Price_Volatility'] = df['Price_Change'].rolling(20).std()
        df['Volume_Volatility'] = df['Volume'].pct_change().rolling(20).std()
        
        # Market structure indicators
        df['Higher_High'] = (df['High'] > df['High'].shift(1)).astype(int)
        df['Lower_Low'] = (df['Low'] < df['Low'].shift(1)).astype(int)
        
        # Support and Resistance levels
        df['Resistance'] = df['High'].rolling(20).max()
        df['Support'] = df['Low'].rolling(20).min()
        df['Distance_to_Resistance'] = (df['Resistance'] - df['Close']) / df['Close']
        df['Distance_to_Support'] = (df['Close'] - df['Support']) / df['Close']
        
        return df
    
    def create_features(self, data):
        """
        Create feature matrix for LSTM model
        """
        # Calculate all technical indicators
        df = self.calculate_technical_indicators(data)
        
        # Select features for the model
        feature_columns = [
            'Close', 'Volume', 'High', 'Low', 'Open',
            'SMA_20', 'SMA_50', 'EMA_12', 'EMA_26', 'EMA_50',
            'MACD', 'MACD_Signal', 'MACD_Histogram',
            'RSI', 'RSI_30', 'Stoch_K', 'Stoch_D', 'Williams_R',
            'BB_Upper', 'BB_Lower', 'BB_Width', 'BB_Position',
            'ATR', 'ADX', 'DI_Plus', 'DI_Minus',
            'OBV', 'Volume_Ratio', 'MFI', 'AD',
            'ROC', 'CCI', 'PSAR',
            'Tenkan', 'Kijun', 'VWAP',
            'Price_Change', 'High_Low_Ratio', 'Close_Open_Ratio',
            'Price_Volatility', 'Volume_Volatility',
            'Distance_to_Resistance', 'Distance_to_Support'
        ]
        
        # Remove rows with NaN values
        df = df.dropna()
        
        # Create target variable (next period's price movement)
        df['Target'] = np.where(df['Close'].shift(-1) > df['Close'], 1, 0)
        df['Future_Return'] = (df['Close'].shift(-1) - df['Close']) / df['Close']
        
        # Remove last row (no target)
        df = df[:-1]
        
        return df[feature_columns], df['Target'], df['Future_Return'], df
    
    def prepare_lstm_data(self, features, targets, future_returns):
        """
        Prepare data for LSTM training
        """
        # Scale features
        scaled_features = self.scaler.fit_transform(features)
        
        # Create sequences for LSTM
        X, y, returns = [], [], []
        
        for i in range(self.lookback_window, len(scaled_features)):
            X.append(scaled_features[i-self.lookback_window:i])
            y.append(targets.iloc[i])
            returns.append(future_returns.iloc[i])
        
        return np.array(X), np.array(y), np.array(returns)
    
    def build_lstm_model(self, input_shape):
        """
        Build advanced LSTM model with attention mechanism
        """
        model = Sequential([
            Input(shape=input_shape),
            LSTM(128, return_sequences=True, dropout=0.2, recurrent_dropout=0.2),
            LSTM(64, return_sequences=True, dropout=0.2, recurrent_dropout=0.2),
            LSTM(32, return_sequences=False, dropout=0.2, recurrent_dropout=0.2),
            Dense(50, activation='relu'),
            Dropout(0.3),
            Dense(25, activation='relu'),
            Dropout(0.2),
            Dense(1, activation='sigmoid')  # Binary classification (buy/sell)
        ])
        
        model.compile(
            optimizer=Adam(learning_rate=0.001),
            loss='binary_crossentropy',
            metrics=['accuracy', 'precision', 'recall']
        )
        
        return model
    
    def calculate_confidence_score(self, prediction, technical_signals):
        """
        Calculate confidence score based on prediction and technical analysis alignment
        """
        # Base confidence from model prediction
        base_confidence = abs(prediction - 0.5) * 2  # Convert to 0-1 scale
        
        # Technical analysis confirmation
        technical_score = 0
        total_signals = 0
        
        # RSI confirmation
        if 'RSI' in technical_signals:
            if technical_signals['RSI'] < 30 and prediction > 0.5:  # Oversold + buy signal
                technical_score += 1
            elif technical_signals['RSI'] > 70 and prediction < 0.5:  # Overbought + sell signal
                technical_score += 1
            total_signals += 1
        
        # MACD confirmation
        if 'MACD_Signal' in technical_signals:
            macd_bullish = technical_signals['MACD'] > technical_signals['MACD_Signal']
            if (macd_bullish and prediction > 0.5) or (not macd_bullish and prediction < 0.5):
                technical_score += 1
            total_signals += 1
        
        # Bollinger Bands confirmation
        if 'BB_Position' in technical_signals:
            bb_pos = technical_signals['BB_Position']
            if (bb_pos < 0.2 and prediction > 0.5) or (bb_pos > 0.8 and prediction < 0.5):
                technical_score += 1
            total_signals += 1
        
        # Volume confirmation
        if 'Volume_Ratio' in technical_signals:
            if technical_signals['Volume_Ratio'] > 1.5:  # High volume confirmation
                technical_score += 0.5
            total_signals += 0.5
        
        # Calculate final confidence
        if total_signals > 0:
            technical_confirmation = technical_score / total_signals
            final_confidence = (base_confidence + technical_confirmation) / 2
        else:
            final_confidence = base_confidence
        
        return min(final_confidence, 1.0)
    
    def generate_trading_signal(self, data_row, prediction, confidence):
        """
        Generate trading signal with detailed explanation
        """
        signal_strength = "STRONG" if confidence > 0.8 else "MODERATE" if confidence > 0.6 else "WEAK"
        
        if confidence < self.confidence_threshold:
            return {
                'action': 'HOLD',
                'confidence': confidence,
                'strength': 'LOW',
                'explanation': f"Confidence ({confidence:.2%}) below threshold ({self.confidence_threshold:.0%}). Waiting for clearer signals.",
                'technical_reasons': []
            }
        
        action = 'BUY' if prediction > 0.5 else 'SELL'
        
        # Generate detailed explanation
        reasons = []
        
        # RSI analysis
        rsi = data_row.get('RSI', 50)
        if rsi < 30:
            reasons.append(f"RSI oversold at {rsi:.1f} - potential reversal")
        elif rsi > 70:
            reasons.append(f"RSI overbought at {rsi:.1f} - potential correction")
        
        # MACD analysis
        macd = data_row.get('MACD', 0)
        macd_signal = data_row.get('MACD_Signal', 0)
        if macd > macd_signal:
            reasons.append("MACD bullish crossover - upward momentum")
        else:
            reasons.append("MACD bearish crossover - downward momentum")
        
        # Bollinger Bands analysis
        bb_position = data_row.get('BB_Position', 0.5)
        if bb_position < 0.2:
            reasons.append("Price near lower Bollinger Band - potential bounce")
        elif bb_position > 0.8:
            reasons.append("Price near upper Bollinger Band - potential pullback")
        
        # Volume analysis
        volume_ratio = data_row.get('Volume_Ratio', 1)
        if volume_ratio > 1.5:
            reasons.append(f"High volume confirmation ({volume_ratio:.1f}x average)")
        
        # Trend analysis
        sma_20 = data_row.get('SMA_20', 0)
        sma_50 = data_row.get('SMA_50', 0)
        close_price = data_row.get('Close', 0)
        
        if close_price > sma_20 > sma_50:
            reasons.append("Price above short and medium-term moving averages - uptrend")
        elif close_price < sma_20 < sma_50:
            reasons.append("Price below short and medium-term moving averages - downtrend")
        
        explanation = f"Model predicts {action} with {confidence:.1%} confidence. "
        explanation += f"Signal strength: {signal_strength}. "
        explanation += "Key factors: " + "; ".join(reasons[:3])  # Top 3 reasons
        
        return {
            'action': action,
            'confidence': confidence,
            'strength': signal_strength,
            'explanation': explanation,
            'technical_reasons': reasons,
            'prediction_value': prediction
        }
    
    def train_model(self, data, validation_split=0.2, epochs=100):
        """
        Train the LSTM model
        """
        print("Preparing features and training data...")
        features, targets, future_returns, processed_data = self.create_features(data)
        
        # Prepare LSTM data
        X, y, returns = self.prepare_lstm_data(features, targets, future_returns)
        
        print(f"Training data shape: {X.shape}")
        print(f"Target distribution: {np.bincount(y)}")
        
        # Split data
        split_idx = int(len(X) * (1 - validation_split))
        X_train, X_val = X[:split_idx], X[split_idx:]
        y_train, y_val = y[:split_idx], y[split_idx:]
        
        # Build model
        self.model = self.build_lstm_model((X.shape[1], X.shape[2]))
        
        print("Training LSTM model...")
        history = self.model.fit(
            X_train, y_train,
            validation_data=(X_val, y_val),
            epochs=epochs,
            batch_size=32,
            verbose=1,
            callbacks=[
                tf.keras.callbacks.EarlyStopping(patience=10, restore_best_weights=True),
                tf.keras.callbacks.ReduceLROnPlateau(patience=5, factor=0.5)
            ]
        )
        
        # Evaluate model
        val_predictions = self.model.predict(X_val)
        val_predictions_binary = (val_predictions > 0.5).astype(int).flatten()
        
        accuracy = accuracy_score(y_val, val_predictions_binary)
        precision = precision_score(y_val, val_predictions_binary)
        recall = recall_score(y_val, val_predictions_binary)
        f1 = f1_score(y_val, val_predictions_binary)
        
        print(f"\nModel Performance:")
        print(f"Accuracy: {accuracy:.3f}")
        print(f"Precision: {precision:.3f}")
        print(f"Recall: {recall:.3f}")
        print(f"F1-Score: {f1:.3f}")
        
        return history, processed_data
    
    def predict_with_confidence(self, current_data):
        """
        Make prediction with confidence scoring
        """
        if self.model is None:
            raise ValueError("Model not trained yet. Call train_model() first.")
        
        # Prepare features
        features, _, _, processed_data = self.create_features(current_data)
        
        # Get latest data point
        latest_features = features.iloc[-self.lookback_window:].values
        latest_features_scaled = self.scaler.transform(latest_features)
        
        # Reshape for LSTM
        X = latest_features_scaled.reshape(1, self.lookback_window, -1)
        
        # Make prediction
        prediction = self.model.predict(X, verbose=0)[0][0]
        
        # Get technical signals from latest data
        latest_row = processed_data.iloc[-1]
        technical_signals = latest_row.to_dict()
        
        # Calculate confidence
        confidence = self.calculate_confidence_score(prediction, technical_signals)
        
        # Generate trading signal
        signal = self.generate_trading_signal(latest_row, prediction, confidence)
        
        return signal, latest_row
    
    def backtest_model(self, data, initial_capital=10000):
        """
        Backtest the model performance
        """
        print("Running backtest...")
        
        features, targets, future_returns, processed_data = self.create_features(data)
        X, y, returns = self.prepare_lstm_data(features, targets, future_returns)
        
        # Use last 30% for backtesting
        test_start = int(len(X) * 0.7)
        X_test = X[test_start:]
        y_test = y[test_start:]
        returns_test = returns[test_start:]
        
        predictions = self.model.predict(X_test, verbose=0).flatten()
        
        # Simulate trading
        capital = initial_capital
        position = 0  # 0: no position, 1: long position
        trades = []
        
        for i, (pred, actual_return) in enumerate(zip(predictions, returns_test)):
            current_row = processed_data.iloc[test_start + i]
            confidence = self.calculate_confidence_score(pred, current_row.to_dict())
            
            if confidence >= self.confidence_threshold:
                if pred > 0.5 and position == 0:  # Buy signal
                    position = 1
                    entry_price = current_row['Close']
                    trades.append({
                        'type': 'BUY',
                        'price': entry_price,
                        'confidence': confidence,
                        'timestamp': current_row.name
                    })
                elif pred < 0.5 and position == 1:  # Sell signal
                    position = 0
                    exit_price = current_row['Close']
                    if trades and trades[-1]['type'] == 'BUY':
                        trade_return = (exit_price - trades[-1]['price']) / trades[-1]['price']
                        capital *= (1 + trade_return)
                        trades.append({
                            'type': 'SELL',
                            'price': exit_price,
                            'confidence': confidence,
                            'return': trade_return,
                            'timestamp': current_row.name
                        })
        
        total_return = (capital - initial_capital) / initial_capital
        num_trades = len([t for t in trades if t['type'] == 'SELL'])
        
        if num_trades > 0:
            winning_trades = len([t for t in trades if t['type'] == 'SELL' and t['return'] > 0])
            win_rate = winning_trades / num_trades
        else:
            win_rate = 0
        
        print(f"\nBacktest Results:")
        print(f"Total Return: {total_return:.2%}")
        print(f"Number of Trades: {num_trades}")
        print(f"Win Rate: {win_rate:.2%}")
        print(f"Final Capital: ${capital:.2f}")
        
        return {
            'total_return': total_return,
            'win_rate': win_rate,
            'num_trades': num_trades,
            'final_capital': capital,
            'trades': trades
        }

if __name__ == "__main__":
    # Example usage
    predictor = CryptoPredictorLSTM('BTC-USD', '1h')
    
    # Fetch and train
    data = predictor.fetch_data('1y')
    if data is not None:
        history, processed_data = predictor.train_model(data)
        
        # Make current prediction
        signal, current_data = predictor.predict_with_confidence(data)
        
        print(f"\nCurrent Trading Signal:")
        print(f"Action: {signal['action']}")
        print(f"Confidence: {signal['confidence']:.2%}")
        print(f"Strength: {signal['strength']}")
        print(f"Explanation: {signal['explanation']}")
        
        # Run backtest
        backtest_results = predictor.backtest_model(data)