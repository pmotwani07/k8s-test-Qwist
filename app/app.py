from flask import Flask
import os
app = Flask(__name__)

@app.route('/')
def index():
    return f"Hello from Pankaj Personal Test app! pod={os.environ.get('HOSTNAME')}"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
