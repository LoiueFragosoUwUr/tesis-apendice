    #Se implementa el endpoint de inicio de sesión.
@app.post("/auth/login", response_model=AuthResponse)# La ruta POST coeresponde a  /auth/login
#Se garantiza la forma del JSON y ocultan campos no permitidos
def login(payload: UserLogin, db: Session = Depends(get_db)):
    user = db.query(Usuario).filter(Usuario.email == payload.email).first()
    if not user or not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Credenciales inválidas")

    token = create_access_token(
        subject=str(user.usuarioid),
        extra={"email": user.email, "tipo": user.tipo.code if user.tipo else None}
    )
    return {
        "token": {"access_token": token, "token_type": "bearer"},
        "user": to_user_out(user)
    }

# /me protegido con Bearer
bearer = HTTPBearer()
