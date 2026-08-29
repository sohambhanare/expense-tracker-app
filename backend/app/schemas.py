from datetime import date

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator

# ---------- Auth ----------


class RegisterIn(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)


class LoginIn(BaseModel):
    email: EmailStr
    password: str


class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    email: EmailStr


class TokenOut(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserOut


# ---------- Categories ----------


class CategoryIn(BaseModel):
    name: str = Field(min_length=1, max_length=60)
    color: str = Field(default="#6750A4", pattern=r"^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$")
    icon: str = Field(default="label", max_length=40)


class CategoryOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    color: str
    icon: str


# ---------- Transactions ----------


class TransactionIn(BaseModel):
    type: str = Field(pattern=r"^(income|expense)$")
    amount: float = Field(gt=0, le=10_000_000)
    note: str = Field(default="", max_length=280)
    date: date
    category_id: int | None = None

    @field_validator("amount")
    @classmethod
    def round_amount(cls, v: float) -> float:
        return round(v, 2)


class TransactionOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    type: str
    amount: float
    note: str
    date: date
    category_id: int | None
    category: CategoryOut | None = None


# ---------- Stats ----------


class CategorySlice(BaseModel):
    category_id: int | None
    name: str
    color: str
    total: float
    share: float  # 0..1


class BudgetStatus(BaseModel):
    category_id: int
    name: str
    color: str
    limit: float
    spent: float
    pct: float  # 0..n, can exceed 1 when over budget
    remaining: float


class MonthlyPoint(BaseModel):
    month: str  # e.g. "2026-04"
    income: float
    expense: float
    net: float


class Summary(BaseModel):
    balance: float
    month_income: float
    month_expense: float
    month_net: float
    top_categories: list[CategorySlice]
    trend: list[MonthlyPoint]
    budgets: list[BudgetStatus] = []


# ---------- Budgets ----------


class BudgetIn(BaseModel):
    monthly_limit: float = Field(gt=0, le=10_000_000)

    @field_validator("monthly_limit")
    @classmethod
    def round_limit(cls, v: float) -> float:
        return round(v, 2)


class BudgetOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    category_id: int
    monthly_limit: float
