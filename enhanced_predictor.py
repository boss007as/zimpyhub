"""
Enhanced Crypto Predictor with Advanced Technical Analysis
High-precision trading system with comprehensive indicator analysis
"""

import numpy as np
import pandas as pd
import tensorflow as tf
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import LSTM, Dense, Dropout, BatchNormalization, Attention
from tensorflow.keras.optimizers import Adam
from tensorflow.keras.callbacks import EarlyStopping, ReduceLROnPlateau, ModelCheckpoint
from sklearn.preprocessing import MinMaxScaler, RobustScaler
from sklearn.model_selection import TimeSeriesSplit
import yfinance as yf
from advanced_indicators import AdvancedTechnicalIndicators, ConfidenceScoring
import joblib
import json
from datetime import datetime, timedelta
import warnings
warnings.filterwarnings('ignore')

class EnhancedCryptoPredictorLSTM:
    """
    Enhanced crypto predictor with advanced technical analysis and confidence scoring
    """
    
    def __init__(self, symbol='BTC-USD', timeframe='1h'):
        self.symbol = symbol
        self.timeframe = timeframe
        self.model = None
        self.feature_scaler = RobustScaler()  # More robust to outliers
        self.target_scaler = MinMaxScaler()
        self.lookback_window = 60
        self.confidence_threshold = 0.8
        self.min_confluence_score = 0.6
        
        # Feature selection for LSTM
        self.selected_features = [
            # Price and basic data
            'Close', 'High', 'Low', 'Open', 'Volume',
            
            # Trend indicators
            'SMA_20', 'SMA_50', 'EMA_12', 'EMA_26', 'EMA_50',
            'MACD', 'MACD_Signal', 'MACD_Histogram',
            'ADX', 'DI_Plus', 'DI_Minus', 'PSAR',
            'Aroon_Up', 'Aroon_Down', 'Aroon_Oscillator',
            
            # Momentum indicators
            'RSI_9', 'RSI_14', 'RSI_21',
            'Stoch_K', 'Stoch_D', 'Fast_Stoch_K',
            'Williams_R', 'ROC_10', 'CCI', 'MOM',
            'ULTOSC', 'BOP',
            
            # Volatility indicators
            'BB_Upper', 'BB_Lower', 'BB_Width', 'BB_Position',
            'ATR', 'ATR_Ratio', 'TRANGE',
            
            # Volume indicators
            'OBV', 'Volume_Ratio', 'MFI', 'AD', 'ADOSC',
            
            # Ichimoku
            'Tenkan', 'Kijun', 'Senkou_A', 'Senkou_B',
            
            # Price action
            'Price_Change', 'High_Low_Ratio', 'Close_Open_Ratio',
            'Body_Size', 'Price_Volatility_10', 'Price_Volatility_20',
            
            # Support/Resistance
            'Distance_to_Resistance', 'Distance_to_Support',
            
            # Market structure
            'Higher_High', 'Lower_Low', 'Uptrend_Strength', 'Downtrend_Strength',
            
            # Composite indicators
            'Trend_Alignment', 'Momentum_Composite', 'Volume_Strength',
            
            # Candlestick patterns
            'Doji', 'Hammer', 'Shooting_Star', 'Engulfing_Bullish'
        ]
        
        # Risk management parameters
        self.risk_params = {
            'min_confidence': 0.8,
            'min_confluence': 0.6,
            'max_position_size': 0.1,  # 10% of portfolio
            'stop_loss_atr_multiplier': 2.0,
            'take_profit_atr_multiplier': 3.0
        }
    
    def fetch_comprehensive_data(self, period='2y'):
        """
        Fetch and prepare comprehensive market data
        """
        try:
            print(f"Fetching {period} of data for {self.symbol}...")
            ticker = yf.Ticker(self.symbol)
            data = ticker.history(period=period, interval=self.timeframe)
            
            if data.empty:
                raise ValueError(f"No data found for {self.symbol}")
            
            # Clean data
            data = data.dropna()
            data.index = pd.to_datetime(data.index)
            
            print(f"✅ Fetched {len(data)} data points")
            return data
            
        except Exception as e:
            print(f"❌ Error fetching data: {e}")
            return None
    
    def prepare_features(self, data):
        """
        Prepare comprehensive feature set with all indicators
        """
        print("🔧 Calculating technical indicators...")
        
        # Calculate all advanced indicators
        df = AdvancedTechnicalIndicators.calculate_all_indicators(data)
        
        # Add market regime analysis
        df = AdvancedTechnicalIndicators.calculate_market_regime(df)
        
        # Add support/resistance levels
        df = AdvancedTechnicalIndicators.calculate_support_resistance_levels(df)
        
        # Add risk metrics
        df = AdvancedTechnicalIndicators.calculate_risk_metrics(df)
        
        # Create target variables
        # Multi-class target: 0=sell, 1=hold, 2=buy
        future_returns = (df['Close'].shift(-1) - df['Close']) / df['Close']
        df['Future_Return'] = future_returns
        
        # Create classification target based on return thresholds
        return_threshold = df['ATR_Ratio'].rolling(20).mean()  # Dynamic threshold
        
        df['Target'] = np.where(
            future_returns > return_threshold,
            2,  # Strong buy
            np.where(
                future_returns > return_threshold * 0.3,
                1,  # Weak buy/hold
                0   # Sell
            )
        )
        
        # Binary target for main model
        df['Binary_Target'] = np.where(future_returns > 0, 1, 0)
        
        # Remove rows with NaN values
        df = df.dropna()
        
        print(f"✅ Prepared {len(df)} samples with {len(self.selected_features)} features")
        
        return df
    
    def create_lstm_sequences(self, df):
        """
        Create sequences for LSTM training with proper feature selection
        """
        # Select and validate features
        available_features = [f for f in self.selected_features if f in df.columns]
        missing_features = [f for f in self.selected_features if f not in df.columns]
        
        if missing_features:
            print(f"⚠️ Missing features: {missing_features}")
        
        print(f"📊 Using {len(available_features)} features for training")
        
        # Prepare feature matrix
        feature_data = df[available_features].values
        targets = df['Binary_Target'].values
        future_returns = df['Future_Return'].values
        
        # Scale features
        scaled_features = self.feature_scaler.fit_transform(feature_data)
        
        # Create sequences
        X, y, returns, indices = [], [], [], []
        
        for i in range(self.lookback_window, len(scaled_features)):
            X.append(scaled_features[i-self.lookback_window:i])
            y.append(targets[i])
            returns.append(future_returns[i])
            indices.append(df.index[i])
        
        return np.array(X), np.array(y), np.array(returns), indices
    
    def build_advanced_lstm_model(self, input_shape):
        """
        Build advanced LSTM architecture with attention and regularization
        """
        model = Sequential([
            # Input layer
            tf.keras.layers.Input(shape=input_shape),
            
            # First LSTM layer with return sequences
            LSTM(128, return_sequences=True, dropout=0.2, recurrent_dropout=0.2),
            BatchNormalization(),
            
            # Second LSTM layer
            LSTM(64, return_sequences=True, dropout=0.2, recurrent_dropout=0.2),
            BatchNormalization(),
            
            # Third LSTM layer
            LSTM(32, return_sequences=False, dropout=0.2, recurrent_dropout=0.2),
            BatchNormalization(),
            
            # Dense layers with regularization
            Dense(50, activation='relu'),
            Dropout(0.3),
            BatchNormalization(),
            
            Dense(25, activation='relu'),
            Dropout(0.2),
            
            # Output layer
            Dense(1, activation='sigmoid')
        ])
        
        # Compile with advanced optimizer
        model.compile(
            optimizer=Adam(learning_rate=0.001, beta_1=0.9, beta_2=0.999),
            loss='binary_crossentropy',
            metrics=['accuracy', 'precision', 'recall', 'f1_score']
        )
        
        return model
    
    def train_with_cross_validation(self, data, n_splits=5, epochs=100):
        """
        Train model with time series cross-validation
        """
        print("🚀 Starting enhanced training with cross-validation...")
        
        # Prepare comprehensive features
        df = self.prepare_features(data)
        X, y, returns, indices = self.create_lstm_sequences(df)
        
        print(f"📈 Training data shape: {X.shape}")
        print(f"🎯 Target distribution: {np.bincount(y)}")
        
        # Time series cross-validation
        tscv = TimeSeriesSplit(n_splits=n_splits)
        cv_scores = []
        
        best_score = 0
        best_model = None
        
        for fold, (train_idx, val_idx) in enumerate(tscv.split(X)):
            print(f"\n📊 Training fold {fold + 1}/{n_splits}")
            
            X_train, X_val = X[train_idx], X[val_idx]
            y_train, y_val = y[train_idx], y[val_idx]
            
            # Build model for this fold
            model = self.build_advanced_lstm_model((X.shape[1], X.shape[2]))
            
            # Callbacks
            callbacks = [
                EarlyStopping(
                    monitor='val_accuracy',
                    patience=15,
                    restore_best_weights=True,
                    verbose=0
                ),
                ReduceLROnPlateau(
                    monitor='val_loss',
                    patience=8,
                    factor=0.5,
                    min_lr=1e-6,
                    verbose=0
                )
            ]
            
            # Train model
            history = model.fit(
                X_train, y_train,
                validation_data=(X_val, y_val),
                epochs=epochs,
                batch_size=32,
                callbacks=callbacks,
                verbose=0
            )
            
            # Evaluate
            val_accuracy = max(history.history['val_accuracy'])
            cv_scores.append(val_accuracy)
            
            print(f"✅ Fold {fold + 1} validation accuracy: {val_accuracy:.3f}")
            
            # Keep best model
            if val_accuracy > best_score:
                best_score = val_accuracy
                best_model = model
                best_history = history
        
        # Use best model
        self.model = best_model
        
        print(f"\n🏆 Cross-validation results:")
        print(f"📊 Mean accuracy: {np.mean(cv_scores):.3f} ± {np.std(cv_scores):.3f}")
        print(f"🎯 Best accuracy: {best_score:.3f}")
        
        return best_history, df
    
    def predict_with_advanced_confidence(self, current_data):
        """
        Make prediction with advanced confidence analysis
        """
        if self.model is None:
            raise ValueError("Model not trained. Call train_with_cross_validation() first.")
        
        # Prepare features
        df = self.prepare_features(current_data)
        
        # Get latest sequence
        available_features = [f for f in self.selected_features if f in df.columns]
        latest_features = df[available_features].iloc[-self.lookback_window:].values
        latest_features_scaled = self.feature_scaler.transform(latest_features)
        
        # Reshape for LSTM
        X = latest_features_scaled.reshape(1, self.lookback_window, -1)
        
        # Model prediction
        prediction = self.model.predict(X, verbose=0)[0][0]
        
        # Get latest market data
        latest_row = df.iloc[-1]
        
        # Technical confluence analysis
        confluence = AdvancedTechnicalIndicators.get_signal_confluence(df, -1)
        
        # Market regime
        market_regime = latest_row.get('Market_Regime', 'UNKNOWN')
        
        # Volume confirmation
        volume_confirmation = latest_row.get('Volume_Ratio', 1) > 1.5
        
        # Volatility level
        volatility_level = latest_row.get('Volatility_Regime', 'NORMAL')
        
        # Calculate comprehensive confidence
        confidence, confidence_factors = ConfidenceScoring.calculate_comprehensive_confidence(
            prediction, confluence, market_regime, volume_confirmation, volatility_level
        )
        
        # Determine if should trade
        market_conditions = {
            'regime': market_regime,
            'volume_confirmation': volume_confirmation,
            'volatility': volatility_level
        }
        
        should_trade, trade_reason = ConfidenceScoring.should_trade(
            confidence, confluence, market_conditions, self.risk_params
        )
        
        # Generate enhanced signal
        signal = self.generate_enhanced_signal(
            prediction, confidence, confluence, latest_row, 
            should_trade, trade_reason, confidence_factors
        )
        
        return signal, latest_row, confluence
    
    def generate_enhanced_signal(self, prediction, confidence, confluence, 
                                latest_row, should_trade, trade_reason, confidence_factors):
        """
        Generate comprehensive trading signal with detailed analysis
        """
        # Determine base action
        if prediction > 0.6:
            base_action = 'STRONG_BUY'
        elif prediction > 0.5:
            base_action = 'BUY'
        elif prediction < 0.4:
            base_action = 'STRONG_SELL'
        elif prediction < 0.5:
            base_action = 'SELL'
        else:
            base_action = 'HOLD'
        
        # Override with confidence check
        if not should_trade:
            final_action = 'HOLD'
            action_reason = trade_reason
        else:
            final_action = base_action
            action_reason = f"High confidence {base_action.lower()} signal"
        
        # Risk management calculations
        current_price = latest_row.get('Close', 0)
        atr = latest_row.get('ATR', 0)
        
        stop_loss = current_price - (self.risk_params['stop_loss_atr_multiplier'] * atr)
        take_profit = current_price + (self.risk_params['take_profit_atr_multiplier'] * atr)
        
        if final_action in ['SELL', 'STRONG_SELL']:
            stop_loss = current_price + (self.risk_params['stop_loss_atr_multiplier'] * atr)
            take_profit = current_price - (self.risk_params['take_profit_atr_multiplier'] * atr)
        
        # Position sizing
        volatility_adj_size = min(
            self.risk_params['max_position_size'],
            self.risk_params['max_position_size'] / (latest_row.get('ATR_Ratio', 0.01) * 100)
        )
        
        # Compile detailed explanation
        explanation_parts = [
            f"Model prediction: {prediction:.1%} ({'bullish' if prediction > 0.5 else 'bearish'})",
            f"Overall confidence: {confidence:.1%}",
            f"Technical confluence: {confluence['confluence_strength']:.1%}",
            action_reason
        ]
        
        detailed_explanation = ". ".join(explanation_parts)
        
        return {
            'action': final_action,
            'confidence': confidence,
            'should_trade': should_trade,
            'prediction_value': prediction,
            'confluence_score': confluence['confluence_strength'],
            'market_regime': latest_row.get('Market_Regime', 'UNKNOWN'),
            'explanation': detailed_explanation,
            'technical_reasons': confluence['explanations'],
            'confidence_factors': confidence_factors,
            'risk_management': {
                'stop_loss': stop_loss,
                'take_profit': take_profit,
                'position_size': volatility_adj_size,
                'risk_reward_ratio': abs(take_profit - current_price) / abs(current_price - stop_loss)
            },
            'market_metrics': {
                'rsi': latest_row.get('RSI_14', 50),
                'macd': latest_row.get('MACD', 0),
                'bb_position': latest_row.get('BB_Position', 0.5),
                'volume_ratio': latest_row.get('Volume_Ratio', 1),
                'atr_ratio': latest_row.get('ATR_Ratio', 0),
                'adx': latest_row.get('ADX', 0)
            }
        }
    
    def comprehensive_backtest(self, data, initial_capital=10000):
        """
        Comprehensive backtesting with advanced metrics
        """
        print("🧪 Running comprehensive backtest...")
        
        df = self.prepare_features(data)
        X, y, returns, indices = self.create_lstm_sequences(df)
        
        # Use last 30% for testing
        test_start = int(len(X) * 0.7)
        X_test = X[test_start:]
        test_indices = indices[test_start:]
        
        # Get predictions
        predictions = self.model.predict(X_test, verbose=0).flatten()
        
        # Simulate trading with advanced logic
        portfolio = {
            'capital': initial_capital,
            'position': 0,  # 0: no position, 1: long, -1: short
            'entry_price': 0,
            'stop_loss': 0,
            'take_profit': 0
        }
        
        trades = []
        daily_returns = []
        max_drawdown = 0
        peak_capital = initial_capital
        
        for i, (pred, timestamp) in enumerate(zip(predictions, test_indices)):
            current_row = df.loc[timestamp]
            current_price = current_row['Close']
            
            # Get confluence analysis
            confluence = AdvancedTechnicalIndicators.get_signal_confluence(
                df.loc[:timestamp], -1
            )
            
            # Calculate confidence
            market_regime = current_row.get('Market_Regime', 'UNKNOWN')
            volume_confirmation = current_row.get('Volume_Ratio', 1) > 1.5
            volatility_level = current_row.get('Volatility_Regime', 'NORMAL')
            
            confidence, _ = ConfidenceScoring.calculate_comprehensive_confidence(
                pred, confluence, market_regime, volume_confirmation, volatility_level
            )
            
            # Check if should trade
            market_conditions = {
                'regime': market_regime,
                'volume_confirmation': volume_confirmation,
                'volatility': volatility_level
            }
            
            should_trade, _ = ConfidenceScoring.should_trade(
                confidence, confluence, market_conditions, self.risk_params
            )
            
            # Trading logic
            if should_trade and confidence >= self.confidence_threshold:
                atr = current_row.get('ATR', 0)
                
                # Entry signals
                if pred > 0.6 and portfolio['position'] == 0:  # Strong buy signal
                    portfolio['position'] = 1
                    portfolio['entry_price'] = current_price
                    portfolio['stop_loss'] = current_price - (2 * atr)
                    portfolio['take_profit'] = current_price + (3 * atr)
                    
                    trades.append({
                        'type': 'BUY',
                        'timestamp': timestamp,
                        'price': current_price,
                        'confidence': confidence,
                        'confluence': confluence['confluence_strength'],
                        'atr': atr
                    })
                
                # Exit signals
                elif (pred < 0.4 or 
                      current_price <= portfolio['stop_loss'] or 
                      current_price >= portfolio['take_profit']) and portfolio['position'] == 1:
                    
                    exit_reason = 'SIGNAL' if pred < 0.4 else ('STOP_LOSS' if current_price <= portfolio['stop_loss'] else 'TAKE_PROFIT')
                    
                    trade_return = (current_price - portfolio['entry_price']) / portfolio['entry_price']
                    portfolio['capital'] *= (1 + trade_return)
                    portfolio['position'] = 0
                    
                    trades.append({
                        'type': 'SELL',
                        'timestamp': timestamp,
                        'price': current_price,
                        'confidence': confidence,
                        'return': trade_return,
                        'exit_reason': exit_reason
                    })
            
            # Track portfolio performance
            if portfolio['position'] == 1:
                unrealized_return = (current_price - portfolio['entry_price']) / portfolio['entry_price']
                current_portfolio_value = portfolio['capital'] * (1 + unrealized_return)
            else:
                current_portfolio_value = portfolio['capital']
            
            daily_returns.append(current_portfolio_value / initial_capital - 1)
            
            # Track drawdown
            if current_portfolio_value > peak_capital:
                peak_capital = current_portfolio_value
            else:
                drawdown = (peak_capital - current_portfolio_value) / peak_capital
                max_drawdown = max(max_drawdown, drawdown)
        
        # Calculate comprehensive metrics
        total_return = (portfolio['capital'] - initial_capital) / initial_capital
        
        completed_trades = [t for t in trades if t['type'] == 'SELL']
        num_trades = len(completed_trades)
        
        if num_trades > 0:
            winning_trades = [t for t in completed_trades if t['return'] > 0]
            win_rate = len(winning_trades) / num_trades
            avg_win = np.mean([t['return'] for t in winning_trades]) if winning_trades else 0
            avg_loss = np.mean([t['return'] for t in completed_trades if t['return'] < 0])
            profit_factor = abs(avg_win / avg_loss) if avg_loss < 0 else float('inf')
        else:
            win_rate = 0
            avg_win = 0
            avg_loss = 0
            profit_factor = 0
        
        # Sharpe ratio (simplified)
        if len(daily_returns) > 0:
            sharpe_ratio = np.mean(daily_returns) / np.std(daily_returns) * np.sqrt(252) if np.std(daily_returns) > 0 else 0
        else:
            sharpe_ratio = 0
        
        results = {
            'total_return': total_return,
            'win_rate': win_rate,
            'num_trades': num_trades,
            'final_capital': portfolio['capital'],
            'max_drawdown': max_drawdown,
            'profit_factor': profit_factor,
            'sharpe_ratio': sharpe_ratio,
            'avg_win': avg_win,
            'avg_loss': avg_loss,
            'trades': trades,
            'daily_returns': daily_returns
        }
        
        print(f"\n🏆 Backtest Results:")
        print(f"📈 Total Return: {total_return:.2%}")
        print(f"🎯 Win Rate: {win_rate:.1%}")
        print(f"💰 Final Capital: ${portfolio['capital']:.2f}")
        print(f"📉 Max Drawdown: {max_drawdown:.2%}")
        print(f"⚡ Sharpe Ratio: {sharpe_ratio:.2f}")
        print(f"🔢 Number of Trades: {num_trades}")
        
        return results
    
    def save_model(self, filepath='crypto_model'):
        """
        Save trained model and scalers
        """
        if self.model is None:
            raise ValueError("No model to save")
        
        # Save model
        self.model.save(f"{filepath}.h5")
        
        # Save scalers
        joblib.dump(self.feature_scaler, f"{filepath}_feature_scaler.pkl")
        
        # Save configuration
        config = {
            'symbol': self.symbol,
            'timeframe': self.timeframe,
            'lookback_window': self.lookback_window,
            'confidence_threshold': self.confidence_threshold,
            'selected_features': self.selected_features,
            'risk_params': self.risk_params
        }
        
        with open(f"{filepath}_config.json", 'w') as f:
            json.dump(config, f, indent=2)
        
        print(f"✅ Model saved to {filepath}")
    
    def load_model(self, filepath='crypto_model'):
        """
        Load trained model and scalers
        """
        try:
            # Load model
            self.model = tf.keras.models.load_model(f"{filepath}.h5")
            
            # Load scalers
            self.feature_scaler = joblib.load(f"{filepath}_feature_scaler.pkl")
            
            # Load configuration
            with open(f"{filepath}_config.json", 'r') as f:
                config = json.load(f)
            
            self.symbol = config['symbol']
            self.timeframe = config['timeframe']
            self.lookback_window = config['lookback_window']
            self.confidence_threshold = config['confidence_threshold']
            self.selected_features = config['selected_features']
            self.risk_params = config['risk_params']
            
            print(f"✅ Model loaded from {filepath}")
            return True
            
        except Exception as e:
            print(f"❌ Error loading model: {e}")
            return False

# Example usage and testing
if __name__ == "__main__":
    # Initialize enhanced predictor
    predictor = EnhancedCryptoPredictorLSTM('BTC-USD', '1h')
    
    # Fetch data and train
    print("🚀 Starting enhanced crypto predictor...")
    data = predictor.fetch_comprehensive_data('1y')
    
    if data is not None:
        # Train with cross-validation
        history, processed_data = predictor.train_with_cross_validation(data, epochs=50)
        
        # Run comprehensive backtest
        backtest_results = predictor.comprehensive_backtest(data)
        
        # Make current prediction
        signal, current_data, confluence = predictor.predict_with_advanced_confidence(data)
        
        print(f"\n🎯 Current Trading Signal:")
        print(f"Action: {signal['action']}")
        print(f"Confidence: {signal['confidence']:.1%}")
        print(f"Should Trade: {signal['should_trade']}")
        print(f"Explanation: {signal['explanation']}")
        
        # Save model
        predictor.save_model('enhanced_crypto_model')
        
        print("\n✅ Enhanced crypto predictor ready!")
    else:
        print("❌ Failed to fetch data")