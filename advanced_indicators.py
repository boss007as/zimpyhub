"""
Advanced Technical Indicators for Crypto Trading
Comprehensive collection of professional trading indicators
"""

import numpy as np
import pandas as pd
import talib
from typing import Dict, List, Tuple

class AdvancedTechnicalIndicators:
    """
    Professional-grade technical indicators used by institutional traders
    """
    
    @staticmethod
    def calculate_all_indicators(data: pd.DataFrame) -> pd.DataFrame:
        """
        Calculate comprehensive set of technical indicators
        """
        df = data.copy()
        high = df['High'].values
        low = df['Low'].values
        close = df['Close'].values
        volume = df['Volume'].values
        open_price = df['Open'].values
        
        # === TREND INDICATORS ===
        
        # Moving Averages (Multiple timeframes)
        for period in [5, 10, 20, 50, 100, 200]:
            df[f'SMA_{period}'] = talib.SMA(close, timeperiod=period)
            df[f'EMA_{period}'] = talib.EMA(close, timeperiod=period)
        
        # MACD with multiple settings
        macd, macd_signal, macd_hist = talib.MACD(close, fastperiod=12, slowperiod=26, signalperiod=9)
        df['MACD'] = macd
        df['MACD_Signal'] = macd_signal
        df['MACD_Histogram'] = macd_hist
        
        # Additional MACD timeframes
        macd_fast, macd_signal_fast, macd_hist_fast = talib.MACD(close, fastperiod=5, slowperiod=13, signalperiod=5)
        df['MACD_Fast'] = macd_fast
        df['MACD_Signal_Fast'] = macd_signal_fast
        
        # Directional Movement Index (ADX)
        df['ADX'] = talib.ADX(high, low, close, timeperiod=14)
        df['DI_Plus'] = talib.PLUS_DI(high, low, close, timeperiod=14)
        df['DI_Minus'] = talib.MINUS_DI(high, low, close, timeperiod=14)
        
        # Parabolic SAR
        df['PSAR'] = talib.SAR(high, low, acceleration=0.02, maximum=0.2)
        
        # Aroon Oscillator
        aroon_down, aroon_up = talib.AROON(high, low, timeperiod=14)
        df['Aroon_Up'] = aroon_up
        df['Aroon_Down'] = aroon_down
        df['Aroon_Oscillator'] = aroon_up - aroon_down
        
        # === MOMENTUM INDICATORS ===
        
        # RSI with multiple timeframes
        for period in [9, 14, 21, 30]:
            df[f'RSI_{period}'] = talib.RSI(close, timeperiod=period)
        
        # Stochastic Oscillator
        slowk, slowd = talib.STOCH(high, low, close, fastk_period=14, slowk_period=3, slowd_period=3)
        df['Stoch_K'] = slowk
        df['Stoch_D'] = slowd
        
        # Fast Stochastic
        fastk, fastd = talib.STOCHF(high, low, close, fastk_period=5, fastd_period=3)
        df['Fast_Stoch_K'] = fastk
        df['Fast_Stoch_D'] = fastd
        
        # Williams %R
        df['Williams_R'] = talib.WILLR(high, low, close, timeperiod=14)
        
        # Rate of Change
        for period in [10, 20, 30]:
            df[f'ROC_{period}'] = talib.ROC(close, timeperiod=period)
        
        # Commodity Channel Index
        df['CCI'] = talib.CCI(high, low, close, timeperiod=14)
        df['CCI_20'] = talib.CCI(high, low, close, timeperiod=20)
        
        # Momentum
        df['MOM'] = talib.MOM(close, timeperiod=10)
        
        # === VOLATILITY INDICATORS ===
        
        # Bollinger Bands
        bb_upper, bb_middle, bb_lower = talib.BBANDS(close, timeperiod=20, nbdevup=2, nbdevdn=2)
        df['BB_Upper'] = bb_upper
        df['BB_Middle'] = bb_middle
        df['BB_Lower'] = bb_lower
        df['BB_Width'] = (bb_upper - bb_lower) / bb_middle
        df['BB_Position'] = (close - bb_lower) / (bb_upper - bb_lower)
        
        # Bollinger Bands with different settings
        bb_upper_10, bb_middle_10, bb_lower_10 = talib.BBANDS(close, timeperiod=10, nbdevup=2, nbdevdn=2)
        df['BB_Width_10'] = (bb_upper_10 - bb_lower_10) / bb_middle_10
        
        # Average True Range
        df['ATR'] = talib.ATR(high, low, close, timeperiod=14)
        df['ATR_Ratio'] = df['ATR'] / close
        
        # True Range
        df['TRANGE'] = talib.TRANGE(high, low, close)
        
        # === VOLUME INDICATORS ===
        
        # On-Balance Volume
        df['OBV'] = talib.OBV(close, volume)
        
        # Volume moving averages
        df['Volume_SMA_20'] = talib.SMA(volume, timeperiod=20)
        df['Volume_SMA_50'] = talib.SMA(volume, timeperiod=50)
        df['Volume_Ratio'] = volume / df['Volume_SMA_20']
        
        # Money Flow Index
        df['MFI'] = talib.MFI(high, low, close, volume, timeperiod=14)
        
        # Accumulation/Distribution Line
        df['AD'] = talib.AD(high, low, close, volume)
        
        # Chaikin A/D Oscillator
        df['ADOSC'] = talib.ADOSC(high, low, close, volume, fastperiod=3, slowperiod=10)
        
        # === PRICE ACTION INDICATORS ===
        
        # Price changes and ratios
        df['Price_Change'] = close / np.roll(close, 1) - 1
        df['High_Low_Ratio'] = high / low
        df['Close_Open_Ratio'] = close / open_price
        df['Body_Size'] = abs(close - open_price) / open_price
        
        # Volatility measures
        df['Price_Volatility_10'] = df['Price_Change'].rolling(10).std()
        df['Price_Volatility_20'] = df['Price_Change'].rolling(20).std()
        df['Volume_Volatility'] = (volume / np.roll(volume, 1) - 1).rolling(20).std()
        
        # === ICHIMOKU CLOUD ===
        
        # Ichimoku components
        df['Tenkan'] = (df['High'].rolling(9).max() + df['Low'].rolling(9).min()) / 2
        df['Kijun'] = (df['High'].rolling(26).max() + df['Low'].rolling(26).min()) / 2
        df['Senkou_A'] = ((df['Tenkan'] + df['Kijun']) / 2).shift(26)
        df['Senkou_B'] = ((df['High'].rolling(52).max() + df['Low'].rolling(52).min()) / 2).shift(26)
        df['Chikou'] = close.shift(-26)
        
        # === FIBONACCI AND SUPPORT/RESISTANCE ===
        
        # Dynamic support and resistance
        df['Resistance_20'] = df['High'].rolling(20).max()
        df['Support_20'] = df['Low'].rolling(20).min()
        df['Resistance_50'] = df['High'].rolling(50).max()
        df['Support_50'] = df['Low'].rolling(50).min()
        
        # Distance to key levels
        df['Distance_to_Resistance'] = (df['Resistance_20'] - close) / close
        df['Distance_to_Support'] = (close - df['Support_20']) / close
        
        # === MARKET STRUCTURE ===
        
        # Higher highs and lower lows
        df['Higher_High'] = (df['High'] > df['High'].shift(1)).astype(int)
        df['Lower_Low'] = (df['Low'] < df['Low'].shift(1)).astype(int)
        df['Higher_Low'] = (df['Low'] > df['Low'].shift(1)).astype(int)
        df['Lower_High'] = (df['High'] < df['High'].shift(1)).astype(int)
        
        # Trend strength
        df['Uptrend_Strength'] = df['Higher_High'].rolling(10).sum()
        df['Downtrend_Strength'] = df['Lower_Low'].rolling(10).sum()
        
        # === ADVANCED OSCILLATORS ===
        
        # Ultimate Oscillator
        df['ULTOSC'] = talib.ULTOSC(high, low, close, timeperiod1=7, timeperiod2=14, timeperiod3=28)
        
        # Balance of Power
        df['BOP'] = talib.BOP(open_price, high, low, close)
        
        # === PATTERN RECOGNITION ===
        
        # Candlestick patterns (key ones)
        df['Doji'] = talib.CDLDOJI(open_price, high, low, close)
        df['Hammer'] = talib.CDLHAMMER(open_price, high, low, close)
        df['Shooting_Star'] = talib.CDLSHOOTINGSTAR(open_price, high, low, close)
        df['Engulfing_Bullish'] = talib.CDLENGULFING(open_price, high, low, close)
        df['Morning_Star'] = talib.CDLMORNINGSTAR(open_price, high, low, close)
        df['Evening_Star'] = talib.CDLEVENINGSTAR(open_price, high, low, close)
        
        # === CUSTOM COMPOSITE INDICATORS ===
        
        # Multi-timeframe trend alignment
        df['Trend_Alignment'] = (
            (close > df['SMA_20']).astype(int) +
            (df['SMA_20'] > df['SMA_50']).astype(int) +
            (df['SMA_50'] > df['SMA_200']).astype(int)
        ) / 3
        
        # Momentum composite
        df['Momentum_Composite'] = (
            ((df['RSI_14'] - 50) / 50) +
            (df['Stoch_K'] - 50) / 50 +
            (df['Williams_R'] + 50) / 50
        ) / 3
        
        # Volume strength
        df['Volume_Strength'] = (
            (df['Volume_Ratio'] > 1.5).astype(int) +
            (df['OBV'] > df['OBV'].shift(1)).astype(int) +
            (df['MFI'] > 50).astype(int)
        ) / 3
        
        # Volatility regime
        df['Volatility_Regime'] = np.where(
            df['ATR_Ratio'] > df['ATR_Ratio'].rolling(50).quantile(0.8),
            'HIGH',
            np.where(
                df['ATR_Ratio'] < df['ATR_Ratio'].rolling(50).quantile(0.2),
                'LOW',
                'NORMAL'
            )
        )
        
        return df
    
    @staticmethod
    def get_signal_confluence(df: pd.DataFrame, index: int) -> Dict:
        """
        Analyze signal confluence from multiple indicators
        """
        row = df.iloc[index]
        signals = {'bullish': 0, 'bearish': 0, 'neutral': 0}
        explanations = []
        
        # RSI signals
        rsi = row.get('RSI_14', 50)
        if rsi < 30:
            signals['bullish'] += 2
            explanations.append(f"RSI oversold ({rsi:.1f}) - strong buy signal")
        elif rsi > 70:
            signals['bearish'] += 2
            explanations.append(f"RSI overbought ({rsi:.1f}) - strong sell signal")
        elif rsi < 40:
            signals['bullish'] += 1
            explanations.append(f"RSI below 40 ({rsi:.1f}) - bullish bias")
        elif rsi > 60:
            signals['bearish'] += 1
            explanations.append(f"RSI above 60 ({rsi:.1f}) - bearish bias")
        
        # MACD signals
        macd = row.get('MACD', 0)
        macd_signal = row.get('MACD_Signal', 0)
        macd_hist = row.get('MACD_Histogram', 0)
        
        if macd > macd_signal and macd_hist > 0:
            signals['bullish'] += 2
            explanations.append("MACD bullish crossover with positive histogram")
        elif macd < macd_signal and macd_hist < 0:
            signals['bearish'] += 2
            explanations.append("MACD bearish crossover with negative histogram")
        
        # Bollinger Bands signals
        bb_position = row.get('BB_Position', 0.5)
        if bb_position < 0.1:
            signals['bullish'] += 2
            explanations.append(f"Price at lower Bollinger Band ({bb_position:.2f}) - oversold")
        elif bb_position > 0.9:
            signals['bearish'] += 2
            explanations.append(f"Price at upper Bollinger Band ({bb_position:.2f}) - overbought")
        
        # Volume confirmation
        volume_ratio = row.get('Volume_Ratio', 1)
        if volume_ratio > 2:
            explanations.append(f"High volume confirmation ({volume_ratio:.1f}x average)")
        
        # Trend alignment
        trend_alignment = row.get('Trend_Alignment', 0.5)
        if trend_alignment > 0.8:
            signals['bullish'] += 1
            explanations.append("Strong uptrend alignment across timeframes")
        elif trend_alignment < 0.2:
            signals['bearish'] += 1
            explanations.append("Strong downtrend alignment across timeframes")
        
        # ADX trend strength
        adx = row.get('ADX', 0)
        if adx > 25:
            explanations.append(f"Strong trend detected (ADX: {adx:.1f})")
        
        # Calculate overall signal strength
        total_signals = signals['bullish'] + signals['bearish'] + signals['neutral']
        if total_signals > 0:
            bullish_ratio = signals['bullish'] / total_signals
            bearish_ratio = signals['bearish'] / total_signals
        else:
            bullish_ratio = bearish_ratio = 0
        
        # Determine overall signal
        if bullish_ratio > 0.6:
            overall_signal = 'STRONG_BUY'
        elif bullish_ratio > 0.4:
            overall_signal = 'BUY'
        elif bearish_ratio > 0.6:
            overall_signal = 'STRONG_SELL'
        elif bearish_ratio > 0.4:
            overall_signal = 'SELL'
        else:
            overall_signal = 'HOLD'
        
        return {
            'signal': overall_signal,
            'bullish_score': signals['bullish'],
            'bearish_score': signals['bearish'],
            'bullish_ratio': bullish_ratio,
            'bearish_ratio': bearish_ratio,
            'explanations': explanations[:5],  # Top 5 explanations
            'confluence_strength': max(bullish_ratio, bearish_ratio)
        }
    
    @staticmethod
    def calculate_market_regime(df: pd.DataFrame) -> pd.DataFrame:
        """
        Identify market regime (trending, ranging, volatile)
        """
        # ADX for trend strength
        adx = df['ADX'].rolling(10).mean()
        
        # Volatility measure
        volatility = df['ATR_Ratio'].rolling(20).mean()
        
        # Price efficiency (how much price moves vs. path taken)
        price_efficiency = abs(df['Close'] - df['Close'].shift(20)) / df['ATR'].rolling(20).sum()
        
        # Classify regime
        regime = []
        for i in range(len(df)):
            if i < 20:
                regime.append('UNKNOWN')
                continue
                
            current_adx = adx.iloc[i] if not pd.isna(adx.iloc[i]) else 0
            current_vol = volatility.iloc[i] if not pd.isna(volatility.iloc[i]) else 0
            current_eff = price_efficiency.iloc[i] if not pd.isna(price_efficiency.iloc[i]) else 0
            
            if current_adx > 25 and current_eff > 0.3:
                regime.append('TRENDING')
            elif current_vol > df['ATR_Ratio'].quantile(0.8):
                regime.append('VOLATILE')
            else:
                regime.append('RANGING')
        
        df['Market_Regime'] = regime
        return df
    
    @staticmethod
    def calculate_support_resistance_levels(df: pd.DataFrame, window: int = 20) -> pd.DataFrame:
        """
        Calculate dynamic support and resistance levels
        """
        # Pivot points
        df['Pivot'] = (df['High'] + df['Low'] + df['Close']) / 3
        df['R1'] = 2 * df['Pivot'] - df['Low']
        df['S1'] = 2 * df['Pivot'] - df['High']
        df['R2'] = df['Pivot'] + (df['High'] - df['Low'])
        df['S2'] = df['Pivot'] - (df['High'] - df['Low'])
        
        # Dynamic levels based on recent price action
        df['Dynamic_Resistance'] = df['High'].rolling(window).max()
        df['Dynamic_Support'] = df['Low'].rolling(window).min()
        
        # Fibonacci retracement levels (simplified)
        high_20 = df['High'].rolling(20).max()
        low_20 = df['Low'].rolling(20).min()
        range_20 = high_20 - low_20
        
        df['Fib_23.6'] = high_20 - 0.236 * range_20
        df['Fib_38.2'] = high_20 - 0.382 * range_20
        df['Fib_50.0'] = high_20 - 0.500 * range_20
        df['Fib_61.8'] = high_20 - 0.618 * range_20
        
        return df
    
    @staticmethod
    def calculate_risk_metrics(df: pd.DataFrame) -> pd.DataFrame:
        """
        Calculate risk and money management metrics
        """
        # Volatility-based stop loss
        df['Stop_Loss_Long'] = df['Close'] - 2 * df['ATR']
        df['Stop_Loss_Short'] = df['Close'] + 2 * df['ATR']
        
        # Position sizing based on volatility
        df['Position_Size'] = 1 / (df['ATR_Ratio'] * 100)  # Inverse volatility sizing
        
        # Risk-reward ratio
        df['Risk_Reward_Ratio'] = df['ATR'] / abs(df['Close'] - df['Support_20'])
        
        # Maximum favorable excursion
        df['MFE_Long'] = (df['High'].rolling(5).max() - df['Close']) / df['Close']
        df['MAE_Long'] = (df['Close'] - df['Low'].rolling(5).min()) / df['Close']
        
        return df

class ConfidenceScoring:
    """
    Advanced confidence scoring system for trading signals
    """
    
    @staticmethod
    def calculate_comprehensive_confidence(
        prediction: float,
        technical_confluence: Dict,
        market_regime: str,
        volume_confirmation: bool,
        volatility_level: str
    ) -> Tuple[float, List[str]]:
        """
        Calculate comprehensive confidence score
        """
        confidence_factors = []
        base_score = abs(prediction - 0.5) * 2  # Base model confidence
        
        # Technical confluence boost
        confluence_score = technical_confluence.get('confluence_strength', 0)
        if confluence_score > 0.7:
            base_score += 0.2
            confidence_factors.append(f"Strong technical confluence ({confluence_score:.1%})")
        elif confluence_score > 0.5:
            base_score += 0.1
            confidence_factors.append(f"Moderate technical confluence ({confluence_score:.1%})")
        
        # Market regime adjustment
        if market_regime == 'TRENDING':
            base_score += 0.1
            confidence_factors.append("Trending market favors directional trades")
        elif market_regime == 'RANGING':
            base_score -= 0.1
            confidence_factors.append("Ranging market reduces confidence")
        elif market_regime == 'VOLATILE':
            base_score -= 0.15
            confidence_factors.append("High volatility increases uncertainty")
        
        # Volume confirmation
        if volume_confirmation:
            base_score += 0.1
            confidence_factors.append("Volume confirms price movement")
        
        # Volatility adjustment
        if volatility_level == 'LOW':
            base_score += 0.05
            confidence_factors.append("Low volatility supports prediction")
        elif volatility_level == 'HIGH':
            base_score -= 0.1
            confidence_factors.append("High volatility reduces confidence")
        
        # Cap confidence at 95%
        final_confidence = min(base_score, 0.95)
        
        return final_confidence, confidence_factors
    
    @staticmethod
    def should_trade(
        confidence: float,
        confluence: Dict,
        market_conditions: Dict,
        risk_parameters: Dict
    ) -> Tuple[bool, str]:
        """
        Determine if conditions are suitable for trading
        """
        min_confidence = risk_parameters.get('min_confidence', 0.8)
        min_confluence = risk_parameters.get('min_confluence', 0.6)
        
        reasons = []
        
        # Check confidence threshold
        if confidence < min_confidence:
            return False, f"Confidence ({confidence:.1%}) below threshold ({min_confidence:.1%})"
        
        # Check technical confluence
        if confluence.get('confluence_strength', 0) < min_confluence:
            confluence_strength = confluence.get('confluence_strength', 0)
            return False, f"Technical confluence ({confluence_strength:.1%}) below threshold ({min_confluence:.1%})"
        
        # Check market conditions
        if market_conditions.get('regime') == 'VOLATILE':
            return False, "Market too volatile for high-confidence trading"
        
        # Check volume confirmation
        if not market_conditions.get('volume_confirmation', False):
            return False, "Insufficient volume confirmation"
        
        # All conditions met
        return True, "All conditions met for high-confidence trade"

# Export functions for easy import
__all__ = ['AdvancedTechnicalIndicators', 'ConfidenceScoring']