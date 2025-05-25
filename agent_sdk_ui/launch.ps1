# Agent SDK UI Launch Script
# This script launches the Streamlit web interface for the Agent SDK

Write-Host "🤖 Launching Agent SDK UI..." -ForegroundColor Green

# Check if streamlit is installed
try {
    streamlit --version | Out-Null
    Write-Host "✅ Streamlit is installed" -ForegroundColor Green
} catch {
    Write-Host "❌ Streamlit not found. Installing..." -ForegroundColor Yellow
    pip install -r requirements.txt
}

# Change to the UI directory
Set-Location "h:\My Drive\Github\Agentic Data Science\agent_sdk_ui"

Write-Host "🚀 Starting Streamlit app..." -ForegroundColor Green
Write-Host "📱 The app will open in your browser at http://localhost:8501" -ForegroundColor Cyan
Write-Host "⏹️  Press Ctrl+C to stop the server" -ForegroundColor Yellow

# Launch Streamlit
streamlit run app.py --server.port 8501 --server.address localhost
