import calendar
from datetime import date

from fastapi import APIRouter, Depends, Query
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from ..database import get_db
from ..deps import get_current_user
from ..models import Budget, Transaction, User
from ..schemas import BudgetStatus, CategorySlice, MonthlyPoint, Summary

router = APIRouter(prefix="/stats", tags=["stats"])


@router.get("/summary", response_model=Summary)
def summary(
    months: int = Query(6, ge=1, le=24),
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    today = date.today()
    first_of_month = today.replace(day=1)

    # Overall balance
    income_total = db.scalar(
        select(func.coalesce(func.sum(Transaction.amount), 0.0)).where(
            Transaction.user_id == user.id, Transaction.type == "income"
        )
    )
    expense_total = db.scalar(
        select(func.coalesce(func.sum(Transaction.amount), 0.0)).where(
            Transaction.user_id == user.id, Transaction.type == "expense"
        )
    )
    balance = float(income_total) - float(expense_total)

    # This month
    month_income = db.scalar(
        select(func.coalesce(func.sum(Transaction.amount), 0.0)).where(
            Transaction.user_id == user.id,
            Transaction.type == "income",
            Transaction.date >= first_of_month,
        )
    )
    month_expense = db.scalar(
        select(func.coalesce(func.sum(Transaction.amount), 0.0)).where(
            Transaction.user_id == user.id,
            Transaction.type == "expense",
            Transaction.date >= first_of_month,
        )
    )
    month_income, month_expense = float(month_income), float(month_expense)

    # Expense slices by category (current month)
    rows = db.execute(
        select(
            Transaction.category_id,
            func.coalesce(func.sum(Transaction.amount), 0.0),
        )
        .where(
            Transaction.user_id == user.id,
            Transaction.type == "expense",
            Transaction.date >= first_of_month,
        )
        .group_by(Transaction.category_id)
    ).all()

    from ..models import Category

    cat_map = {
        c.id: c for c in db.scalars(select(Category).where(Category.user_id == user.id))
    }
    month_expense_sum = month_expense if month_expense > 0 else 1.0
    slices = [
        CategorySlice(
            category_id=cid,
            name=cat_map[cid].name if cid in cat_map else "Uncategorized",
            color=cat_map[cid].color if cid in cat_map else "#9E9E9E",
            total=float(total),
            share=float(total) / month_expense_sum,
        )
        for cid, total in rows
    ]
    slices.sort(key=lambda s: s.total, reverse=True)

    # Monthly trend for the last `months` months
    trend: list[MonthlyPoint] = []
    for i in range(months - 1, -1, -1):
        month = first_of_month.month - i
        year = first_of_month.year
        while month <= 0:
            month += 12
            year -= 1
        start = date(year, month, 1)
        end = date(year + (month == 12), (month % 12) + 1, 1)
        inc = db.scalar(
            select(func.coalesce(func.sum(Transaction.amount), 0.0)).where(
                Transaction.user_id == user.id,
                Transaction.type == "income",
                Transaction.date >= start,
                Transaction.date < end,
            )
        )
        exp = db.scalar(
            select(func.coalesce(func.sum(Transaction.amount), 0.0)).where(
                Transaction.user_id == user.id,
                Transaction.type == "expense",
                Transaction.date >= start,
                Transaction.date < end,
            )
        )
        inc, exp = float(inc), float(exp)
        trend.append(MonthlyPoint(month=start.strftime("%Y-%m"), income=inc, expense=exp, net=inc - exp))

    # Budget progress for the current month
    user_budgets = list(
        db.scalars(select(Budget).where(Budget.user_id == user.id).order_by(Budget.id))
    )
    budget_statuses: list[BudgetStatus] = []
    if user_budgets:
        spent_rows = dict(
            db.execute(
                select(Transaction.category_id, func.sum(Transaction.amount))
                .where(
                    Transaction.user_id == user.id,
                    Transaction.type == "expense",
                    Transaction.date >= first_of_month,
                    Transaction.category_id.isnot(None),
                )
                .group_by(Transaction.category_id)
            ).all()
        )
        for b in user_budgets:
            cat = cat_map.get(b.category_id)
            if cat is None:
                continue
            spent = float(spent_rows.get(b.category_id, 0.0))
            limit = float(b.monthly_limit)
            budget_statuses.append(
                BudgetStatus(
                    category_id=b.category_id,
                    name=cat.name,
                    color=cat.color,
                    limit=limit,
                    spent=spent,
                    pct=(spent / limit) if limit > 0 else 0.0,
                    remaining=limit - spent,
                )
            )
        budget_statuses.sort(key=lambda s: -s.pct)

    return Summary(
        balance=balance,
        month_income=month_income,
        month_expense=month_expense,
        month_net=month_income - month_expense,
        top_categories=slices,
        trend=trend,
        budgets=budget_statuses,
    )
