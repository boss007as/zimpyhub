#!/usr/bin/env python3
"""
Simplified launcher for systems with limited package availability
"""

import sys
import subprocess

def launch_basic_ui():
    """Launch basic UI with available packages"""
    print("🚀 Launching simplified crypto predictor...")
    
    try:
        # Try to launch Streamlit
        subprocess.run([sys.executable, "-m", "streamlit", "run", "crypto_ui.py"])
    except FileNotFoundError:
        print("❌ Streamlit not found")
        print("💡 Try: pip3 install --user streamlit")
    except Exception as e:
        print(f"❌ Error launching: {e}")
        print("💡 Try running manually: python3 -m streamlit run crypto_ui.py")

def show_manual_instructions():
    """Show manual installation instructions"""
    print("📚 Manual Installation Instructions:")
    print("=" * 50)
    print()
    print("1. Install system packages:")
    print("   sudo apt install python3-numpy python3-pandas python3-matplotlib")
    print()
    print("2. Install Python packages:")
    print("   pip3 install --user streamlit yfinance plotly")
    print()
    print("3. Install TA-Lib:")
    print("   sudo apt install libta-lib-dev")
    print("   pip3 install --user talib-binary")
    print()
    print("4. Install TensorFlow:")
    print("   pip3 install --user tensorflow-cpu")
    print()
    print("5. Launch application:")
    print("   python3 -m streamlit run crypto_ui.py")

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--help":
        show_manual_instructions()
    else:
        launch_basic_ui()
