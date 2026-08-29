from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..database import get_db
from ..deps import get_current_user
from ..models import Category, User
from ..schemas import CategoryIn, CategoryOut

router = APIRouter(prefix="/categories", tags=["categories"])


@router.get("", response_model=list[CategoryOut])
def list_categories(user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    return list(
        db.scalars(select(Category).where(Category.user_id == user.id).order_by(Category.name))
    )


@router.post("", response_model=CategoryOut, status_code=status.HTTP_201_CREATED)
def create_category(
    payload: CategoryIn,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    dup = db.scalar(
        select(Category).where(Category.user_id == user.id, Category.name == payload.name.strip())
    )
    if dup:
        raise HTTPException(status.HTTP_409_CONFLICT, "Category already exists")
    cat = Category(user_id=user.id, name=payload.name.strip(), color=payload.color, icon=payload.icon)
    db.add(cat)
    db.commit()
    db.refresh(cat)
    return cat


@router.put("/{category_id}", response_model=CategoryOut)
def update_category(
    category_id: int,
    payload: CategoryIn,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    cat = db.scalar(select(Category).where(Category.id == category_id, Category.user_id == user.id))
    if cat is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Category not found")
    cat.name = payload.name.strip()
    cat.color = payload.color
    cat.icon = payload.icon
    db.commit()
    db.refresh(cat)
    return cat


@router.delete("/{category_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_category(
    category_id: int,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    cat = db.scalar(select(Category).where(Category.id == category_id, Category.user_id == user.id))
    if cat is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Category not found")
    db.delete(cat)  # transactions fall back to category_id=NULL via ON DELETE SET NULL
    db.commit()
