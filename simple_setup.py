#!/usr/bin/env python3
"""
Simplified setup for systems with package management restrictions
Works with system Python packages
"""

import subprocess
import sys
import os
import importlib

def check_python_version():
    """Check Python version"""
    version = sys.version_info
    if version.major < 3 or (version.major == 3 and version.minor < 8):
        print(f"❌ Python {version.major}.{version.minor} detected. Python 3.8+ required.")
        return False
    print(f"✅ Python {version.major}.{version.minor} - Compatible")
    return True

def check_package(package_name, import_name=None):
    """Check if a package is available"""
    if import_name is None:
        import_name = package_name
    
    try:
        importlib.import_module(import_name)
        print(f"✅ {package_name} - Available")
        return True
    except ImportError:
        print(f"❌ {package_name} - Missing")
        return False

def install_with_system_packages():
    """Try to install using system package manager"""
    print("📦 Attempting to install system packages...")
    
    # Ubuntu/Debian packages
    system_packages = [
        "python3-numpy",
        "python3-pandas", 
        "python3-sklearn",
        "python3-matplotlib",
        "python3-pip"
    ]
    
    for package in system_packages:
        try:
            cmd = f"sudo apt install -y {package}"
            print(f"Installing {package}...")
            subprocess.run(cmd, shell=True, check=True)
        except subprocess.CalledProcessError:
            print(f"⚠️ Failed to install {package}")

def install_pip_packages():
    """Install packages with pip (with fallback options)"""
    print("🐍 Installing Python packages...")
    
    # Essential packages with fallback options
    packages = [
        ("streamlit", "streamlit"),
        ("yfinance", "yfinance"),
        ("plotly", "plotly"),
        ("joblib", "joblib"),
        ("requests", "requests"),
        ("tqdm", "tqdm")
    ]
    
    # Try different installation methods
    methods = [
        "pip3 install --user",
        "python3 -m pip install --user", 
        "pip3 install --break-system-packages"
    ]
    
    for package_name, import_name in packages:
        if check_package(package_name, import_name):
            continue
            
        installed = False
        for method in methods:
            try:
                cmd = f"{method} {package_name}"
                print(f"Trying: {cmd}")
                subprocess.run(cmd, shell=True, check=True, capture_output=True)
                installed = True
                break
            except subprocess.CalledProcessError:
                continue
        
        if not installed:
            print(f"⚠️ Could not install {package_name}")

def install_talib():
    """Install TA-Lib with multiple fallback options"""
    print("📊 Installing TA-Lib...")
    
    # Check if already available
    if check_package("talib", "talib"):
        return True
    
    # Try different TA-Lib installation methods
    talib_methods = [
        "pip3 install --user talib-binary",
        "python3 -m pip install --user talib-binary",
        "pip3 install --user TA-Lib",
        "pip3 install --break-system-packages talib-binary"
    ]
    
    # Install system dependencies first
    try:
        subprocess.run("sudo apt install -y libta-lib-dev build-essential", shell=True, check=True)
    except subprocess.CalledProcessError:
        print("⚠️ Could not install TA-Lib system dependencies")
    
    # Try installation methods
    for method in talib_methods:
        try:
            print(f"Trying: {method}")
            subprocess.run(method, shell=True, check=True, capture_output=True)
            if check_package("talib", "talib"):
                print("✅ TA-Lib installed successfully")
                return True
        except subprocess.CalledProcessError:
            continue
    
    print("⚠️ TA-Lib installation failed - some features may not work")
    return False

def install_tensorflow():
    """Install TensorFlow with CPU fallback"""
    print("🧠 Installing TensorFlow...")
    
    if check_package("tensorflow", "tensorflow"):
        return True
    
    # Try different TensorFlow versions
    tf_methods = [
        "pip3 install --user tensorflow-cpu",
        "pip3 install --user tensorflow==2.12.0",
        "python3 -m pip install --user tensorflow-cpu",
        "pip3 install --break-system-packages tensorflow-cpu"
    ]
    
    for method in tf_methods:
        try:
            print(f"Trying: {method}")
            subprocess.run(method, shell=True, check=True, capture_output=True)
            if check_package("tensorflow", "tensorflow"):
                print("✅ TensorFlow installed successfully")
                return True
        except subprocess.CalledProcessError:
            continue
    
    print("⚠️ TensorFlow installation failed")
    return False

def create_minimal_requirements():
    """Create a minimal requirements file for manual installation"""
    minimal_reqs = """# Minimal requirements for Crypto Trading AI
# Install these manually if automated installation fails

# Core packages (try system packages first)
numpy>=1.20.0
pandas>=1.3.0
scikit-learn>=1.0.0

# Essential for the application
streamlit>=1.20.0
yfinance>=0.2.0
plotly>=5.0.0
requests>=2.25.0

# Technical analysis (try talib-binary if TA-Lib fails)
talib-binary>=0.4.0

# Machine learning (CPU version is fine)
tensorflow-cpu>=2.10.0

# Utilities
joblib>=1.0.0
tqdm>=4.60.0
"""
    
    with open("minimal_requirements.txt", "w") as f:
        f.write(minimal_reqs)
    
    print("📝 Created minimal_requirements.txt")
    print("💡 You can install manually with: pip3 install --user -r minimal_requirements.txt")

def test_basic_functionality():
    """Test basic functionality"""
    print("🧪 Testing basic functionality...")
    
    # Test core packages
    core_packages = [
        ("numpy", "numpy"),
        ("pandas", "pandas"), 
        ("streamlit", "streamlit"),
        ("yfinance", "yfinance"),
        ("plotly", "plotly")
    ]
    
    working_packages = 0
    total_packages = len(core_packages)
    
    for package_name, import_name in core_packages:
        if check_package(package_name, import_name):
            working_packages += 1
    
    print(f"📊 {working_packages}/{total_packages} core packages working")
    
    if working_packages >= 3:
        print("✅ Minimum functionality available")
        return True
    else:
        print("❌ Too many missing packages")
        return False

def create_simplified_launcher():
    """Create a simplified launcher that works with available packages"""
    launcher_code = '''#!/usr/bin/env python3
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
'''
    
    with open("simple_launch.py", "w") as f:
        f.write(launcher_code)
    
    # Make executable
    try:
        import stat
        os.chmod("simple_launch.py", stat.S_IRWXU | stat.S_IRGRP | stat.S_IROTH)
    except:
        pass
    
    print("✅ Created simple_launch.py")

def main():
    """Main setup function"""
    print("🚀 Simplified Crypto Trading AI Setup")
    print("=" * 50)
    print("This setup works with system package restrictions")
    print()
    
    # Check Python version
    if not check_python_version():
        sys.exit(1)
    
    # Try system packages first
    install_with_system_packages()
    
    # Install pip packages
    install_pip_packages()
    
    # Install TA-Lib
    install_talib()
    
    # Install TensorFlow
    install_tensorflow()
    
    # Test functionality
    if test_basic_functionality():
        print("\n🎉 Basic setup completed!")
        print("\n📚 Next steps:")
        print("1. Run: python3 simple_launch.py")
        print("2. Or manually: python3 -m streamlit run crypto_ui.py")
    else:
        print("\n⚠️ Setup incomplete - creating fallback options...")
        create_minimal_requirements()
        show_manual_instructions()
    
    # Create simplified launcher
    create_simplified_launcher()
    
    print("\n💡 If issues persist, check INSTALL.md for detailed instructions")

def show_manual_instructions():
    """Show manual installation instructions"""
    print("\n📚 Manual Installation Instructions:")
    print("=" * 50)
    print()
    print("# System packages (Ubuntu/Debian):")
    print("sudo apt update")
    print("sudo apt install python3-numpy python3-pandas python3-matplotlib python3-sklearn")
    print("sudo apt install libta-lib-dev build-essential")
    print()
    print("# Python packages:")
    print("pip3 install --user streamlit yfinance plotly talib-binary tensorflow-cpu")
    print()
    print("# Alternative with --break-system-packages (use with caution):")
    print("pip3 install --break-system-packages streamlit yfinance plotly")
    print()
    print("# Launch application:")
    print("python3 -m streamlit run crypto_ui.py")

if __name__ == "__main__":
    main()