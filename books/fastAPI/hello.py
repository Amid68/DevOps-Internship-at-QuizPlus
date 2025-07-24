from fastapi import FastAPI
from fastapi import Response

app = FastAPI()

@app.get("/hi")
def greet(who):
    return f"Hello? {who}?"

@app.get("/happy")
def happy(status_code=200):
    return ":)"

@app.get("/header/{name}/{value}")
def header(name: str, value: str, response:Response):
    response.headers[name] = value
    return "normal body"
