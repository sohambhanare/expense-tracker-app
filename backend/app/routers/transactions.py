from datetime import date

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.orm import Session, joinedload

from ..database import get_db
from ..deps import get_current_user
from ..models import Category, Transaction, User
from ..schemas import TransactionIn, TransactionOut

router = APIRouter(prefix="/transactions", tags=["transactions"])


def _load(txn_id: int, user: User, db: Session) -> Transaction:
    txn = db.scalar(
        select(Transaction).where(Transaction.id == txn_id, Transaction.user_id == user.id)
    )
    if txn is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Transaction not found")
    return txn


def _validate_category(category_id: int | None, user: User, db: Session) -> None:
    if category_id is None:
        return
    ok = db.scalar(
        select(Category.id).where(Category.id == category_id, Category.user_id == user.id)
    )
    if ok is None:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Unknown category for this account")


@router.get("", response_model=list[TransactionOut])
def list_transactions(
    type: str | None = Query(None, pattern=r"^(income|expense)$"),
    category_id: int | None = None,
    from_date: date | None = None,
    to_date: date | None = None,
    limit: int = Query(100, ge=1, le=500),
    offset: int = Query(0, ge=0),
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    stmt = (
        select(Transaction)
        .options(joinedload(Transaction.category))
        .where(Transaction.user_id == user.id)
        .order_by(Transaction.date.desc(), Transaction.id.desc())
    )
    if type:
        stmt = stmt.where(Transaction.type == type)
    if category_id is not None:
        stmt = stmt.where(Transaction.category_id == category_id)
    if from_date is not None:
        stmt = stmt.where(Transaction.date >= from_date)
    if to_date is not None:
        stmt = stmt.where(Transaction.date <= to_date)
    stmt = stmt.limit(limit).offset(offset)
    return list(db.scalars(stmt))


@router.post("", response_model=TransactionOut, status_code=status.HTTP_201_CREATED)
def create_transaction(
    payload: TransactionIn,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    _validate_category(payload.category_id, user, db)
    txn = Transaction(user_id=user.id, **payload.model_dump())
    db.add(txn)
    db.commit()
    db.refresh(txn)
    return txn


@router.get("/{txn_id}", response_model=TransactionOut)
def get_transaction(
    txn_id: int,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return _load(txn_id, user, db)


@router.put("/{txn_id}", response_model=TransactionOut)
def update_transaction(
    txn_id: int,
    payload: TransactionIn,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    txn = _load(txn_id, user, db)
    _validate_category(payload.category_id, user, db)
    for key, value in payload.model_dump().items():
        setattr(txn, key, value)
    db.commit()
    db.refresh(txn)
    return txn


@router.delete("/{txn_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_transaction(
    txn_id: int,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    db.delete(_load(txn_id, user, db))
    db.commit()
