#!/usr/bin/env python3
"""
Launch script for Crypto Trading AI Predictor
Easy way to start the application with proper checks
"""

import subprocess
import sys
import os
import time
from pathlib import Path

def check_dependencies():
    """Check if all dependencies are installed"""
    print("🔍 Checking dependencies...")
    
    required_packages = [
        'streamlit', 'tensorflow', 'pandas', 'numpy', 
        'yfinance', 'talib', 'plotly', 'scikit-learn'
    ]
    
    missing_packages = []
    
    for package in required_packages:
        try:
            __import__(package.replace('-', '_'))
        except ImportError:
            missing_packages.append(package)
    
    if missing_packages:
        print(f"❌ Missing packages: {', '.join(missing_packages)}")
        print("💡 Run: python setup.py")
        return False
    
    print("✅ All dependencies found")
    return True

def check_files():
    """Check if all required files exist"""
    print("📁 Checking required files...")
    
    required_files = [
        'crypto_ui.py',
        'crypto_predictor.py', 
        'enhanced_predictor.py',
        'advanced_indicators.py',
        'requirements.txt'
    ]
    
    missing_files = []
    
    for file in required_files:
        if not Path(file).exists():
            missing_files.append(file)
    
    if missing_files:
        print(f"❌ Missing files: {', '.join(missing_files)}")
        return False
    
    print("✅ All required files found")
    return True

def launch_streamlit():
    """Launch the Streamlit application"""
    print("🚀 Launching Crypto Trading AI Predictor...")
    print("📱 The app will open in your web browser")
    print("🔗 If it doesn't open automatically, go to: http://localhost:8501")
    print()
    print("⚠️ IMPORTANT REMINDERS:")
    print("   • This tool is for educational purposes only")
    print("   • Always test with paper trading first")
    print("   • Never invest more than you can afford to lose")
    print("   • Cryptocurrency trading involves significant risk")
    print()
    print("🛑 Press Ctrl+C to stop the application")
    print("-" * 60)
    
    try:
        # Launch Streamlit
        subprocess.run([
            sys.executable, '-m', 'streamlit', 'run', 'crypto_ui.py',
            '--server.port=8501',
            '--server.address=localhost',
            '--browser.gatherUsageStats=false'
        ])
    except KeyboardInterrupt:
        print("\n👋 Application stopped by user")
    except Exception as e:
        print(f"\n❌ Error launching application: {e}")
        print("💡 Try running manually: streamlit run crypto_ui.py")

def show_menu():
    """Show interactive menu"""
    print("🚀 Crypto Trading AI Predictor Launcher")
    print("=" * 50)
    print()
    print("Choose an option:")
    print("1. 🚀 Launch Application (Streamlit UI)")
    print("2. 🧪 Run System Tests")
    print("3. ⚙️ Run Setup/Install Dependencies")
    print("4. 📚 View README")
    print("5. ❌ Exit")
    print()
    
    while True:
        try:
            choice = input("Enter your choice (1-5): ").strip()
            
            if choice == '1':
                if check_dependencies() and check_files():
                    launch_streamlit()
                else:
                    print("\n💡 Please run setup first (option 3)")
                break
            
            elif choice == '2':
                print("\n🧪 Running system tests...")
                subprocess.run([sys.executable, 'test_system.py'])
                break
            
            elif choice == '3':
                print("\n⚙️ Running setup...")
                subprocess.run([sys.executable, 'setup.py'])
                break
            
            elif choice == '4':
                if Path('README.md').exists():
                    with open('README.md', 'r') as f:
                        print(f.read())
                else:
                    print("❌ README.md not found")
                break
            
            elif choice == '5':
                print("👋 Goodbye!")
                sys.exit(0)
            
            else:
                print("❌ Invalid choice. Please enter 1-5.")
        
        except KeyboardInterrupt:
            print("\n👋 Goodbye!")
            sys.exit(0)
        except Exception as e:
            print(f"❌ Error: {e}")

def main():
    """Main launcher function"""
    # Check if running with arguments
    if len(sys.argv) > 1:
        arg = sys.argv[1].lower()
        
        if arg in ['--app', '-a', 'app']:
            if check_dependencies() and check_files():
                launch_streamlit()
            else:
                print("❌ Dependencies or files missing. Run setup first.")
                sys.exit(1)
        
        elif arg in ['--test', '-t', 'test']:
            subprocess.run([sys.executable, 'test_system.py'])
        
        elif arg in ['--setup', '-s', 'setup']:
            subprocess.run([sys.executable, 'setup.py'])
        
        elif arg in ['--help', '-h', 'help']:
            print("🚀 Crypto Trading AI Predictor Launcher")
            print()
            print("Usage:")
            print("  python launch.py           # Show interactive menu")
            print("  python launch.py --app     # Launch application directly")
            print("  python launch.py --test    # Run system tests")
            print("  python launch.py --setup   # Run setup")
            print("  python launch.py --help    # Show this help")
        
        else:
            print(f"❌ Unknown argument: {arg}")
            print("💡 Use --help for available options")
    
    else:
        # Show interactive menu
        show_menu()

if __name__ == "__main__":
    main()