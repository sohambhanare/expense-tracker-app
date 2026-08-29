import os

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .database import Base, engine
from .routers import auth, budgets, categories, stats, transactions

ALLOWED_ORIGINS = os.environ.get("ALLOWED_ORIGINS", "*").split(",")

app = FastAPI(
    title="Expense Tracker API",
    description="REST API for a personal finance tracker: auth, transactions, categories, stats.",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[o.strip() for o in ALLOWED_ORIGINS],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(budgets.router)
app.include_router(categories.router)
app.include_router(transactions.router)
app.include_router(stats.router)


@app.on_event("startup")
def on_startup() -> None:
    Base.metadata.create_all(engine)


@app.get("/", tags=["meta"])
def root():
    return {"name": "Expense Tracker API", "docs": "/docs", "health": "/health"}


@app.get("/health", tags=["meta"])
def health():
    return {"status": "ok"}
