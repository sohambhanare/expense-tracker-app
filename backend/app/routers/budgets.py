from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..database import get_db
from ..deps import get_current_user
from ..models import Budget, Category
from ..schemas import BudgetIn, BudgetOut

router = APIRouter(prefix="/budgets", tags=["budgets"])


def _load_category(category_id: int, user, db: Session) -> Category:
    cat = db.scalar(
        select(Category).where(Category.id == category_id, Category.user_id == user.id)
    )
    if cat is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Category not found")
    return cat


@router.get("", response_model=list[BudgetOut])
def list_budgets(
    user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return list(
        db.scalars(
            select(Budget).where(Budget.user_id == user.id).order_by(Budget.category_id)
        )
    )


@router.put("/{category_id}", response_model=BudgetOut)
def upsert_budget(
    category_id: int,
    payload: BudgetIn,
    user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Create or update the monthly budget limit for a category."""
    _load_category(category_id, user, db)
    budget = db.scalar(
        select(Budget).where(
            Budget.user_id == user.id, Budget.category_id == category_id
        )
    )
    if budget is None:
        budget = Budget(
            user_id=user.id,
            category_id=category_id,
            monthly_limit=payload.monthly_limit,
        )
        db.add(budget)
    else:
        budget.monthly_limit = payload.monthly_limit
    db.commit()
    db.refresh(budget)
    return budget


@router.delete("/{category_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_budget(
    category_id: int,
    user=Depends(get_current_user),
    db: Session = Depends(get_db),
):
    budget = db.scalar(
        select(Budget).where(
            Budget.user_id == user.id, Budget.category_id == category_id
        )
    )
    if budget is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "No budget for this category")
    db.delete(budget)
    db.commit()
