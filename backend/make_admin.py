# pyrefly: ignore [missing-import]
from database import SessionLocal
# pyrefly: ignore [missing-import]
from models import User
import sys

def make_admin(email: str):
    db = SessionLocal()
    user = db.query(User).filter(User.email == email).first()
    if not user:
        print(f"User with email '{email}' not found!")
        return
    
    user.is_superadmin = True
    db.commit()
    print(f"Success! {user.name} ({user.email}) is now a Super Admin.")
    db.close()

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python make_admin.py <your_email>")
    else:
        make_admin(sys.argv[1])
