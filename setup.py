#!/usr/bin/env python3
"""
Setup script for Crypto Trading AI Predictor
Handles installation and initial configuration
"""

import subprocess
import sys
import os
from pathlib import Path

def run_command(command, description):
    """Run a command and handle errors"""
    print(f"🔧 {description}...")
    try:
        result = subprocess.run(command, shell=True, check=True, capture_output=True, text=True)
        print(f"✅ {description} completed successfully")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ {description} failed: {e}")
        print(f"Error output: {e.stderr}")
        return False

def check_python_version():
    """Check if Python version is compatible"""
    version = sys.version_info
    if version.major < 3 or (version.major == 3 and version.minor < 8):
        print(f"❌ Python {version.major}.{version.minor} detected. Python 3.8+ required.")
        return False
    print(f"✅ Python {version.major}.{version.minor} detected - Compatible")
    return True

def install_dependencies():
    """Install required Python packages"""
    print("📦 Installing Python dependencies...")
    
    # Upgrade pip first
    if not run_command(f"{sys.executable} -m pip install --upgrade pip", "Upgrading pip"):
        return False
    
    # Install requirements
    if not run_command(f"{sys.executable} -m pip install -r requirements.txt", "Installing requirements"):
        return False
    
    return True

def install_talib():
    """Install TA-Lib library"""
    print("📊 Installing TA-Lib...")
    
    # Try to install TA-Lib
    try:
        import talib
        print("✅ TA-Lib already installed")
        return True
    except ImportError:
        pass
    
    # Platform-specific installation
    if sys.platform.startswith('linux'):
        print("🐧 Detected Linux - Installing TA-Lib dependencies...")
        commands = [
            "sudo apt-get update",
            "sudo apt-get install -y libta-lib-dev",
            f"{sys.executable} -m pip install TA-Lib"
        ]
        for cmd in commands:
            if not run_command(cmd, f"Running: {cmd}"):
                print("⚠️ TA-Lib installation may have failed. Try manual installation.")
                return False
    
    elif sys.platform == 'darwin':
        print("🍎 Detected macOS - Installing TA-Lib via Homebrew...")
        commands = [
            "brew install ta-lib",
            f"{sys.executable} -m pip install TA-Lib"
        ]
        for cmd in commands:
            if not run_command(cmd, f"Running: {cmd}"):
                print("⚠️ TA-Lib installation may have failed. Try manual installation.")
                return False
    
    elif sys.platform.startswith('win'):
        print("🪟 Detected Windows - Installing TA-Lib...")
        if not run_command(f"{sys.executable} -m pip install talib-binary", "Installing TA-Lib binary"):
            print("⚠️ TA-Lib installation may have failed. Try downloading from: https://www.lfd.uci.edu/~gohlke/pythonlibs/#ta-lib")
            return False
    
    return True

def create_directories():
    """Create necessary directories"""
    directories = ['models', 'data', 'logs', 'results']
    
    for directory in directories:
        path = Path(directory)
        if not path.exists():
            path.mkdir(parents=True, exist_ok=True)
            print(f"📁 Created directory: {directory}")
        else:
            print(f"✅ Directory exists: {directory}")
    
    return True

def test_installation():
    """Test if all components are working"""
    print("🧪 Testing installation...")
    
    try:
        # Test imports
        import numpy as np
        import pandas as pd
        import tensorflow as tf
        import yfinance as yf
        import streamlit as st
        import talib
        import plotly
        
        print("✅ All core packages imported successfully")
        
        # Test TensorFlow GPU (if available)
        if tf.config.list_physical_devices('GPU'):
            print("🚀 GPU acceleration available")
        else:
            print("💻 Using CPU (GPU not available)")
        
        # Test data fetching
        print("📊 Testing data fetching...")
        ticker = yf.Ticker("BTC-USD")
        data = ticker.history(period="5d", interval="1h")
        if not data.empty:
            print("✅ Data fetching works correctly")
        else:
            print("⚠️ Data fetching may have issues")
        
        return True
        
    except ImportError as e:
        print(f"❌ Import error: {e}")
        return False
    except Exception as e:
        print(f"❌ Test failed: {e}")
        return False

def main():
    """Main setup function"""
    print("🚀 Crypto Trading AI Predictor Setup")
    print("=" * 50)
    
    # Check Python version
    if not check_python_version():
        sys.exit(1)
    
    # Create directories
    if not create_directories():
        print("❌ Failed to create directories")
        sys.exit(1)
    
    # Install dependencies
    if not install_dependencies():
        print("❌ Failed to install dependencies")
        sys.exit(1)
    
    # Install TA-Lib
    if not install_talib():
        print("⚠️ TA-Lib installation issues - some features may not work")
    
    # Test installation
    if not test_installation():
        print("❌ Installation test failed")
        sys.exit(1)
    
    print("\n🎉 Setup completed successfully!")
    print("\n📚 Next steps:")
    print("1. Run: streamlit run crypto_ui.py")
    print("2. Configure your settings in the UI")
    print("3. Train your first model")
    print("4. Start getting trading signals!")
    print("\n⚠️ Remember: This is for educational purposes only.")
    print("   Always test with paper trading before using real money!")

if __name__ == "__main__":
    main()