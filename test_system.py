#!/usr/bin/env python3
"""
Test script for Crypto Trading AI Predictor
Quick validation of all system components
"""

import sys
import traceback
from datetime import datetime
import warnings
warnings.filterwarnings('ignore')

def test_imports():
    """Test all required imports"""
    print("🧪 Testing imports...")
    
    try:
        import numpy as np
        import pandas as pd
        import tensorflow as tf
        import yfinance as yf
        import talib
        import streamlit as st
        import plotly.graph_objects as go
        import sklearn
        import joblib
        
        print("✅ All core packages imported successfully")
        
        # Version information
        print(f"📊 TensorFlow version: {tf.__version__}")
        print(f"🐼 Pandas version: {pd.__version__}")
        print(f"🔢 NumPy version: {np.__version__}")
        
        return True
        
    except ImportError as e:
        print(f"❌ Import error: {e}")
        return False

def test_data_fetching():
    """Test cryptocurrency data fetching"""
    print("\n📊 Testing data fetching...")
    
    try:
        import yfinance as yf
        
        # Test fetching BTC data
        ticker = yf.Ticker("BTC-USD")
        data = ticker.history(period="10d", interval="1h")
        
        if data.empty:
            print("❌ No data received")
            return False
        
        print(f"✅ Fetched {len(data)} data points for BTC-USD")
        print(f"📅 Date range: {data.index[0]} to {data.index[-1]}")
        print(f"💰 Latest price: ${data['Close'].iloc[-1]:.2f}")
        
        return True
        
    except Exception as e:
        print(f"❌ Data fetching error: {e}")
        return False

def test_technical_indicators():
    """Test technical indicator calculations"""
    print("\n📈 Testing technical indicators...")
    
    try:
        from advanced_indicators import AdvancedTechnicalIndicators
        import yfinance as yf
        import pandas as pd
        
        # Get sample data
        ticker = yf.Ticker("BTC-USD")
        data = ticker.history(period="30d", interval="1h")
        
        if data.empty:
            print("❌ No data for indicator testing")
            return False
        
        # Calculate indicators
        df_with_indicators = AdvancedTechnicalIndicators.calculate_all_indicators(data)
        
        # Check if indicators were calculated
        indicator_columns = [col for col in df_with_indicators.columns if col not in data.columns]
        
        print(f"✅ Calculated {len(indicator_columns)} technical indicators")
        print(f"📊 Sample indicators: {indicator_columns[:10]}")
        
        # Test signal confluence
        confluence = AdvancedTechnicalIndicators.get_signal_confluence(df_with_indicators, -1)
        print(f"🎯 Signal confluence test: {confluence['signal']} with {confluence['confluence_strength']:.1%} strength")
        
        return True
        
    except Exception as e:
        print(f"❌ Technical indicators error: {e}")
        traceback.print_exc()
        return False

def test_model_creation():
    """Test LSTM model creation"""
    print("\n🧠 Testing LSTM model creation...")
    
    try:
        from enhanced_predictor import EnhancedCryptoPredictorLSTM
        
        # Initialize predictor
        predictor = EnhancedCryptoPredictorLSTM('BTC-USD', '1h')
        
        # Test model architecture creation
        model = predictor.build_advanced_lstm_model((60, 50))  # Sample input shape
        
        print(f"✅ LSTM model created successfully")
        print(f"📊 Model parameters: {model.count_params():,}")
        print(f"🏗️ Model layers: {len(model.layers)}")
        
        return True
        
    except Exception as e:
        print(f"❌ Model creation error: {e}")
        traceback.print_exc()
        return False

def test_feature_preparation():
    """Test feature preparation pipeline"""
    print("\n🔧 Testing feature preparation...")
    
    try:
        from enhanced_predictor import EnhancedCryptoPredictorLSTM
        import yfinance as yf
        
        # Initialize predictor
        predictor = EnhancedCryptoPredictorLSTM('BTC-USD', '1h')
        
        # Get sample data
        ticker = yf.Ticker("BTC-USD")
        data = ticker.history(period="30d", interval="1h")
        
        if data.empty:
            print("❌ No data for feature testing")
            return False
        
        # Prepare features
        df = predictor.prepare_features(data)
        
        print(f"✅ Features prepared successfully")
        print(f"📊 Dataset shape: {df.shape}")
        print(f"🔢 Available features: {len(predictor.selected_features)}")
        print(f"📈 Target distribution: {df['Binary_Target'].value_counts().to_dict()}")
        
        return True
        
    except Exception as e:
        print(f"❌ Feature preparation error: {e}")
        traceback.print_exc()
        return False

def test_confidence_scoring():
    """Test confidence scoring system"""
    print("\n🎯 Testing confidence scoring...")
    
    try:
        from advanced_indicators import ConfidenceScoring
        
        # Sample data for testing
        test_confluence = {
            'confluence_strength': 0.75,
            'bullish_score': 3,
            'bearish_score': 1
        }
        
        # Test confidence calculation
        confidence, factors = ConfidenceScoring.calculate_comprehensive_confidence(
            prediction=0.7,
            technical_confluence=test_confluence,
            market_regime='TRENDING',
            volume_confirmation=True,
            volatility_level='NORMAL'
        )
        
        print(f"✅ Confidence scoring works")
        print(f"🎯 Sample confidence: {confidence:.1%}")
        print(f"📋 Confidence factors: {len(factors)}")
        
        # Test trading decision
        risk_params = {'min_confidence': 0.8, 'min_confluence': 0.6}
        should_trade, reason = ConfidenceScoring.should_trade(
            confidence, test_confluence, 
            {'regime': 'TRENDING', 'volume_confirmation': True}, 
            risk_params
        )
        
        print(f"💡 Trading decision: {should_trade} - {reason}")
        
        return True
        
    except Exception as e:
        print(f"❌ Confidence scoring error: {e}")
        traceback.print_exc()
        return False

def test_streamlit_ui():
    """Test if Streamlit UI can be imported"""
    print("\n🖥️ Testing Streamlit UI components...")
    
    try:
        from crypto_ui import CryptoTradingUI
        
        # Test UI class creation
        ui = CryptoTradingUI()
        
        print("✅ Streamlit UI components loaded successfully")
        print("🚀 Ready to run: streamlit run crypto_ui.py")
        
        return True
        
    except Exception as e:
        print(f"❌ Streamlit UI error: {e}")
        return False

def run_comprehensive_test():
    """Run a quick end-to-end test"""
    print("\n🚀 Running comprehensive system test...")
    
    try:
        from enhanced_predictor import EnhancedCryptoPredictorLSTM
        import yfinance as yf
        
        print("📊 Initializing predictor...")
        predictor = EnhancedCryptoPredictorLSTM('BTC-USD', '1h')
        
        print("📈 Fetching sample data...")
        data = predictor.fetch_comprehensive_data('7d')  # Small dataset for testing
        
        if data is None or data.empty:
            print("❌ Failed to fetch data")
            return False
        
        print("🔧 Preparing features...")
        df = predictor.prepare_features(data)
        
        print("🧠 Creating model architecture...")
        X, y, returns, indices = predictor.create_lstm_sequences(df)
        model = predictor.build_advanced_lstm_model((X.shape[1], X.shape[2]))
        
        print("✅ Comprehensive test completed successfully!")
        print(f"📊 Data points: {len(data)}")
        print(f"🔢 Features: {X.shape[2]}")
        print(f"🎯 Samples: {len(X)}")
        
        return True
        
    except Exception as e:
        print(f"❌ Comprehensive test error: {e}")
        traceback.print_exc()
        return False

def main():
    """Run all tests"""
    print("🧪 Crypto Trading AI Predictor - System Test")
    print("=" * 60)
    print(f"🕐 Test started at: {datetime.now()}")
    print()
    
    tests = [
        ("Import Test", test_imports),
        ("Data Fetching Test", test_data_fetching),
        ("Technical Indicators Test", test_technical_indicators),
        ("Model Creation Test", test_model_creation),
        ("Feature Preparation Test", test_feature_preparation),
        ("Confidence Scoring Test", test_confidence_scoring),
        ("Streamlit UI Test", test_streamlit_ui),
        ("Comprehensive Test", run_comprehensive_test)
    ]
    
    passed = 0
    failed = 0
    
    for test_name, test_func in tests:
        try:
            if test_func():
                passed += 1
            else:
                failed += 1
        except Exception as e:
            print(f"❌ {test_name} crashed: {e}")
            failed += 1
        
        print("-" * 40)
    
    print(f"\n📊 Test Results:")
    print(f"✅ Passed: {passed}")
    print(f"❌ Failed: {failed}")
    print(f"📈 Success Rate: {passed/(passed+failed)*100:.1f}%")
    
    if failed == 0:
        print("\n🎉 All tests passed! System is ready to use.")
        print("\n🚀 To start the application:")
        print("   streamlit run crypto_ui.py")
    else:
        print(f"\n⚠️ {failed} tests failed. Please check the errors above.")
        print("💡 Try running: python setup.py")
    
    print(f"\n🕐 Test completed at: {datetime.now()}")

if __name__ == "__main__":
    main()