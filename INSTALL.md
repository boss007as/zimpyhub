# 🚀 Installation Guide - Crypto Trading AI Predictor

This guide will help you install and set up the Crypto Trading AI Predictor on your system.

## 📋 System Requirements

- **Python 3.8+** (Python 3.9+ recommended)
- **4GB+ RAM** (8GB+ recommended for training)
- **2GB+ free disk space**
- **Internet connection** (for data fetching)
- **Optional**: GPU for faster training (CUDA-compatible)

## 🐧 Linux Installation (Ubuntu/Debian)

### Step 1: Install System Dependencies
```bash
# Update package list
sudo apt update

# Install Python and essential tools
sudo apt install -y python3 python3-pip python3-venv python3-dev

# Install TA-Lib dependencies
sudo apt install -y build-essential libta-lib-dev

# Optional: Install GPU support (if you have NVIDIA GPU)
# sudo apt install nvidia-driver-470 nvidia-cuda-toolkit
```

### Step 2: Create Virtual Environment
```bash
# Create virtual environment
python3 -m venv crypto_env

# Activate virtual environment
source crypto_env/bin/activate

# Upgrade pip
pip install --upgrade pip
```

### Step 3: Install Python Dependencies
```bash
# Install all requirements
pip install -r requirements.txt

# If TA-Lib installation fails, try:
pip install talib-binary
```

## 🍎 macOS Installation

### Step 1: Install Homebrew (if not installed)
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Step 2: Install Dependencies
```bash
# Install Python and TA-Lib
brew install python ta-lib

# Create virtual environment
python3 -m venv crypto_env
source crypto_env/bin/activate

# Install Python packages
pip install --upgrade pip
pip install -r requirements.txt
```

## 🪟 Windows Installation

### Step 1: Install Python
1. Download Python from [python.org](https://python.org)
2. **Important**: Check "Add Python to PATH" during installation
3. Install with "pip" option enabled

### Step 2: Install TA-Lib
```cmd
# Option 1: Try binary wheel
pip install talib-binary

# Option 2: If above fails, download from:
# https://www.lfd.uci.edu/~gohlke/pythonlibs/#ta-lib
# Then install the downloaded .whl file:
# pip install TA_Lib-0.4.XX-cpXX-cpXX-winXX.whl
```

### Step 3: Create Virtual Environment
```cmd
# Create virtual environment
python -m venv crypto_env

# Activate virtual environment
crypto_env\Scripts\activate

# Install dependencies
pip install --upgrade pip
pip install -r requirements.txt
```

## 🐳 Docker Installation (Recommended for Easy Setup)

### Create Dockerfile
```dockerfile
FROM python:3.9-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libta-lib-dev \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements and install Python packages
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY . .

# Expose Streamlit port
EXPOSE 8501

# Run the application
CMD ["streamlit", "run", "crypto_ui.py", "--server.port=8501", "--server.address=0.0.0.0"]
```

### Build and Run
```bash
# Build Docker image
docker build -t crypto-predictor .

# Run container
docker run -p 8501:8501 crypto-predictor
```

## 🔧 Alternative Installation Methods

### Method 1: Using System Packages (Linux)
If you can't create virtual environments:

```bash
# Install using system package manager
sudo apt install -y python3-numpy python3-pandas python3-sklearn
sudo apt install -y python3-tensorflow python3-matplotlib
sudo apt install -y python3-streamlit

# Install remaining packages with --break-system-packages (use with caution)
pip3 install --break-system-packages yfinance talib-binary plotly
```

### Method 2: Using Conda
```bash
# Install Miniconda
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh

# Create conda environment
conda create -n crypto_env python=3.9
conda activate crypto_env

# Install packages
conda install numpy pandas scikit-learn tensorflow matplotlib
pip install streamlit yfinance talib plotly
```

## 📦 Package-by-Package Installation

If you encounter issues with `requirements.txt`, install packages individually:

```bash
# Core packages
pip install numpy==1.24.3
pip install pandas==2.0.3
pip install scikit-learn==1.3.0

# Machine Learning
pip install tensorflow==2.13.0
pip install keras==2.13.1

# Technical Analysis
pip install talib-binary==0.4.26
pip install ta==0.10.2
pip install pandas-ta==0.3.14b0

# Data Sources
pip install yfinance==0.2.18
pip install ccxt==4.0.77
pip install requests==2.31.0

# Visualization
pip install matplotlib==3.7.2
pip install plotly==5.15.0
pip install seaborn==0.12.2
pip install streamlit==1.25.0

# Utilities
pip install joblib==1.3.2
pip install python-dotenv==1.0.0
pip install tqdm==4.65.0
```

## 🧪 Verify Installation

### Quick Test
```bash
# Test Python imports
python3 -c "import numpy, pandas, tensorflow, yfinance, streamlit; print('✅ All packages installed successfully')"

# Run system test
python3 test_system.py

# Launch application
python3 launch.py
```

### Full Test
```bash
# Run comprehensive test
python3 test_system.py

# If all tests pass, launch the UI
streamlit run crypto_ui.py
```

## 🚨 Troubleshooting

### Common Issues and Solutions

#### 1. TA-Lib Installation Failed
```bash
# Linux/macOS
sudo apt install libta-lib-dev  # Ubuntu/Debian
brew install ta-lib             # macOS

# Windows
pip install talib-binary
# Or download wheel from: https://www.lfd.uci.edu/~gohlke/pythonlibs/#ta-lib
```

#### 2. TensorFlow Installation Issues
```bash
# CPU-only version
pip install tensorflow-cpu

# For older systems
pip install tensorflow==2.12.0
```

#### 3. Memory Issues
```bash
# Reduce batch size in config.json
"batch_size": 16  # Instead of 32

# Use CPU-only TensorFlow
pip uninstall tensorflow
pip install tensorflow-cpu
```

#### 4. Permission Errors (Linux)
```bash
# Use virtual environment (recommended)
python3 -m venv crypto_env
source crypto_env/bin/activate

# Or install with user flag
pip install --user package_name
```

#### 5. Streamlit Port Issues
```bash
# Use different port
streamlit run crypto_ui.py --server.port=8502

# Or specify in launch
python3 launch.py --port 8502
```

## 🎯 Quick Start Commands

After successful installation:

```bash
# Method 1: Use launcher (recommended)
python3 launch.py

# Method 2: Direct Streamlit launch
streamlit run crypto_ui.py

# Method 3: Test first, then launch
python3 test_system.py && streamlit run crypto_ui.py
```

## 🔄 Updates and Maintenance

### Update Dependencies
```bash
# Activate environment
source crypto_env/bin/activate  # Linux/macOS
# crypto_env\Scripts\activate   # Windows

# Update packages
pip install --upgrade -r requirements.txt

# Update specific package
pip install --upgrade yfinance
```

### Check for Issues
```bash
# Run health check
python3 test_system.py

# Check package versions
pip list | grep -E "(tensorflow|pandas|numpy|streamlit)"
```

## 💡 Performance Tips

### For Better Performance:
1. **Use SSD storage** for faster data access
2. **Increase RAM** for larger datasets
3. **Use GPU** for faster model training
4. **Close other applications** during training
5. **Use smaller datasets** for testing

### GPU Setup (Optional):
```bash
# Install CUDA (NVIDIA GPUs only)
# Follow: https://developer.nvidia.com/cuda-downloads

# Install TensorFlow GPU
pip install tensorflow[and-cuda]

# Verify GPU detection
python3 -c "import tensorflow as tf; print('GPU Available:', tf.config.list_physical_devices('GPU'))"
```

## 📞 Getting Help

If you encounter issues:

1. **Check this guide** for common solutions
2. **Run test script**: `python3 test_system.py`
3. **Check system requirements** and versions
4. **Try alternative installation methods**
5. **Use Docker** for isolated environment

## ⚠️ Important Notes

- **Educational Purpose**: This tool is for learning and research
- **Risk Warning**: Cryptocurrency trading involves significant risk
- **No Guarantees**: Past performance doesn't predict future results
- **Test First**: Always use paper trading before real money
- **Stay Updated**: Keep dependencies updated for security

---

🚀 **Ready to start?** Run `python3 launch.py` and begin your AI trading journey!