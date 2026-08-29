from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..database import get_db
from ..deps import get_current_user
from ..models import Category, User
from ..schemas import LoginIn, RegisterIn, TokenOut, UserOut
from ..security import create_access_token, hash_password, verify_password

router = APIRouter(prefix="/auth", tags=["auth"])

DEFAULT_CATEGORIES = [
    # name, color, icon
    ("Food & Drinks", "#FF7043", "restaurant"),
    ("Groceries", "#66BB6A", "shopping_cart"),
    ("Transport", "#42A5F5", "directions_car"),
    ("Housing", "#8D6E63", "home"),
    ("Bills & Utilities", "#AB47BC", "receipt"),
    ("Health", "#EF5350", "favorite"),
    ("Entertainment", "#FFA726", "movie"),
    ("Shopping", "#EC407A", "shopping_bag"),
    ("Education", "#5C6BC0", "school"),
    ("Salary", "#26A69A", "payments"),
    ("Freelance", "#26C6DA", "work"),
    ("Other", "#9E9E9E", "label"),
]


def _seed_categories(db: Session, user: User) -> None:
    for name, color, icon in DEFAULT_CATEGORIES:
        db.add(Category(user_id=user.id, name=name, color=color, icon=icon))
    db.commit()


@router.post("/register", response_model=TokenOut, status_code=status.HTTP_201_CREATED)
def register(payload: RegisterIn, db: Session = Depends(get_db)):
    email = payload.email.lower()
    exists = db.scalar(select(User).where(User.email == email))
    if exists:
        raise HTTPException(status.HTTP_409_CONFLICT, "An account with this email already exists")

    user = User(
        name=payload.name.strip(),
        email=email,
        password_hash=hash_password(payload.password),
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    _seed_categories(db, user)
    return TokenOut(
        access_token=create_access_token(user.id),
        user=UserOut.model_validate(user),
    )


@router.post("/login", response_model=TokenOut)
def login(payload: LoginIn, db: Session = Depends(get_db)):
    user = db.scalar(select(User).where(User.email == payload.email.lower()))
    if user is None or not verify_password(payload.password, user.password_hash):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Incorrect email or password")
    return TokenOut(
        access_token=create_access_token(user.id),
        user=UserOut.model_validate(user),
    )


@router.get("/me", response_model=UserOut)
def me(user: User = Depends(get_current_user)):
    return user
